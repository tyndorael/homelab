output "nami_id" {
  description = "Internal VM ID in Proxmox"
  value       = proxmox_vm_qemu.nami.id
}

output "nami_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.nami.name
}

output "nami_node" {
  description = "Proxmox node where the VM was created"
  value       = proxmox_vm_qemu.nami.target_node
}
