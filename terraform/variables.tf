variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "vm_template_name" {
  description = "Name of the VM template to clone"
  type        = string
  default     = "ubuntu-cloud-template"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "vm_cores" {
  description = "Number of CPU cores per VM"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory in MB per VM"
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = "20G"
}

variable "vm_storage" {
  description = "Storage location for VMs"
  type        = string
  default     = "local-lvm"
}

variable "vm_network_bridge" {
  description = "Network bridge for VMs"
  type        = string
  default     = "vmbr0"
}

variable "vm_network_model" {
  description = "Network model"
  type        = string
  default     = "virtio"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "vm_ip_base" {
  description = "Base IP address for VMs (e.g., 192.168.1)"
  type        = string
  default     = "192.168.1"
}

variable "vm_ip_start" {
  description = "Starting IP address octet"
  type        = number
  default     = 100
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "monitoring_vm_cores" {
  description = "CPU cores for monitoring VM"
  type        = number
  default     = 2
}

variable "monitoring_vm_memory" {
  description = "Memory for monitoring VM in MB"
  type        = number
  default     = 4096
}

variable "cipassword" {
  description = "Password of VMs"
  type        = string
  default     = "password"
}
