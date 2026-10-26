#!/usr/bin/env bash
# patch-node.sh — rolling OS patch one Raft node at a time (Demo A)
# Strategy: golden-image rebake + VM re-clone (avoids live apt on slow DC egress)
# Alternative inline: ansible-playbook with apt role (uncomment INLINE section below)
set -euo pipefail

NODES=("bao-1" "bao-2" "bao-3")
CACERT="${BAO_CACERT:-/etc/openbao/tls/ca.crt}"

check_health() {
  local addr="https://$1:8200"
  local sealed
  sealed=$(BAO_ADDR="$addr" BAO_CACERT="$CACERT" bao status -format=json | jq -r .sealed)
  [[ "$sealed" == "false" ]]
}

wait_healthy() {
  local ip="$1" retries=30
  echo "  Waiting for $ip to unseal and rejoin..."
  while ! check_health "$ip"; do
    sleep 5
    ((retries--))
    [[ $retries -gt 0 ]] || { echo "TIMEOUT: $ip never rejoined"; exit 1; }
  done
  echo "  $ip is unsealed and healthy."
}

# ── Method: golden-image rebake + re-clone (PREFERRED — avoids live apt) ──
rebake_and_reclone() {
  local node="$1"
  echo "=== Patching $node via re-clone ==="
  echo "  Step 1: trigger golden-image rebuild in CI (or: ansible-playbook build.yml)"
  echo "  Step 2: destroy and re-clone VM from new template"
  # tofu destroy + apply scoped to one node
  cd tofu/
  tofu apply -target="proxmox_virtual_environment_vm.bao_raft[\"$node\"]" \
    -replace="proxmox_virtual_environment_vm.bao_raft[\"$node\"]" -auto-approve
  cd ..
  # re-run Ansible to reconfigure the fresh clone
  ansible-playbook ansible/site.yml --limit "$node"
}

# ── Method: inline apt (fallback — only if golden rebake is not available) ──
# inline_patch() {
#   local node="$1"
#   echo "=== Patching $node inline ==="
#   ansible "$node" -b -m apt -a "upgrade=dist update_cache=yes" -i ansible/inventory/hosts.ini
#   ansible "$node" -b -m reboot -i ansible/inventory/hosts.ini
# }

echo "=== Demo A: Rolling OS patch ==="
for node in "${NODES[@]}"; do
  # Map node name to IP for health check
  ip_var="${node//-/_}_ip"
  ip=$(grep "$node" ansible/inventory/hosts.ini | grep -oP 'ansible_host=\K[^\s]+')

  rebake_and_reclone "$node"
  wait_healthy "$ip"

  echo "  Raft peers after $node:"
  bao operator raft list-peers

  echo "  Test secret readable:"
  bao kv get secret/poc/test

  echo ""
done

echo "=== Demo A complete: all nodes patched, cluster healthy ==="