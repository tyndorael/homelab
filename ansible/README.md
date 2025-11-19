# Homelab Ansible Automation

This directory contains Ansible playbooks and roles to automate the provisioning and deployment of Docker-based homelab services.

## Overview

Ansible automates:
- ✅ System configuration (hostname, timezone, packages)
- ✅ Docker installation and configuration
- ✅ NFS and CIFS storage mounts
- ✅ Firewall setup (UFW)
- ✅ Docker TCP API configuration
- ✅ Docker stack deployment

## Prerequisites

### 1. Install Ansible

**Windows (WSL2 or PowerShell with Python):**
```powershell
# Using pip
pip install ansible

# Or using Chocolatey
choco install ansible
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# Or using pip
pip install ansible
```

**macOS:**
```bash
brew install ansible
```

### 2. Verify Installation

```bash
ansible --version
```

### 3. SSH Access to VMs

Ensure SSH key-based authentication is configured:

```bash
# Copy SSH key to VMs
ssh-copy-id ubuntu@192.168.1.100  # Herta
ssh-copy-id ubuntu@192.168.1.101  # Cyrene
ssh-copy-id ubuntu@192.168.1.102  # Bronya

# Test connection
ssh ubuntu@192.168.1.100
```

### 4. Update Inventory

Edit `inventory.ini` with your VM IP addresses:

```ini
[docker_hosts]
herta ansible_host=192.168.1.100
cyrene ansible_host=192.168.1.101
bronya ansible_host=192.168.1.102
```

## Configuration

### 1. Common Variables

Edit `group_vars/all.yml`:

```yaml
# System
timezone: "America/New_York"

# NFS Server
nfs_server: "192.168.1.10"

# CIFS Server
cifs_server: "192.168.1.10"
cifs_username: "your-username"
cifs_password: "your-password"

# Docker TCP API
docker_tcp_api_enabled: true
docker_tcp_api_port: 2375
```

### 2. Host-Specific Variables

Edit files in `host_vars/`:
- `herta.yml` - Herta-specific config
- `cyrene.yml` - Cyrene-specific config
- `bronya.yml` - Bronya-specific config

### 3. Secure Sensitive Variables

Use Ansible Vault for passwords:

```bash
# Create encrypted file
ansible-vault create secrets.yml

# Add to secrets.yml:
cifs_username: your-username
cifs_password: your-password
```

Update `group_vars/all.yml`:
```yaml
cifs_username: "{{ vault_cifs_username }}"
cifs_password: "{{ vault_cifs_password }}"
```

## Usage

### Test Connectivity

```bash
# Ping all hosts
ansible all -m ping

# Check if hosts are reachable
ansible all -m command -a "hostname"
```

### Full Provisioning

Provision all VMs from scratch:

```bash
# Run full playbook
ansible-playbook site.yml

# With vault password
ansible-playbook site.yml --ask-vault-pass

# Run on specific host
ansible-playbook site.yml --limit herta

# Dry run (check mode)
ansible-playbook site.yml --check
```

### Selective Provisioning

Run specific roles using tags:

```bash
# Only common system setup
ansible-playbook site.yml --tags common

# Only Docker installation
ansible-playbook site.yml --tags docker

# Only storage mounts
ansible-playbook site.yml --tags storage

# Only firewall configuration
ansible-playbook site.yml --tags firewall

# Only deploy Docker stacks
ansible-playbook site.yml --tags deploy

# Multiple tags
ansible-playbook site.yml --tags "docker,storage"
```

### Deploy Docker Stacks Only

If VMs are already provisioned and you just want to deploy stacks:

```bash
# Deploy all stacks
ansible-playbook deploy-stacks.yml

# Deploy to specific host
ansible-playbook deploy-stacks.yml --limit cyrene
```

### Update Specific Stack

```bash
# Update just one stack on one host
ansible-playbook deploy-stacks.yml --limit herta --extra-vars "deploy_single_stack=portainer"
```

## Playbooks

### site.yml

Main playbook - full provisioning:
1. Common system setup
2. Docker installation
3. Storage configuration
4. Firewall setup
5. Homelab stack deployment

### deploy-stacks.yml

Lightweight playbook - only deploys Docker stacks.

## Roles

### common

System configuration:
- Hostname
- Timezone
- System packages
- Sysctl tuning
- Swap disable

### docker

Docker setup:
- Repository configuration
- Docker Engine installation
- Docker Compose installation
- Docker daemon configuration
- User permissions
- TCP API configuration

### storage

Storage mounts:
- NFS mounts
- CIFS/SMB mounts
- Mount verification

### firewall

UFW firewall:
- Default policies
- SSH access
- Service ports
- Docker TCP API restrictions

### homelab

Stack deployment:
- Git repository clone
- Docker network creation
- Environment file generation
- Stack deployment
- Health verification

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory.ini            # Host inventory
├── site.yml                 # Main playbook
├── deploy-stacks.yml        # Stack deployment playbook
├── group_vars/
│   └── all.yml              # Common variables
├── host_vars/
│   ├── herta.yml            # Herta-specific vars
│   ├── cyrene.yml           # Cyrene-specific vars
│   └── bronya.yml           # Bronya-specific vars
└── roles/
    ├── common/              # System setup
    ├── docker/              # Docker installation
    ├── storage/             # NFS/CIFS mounts
    ├── firewall/            # UFW configuration
    └── homelab/             # Stack deployment
