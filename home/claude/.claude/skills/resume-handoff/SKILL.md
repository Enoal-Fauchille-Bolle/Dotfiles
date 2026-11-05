---
name: resume-handoff
description: Resumes work from a handoff file after checking each of its claims against the real current state.
argument-hint: "<path to the handoff>"
disable-model-invocation: true
---

Resume the work described in the handoff at `$ARGUMENTS`.

If `$ARGUMENTS` is empty, ask Enoal for the path. Do not pick a handoff yourself.

## 1. Read

Read the whole handoff, then the files it names as required reading.

## 2. Reconcile it with reality

A handoff describes the state at the moment it was written. Since then, things may
have moved: a push, a merged pull request, a review that took place, a fix made in
another session. Treat every claim in its "State" and "Next step" sections as a
hypothesis to check.

For each claim that something is done, in progress or pending, check it with the
cheapest reliable source:

- the check the handoff gives for it, when it gives one;
- git, in the repository concerned: `git log --oneline -20`, `git status`,
  `git branch -vv`, the remote branches;
- pull requests: `gh pr list --author @me --state all`, in the right repository;
- tickets: their status, when the handoff names one;
- a live host: read-only commands only, nothing that changes its state;
- later handoffs of the same thread in `~/.claude/exports/<project>/handoffs/`, which
  may already record it as done.

Then show Enoal one table:

| Point | Handoff says | Real state | Evidence |
| --- | --- | --- | --- |

Evidence is a commit hash, a pull request URL, or a command and its output; never
"probably". When a point cannot be checked from here, write "not checked" and why.

Below the table, list the points that turned out stale, then the steps that remain,
and for each remaining step whether it needs a decision from Enoal.

## 3. Wait for the go

Stop there and do nothing else until Enoal answers. If Enoal corrects the table,
update it first.

## 4. Carry out the remaining steps

Once Enoal says go:

- Run the steps that need no decision, one at a time, in order.
- When a step needs a decision, ask one question at a time, with the options, your
  recommendation and its reason.
- After a coherent group of edits, run the project's own checks, then commit
  according to `~/.claude/CLAUDE.md` and the repository's `CLAUDE.md`.
- If a step shows that the plan no longer holds, stop and say so instead of
  improvising a new plan.

## 5. Close

When the task of the handoff is finished, tell Enoal, then set its properties with
Edit, without touching its body: `statut: terminé`, `cloture: <today, YYYY-MM-DD>`,
and remove its `prochaine_etape` line.

If work remains for another session, propose `/handoff` instead: it writes the next
handoff and marks this one `remplacé`.
