# HashiCorp Vault Integration for Terraform

This guide explains how to use HashiCorp Vault to manage secrets for your Terraform-managed VMs.

## Why Use Vault?

**Benefits:**
- Centralized secret management
- Secrets never stored in `.tfvars` files
- Automatic secret rotation
- Audit logging of secret access
- Fine-grained access control
- Encryption at rest and in transit

## Prerequisites

### Option 1: Use Existing Vault Server

If you already have Vault running (e.g., in your homelab):
- Vault server address (e.g., `https://vault.local:8200`)
- Access credentials (token or AppRole)

### Option 2: Deploy Vault with Docker

Quick setup for homelab:

```bash
# Create directories
mkdir -p vault/config vault/data vault/logs

# Create Vault configuration
cat > vault/config/vault.hcl <<EOF
ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

storage "file" {
  path = "/vault/data"
}

api_addr = "http://0.0.0.0:8200"
EOF

# Start Vault container
docker run -d \
  --name vault \
  --cap-add=IPC_LOCK \
  -p 8200:8200 \
  -v $(pwd)/vault/config:/vault/config:ro \
  -v $(pwd)/vault/data:/vault/data \
  -v $(pwd)/vault/logs:/vault/logs \
  vault:latest server
```

### Option 3: Deploy Vault in Kubernetes

See [Vault Helm Chart](https://github.com/hashicorp/vault-helm).

## Initial Vault Setup

### 1. Initialize Vault

```bash
# Set Vault address
export VAULT_ADDR='http://localhost:8200'

# Initialize Vault (first time only)
vault operator init

# Save output! You'll get:
# - 5 unseal keys
# - 1 root token
```

**⚠️ IMPORTANT**: Store unseal keys and root token securely (password manager, encrypted file, etc.).

### 2. Unseal Vault

Vault starts sealed. Unseal with 3 of 5 keys:

```bash
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

### 3. Login

```bash
vault login <root-token>
```

## Configure Vault for Terraform

### 1. Enable KV Secrets Engine

```bash
# Enable v2 KV secrets engine
vault secrets enable -version=2 -path=secret kv

# Or if using v1 (simpler)
vault secrets enable -version=1 -path=secret kv
```

### 2. Store Proxmox Credentials

```bash
# Store Proxmox API credentials
vault kv put secret/homelab/proxmox \
  api_token_id="terraform@pam!terraform" \
  api_token_secret="your-proxmox-token-secret"
```

### 3. Store VM Credentials

```bash
# Store VM user credentials
vault kv put secret/homelab/vm \
  user="ubuntu" \
  password="your-secure-password" \
  ssh_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
```

### 4. Create Terraform Policy

```bash
# Create policy file
cat > terraform-policy.hcl <<EOF
# Allow Terraform to read homelab secrets
path "secret/data/homelab/*" {
  capabilities = ["read", "list"]
}

path "secret/homelab/*" {
  capabilities = ["read", "list"]
}
EOF

# Apply policy
vault policy write terraform-policy terraform-policy.hcl
```

### 5. Create Token for Terraform

```bash
# Create token with Terraform policy
vault token create -policy=terraform-policy -period=768h -display-name="terraform-homelab"

# Save the token for Terraform
```

## Alternative: AppRole Authentication (Recommended for CI/CD)

More secure than tokens:

```bash
# Enable AppRole
vault auth enable approle

# Create AppRole
vault write auth/approle/role/terraform-homelab \
  token_policies="terraform-policy" \
  token_ttl=1h \
  token_max_ttl=4h

# Get Role ID
vault read auth/approle/role/terraform-homelab/role-id

# Generate Secret ID
vault write -f auth/approle/role/terraform-homelab/secret-id
```

## Integrate with Terraform

### Method 1: Using Environment Variables (Recommended)

```powershell
# Windows PowerShell
$env:VAULT_ADDR = "http://localhost:8200"
$env:VAULT_TOKEN = "your-terraform-token"

# Linux/macOS
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="your-terraform-token"
```

### Method 2: Update Terraform Configuration

Create `vault.tf` in each VM directory:

```hcl
# vault.tf
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
  }
}

provider "vault" {
  address = var.vault_address
}

# Read Proxmox credentials from Vault
data "vault_kv_secret_v2" "proxmox" {
  mount = "secret"
  name  = "homelab/proxmox"
}

# Read VM credentials from Vault
data "vault_kv_secret_v2" "vm" {
  mount = "secret"
  name  = "homelab/vm"
}

# Variable for Vault address
variable "vault_address" {
  description = "Vault server address"
  type        = string
  default     = "http://localhost:8200"
}
```

Update `main.tf`:

```hcl
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = data.vault_kv_secret_v2.proxmox.data["api_token_id"]
  pm_api_token_secret = data.vault_kv_secret_v2.proxmox.data["api_token_secret"]
  pm_tls_insecure     = var.proxmox_tls_insecure
}

resource "proxmox_vm_qemu" "herta" {
  # ... other configuration ...
  
  ciuser     = data.vault_kv_secret_v2.vm.data["user"]
  cipassword = data.vault_kv_secret_v2.vm.data["password"]
  sshkeys    = data.vault_kv_secret_v2.vm.data["ssh_public_key"]
}
```

## Deployment with Vault

```powershell
# Set Vault environment variables
$env:VAULT_ADDR = "http://localhost:8200"
$env:VAULT_TOKEN = "your-token"

# Initialize Terraform (first time)
cd terraform\herta
terraform init

# Plan (Terraform will fetch secrets from Vault)
terraform plan

