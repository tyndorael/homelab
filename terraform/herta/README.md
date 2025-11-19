# Herta VM - Terraform Configuration

This directory contains Terraform configuration to deploy the Herta VM on Proxmox.

## Prerequisites

### 1. Install Terraform

**Windows (PowerShell):**
```powershell
# Using Chocolatey
choco install terraform

# Or using Scoop
scoop install terraform

# Verify installation
terraform version
```

**Linux:**
```bash
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 2. Create Proxmox API Token

1. Access Proxmox web interface: `https://your-proxmox:8006`
2. Navigate to **Datacenter** → **Permissions** → **API Tokens**
3. Click **Add**
4. Configure:
   - User: `terraform@pam`
   - Token ID: `terraform`
   - Privilege Separation: Unchecked (or configure appropriate permissions)
5. Click **Add**
6. **Save the token secret** - it won't be shown again!

### 3. Grant Permissions to Terraform User

```bash
# SSH to Proxmox server
ssh root@proxmox

# Create terraform user (if not exists)
pveum user add terraform@pam

# Grant necessary permissions
pveum aclmod / -user terraform@pam -role PVEVMAdmin
pveum aclmod /storage -user terraform@pam -role PVEDatastoreUser
```

### 4. Verify Ubuntu Cloud Image Template

This configuration uses the existing `ubuntu-cloudinit` template (ID: 8000).

To verify your template exists:

```bash
# SSH to Proxmox
ssh root@proxmox

# List templates
qm list | grep template

# View template configuration
qm config 8000
```

**Template Requirements:**
- Must have cloud-init support enabled
- Should have QEMU Guest Agent installed
- Network interface configured (virtio recommended)

## Configuration

### 1. Create Configuration File

Copy the example and customize:

```powershell
# Windows
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars

# Linux
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### 2. Required Configuration

Edit `terraform.tfvars` and update:

```hcl
# Proxmox connection
proxmox_api_url          = "https://YOUR_PROXMOX_IP:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!terraform"
proxmox_api_token_secret = "YOUR-TOKEN-SECRET"
proxmox_node             = "pve"  # Your node name

# Template
template_name = "ubuntu-cloudinit"  # Template ID: 8000

# Storage
vm_storage = "local-lvm"  # Your storage pool name

# Network - Static IP (recommended)
vm_ip_config = "ip=192.168.1.100/24,gw=192.168.1.1"

# SSH Key
vm_ssh_keys = <<-EOT
ssh-rsa AAAAB... your-public-key-here
EOT
```

### 3. Security Best Practices

**Option 1: HashiCorp Vault (Recommended for Production)**

Store secrets in Vault for centralized secret management:

```bash
# Store secrets in Vault
vault kv put secret/homelab/proxmox \
  api_token_id="terraform@pam!terraform" \
  api_token_secret="your-token-secret"

vault kv put secret/homelab/vm \
  user="ubuntu" \
  password="your-password" \
  ssh_public_key="ssh-rsa AAAAB..."
```

See [VAULT_SETUP.md](../VAULT_SETUP.md) for complete Vault integration guide.

**Option 2: Environment Variables**
```powershell
# Windows PowerShell
$env:TF_VAR_proxmox_api_token_secret = "your-token-secret"
$env:TF_VAR_vm_password = "your-vm-password"

# Linux
export TF_VAR_proxmox_api_token_secret="your-token-secret"
export TF_VAR_vm_password="your-vm-password"
```

**Option 3: secrets.auto.tfvars (Git-ignored)**
```hcl
proxmox_api_token_secret = "your-token-secret"
vm_password              = "your-vm-password"
```

## Deployment

### 1. Initialize Terraform

```powershell
terraform init
```

This downloads the Proxmox provider.

### 2. Review Plan

```powershell
terraform plan
```

Review the changes Terraform will make.

### 3. Apply Configuration

```powershell
terraform apply
```

Type `yes` when prompted. The VM will be created in ~1-2 minutes.

### 4. Get VM Information

```powershell
# Show all outputs
terraform output

