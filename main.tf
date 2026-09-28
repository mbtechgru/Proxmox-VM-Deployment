locals {
  vms = {
    for i in range(var.vm_count) : format("%s-%02d", var.vm_name_prefix, i + 1) => {
      vm_id = var.vm_id_start + i
      node  = var.nodes[i % length(var.nodes)]
      ipv4  = length(var.ipv4_addresses) > i ? var.ipv4_addresses[i] : "dhcp"
    }
  }
}

resource "proxmox_virtual_environment_vm" "win11" {
  for_each = local.vms

  name      = each.key
  node_name = each.value.node
  vm_id     = each.value.vm_id
  pool_id   = var.pool_id
  tags      = var.tags

  description = "Windows 11 - managed by Terraform"

  clone {
    node_name    = var.template_node
    vm_id        = var.template_vm_id
    datastore_id = var.datastore_id
    full         = true
    retries      = 3
  }

  # Windows 11 requirements: q35 + UEFI + TPM 2.0
  machine = "q35"
  bios    = "ovmf"

  operating_system {
    type = "win11"
  }

  efi_disk {
    datastore_id      = var.datastore_id
    type              = "4m"
    pre_enrolled_keys = true
  }

  tpm_state {
    datastore_id = var.datastore_id
    version      = "v2.0"
  }

  cpu {
    cores   = var.cpu_cores
    sockets = 1
    type    = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    interface    = var.disk_interface
    datastore_id = var.datastore_id
    size         = var.disk_size_gb
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  network_device {
    bridge  = var.network_bridge
    model   = "virtio"
    vlan_id = var.vlan_id
  }

  # Requires the QEMU guest agent (virtio-win) installed in the template.
  agent {
    enabled = true
    timeout = "15m"
  }

  dynamic "initialization" {
    for_each = var.enable_cloudinit ? [1] : []
    content {
      datastore_id = var.datastore_id
      interface    = "ide2"

      ip_config {
        ipv4 {
          address = each.value.ipv4
          gateway = each.value.ipv4 == "dhcp" ? null : var.ipv4_gateway
        }
      }

      dynamic "dns" {
        for_each = length(var.dns_servers) > 0 ? [1] : []
        content {
          servers = var.dns_servers
        }
      }
    }
  }

  started         = var.start_on_create
  on_boot         = var.on_boot
  stop_on_destroy = true

  timeout_clone  = 3600
  timeout_create = 3600
}
