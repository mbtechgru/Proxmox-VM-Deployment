# --- Proxmox connection ------------------------------------------------------

variable "proxmox_endpoint" {
  description = "Proxmox API URL, e.g. https://pve1.example.local:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token in the form 'user@realm!tokenid=secret'. Prefer setting via TF_VAR_proxmox_api_token."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (self-signed Proxmox certs)."
  type        = bool
  default     = true
}

# --- Cluster layout ----------------------------------------------------------

variable "nodes" {
  description = "Cluster nodes to spread VMs across (round-robin)."
  type        = list(string)
  default     = ["pve1", "pve2", "pve3"]

  validation {
    condition     = length(var.nodes) > 0
    error_message = "At least one node is required."
  }
}

variable "template_node" {
  description = "Node that holds the Windows 11 template."
  type        = string
  default     = "pve1"
}

variable "template_vm_id" {
  description = "VM ID of the Windows 11 template to clone."
  type        = number
}

variable "datastore_id" {
  description = "Target datastore for VM disks. Should be shared storage (Ceph/NFS/iSCSI) when cloning across nodes."
  type        = string
  default     = "local-lvm"
}

# --- VM definition -----------------------------------------------------------

variable "vm_count" {
  description = "Number of VMs to create."
  type        = number
  default     = 10
}

variable "vm_name_prefix" {
  description = "VM name prefix; VMs are named <prefix>-01, <prefix>-02, ... Keep the full name <= 15 chars for Windows NetBIOS."
  type        = string
  default     = "win11"
}

variable "vm_id_start" {
  description = "First VM ID; subsequent VMs increment by 1."
  type        = number
  default     = 2001
}

variable "cpu_cores" {
  type    = number
  default = 4
}

variable "cpu_type" {
  description = "CPU type. 'host' gives best performance but blocks live migration between dissimilar CPUs; use 'x86-64-v2-AES' for mixed hardware."
  type        = string
  default     = "host"
}

variable "memory_mb" {
  type    = number
  default = 8192
}

variable "disk_interface" {
  description = "Interface of the template's OS disk (must match the template, e.g. scsi0 or virtio0)."
  type        = string
  default     = "scsi0"
}

variable "disk_size_gb" {
  description = "OS disk size in GB. Must be >= the template disk size (disks can grow, not shrink)."
  type        = number
  default     = 80
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN tag for the NIC; null for untagged."
  type        = number
  default     = null
}

variable "pool_id" {
  description = "Optional Proxmox resource pool."
  type        = string
  default     = null
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "win11"]
}

variable "start_on_create" {
  type    = bool
  default = true
}

variable "on_boot" {
  description = "Start VMs when the host boots."
  type        = bool
  default     = true
}

# --- Optional cloudbase-init --------------------------------------------------

variable "enable_cloudinit" {
  description = "Attach a cloud-init drive. Only useful if cloudbase-init is installed in the template."
  type        = bool
  default     = false
}

variable "ipv4_addresses" {
  description = "Optional static IPs (CIDR) per VM, in order. Leave empty for DHCP. Requires enable_cloudinit."
  type        = list(string)
  default     = []
}

variable "ipv4_gateway" {
  type    = string
  default = null
}

variable "dns_servers" {
  type    = list(string)
  default = []
}
