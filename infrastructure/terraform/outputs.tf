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

output "nami_ipv4_guest_agent" {
  description = "Current IPv4 reported by qemu-guest-agent (null if unavailable)"
  value       = try(proxmox_vm_qemu.nami.default_ipv4_address, null)
}

output "nami_ipv6_guest_agent" {
  description = "Current IPv6 reported by qemu-guest-agent (null if unavailable)"
  value       = try(proxmox_vm_qemu.nami.default_ipv6_address, null)
}

output "herta_id" {
  description = "Internal VM ID in Proxmox"
  value       = proxmox_vm_qemu.herta.id
}

output "herta_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.herta.name
}

output "herta_node" {
  description = "Proxmox node where the VM was created"
  value       = proxmox_vm_qemu.herta.target_node
}

output "herta_ipv4_guest_agent" {
  description = "Current IPv4 reported by qemu-guest-agent (null if unavailable)"
  value       = try(proxmox_vm_qemu.herta.default_ipv4_address, null)
}

output "herta_ipv6_guest_agent" {
  description = "Current IPv6 reported by qemu-guest-agent (null if unavailable)"
  value       = try(proxmox_vm_qemu.herta.default_ipv6_address, null)
}

output "hyacine_id" {
  description = "Internal VM ID in Proxmox"
  value       = proxmox_vm_qemu.hyacine.id
}

output "hyacine_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.hyacine.name
}

output "hyacine_node" {
  description = "Proxmox node where the VM was created"
  value       = proxmox_vm_qemu.hyacine.target_node
}

output "hyacine_ipv4_guest_agent" {
  description = "Current IPv4 reported by qemu-guest-agent (null if unavailable)"
  value       = try(proxmox_vm_qemu.hyacine.default_ipv4_address, null)
}

output "hyacine_ipv6_guest_agent" {
  description = "Current IPv6 reported by qemu-guest-agent (null if unavailable)"
  value       = try(proxmox_vm_qemu.hyacine.default_ipv6_address, null)
}
