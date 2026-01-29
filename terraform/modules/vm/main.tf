terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
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
  description = "Password for VMs"
  type = string
  default = "password"
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.proxmox_node
  clone       = var.template_name
  
  agent    = 1
  os_type  = "cloud-init"
  cloudinit_cdrom_storage = var.storage
  
  cpu {
    cores   = var.cores
    sockets = 1
    type    = "host"
  }
  
  memory   = var.memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  disk {
    slot     = "scsi0"
    size     = var.disk_size
    type     = "disk"
    storage  = var.storage
    iothread = true
  }
  
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

  ipconfig0 = "ip=${var.ip_address},gw=${var.gateway}"
  
  sshkeys = var.ssh_public_key
  
  ciuser = "ubuntu"
  tags   = var.tags
  cipassword = var.cipassword
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
