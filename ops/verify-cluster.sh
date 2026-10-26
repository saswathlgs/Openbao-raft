#!/usr/bin/env bash
# verify-cluster.sh — run after site.yml; confirms healthy 3-node Raft cluster
set -euo pipefail

BAO="${BAO_BIN:-bao}"
CACERT="${BAO_CACERT:-/etc/openbao/tls/ca.crt}"
NODES=("172.16.10.11" "172.16.10.12" "172.16.10.13")
LEADER_ADDR="https://${NODES[0]}:8200"

export BAO_ADDR="$LEADER_ADDR"
export BAO_CACERT="$CACERT"
# BAO_TOKEN must be set in env — read from SOPS before running:
# export BAO_TOKEN=$(sops -d secrets/init-output.sops.json | jq -r .root_token)

echo "=== Raft peer list ==="
$BAO operator raft list-peers

echo ""
echo "=== Cluster status ==="
$BAO status

echo ""
echo "=== KV test secret ==="
$BAO kv get secret/poc/test

echo ""
echo "=== Per-node status ==="
for ip in "${NODES[@]}"; do
  echo "--- $ip ---"
  BAO_ADDR="https://$ip:8200" $BAO status -format=json | \
    jq '{sealed: .sealed, standby: .standby, cluster_name: .cluster_name}'
done