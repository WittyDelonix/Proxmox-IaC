[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

[app_servers]
%{ for vm in app_vms ~}
${vm.name} ansible_host=${vm.ip} vm_id=${vm.id}
%{ endfor ~}

[monitoring]
${monitoring_vm.name} ansible_host=${monitoring_vm.ip} vm_id=${monitoring_vm.id}

[self_healing]
${self_healing_vm.name} ansible_host=${self_healing_vm.ip} vm_id=${self_healing_vm.id}

[prometheus]
${monitoring_vm.name}

[grafana]
${monitoring_vm.name}

[node_exporters:children]
app_servers
monitoring
self_healing
