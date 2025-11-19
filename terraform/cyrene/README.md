# Cyrene VM - Terraform Configuration

This directory contains Terraform configuration to deploy the Cyrene VM on Proxmox.

## Prerequisites

See the main [Herta VM README](../herta/README.md) for complete setup instructions including:
- Terraform installation
- Proxmox API token creation
- User permissions setup
- Ubuntu cloud-init template verification (ID: 8000)

## Quick Start

### 1. Configure the VM

```powershell
# Copy example configuration
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit with your settings
notepad terraform.tfvars
```

### 2. Update Configuration

Key settings to customize in `terraform.tfvars`:

```hcl
# Proxmox connection
proxmox_api_url          = "https://YOUR_PROXMOX_IP:8006/api2/json"
proxmox_api_token_secret = "YOUR-TOKEN-SECRET"

# Network - Recommended: Static IP for Cyrene
vm_ip_config = "ip=192.168.1.101/24,gw=192.168.1.1"

# SSH Key
vm_ssh_keys = "ssh-rsa AAAAB... your-key"
```

### 3. Deploy

```powershell
# Initialize Terraform
terraform init

# Review changes
terraform plan

# Deploy VM
terraform apply
```

### 4. Connect

```bash
# SSH to Cyrene VM
ssh ubuntu@192.168.1.101

# Or use terraform output
ssh ubuntu@$(terraform output -raw vm_ip | cut -d'=' -f2 | cut -d',' -f1)
```

## VM Specifications

**Default Configuration:**
- Name: `cyrene`
- Template: `ubuntu-cloudinit` (ID: 8000)
- CPU: 4 cores, 1 socket
- Memory: 8GB
- Disk: 50GB
- Network: vmbr0 (bridge mode)
- IP: 192.168.1.101/24 (example - customize in tfvars)

## Customization

Adjust resources in `terraform.tfvars`:

```hcl
vm_cores     = 6     # More CPU cores
vm_memory    = 16384 # 16GB RAM
vm_disk_size = "100G" # Larger disk
```

Then apply changes:
```powershell
terraform apply
```

## Integration with Homelab

After VM creation, run the homelab setup script:

```bash
# Clone homelab repository
git clone https://github.com/your-username/homelab.git
cd homelab

# Run setup
chmod +x setup-homelab.sh
./setup-homelab.sh
```

## Management

```powershell
# View VM details
terraform show

# Get outputs
terraform output

# Update VM (after editing tfvars)
terraform apply

# Destroy VM
terraform destroy
```

## Secret Management

For secure credential storage using HashiCorp Vault, see [VAULT_SETUP.md](../VAULT_SETUP.md).

## Troubleshooting

For common issues, see the [Herta VM README troubleshooting section](../herta/README.md#troubleshooting).

## Related VMs

- [Herta VM](../herta/) - Primary Docker host (192.168.1.100)
- [Bronya VM](../bronya/) - Additional Docker host (192.168.1.102)
