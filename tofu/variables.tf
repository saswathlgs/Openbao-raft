variable "proxmox_endpoint" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://pve1.lab.local:8006"
}

variable "proxmox_node" {
  type    = string
  default = "pve1"
}

variable "golden_image_template" {
  description = "Proxmox template name from lingaasys-golden-image pipeline"
  type        = string
  default     = "poc-golden-image"
}

variable "storage" {a
  type    = string
  default = "local-lvm"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "gateway" {
  type    = string
  default = "172.16.0.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["172.16.0.4", "172.16.0.25"]
}

variable "ansible_pubkey" {
  description = "SSH public key for the ansible automation user (post-clone)"
  type        = string
}

# ── bao-transit (auto-unseal provider) ──────────────────────────────────────
variable "transit_vmid" {
  type    = number
  default = 9010
}
variable "transit_ip" {
  type    = string
  default = "172.16.10.10/21"
}
variable "transit_cores" {
  type    = number
  default = 2
}
variable "transit_memory" {
  type    = number
  default = 2048
}
variable "transit_disk" {
  type    = string
  default = "10G"
}

# ── Raft cluster nodes ───────────────────────────────────────────────────────
variable "raft_nodes" {
  description = "Map of Raft node name → VMID + IP"
  type = map(object({
    vmid   = number
    ip     = string
  }))
  default = {
    bao-1 = { vmid = 9011, ip = "172.16.10.11/21" }
    bao-2 = { vmid = 9012, ip = "172.16.10.12/21" }
    bao-3 = { vmid = 9013, ip = "172.16.10.13/21" }
  }
}

variable "raft_cores" {
  type    = number
  default = 2
}
variable "raft_memory" {
  type    = number
  default = 4096
}
variable "raft_disk" {
  type    = string
  default = "20G"
}