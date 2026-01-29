# Proxmox Configuration
proxmox_tls_insecure     = true
proxmox_node             = "pve"

# VM Template Configuration
vm_template_name = "ubuntu-cloud-template"

# VM Specifications
vm_count  = 0
vm_cores  = 2
vm_memory = 1024
vm_disk_size = "10G"
vm_storage = "local-lvm"

# Network Configuration
vm_network_bridge = "vmbr0"
vm_network_model  = "virtio"
vm_ip_base        = "192.168.58"
vm_ip_start       = 100

# SSH Configuration
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCu4ENiauMIuKOdlEElUXpYuv0BqnHPnbd3/qZXTMTimK2VrU7RAFJzm4PTSP3DP8oKmm7hA0EurVoM/RHh6GX/3rh3LxGohOtRAg7oishCSqnF+CPLClqKRjOSu1mTOh0KKnUbmQ3XWc8yPIx3vsWyXdxtEif3uemWpbBFKkfHTUF0abwdEKb5rEU8rKgflH+7NtSUINKS5qDcdh3FTK3o3l7SY+2HwGOdsK4XAC1TG2yPF0asHL07rxZiwPlmVR2KOMyreRJ8zt5BogfuWIFEh3MxGKVeI5W8nLAtDmIsz9pD26CgvLVAUvXdXhVSqaXIEq3dEi4pRsrVFx44GAfehAe9WjIQXTN0EhfUiPniS5D9DkT1+Odad1EcnRCDxSXM2McWcFmK/77MdTZaK+H6LhH+VxEC/nKfDrt/9tHoG8nwqdRHRuYRLCep+yjwO/2FX1pYMXMhSM+Z3GvBH5JFuPxVxyu/TPoYUJe5FJ7CCEBgLzqZzpd83ugHWMffUnlm3MXL1fyzY6dKGjAlsvPM8LMhNytlEsrxy9EYdh6QWafoqLRezMxgfOYaMKx5VfqRQWNHQ69KjOrp27cTsVzWt1wK+r2px92h4mWN3t0u3uZRuqdJexXONNw3VoaVJxt82LN0st1eB4e4apb6sP7EnjDywa8nKLliQyF2emJj9Q=="

# Environment
environment = "production"

# Monitoring VM Specifications
monitoring_vm_cores  = 2
monitoring_vm_memory = 1024
