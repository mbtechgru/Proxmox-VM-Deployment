output "vms" {
  description = "Created VMs with their node, VM ID and IPv4 addresses reported by the guest agent."
  value = {
    for name, vm in proxmox_virtual_environment_vm.win11 : name => {
      vm_id = vm.vm_id
      node  = vm.node_name
      ipv4  = flatten(vm.ipv4_addresses)
    }
  }
}
