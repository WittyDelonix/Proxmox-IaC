output "app_vm_ips" {
  description = "IP addresses of application VMs"
  value = [
    for vm in module.app_vms : split("/", vm.vm_ip)[0]
  ]
}

output "monitoring_vm_ip" {
  description = "IP address of monitoring VM"
  value       = split("/", module.monitoring_vm.vm_ip)[0]
}

output "self_healing_vm_ip" {
  description = "IP address of self-healing VM"
  value       = split("/", module.self_healing_vm.vm_ip)[0]
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${split("/", module.monitoring_vm.vm_ip)[0]}:9090"
}

output "alertmanager_url" {
  description = "Alertmanager URL"
  value       = "http://${split("/", module.monitoring_vm.vm_ip)[0]}:9093"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://${split("/", module.monitoring_vm.vm_ip)[0]}:3000"
}

output "self_healing_webhook_url" {
  description = "Self-Healing Webhook URL"
  value       = "http://${split("/", module.self_healing_vm.vm_ip)[0]}:5000/webhook"
}

output "inventory_file" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}