# Apply
terraform apply
```

## Vault KV Version Differences

### KV v1 (Simpler)

```hcl
data "vault_generic_secret" "proxmox" {
  path = "secret/homelab/proxmox"
}

# Access: data.vault_generic_secret.proxmox.data["api_token_id"]
```

### KV v2 (Versioned - Recommended)

```hcl
data "vault_kv_secret_v2" "proxmox" {
  mount = "secret"
  name  = "homelab/proxmox"
}

# Access: data.vault_kv_secret_v2.proxmox.data["api_token_id"]
```

Check your version:
```bash
vault secrets list -detailed
```

## Security Best Practices

### 1. Use AppRole for Automation

Instead of long-lived tokens:

```powershell
# Set AppRole credentials
$env:VAULT_ROLE_ID = "your-role-id"
$env:VAULT_SECRET_ID = "your-secret-id"
```

Update Vault provider:
```hcl
provider "vault" {
  address = var.vault_address
  
  auth_login {
    path = "auth/approle/login"
    
    parameters = {
      role_id   = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}
```

### 2. Restrict Token Capabilities

```bash
# Create limited policy for specific VMs
cat > herta-policy.hcl <<EOF
path "secret/data/homelab/proxmox" {
  capabilities = ["read"]
}
path "secret/data/homelab/vm" {
  capabilities = ["read"]
}
EOF

vault policy write herta-policy herta-policy.hcl
vault token create -policy=herta-policy
```

### 3. Enable Audit Logging

```bash
vault audit enable file file_path=/vault/logs/audit.log
```

### 4. Use TLS in Production

```bash
# Generate certificates
vault write pki/root/generate/internal \
  common_name="vault.local" \
  ttl=87600h

# Update Vault config
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/certs/vault.crt"
  tls_key_file  = "/vault/certs/vault.key"
}
```

## Vault High Availability

For production, use HA setup:

```yaml
# docker-compose.yml
version: '3'
services:
  vault:
    image: vault:latest
    environment:
      VAULT_RAFT_NODE_ID: vault-node-1
    volumes:
      - ./vault-config.hcl:/vault/config/vault.hcl
      - vault-data:/vault/data
    ports:
      - "8200:8200"
    cap_add:
      - IPC_LOCK
```

## Troubleshooting

### Vault Sealed

```bash
vault status
# If sealed: true
vault operator unseal
```

### Permission Denied

```bash
# Check token capabilities
vault token capabilities secret/homelab/proxmox

# Verify policy
vault policy read terraform-policy
```

### Connection Refused

```bash
# Check Vault is running
curl $VAULT_ADDR/v1/sys/health

# Verify VAULT_ADDR is set
echo $VAULT_ADDR
```

### Token Expired

```bash
# Check token info
vault token lookup

# Renew token
vault token renew

# Create new token
vault token create -policy=terraform-policy
```

## Migration from tfvars to Vault

### 1. Store Current Secrets

```bash
# Read current secrets from terraform.tfvars
# Store in Vault
vault kv put secret/homelab/proxmox \
  api_token_id="$(grep api_token_id terraform.tfvars | cut -d'=' -f2 | tr -d ' "')" \
  api_token_secret="$(grep api_token_secret terraform.tfvars | cut -d'=' -f2 | tr -d ' "')"
```

### 2. Update Terraform Files

Add `vault.tf` to each VM directory (see example above).

### 3. Remove Secrets from tfvars

```hcl
# terraform.tfvars - after Vault migration
# Keep only non-sensitive configuration
proxmox_api_url = "https://192.168.1.10:8006/api2/json"
proxmox_node    = "pve"
vm_cores        = 4
vm_memory       = 8192
# ... other non-sensitive values
```

### 4. Test

```powershell
terraform plan
# Should fetch secrets from Vault
```

## Vault in Docker Stack

Add to your infrastructure stack:

```yaml
# stacks/infrastructure/infrastructure-stack.yml
services:
  vault:
    image: vault:latest
    container_name: vault
    cap_add:
      - IPC_LOCK
    ports:
      - "8200:8200"
    environment:
      - VAULT_ADDR=http://0.0.0.0:8200
    volumes:
      - vault-config:/vault/config:ro
      - vault-data:/vault/data
      - vault-logs:/vault/logs
    command: server
    restart: unless-stopped
    networks:
      - infrastructure
    labels:
      - "dockpeek.tags=infrastructure,secrets,vault"

volumes:
  vault-config:
  vault-data:
  vault-logs:
```

## Resources

- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Terraform Vault Provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
- [Vault on Docker Hub](https://hub.docker.com/_/vault)
- [Vault Best Practices](https://developer.hashicorp.com/vault/tutorials/operations/production-hardening)

## Quick Reference

```bash
# Common Vault commands
vault status                          # Check Vault status
vault operator unseal                 # Unseal Vault
vault login                          # Login to Vault
vault kv put secret/path key=value   # Store secret
vault kv get secret/path             # Read secret
vault kv list secret/                # List secrets
vault token create -policy=name      # Create token
vault policy list                    # List policies
vault policy read name               # Read policy
vault audit list                     # List audit devices
```

## Next Steps

1. Set up Vault server (Docker or existing)
2. Store Proxmox and VM credentials
3. Create Terraform policy and token
4. Add `vault.tf` to VM directories
5. Update `main.tf` to use Vault secrets
6. Set `VAULT_ADDR` and `VAULT_TOKEN` environment variables
7. Test with `terraform plan`
8. Remove sensitive values from `.tfvars` files
