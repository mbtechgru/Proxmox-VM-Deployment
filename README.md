# Windows 11 VMs on Proxmox

Clones `vm_count` (default 10) Windows 11 VMs from a template and spreads them
round-robin across the cluster nodes (10 VMs on 3 nodes gives a 4/3/3 split).
Uses the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) provider.

## Template prerequisites

- q35 machine, OVMF (UEFI) with EFI disk, TPM 2.0 state disk
- VirtIO drivers and **QEMU guest agent** installed (virtio-win ISO)
- Sysprepped (`sysprep /generalize /oobe /shutdown`) so clones get unique SIDs
- Converted to a template
- Optional: cloudbase-init, if you want static IPs via `enable_cloudinit`

**Storage:** put the template and `datastore_id` on shared storage (Ceph, NFS,
iSCSI) so clones can land directly on any node. With local-only storage the
provider has to clone on the template node and then migrate, which is much slower.

## Check these before applying

- **Sysprep the template.** Otherwise all clones end up with the same SID.
- **Match the disk settings to the template.** `disk_interface` (default `scsi0`)
  has to be the template's disk interface, and `disk_size_gb` has to be at least
  the template's disk size, because disks can only grow.
- **Use shared storage.** Ceph, NFS or iSCSI for both the template and
  `datastore_id` lets clones go straight to any node. With local storage, each VM
  is cloned on the template's node and then migrated, which is slow.
- **CPU type.** `cpu_type = "host"` gives the best performance, but it can block
  live migration if your hosts have different CPUs. In that case, switch to
  `x86-64-v2-AES`.
- **Name length.** Windows limits computer names to 15 characters, so keep
  `vm_name_prefix` short.

## API token

```sh
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role PVEAdmin
pveum user token add terraform@pve tf --privsep 0
```

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars   # edit values
export TF_VAR_proxmox_api_token='terraform@pve!tf=<secret>'
terraform init
terraform plan
terraform apply -parallelism=3   # limits concurrent clones to avoid storage lock contention
```

The `vms` output shows each VM's node, ID and the IPs the guest agent reports.
