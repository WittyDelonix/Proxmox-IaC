# Proxmox Configuration
proxmox_tls_insecure = true
proxmox_node         = "pve"

# VM Template Configuration
vm_template_name = "debian13-base"

# VM Specifications
vm_count     = 1
vm_cores     = 2
vm_memory    = 1024
vm_disk_size = "10G"
vm_storage   = "local-lvm"

# Network Configuration
vm_network_bridge = "vmbr0"
vm_network_model  = "virtio"
vm_ip_base        = "192.168.58"
vm_ip_start       = 120

# SSH Configuration
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCZS25NGcYpaLxuUtMOthEBcHxmaReqWSvJ62aY/mzNL5FhcX7debWqxaesRF0zblDO6oY36+Nhs3VyxGdRSzmrnASycy3iexEFscaUEsmt0LweZd5i6N1eeCceMwsftQFegvv9e/z3SxvGfhxT2iNejmO3BK5F4nLqnUyCvVyFlVogFMSsh6bKzVB9E/T9V2sJYWeXzUL8lOZ6CqW3U6nL6XPs53MEYv8u9DR5l7zKTCiQFb9/gVVGgK+Fl2zlBm+6Tvdqb3EAyn0Tj3iCjx0HB4hBr5/2ppXux1FKn34f+6ybhmV0PEx5V34I9e+tSNb11iM/4l7e6gAqIXARwauXkX3UfpN0emDgiC6cet6FLp3cHJjmbus+JCteu1Ck4GxR20chnfpPozye1vujZr8Gpc3Uwemc6HORc+GpAPfQJWMV1pVFPs41Um4E90zKlo1QcclW3OAKgNn6R8aUgXIGcUImO9JH+W4r0Ch7Ee3QQGRmh7EBBJ+gcXRtzSDVIG0hSE99VRPdJyxPzYzW/yExZlAQNFJ8VJtUq+crsOqmaVb+noTOILJIMR36Ajd+1XIyUkzPYz32Y+tRmYkOIQ366TRhZ++35u4VGmFZ/ZN4Ms6ejdgQgJg0b5P4h4Leq3XoGFn65rqYPv0ITDZSQpVzqCw7fsgnPYw2RRJxtK97Yw== sysad@github"

# Environment
environment = "production"

# Monitoring VM Specifications
monitoring_vm_cores  = 2
monitoring_vm_memory = 1024

# Password for VMS
cipassword = "vuviet5703"
