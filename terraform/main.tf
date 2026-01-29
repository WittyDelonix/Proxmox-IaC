# Application VMs
module "app_vms" {
  source   = "./modules/vm"
  count    = var.vm_count
  
  vm_id          = 101 + count.index
  vm_name        = "app-vm-${count.index + 1}"
  proxmox_node   = var.proxmox_node
  template_name  = var.vm_template_name
  cores          = var.vm_cores
  memory         = var.vm_memory
  disk_size      = var.vm_disk_size
  storage        = var.vm_storage
  network_bridge = var.vm_network_bridge
  network_model  = var.vm_network_model
  ip_address     = "${var.vm_ip_base}.${var.vm_ip_start + count.index}/24"
  gateway        = "${var.vm_ip_base}.2"
  ssh_public_key = var.ssh_public_key
  tags           = "app;${var.environment}"
}

# Monitoring VM (Prometheus + Grafana)
module "monitoring_vm" {
  source = "./modules/vm"
  
  vm_id          = 200
  vm_name        = "monitoring-vm"
  proxmox_node   = var.proxmox_node
  template_name  = var.vm_template_name
  cores          = var.monitoring_vm_cores
  memory         = var.monitoring_vm_memory
  disk_size      = "10G"
  storage        = var.vm_storage
  network_bridge = var.vm_network_bridge
  network_model  = var.vm_network_model
  ip_address     = "${var.vm_ip_base}.${var.vm_ip_start + var.vm_count}/24"
  gateway        = "${var.vm_ip_base}.2"
  ssh_public_key = var.ssh_public_key
  tags           = "monitoring;${var.environment}"
}

# Self-Healing Service VM
module "self_healing_vm" {
  source = "./modules/vm"
  
  vm_id          = 201
  vm_name        = "self-healing-vm"
  proxmox_node   = var.proxmox_node
  template_name  = var.vm_template_name
  cores          = 2
  memory         = 1024
  disk_size      = "10G"
  storage        = var.vm_storage
  network_bridge = var.vm_network_bridge
  network_model  = var.vm_network_model
  ip_address     = "${var.vm_ip_base}.${var.vm_ip_start + var.vm_count + 1}/24"
  gateway        = "${var.vm_ip_base}.2"
  ssh_public_key = var.ssh_public_key
  tags           = "self-healing;${var.environment}"
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    app_vms = [
      for vm in module.app_vms : {
        name = vm.vm_name
        ip   = split("/", vm.vm_ip)[0]
        id   = vm.vm_id
      }
    ]
    monitoring_vm = {
      name = module.monitoring_vm.vm_name
      ip   = split("/", module.monitoring_vm.vm_ip)[0]
      id   = module.monitoring_vm.vm_id
    }
    self_healing_vm = {
      name = module.self_healing_vm.vm_name
      ip   = split("/", module.self_healing_vm.vm_ip)[0]
      id   = module.self_healing_vm.vm_id
    }
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}
