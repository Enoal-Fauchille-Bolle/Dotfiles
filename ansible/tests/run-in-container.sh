#!/usr/bin/env bash
# Runs the playbook on the committed tree inside a privileged Debian 13 container
# with systemd, twice, and fails unless the second run changes nothing. Flatpak
# applications are skipped because they are large and start nothing in a container.
#
#   ansible/tests/run-in-container.sh [ansible-playbook arguments]
#   CONTAINER_ENGINE=docker ansible/tests/run-in-container.sh
set -euo pipefail

engine="${CONTAINER_ENGINE:-podman}"
name="dotfiles-playbook-test"
image="localhost/dotfiles-playbook-test"
root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

cleanup() { "$engine" rm --force "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup

"$engine" build --tag "$image" --file "$root/ansible/tests/Containerfile" "$root/ansible/tests"

# Docker needs the cgroup tree handed over for systemd; Podman sets it up by itself.
run_args=(--detach --privileged --name "$name")
if [[ "$engine" == docker ]]; then
    run_args+=(--cgroupns=host --volume /sys/fs/cgroup:/sys/fs/cgroup:rw)
fi
"$engine" run "${run_args[@]}" "$image"

# `is-system-running` exits non-zero on "degraded", which is enough to go on.
for _ in {1..30}; do
    state="$("$engine" exec "$name" systemctl is-system-running 2>/dev/null || true)"
    [[ "$state" == running || "$state" == degraded ]] && break
    sleep 1
done
echo "systemd: ${state:-unknown}"

as_tester() { "$engine" exec --user tester --workdir /home/tester "$name" "$@"; }

as_tester mkdir Dotfiles
git -C "$root" archive HEAD | "$engine" exec --interactive --user tester "$name" tar -x -C /home/tester/Dotfiles

play() {
    as_tester env ANSIBLE_CONFIG=/home/tester/Dotfiles/ansible/ansible.cfg HOME=/home/tester \
        ${CARGO_BUILD_JOBS:+CARGO_BUILD_JOBS="$CARGO_BUILD_JOBS"} \
        ansible-playbook --skip-tags flatpak_apps \
        --inventory /home/tester/Dotfiles/ansible/inventory.ini \
        /home/tester/Dotfiles/ansible/playbooks/all.yml "$@"
}

echo "=== First run ==="
play "$@"

echo "=== Second run, which must change nothing ==="
output="$(mktemp)"
play "$@" | tee "$output"
if ! grep -qE 'changed=0 +unreachable=0 +failed=0' "$output"; then
    rm -f "$output"
    echo "The second run changed something: the playbook is not idempotent." >&2
    exit 1
fi
rm -f "$output"
echo "OK: the second run changed nothing."
