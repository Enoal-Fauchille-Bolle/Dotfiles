# Restic backup

A daily, encrypted backup of the personal data on the laptop to a Backblaze
B2 bucket, made with [restic](https://restic.net) and watched by an Uptime
Kuma push monitor. restic encrypts on the laptop before upload, stores only
the blocks that changed, and keeps a history of snapshots, so a deleted or
encrypted file can be recovered from an older day.

## Pieces

| File | Source | Role |
|---|---|---|
| `~/my_scripts/restic-backup.sh` | `scripts` stow package | backup, retention, report to Kuma |
| `~/.config/systemd/user/restic-backup.{service,timer}` | `systemd` stow package | daily run, caught up at the next login when missed |
| `~/.config/restic/include`, `exclude` | this role, from `restic_include` and `restic_exclude` in `group_vars/all.yml` | what is backed up |
| `~/.config/restic/env` | this role, created with comments only | repository, keys, password, Kuma URL |

Only the paths in `restic_include` are backed up. To add one, edit the list
and run `~/Dotfiles/bootstrap.sh --tags restic`. A listed path that does not
exist is skipped with a warning in the journal (`does not match any files`),
and the run still counts as a success.

Retention: 7 daily, 4 weekly and 12 monthly snapshots (`restic forget`
every day, `--prune` on Sundays to free the space on B2). The timer is a
user timer: it only runs while a session is open, and `Persistent=true`
runs a missed day at the next login.

Report to Kuma, by exit code of `restic backup`:

- **0**: `up`.
- **3** (snapshot saved, some files unreadable): `up`, with the reason in
  the message.
- **Anything else**, or a failed `forget`: `down`, so Kuma alerts at once.
- **No push for 3 days** (laptop off, timer stopped): Kuma alerts on its own.

## First setup

1. **Bucket**: in the Backblaze console, create a private bucket and set its
   lifecycle rule to "Keep only the last version" (otherwise the space that
   `prune` frees stays billed as hidden versions). Note the S3 endpoint shown
   on the bucket page (`s3.<region>.backblazeb2.com`).
2. **Key**: create an application key restricted to that bucket alone, with
   read and write access. A stolen laptop then exposes no other bucket of the
   account.
3. **Password manager**: generate the repository password and save it with
   the key ID and application key. Without the password, the backup cannot be
   decrypted by anyone, including its owner.
4. **Environment file**: uncomment and fill `~/.config/restic/env`
   (`RESTIC_REPOSITORY='s3:https://s3.<region>.backblazeb2.com/<bucket>'`).
   restic uses the S3 API of B2 because its documentation advises against its
   native `b2:` backend.
5. **Repository**: `source ~/.config/restic/env && restic init`.
6. **Kuma**: add a monitor of type Push with a heartbeat interval of
   259200 seconds (3 days), and copy its push URL into `KUMA_PUSH_URL`. The
   script strips the `?status=up&msg=OK&ping=` suffix by itself.
7. **First run**: `systemctl --user start restic-backup.service`, then
   `journalctl --user -u restic-backup -f`. The first upload sends everything
   (about 14 GB); the next ones only send the changes.
8. **Restore test**: restore one folder (below) and compare it with the
   original before relying on the backup.

## Daily use

```bash
systemctl --user list-timers restic-backup.timer   # next and last run
journalctl --user -u restic-backup                 # output of the runs
source ~/.config/restic/env
restic snapshots                                   # history
restic ls latest /home/$USER/Documents             # browse a snapshot
```

## Restore

Every command below needs `source ~/.config/restic/env` first. On a new
laptop, run the playbook, then fill `~/.config/restic/env` from the password
manager.

One folder or file, into a scratch directory:

```bash
restic restore latest --target /tmp/restore --include /home/$USER/Documents/CV
# the files land in /tmp/restore/home/$USER/Documents/CV
```

An older version: pick a snapshot ID in `restic snapshots` and use it in
place of `latest`.

Everything, in place (the user name must be the same as on the old laptop,
since the snapshots store absolute paths):

```bash
restic restore latest --target /
```

Existing files are overwritten by the version in the snapshot, which is the
point on a fresh install: the empty `~/.zshrc.secrets` and `~/.wakatime.key`
that the playbook creates get their real content back. Then reboot, as after
the first playbook run.

## Remove a folder from every snapshot

To stop paying for a large folder that should never have been backed up,
remove it from `restic_include` (or add it to `restic_exclude`), run the
playbook, then rewrite the history and free the space:

```bash
source ~/.config/restic/env
restic rewrite --exclude /home/$USER/Documents/big-folder --forget
restic prune
```

`--forget` drops the original snapshots once their rewritten copies exist;
without it, both stay and nothing is freed.
