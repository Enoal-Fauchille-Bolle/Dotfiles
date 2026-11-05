---
name: handoff
description: Writes the resume prompt of the current conversation to a file, before a /clear.
argument-hint: "[destination path]"
disable-model-invocation: true
allowed-tools: Write, Edit
---

Build the resume prompt of this conversation and write it to a file, in English.

Destination: `$ARGUMENTS` if given, otherwise
`~/.claude/exports/<project>/handoffs/handoff-<topic>-<YYYY-MM-DD>.md`, where
`<project>` is an existing folder of `~/.claude/exports/` chosen from the topic, not
from the current folder. If none fits, ask Enoal before creating one. Never inside a
git repository: a handoff is not meant to be versioned, and the current folder often
is one.

The file starts with its properties (YAML frontmatter), read by the Obsidian base
`~/.claude/exports/Suivi.base` (views embedded in the README and in each
`<project>/<project>.md` page). Keys and fixed values stay in French, because the base
filters on them:

```yaml
---
type: handoff
projet: <project>
statut: en-cours
date: <YYYY-MM-DD from the file name>
titre: "<handoff title, without the Handoff prefix or the date>"
prochaine_etape: "<section 6 summed up in 45 characters at most, starting with a verb>"
---
```

Add, only when it applies:
- `reprise: YYYY-MM-DD` if the follow-up cannot start before a date;
- `attente: "<sentence>"` if the follow-up waits for an outside event (a server waking
  up, an action from Enoal, a symptom coming back).

Do not modify `~/.claude/exports/README.md`: the index no longer copies the state of
the handoffs.

If this handoff follows another one of the same thread (the one this session resumed,
or the one this text says it replaces), change the properties of the previous one with
Edit, without touching its body:
- `statut: remplacé`;
- `remplace_par: "[[<name of the new file without .md>]]"`;
- `cloture: <date of the new handoff>`;
- remove its `prochaine_etape` line.

If the previous one is uncertain, ask Enoal rather than picking one.

The file contains this, in this order, and nothing else:

1. **Goal**: what the session was trying to achieve, in one sentence.
2. **State**: what is done, what is not, what is in progress. For each item that is
   not done or in progress, give the check that proves its state from a fresh
   session (a command, a PR or ticket to look at, a file to read), so that
   `/resume-handoff` can verify it before acting.
3. **Decisions and why**: including the leads ruled out and their reason.
4. **Files touched**: exact paths, and what changed in each.
5. **Checks**: commands run and their result; the ones still to run.
6. **Next step**: one action, in the imperative, the most useful one.
7. **Model and effort** recommended for the follow-up, with the reason.

Writing rules:

- Paths, identifiers, commands, error messages and numbers **verbatim**, paths in full
  from `/` or `~`.
- Leave out an uncertain fact rather than rebuild it from memory.
- Written for a conversation that knows nothing: no "as seen above".
- Aim for ~2k tokens.

Then, before concluding, tell Enoal which of the three kinds of continuity fits here,
and why. The decision belongs to Enoal:

- this **handoff** (~2k) if the substance fits in what you just wrote;
- a **pasted `/export`** (~30k) if the substance is the reasoning (an analysis or
  design session, where you do not know yet what will matter);
- **`--resume`** (full context) if the substance is the diff and the test output,
  exactly what an export throws away.

End by showing the file path, reminding that `/clear` is free, and that the next
session starts with `/resume-handoff <path>`.
