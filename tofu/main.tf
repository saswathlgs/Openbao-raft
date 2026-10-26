provider "proxmox" {
  endpoint = var.proxmox_endpoint
  # Credentials injected via BAO_TOKEN or PM_API_TOKEN env vars — never in code
  insecure  = true  # lab: self-signed Proxmox cert; remove for production
}

locals {
  dns_joined   = join(" ", var.dns_servers)
  template_id  = data.proxmox_virtual_environment_vms.golden.vms[0].vm_id
}

# Look up the golden image template by name so we don't hard-code a VMID
data "proxmox_virtual_environment_vms" "golden" {
  node_name = var.proxmox_node
  tags      = ["golden-image"]  # tag set by the finalize_template role
  filter {
    name   = "name"
    values = [var.golden_image_template]
  }
}

# ── bao-transit ──────────────────────────────────────────────────────────────
resource "proxmox_virtual_environment_vm" "bao_transit" {
  name      = "bao-transit"
  node_name = var.proxmox_node
  vm_id     = var.transit_vmid
  clone {
    vm_id   = local.template_id
    full    = true
    retries = 3
  }
  cpu    { cores = var.transit_cores }
  memory { dedicated = var.transit_memory }
  disk {
    datastore_id = var.storage
    size         = var.transit_disk
    interface    = "scsi0"
    file_format  = "raw"
    discard      = "on"
  }
  network_device { bridge = var.bridge }
  initialization {
    ip_config {
      ipv4 {
        address = var.transit_ip
        gateway = var.gateway
      }
    }
    dns { servers = var.dns_servers }
    user_account {
      username = "ansible"
      keys     = [var.ansible_pubkey]
    }
  }
  tags = ["openbao", "transit"]
}

# ── Raft cluster nodes ────────────────────────────────────────────────────────
resource "proxmox_virtual_environment_vm" "bao_raft" {
  for_each  = var.raft_nodes
  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vmid

  clone {
    vm_id   = local.template_id
    full    = true
    retries = 3
  }
  cpu    { cores = var.raft_cores }
  memory { dedicated = var.raft_memory }
  disk {
    datastore_id = var.storage
    size         = var.raft_disk
    interface    = "scsi0"
    file_format  = "raw"
    discard      = "on"
  }
  network_device { bridge = var.bridge }
  initialization {
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = var.gateway
      }
    }
    dns { servers = var.dns_servers }
    user_account {
      username = "ansible"
      keys     = [var.ansible_pubkey]
    }
  }
  tags = ["openbao", "raft"]

  # Ensure transit unsealer is up before Raft nodes boot
  depends_on = [proxmox_virtual_environment_vm.bao_transit]
}