locals {
  # Convenience map — used in outputs and Ansible inventory generation
  vms = {
    bao-transit = {
      ip    = var.transit_ip
      cpus  = var.transit_cpus
      mem   = var.transit_memory
    }
    bao-1 = {
      ip    = var.bao1_ip
      cpus  = var.raft_cpus
      mem   = var.raft_memory
    }
    bao-2 = {
      ip    = var.bao2_ip
      cpus  = var.raft_cpus
      mem   = var.raft_memory
    }
    bao-3 = {
      ip    = var.bao3_ip
      cpus  = var.raft_cpus
      mem   = var.raft_memory
    }
  }
}