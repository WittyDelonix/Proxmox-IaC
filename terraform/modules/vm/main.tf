terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0.1-rc1"
    }
  }
}

variable "vm_id" {
  description = "VM ID"
  type        = number
}

variable "vm_name" {
  description = "VM name"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node"
  type        = string
}

variable "template_name" {
  description = "Template to clone"
  type        = string
}

variable "cores" {
  description = "CPU cores"
  type        = number
}

variable "memory" {
  description = "Memory in MB"
  type        = number
}

variable "disk_size" {
  description = "Disk size"
  type        = string
}

variable "storage" {
  description = "Storage location"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
}

variable "network_model" {
  description = "Network model"
  type        = string
}

variable "ip_address" {
  description = "IP address with CIDR"
  type        = string
}

variable "gateway" {
  description = "Gateway IP"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "tags" {
  description = "Tags for the VM"
  type        = string
  default     = ""
}
variable "cipassword" {
  description = "Password"
  type = string
  default = "password"
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.proxmox_node
  clone       = var.template_name
  
  # Full clone (required for disk resize and cloud-init)
  full_clone = true
  
  # QEMU Agent
  agent    = 1
  
  # OS type for cloud-init
  os_type  = "cloud-init"
  
  # CPU configuration
  cores    = var.cores
  sockets  = 1
  
  # Memory
  memory   = var.memory
  
  # SCSI controller
  scsihw   = "virtio-scsi-pci"
  
  # Boot order - CRITICAL
  boot = "order=scsi0;ide2"
  
  # Disk configuration for v3 - SIMPLIFIED
  disk {
    slot     = 0
    size     = var.disk_size
    type     = "scsi"
    storage  = var.storage
    iothread = 1
  }
  
  # Cloud-init drive
  # This is auto-created when cloning from template
  # We just need to ensure it exists
  
  # Network configuration
  network {
    id     = 0
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Cloud-init configuration
  ipconfig0 = "ip=${var.ip_address},gw=${var.gateway}"
  
  sshkeys = var.ssh_public_key
  
  ciuser = "ubuntu"
  cipassword = var.cipassword
  tags = var.tags
}

output "vm_id" {
  value = proxmox_vm_qemu.vm.vmid
}

output "vm_name" {
  value = proxmox_vm_qemu.vm.name
}

output "vm_ip" {
  value = var.ip_address
}
