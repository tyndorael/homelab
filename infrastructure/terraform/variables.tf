variable "pm_api_url" {
  description = "Proxmox API URL (e.g., https://192.168.50.153:8006/api2/json)"
  type        = string
  default     = "https://192.168.50.153:8006/api2/json"
}

variable "pm_user" {
  description = "Proxmox user with permissions on the target node (e.g., root@pam)"
  type        = string
  default     = "root@pam"
}

variable "pm_api_token_id" {
  description = "API token ID: <user>@pam!<token-name>"
  type        = string
}

variable "pm_api_token_secret" {
  description = "API token secret"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Allow insecure TLS for on-prem/without CA"
  type        = bool
  default     = true
}

variable "pm_target_node" {
  description = "Proxmox node name where the VM will be created"
  type        = string
  default     = "iono"
}

variable "pm_pool" {
  description = "Optional Proxmox pool to place the VM"
  type        = string
  default     = null
}

variable "template_name" {
  description = "Base cloud-init template name"
  type        = string
  default     = "ubuntu-cloudinit"
}

variable "vm_cores" {
  description = "Number of vCPUs for the VM"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "RAM in MB"
  type        = number
  default     = 4096
}


variable "vm_disk_size" {
  description = "Disk size (e.g., 20G)"
  type        = string
  default     = "32G"
}

variable "vm_disk_storage" {
  description = "Proxmox storage name for the disk (e.g., local-lvm)"
  type        = string
  default     = "local-lvm"
}


variable "vm_bridge" {
  description = "Proxmox network bridge (e.g., vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "vm_ipconfig0" {
  description = "Cloud-init network config. E.g., dhcp or ip=192.168.50.200/24,gw=192.168.50.1"
  type        = string
  default     = "dhcp"
}

variable "vm_ci_user" {
  description = "Cloud-init user to create inside the VM"
  type        = string
  default     = "ubuntu"
}

variable "vm_ci_password" {
  description = "Password for the cloud-init user (plaintext; consider using env TF_VAR_vm_ci_password)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to the public key file to inject (relative to this module)"
  type        = string
  default     = "../../keys/iono-proxmox.pub"
}
