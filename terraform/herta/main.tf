terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

resource "proxmox_vm_qemu" "herta" {
  name        = var.vm_name
  target_node = var.proxmox_node
  desc        = "Herta VM - Docker host for homelab services"
  
  # Clone from template
  clone      = var.template_name
  full_clone = true
  
  # VM Resources
  cores   = var.vm_cores
  sockets = var.vm_sockets
  memory  = var.vm_memory
  
  # Boot settings
  boot    = "order=scsi0"
  onboot  = true
  agent   = 1  # QEMU Guest Agent
  
  # Network configuration
  network {
    model  = "virtio"
    bridge = var.vm_network_bridge
    tag    = var.vm_vlan_tag != 0 ? var.vm_vlan_tag : null
  }
  
  # Disk configuration
  disk {
    type    = "scsi"
    storage = var.vm_storage
    size    = var.vm_disk_size
    format  = "raw"
    ssd     = 1
    discard = "on"
  }
  
  # Cloud-init configuration
  os_type   = "cloud-init"
  ipconfig0 = var.vm_ip_config
  
  ciuser     = var.vm_user
  cipassword = var.vm_password
  sshkeys    = var.vm_ssh_keys
  
  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# Output VM information
output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_vm_qemu.herta.vmid
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_vm_qemu.herta.name
}

output "vm_ip" {
  description = "The IP address configuration"
  value       = proxmox_vm_qemu.herta.ipconfig0
}
