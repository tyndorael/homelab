# Homelab Infrastructure

IaC and automation for a Proxmox-based homelab. Terraform handles VM lifecycle; Ansible configures guests, Pi nodes, and service stacks.

## Layout
- infrastructure/terraform: Proxmox VM definitions and variables
- infrastructure/ansible: Playbooks for guests, AI server, Pi, mounts
- stacks/: Docker Compose stacks and setup guides
- keys/: Local SSH keys (should stay untracked)

## Quick start
1) Terraform
   - From infrastructure/terraform: `terraform init` then `terraform plan -out plan/terraform.tfplan` and `terraform apply plan/terraform.tfplan`.
   - Use environment vars (recommended) instead of committing secrets:
     - `TF_VAR_pm_api_url`, `TF_VAR_pm_api_token_id`, `TF_VAR_pm_api_token_secret`, `TF_VAR_vm_ci_password`, etc.
   - Keep terraform.tfvars local and gitignored if you use one.

2) Ansible
   - Inventory: infrastructure/ansible/inventory/hosts.ini
   - Examples:
     - Base tools on Proxmox guests: `ansible-playbook base-tools.yml -i inventory/hosts.ini -e docker_user=<user>`
     - SMB mounts: `ansible-playbook smb-mount.yml -i inventory/hosts.ini -e "smb_username=<user> smb_password=<pass>"`
     - Pi Docker/Portainer: `ansible-playbook pi-tools.yml -i inventory/hosts.ini`

## Secrets hygiene
- Do not commit terraform.tfvars or private keys. Use terraform.tfvars.example as a template.
- Store SSH keys outside git (keys/ is local-only) and rotate any exposed credentials.
