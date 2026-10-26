include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  proxmox_endpoint      = local.env.locals.proxmox_endpoint
  proxmox_node          = local.env.locals.proxmox_node
  golden_image_template = local.env.locals.golden_image_template
  ansible_pubkey        = file("~/.ssh/ansible_ed25519.pub")
}