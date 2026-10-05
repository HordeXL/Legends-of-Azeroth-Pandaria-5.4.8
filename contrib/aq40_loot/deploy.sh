#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
    echo "Run this script with sudo to install worldserver and restart mop-world.service." >&2
    exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
built_binary="$repo_dir/build/src/server/worldserver/worldserver"
installed_binary=/usr/local/bin/worldserver
test -x "$built_binary"
test -x "$installed_binary"

backup_binary="$(mktemp /usr/local/bin/worldserver.before-aq40-loot.XXXXXX)"
cp --preserve=all -- "$installed_binary" "$backup_binary"
staged_binary="$(mktemp /usr/local/bin/worldserver.aq40-loot.XXXXXX)"
install -m 755 -- "$built_binary" "$staged_binary"
echo "Previous executable saved to $backup_binary"

rollback() {
    echo "Deployment failed; restoring $backup_binary" >&2
    systemctl stop mop-world.service || true
    cp --preserve=all -- "$backup_binary" "$staged_binary"
    mv -f -- "$staged_binary" "$installed_binary"
    systemctl start mop-world.service
}
trap rollback ERR
systemctl stop mop-world.service
mv -f -- "$staged_binary" "$installed_binary"
systemctl start mop-world.service
systemctl is-active --quiet mop-world.service
trap - ERR
echo "New executable installed; mop-world.service started. Check startup logs before playing."
