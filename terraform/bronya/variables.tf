# Proxmox Provider Variables
variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox.local:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., terraform@pam!terraform)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (useful for self-signed certificates)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name where the VM will be created"
  type        = string
  default     = "pve"
}

# VM Configuration Variables
variable "vm_name" {
  description = "Name of the VM"
  type        = string
  default     = "bronya"
}

variable "template_name" {
  description = "Name of the template to clone from"
  type        = string
  default     = "ubuntu-cloudinit"
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "vm_sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "vm_memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 8192
}

variable "vm_disk_size" {
  description = "Disk size (e.g., '50G')"
  type        = string
  default     = "50G"
}

variable "vm_storage" {
  description = "Storage pool name"
  type        = string
  default     = "local-lvm"
}

# Network Configuration Variables
variable "vm_network_bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}

variable "vm_vlan_tag" {
  description = "VLAN tag (0 for no VLAN)"
  type        = number
  default     = 0
}

variable "vm_ip_config" {
  description = "IP configuration (e.g., 'ip=192.168.1.100/24,gw=192.168.1.1' or 'ip=dhcp')"
  type        = string
  default     = "ip=dhcp"
}

# Cloud-init Variables
variable "vm_user" {
  description = "Default user for cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "vm_password" {
  description = "Password for the default user"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vm_ssh_keys" {
  description = "SSH public keys for the default user (one per line)"
  type        = string
  default     = ""
}
