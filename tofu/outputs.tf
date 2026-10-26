output "transit_ip" {
  value = split("/", var.transit_ip)[0]
}

output "raft_ips" {
  value = { for k, v in var.raft_nodes : k => split("/", v.ip)[0] }
}