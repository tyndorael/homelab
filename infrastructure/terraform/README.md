# Terraform Proxmox: VM "nami"

Terraform project to manage VMs in Proxmox using the `ubuntu-cloudinit` template and the `iono-proxmox.pub` public key. Uses the `Telmate/proxmox` provider.

## Requirements
- Terraform >= 1.5 installed.
- Access to the Proxmox API (e.g., `https://192.168.50.153:8006`). Cluster/node name: `iono` (default in variables).
- API token with permissions: VM/Clone, VM/Config, VM/Console, VM/Monitor, Datastore/AllocateSpace, SDN/Use, Sys/Modify on the target node.
- Existing cloud-init template: `ubuntu-cloudinit` (already with the right public key or use `ssh_public_key_path`).

## Quick setup
1) Copy the sample variables and edit sensitive values:

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your token, node (default `iono`), and if needed storage/bridge
```

2) (Optional) Use env vars instead of writing the secret to disk:

```bash
export TF_VAR_pm_api_token_secret="<token-secret>"
```

## Provision the VM "nami"

```bash
cd infrastructure/terraform
terraform init -upgrade
terraform plan -out plan/terraform.tfplan
terraform apply plan/terraform.tfplan
```

Terraform will print the VM `id` and node at the end.

## Destroy the VM

```bash
cd infrastructure/terraform
terraform destroy
```

## Notes
- State is stored locally at `state/terraform.tfstate`; the `state/` folder is ignored in git.
- Plans are written to `plan/terraform.tfplan` by the example commands; the `plan/` folder is ignored in git.
- `ssh_public_key_path` defaults to `../../keys/iono-proxmox.pub`. Adjust if you use another key.
- To avoid cert issues in local labs, `pm_tls_insecure` defaults to `true`.
