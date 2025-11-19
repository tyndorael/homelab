# HashiCorp Vault Integration Example
# This file demonstrates how to use Vault with Terraform for secret management

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
  }
}

# Configure Vault provider
provider "vault" {
  address = var.vault_address  # e.g., "https://vault.example.com:8200"
  
  # Option 1: Use token authentication
  token = var.vault_token
  
  # Option 2: Use AppRole authentication (more secure for automation)
  # auth_login {
  #   path = "auth/approle/login"
  #   parameters = {
  #     role_id   = var.vault_role_id
  #     secret_id = var.vault_secret_id
  #   }
  # }
}

# Read secrets from Vault
data "vault_generic_secret" "proxmox_credentials" {
  path = "secret/homelab/proxmox"
  # Expected keys in this secret:
  # - api_token_id
  # - api_token_secret
}

data "vault_generic_secret" "vm_credentials" {
  path = "secret/homelab/vm"
  # Expected keys in this secret:
  # - user
  # - password
  # - ssh_public_key
}

# Use secrets in Proxmox provider
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = data.vault_generic_secret.proxmox_credentials.data["api_token_id"]
  pm_api_token_secret = data.vault_generic_secret.proxmox_credentials.data["api_token_secret"]
  pm_tls_insecure     = var.proxmox_tls_insecure
}

# Use secrets in VM resource
resource "proxmox_vm_qemu" "example" {
  # ... VM configuration ...
  
  ciuser     = data.vault_generic_secret.vm_credentials.data["user"]
  cipassword = data.vault_generic_secret.vm_credentials.data["password"]
  sshkeys    = data.vault_generic_secret.vm_credentials.data["ssh_public_key"]
}

# Variables for Vault configuration
variable "vault_address" {
  description = "Vault server address"
  type        = string
  default     = "https://vault.example.com:8200"
}

variable "vault_token" {
  description = "Vault authentication token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vault_role_id" {
  description = "Vault AppRole role ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vault_secret_id" {
  description = "Vault AppRole secret ID"
  type        = string
  sensitive   = true
  default     = ""
}