```

## Advanced Usage

### Parallel Execution

```bash
# Run on multiple hosts in parallel
ansible-playbook site.yml --forks 3
```

### Verbose Output

```bash
# Increase verbosity
ansible-playbook site.yml -v    # verbose
ansible-playbook site.yml -vv   # more verbose
ansible-playbook site.yml -vvv  # debug level
```

### Specific Tasks

```bash
# Run only specific tasks
ansible-playbook site.yml --start-at-task "Install Docker packages"

# Step through tasks
ansible-playbook site.yml --step
```

### Variable Overrides

```bash
# Override variables on command line
ansible-playbook site.yml --extra-vars "docker_tcp_api_enabled=false"
ansible-playbook site.yml -e "timezone=Europe/London"
```

## Integration with Terraform

After creating VMs with Terraform, provision them with Ansible:

```bash
# 1. Create VMs with Terraform
cd terraform/herta
terraform apply

# 2. Wait for cloud-init to complete
sleep 60

# 3. Update Ansible inventory with IPs
# (Or use dynamic inventory)

# 4. Provision with Ansible
cd ../../ansible
ansible-playbook site.yml
```

### Dynamic Inventory from Terraform

Create `terraform_inventory.py`:

```python
#!/usr/bin/env python3
import json
import subprocess

def get_terraform_output():
    result = subprocess.run(
        ['terraform', 'output', '-json'],
        cwd='../terraform/herta',
        capture_output=True,
        text=True
    )
    return json.loads(result.stdout)

# ... generate Ansible inventory from Terraform outputs
```

## Ansible Vault

### Encrypt Sensitive Files

```bash
# Encrypt file
ansible-vault encrypt group_vars/secrets.yml

# Decrypt file
ansible-vault decrypt group_vars/secrets.yml

# Edit encrypted file
ansible-vault edit group_vars/secrets.yml

# View encrypted file
ansible-vault view group_vars/secrets.yml

# Change vault password
ansible-vault rekey group_vars/secrets.yml
```

### Use Vault Password File

```bash
# Create password file
echo "your-vault-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# Update ansible.cfg
[defaults]
vault_password_file = ~/.ansible_vault_pass

# Run playbook (no prompt)
ansible-playbook site.yml
```

## Troubleshooting

### Connection Issues

```bash
# Test SSH connectivity
ansible all -m ping

# Detailed connection info
ansible all -m setup --tree /tmp/facts

# Check SSH config
ansible all -m command -a "whoami" -vvv
```

### Permission Denied

```bash
# Verify sudo access
ansible all -m command -a "sudo whoami" --become

# Check SSH key
ssh -i ~/.ssh/id_rsa ubuntu@192.168.1.100
```

### Docker Issues

```bash
# Check Docker status
ansible all -m command -a "systemctl status docker"

# Verify Docker installation
ansible all -m command -a "docker --version"

# Check running containers
ansible all -m command -a "docker ps"
```

### Firewall Blocking

```bash
# Check UFW status
ansible all -m command -a "sudo ufw status" --become

# Temporarily disable UFW
ansible all -m command -a "sudo ufw disable" --become
```

### Mount Issues

```bash
# Check mounts
ansible all -m command -a "mount | grep nfs"
ansible all -m command -a "mount | grep cifs"

# Test mount manually
ssh ubuntu@192.168.1.100
sudo mount -t nfs 192.168.1.10:/mnt/pool/vm_shares /nfs/vm_shares
```

## Best Practices

1. **Version Control**: Commit playbooks and roles to Git
2. **Vault Encryption**: Never commit plain-text passwords
3. **Idempotency**: Ensure tasks can run multiple times safely
4. **Tags**: Use tags for selective execution
5. **Testing**: Use `--check` mode before applying changes
6. **Documentation**: Comment complex tasks
7. **Roles**: Keep roles focused and reusable
8. **Variables**: Use group_vars and host_vars for organization

## Monitoring Playbook Execution

Enable profiling in `ansible.cfg`:

```ini
[defaults]
callbacks_enabled = profile_tasks, timer
```

This shows task execution times.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Homelab

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Ansible
        run: pip install ansible
      
      - name: Run Ansible Playbook
        env:
          ANSIBLE_VAULT_PASSWORD: ${{ secrets.VAULT_PASSWORD }}
        run: |
          cd ansible
          echo "$ANSIBLE_VAULT_PASSWORD" > .vault_pass
          ansible-playbook site.yml --vault-password-file .vault_pass
```

## Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/) - Pre-built roles
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Docker Ansible Module](https://docs.ansible.com/ansible/latest/collections/community/docker/)

## Related Documentation

- [Terraform Setup](../terraform/) - VM provisioning
- [Homelab Stacks](../stacks/) - Docker Compose files
- [Setup Script](../setup-homelab.sh) - Manual setup alternative