# Specific output
terraform output vm_ip
```

## Post-Deployment

### 1. Connect to VM

```bash
# SSH using configured user
ssh ubuntu@192.168.1.100

# Or use the IP from terraform output
ssh ubuntu@$(terraform output -raw vm_ip | cut -d'=' -f2 | cut -d',' -f1)
```

### 2. Run Homelab Setup Script

```bash
# Clone homelab repository
git clone https://github.com/your-username/homelab.git
cd homelab

# Run setup script
chmod +x setup-homelab.sh
./setup-homelab.sh
```

## Management

### Update VM Configuration

1. Edit `terraform.tfvars` (e.g., increase memory)
2. Apply changes:
   ```powershell
   terraform apply
   ```

### View Current State

```powershell
terraform show
```

### Destroy VM

```powershell
terraform destroy
```

**⚠️ Warning**: This permanently deletes the VM!

## Troubleshooting

### Authentication Error

```
Error: error creating Api: error creating API client: error checking login: Received error for API call: <nil>
```

**Solution:**
- Verify `proxmox_api_url` is correct
- Check `proxmox_api_token_id` format: `user@realm!tokenid`
- Confirm `proxmox_api_token_secret` is correct
- Ensure Proxmox is accessible from your machine

### Permission Denied

```
Error: error creating VM: 403 Permission denied
```

**Solution:**
- Verify user has `PVEVMAdmin` role
- Check storage permissions: `PVEDatastoreUser`
- Test with Proxmox API:
  ```bash
  curl -k -H "Authorization: PVEAPIToken=terraform@pam!terraform=YOUR-TOKEN" \
    https://proxmox:8006/api2/json/nodes/pve/qemu
  ```

### Template Not Found

```
Error: Error cloning VM: VM 'ubuntu-cloudinit' not found
```

**Solution:**
- List templates: `qm list` on Proxmox
- Verify template ID 8000 exists: `qm config 8000`
- Ensure template is on the correct node
- Update `template_name` in `terraform.tfvars` if needed

### Cloud-init Not Working

VM created but can't SSH or no network:

**Solution:**
1. Check VM has cloud-init drive:
   ```bash
   qm config <vmid> | grep ide2
   ```
2. Verify cloud-init settings:
   ```bash
   qm cloudinit dump <vmid> user
   ```
3. Check VM console for errors:
   - Proxmox Web UI → VM → Console
   - Run: `sudo cloud-init status --long`

### Storage Not Found

```
Error: storage 'local-lvm' does not exist
```

**Solution:**
- List storage: `pvesm status` on Proxmox
- Update `vm_storage` in `terraform.tfvars`

## Advanced Configuration

### Multiple VMs

Create additional `.tf` files or use `count`:

```hcl
# Create 3 VMs
resource "proxmox_vm_qemu" "herta" {
  count = 3
  name  = "herta-${count.index + 1}"
  # ... rest of configuration
}
```

### Using Modules

```hcl
module "herta_vm" {
  source = "./modules/proxmox-vm"
  
  vm_name   = "herta"
  vm_cores  = 4
  vm_memory = 8192
  # ... other variables
}
```

### Remote State

Store state in Terraform Cloud or S3:

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "homelab/herta/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Files

- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `terraform.tfvars.example` - Example configuration
- `terraform.tfvars` - Your configuration (git-ignored)
- `.gitignore` - Prevents committing sensitive files

## Resources

- [Telmate Proxmox Provider Docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Proxmox API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
- [HashiCorp Vault Integration](../VAULT_SETUP.md) - Secure secret management

## Support

For issues specific to:
- **Terraform**: Check [Terraform Issues](https://github.com/hashicorp/terraform/issues)
- **Proxmox Provider**: Check [Provider Issues](https://github.com/Telmate/terraform-provider-proxmox/issues)
- **Homelab Setup**: See main [README.md](../../README.md)
