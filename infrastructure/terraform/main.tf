terraform {
  required_version = ">= 1.5.0"

  backend "local" {
    path = "state/terraform.tfstate"
  }

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_user             = var.pm_user
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
  pm_parallel         = 1
}

resource "proxmox_vm_qemu" "nami" {
  name        = "nami"
  target_node = var.pm_target_node

  # Source: existing cloud-init template in Proxmox
  clone      = var.template_name
  full_clone = true

  # Hardware
  agent    = 1
  os_type  = "cloud-init"
  memory   = var.vm_memory
  bios     = "ovmf"
  machine  = "q35"
  scsihw   = "virtio-scsi-pci"
  boot     = "order=scsi0;net0"
  bootdisk = "scsi0"

  cpu {
    cores   = var.vm_cores
    sockets = 1
  }

  disk {
    slot     = "scsi0"
    size     = var.vm_disk_size
    type     = "disk"
    storage  = var.vm_disk_storage
    iothread = true
    discard  = true
  }

  # Cloud-init disk
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.vm_disk_storage
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.vm_bridge
    firewall = true
  }

  # Cloud-init
  ipconfig0 = var.vm_ipconfig0
  ciuser    = var.vm_ci_user
  cipassword = var.vm_ci_password
  sshkeys   = file(var.ssh_public_key_path)

  # Optional: Proxmox pool
  pool = var.pm_pool

  lifecycle {
    ignore_changes = [
      # Allow updating the base template without forcing reprovision
      clone,
    ]
  }
}
