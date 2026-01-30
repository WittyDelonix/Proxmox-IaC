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
  description = "Password"
  type        = string
  default     = "password"
}
resource "proxmox_vm_qemu" "vm" {
  vmid        = var.vm_id
  name        = var.vm_name
  target_node = var.proxmox_node

  clone      = var.template_name
  full_clone = false
  bios       = "ovmf"
  agent      = 1
  scsihw     = "virtio-scsi-single"

  os_type = "cloud-init"
  memory  = var.memory

  vm_state = "running"
  onboot   = true
  startup  = "order=1"

  ipconfig0  = "ip=${var.ip_address},gw=${var.gateway}"
  skip_ipv6  = true
  ciuser     = "ubuntu"
  cipassword = var.cipassword
  sshkeys    = var.ssh_public_key
  tags       = var.tags

  cpu {
    type    = "x86-64-v2-AES"
    sockets = 1
    cores   = var.cores
  }

  serial {
    id   = 0
    type = "socket"
  }

  network {
    id       = 0
    model    = var.network_model
    bridge   = var.network_bridge
    firewall = false
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size      = var.disk_size
          storage   = var.storage
          replicate = "true"
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = var.storage
        }
      }
    }
  }
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
