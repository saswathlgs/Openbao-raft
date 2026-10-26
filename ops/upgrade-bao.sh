#!/usr/bin/env bash
# upgrade-bao.sh — rolling OpenBao version upgrade (Demo B)
# Bumps openbao_version, upgrades followers first, then steps down leader
set -euo pipefail

NEW_VERSION="${1:?Usage: $0 <new_version> e.g. 2.1.0}"
CACERT="${BAO_CACERT:-/etc/openbao/tls/ca.crt}"
FOLLOWERS=("bao-2" "bao-3")
LEADER="bao-1"

leader_ip=$(grep "$LEADER" ansible/inventory/hosts.ini | grep -oP 'ansible_host=\K[^\s]+')
export BAO_ADDR="https://${leader_ip}:8200"
export BAO_CACERT="$CACERT"
# BAO_TOKEN from SOPS: export BAO_TOKEN=$(sops -d secrets/init-output.sops.json | jq -r .root_token)

wait_voter() {
  local node="$1" retries=30
  echo "  Waiting for $node to appear as voter in Raft..."
  while ! bao operator raft list-peers | grep -q "$node.*voter"; do
    sleep 5
    ((retries--))
    [[ $retries -gt 0 ]] || { echo "TIMEOUT: $node never became voter"; exit 1; }
  done
  echo "  $node is a voter."
}

upgrade_node() {
  local node="$1"
  echo "=== Upgrading $node to $NEW_VERSION ==="
  ansible-playbook ansible/site.yml \
    --limit "$node" \
    --tags openbao_install \
    -e "openbao_version=$NEW_VERSION" \
    -i ansible/inventory/hosts.ini
}

echo "=== Demo B: Rolling OpenBao upgrade to $NEW_VERSION ==="

echo "--- Step 1: Upgrade followers ---"
for node in "${FOLLOWERS[@]}"; do
  upgrade_node "$node"
  wait_voter "$node"
  echo "  bao version on $node:"
  ansible "$node" -b -a "bao version" -i ansible/inventory/hosts.ini
  echo ""
done

echo "--- Step 2: Step down leader, then upgrade ---"
echo "  Stepping down $LEADER..."
bao operator step-down
sleep 5  # brief pause for election

echo "  New leader elected. Raft peers:"
bao operator raft list-peers

upgrade_node "$LEADER"
wait_voter "$LEADER"

echo "--- Step 3: Final verification ---"
echo "  bao version on all nodes:"
for node in bao-1 bao-2 bao-3; do
  ansible "$node" -b -a "bao version" -i ansible/inventory/hosts.ini
done

echo ""
echo "  Raft peers:"
bao operator raft list-peers

echo ""
echo "  Test secret:"
bao kv get secret/poc/test

echo ""
echo "=== Demo B complete. Rollback: re-run with previous version, or: ==="
echo "  bao operator raft snapshot restore <snapshot-file>"
echo "  ansible-playbook ansible/site.yml -e openbao_version=2.0.3"