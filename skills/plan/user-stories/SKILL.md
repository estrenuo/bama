---
name: user-stories
description: Prioritized backlog of user stories with checkable acceptance criteria (docs/STORIES.md) for a macOS app, built from a brief, research, or screen index. Use after app-brief or clone, or when the user asks for user stories, a backlog, a feature list, or "what do we build first".
---

# User stories

Screens show what an app looks like. Stories say what a person does with
it. You build and test stories, not screens.

Read `docs/BRIEF.md`, `docs/research/*.md`, and `docs/screens/INDEX.md`
where they exist. Write `docs/STORIES.md`. If it already exists, keep every
story, number, acceptance line, and `UX:` block, and bring the file into
the format below.

## File layout

The file has these parts, in this order:

1. `# Stories: <app>`.
2. A short **How to read this file** block. It names the sources (brief,
   PRD, screen index), what each check tag runs in this project and which
   tags it does not use, what `Screens:` names here, and what the status
   values mean.
3. An **overview table**: one row per milestone with the number of stories
   `done`, `doing`, and `todo`, and a total row.
4. `## M1 <name>` and onwards. Each milestone opens with one sentence that
   says when it is done.
5. `## Later` and `## Dropped`, one line per item. Write "Nothing yet." when
   a section is empty.

```markdown
# Stories: Tasks

## How to read this file

- Sources: `docs/BRIEF.md` and `docs/screens/INDEX.md`.
- `[unit]` a Swift Testing test in `Tests/TasksKitTests`. `[self]` a check
  in `SelfTest.swift`, run by `tools/selftest.sh`. `[snap]` a page from
  `tools/snap.sh`. `[manual]` a person tries it. All four tags are in use.
- `Screens:` names reference screenshots in `docs/screens/`.
- `Status:` `done` is on `main`, `doing` is partly built or on an unmerged
  branch, `todo` is not built, `dropped` will not be built.

## Overview

| Milestone | done | doing | todo |
| --- | --- | --- | --- |
| M1 Core loop | 4 | 1 | 2 |
| M2 Organize | 0 | 0 | 6 |
| **Total** | **4** | **1** | **8** |

## M1 Core loop

Done when a person can add, complete, and find tasks, and they survive a
restart.

### S-001 ...

## Later

- S-031 Sync between Macs.

## Dropped

- Team sharing: the app is for one person.
```

Change the counts in the overview table whenever a `Status:` changes.

## Story format

```markdown
### S-012 Complete a task with the keyboard
As the user, I select a task and press Command-Return to complete it.
Screens: 01-inbox.png, 02-today.png
Depends: S-004
Acceptance:
- [snap] The circle fills and the row fades out within half a second.
- [self] An "Undo" banner shows for five seconds; Command-Z also undoes it.
- [unit] A recurring task moves to its next date.
UX: Command-Return completes. The row fades; "Undo" stays for five seconds.
Status: done
Source: BRIEF.md "Main jobs" 2; Sources/TasksKit/TaskStore.swift, Tests/TasksKitTests/TaskStoreTests.swift `completeRecurring`
```

- One action per story. "Rename a project from its context menu", not
  "Manage projects".
- Every acceptance line starts with how it is checked: `[snap]` snapshot,
  `[unit]` unit test, `[self]` self-test, `[manual]` a person must try it.
  "Works well" is not checkable.
- `Screens:` links reference screenshots, so `improve-loop` knows what to
  compare. Without a reference app, name the snapshot pages that will show
  the story. A panel, sheet, or menu needs its own snapshot page.
- `Depends:` (optional) lists stories that must be done first.
- `UX:` (optional) comes from `ux-design`, just before the story is built.
- `Status:` holds only the value: `todo`, `doing`, `done`, or `dropped`.
  No notes on that line.
- In a `done` story whose `[manual]` check on a real device has not been
  done yet, that acceptance line ends with `(not yet checked)`, in the
  project's language (`(nog niet gecontroleerd)` in Dutch).
- `Source:` is required. It names the requirement: a brief section, a PRD
  paragraph, a screen, or a research row. A `done` story also names the
  main file and the test that prove it. Look them up in the code. With no
  test, name only the file.
- Keep a control and the only surface that shows it in one story: a
  highlighting field that lives only in the quick-add panel ships with the
  panel.

## Language

Write the stories in the project's own language, the one its `CLAUDE.md`
uses. The labels (`Screens:`, `Depends:`, `Acceptance:`, `UX:`, `Status:`,
`Source:`), the check tags, and the status values stay English in every
project.

## Status

Status follows `main`:

- `done`: the code is on `main`.
- `doing`: part of it is built, or it sits on a branch that is not merged.
- `todo`: nothing is built.
- `dropped`: it will not be built. Move it to `## Dropped`.

## Working rules

The app's `CLAUDE.md` holds these four rules. The `new-mac-app` template
has them; add them to an app that lacks them.

- `docs/STORIES.md` is the only place for what has to be built and how far
  it is. There is no TODO or backlog file next to it. A PRD says what is
  wanted, never the status.
- Status follows `main`, as above.
- Change `Status:` in the same commit as the code.
- A new wish or bug first gets a story or an acceptance line, then gets
  built.

## Milestones

Each milestone ends with an app the user can use for a day.

1. **M1 Core loop**: the one thing the app is for, end to end. Data
   survives a restart.
2. **M2 Organize**: the main structure, sidebar pages, moving items.
3. **M3 Time**: dates, Today and Upcoming, recurrence, reminders.
4. **M4 Speed**: quick-add panel, global shortcut, natural language input,
   keyboard navigation, search, menu commands.
5. **M5 System**: menu bar, Share menu, Shortcuts, notifications, CLI.
6. **M6 Polish**: drag and drop, context menus, empty states, icon, settings.

Rename milestones to fit the app. Open each one with its "Done when"
sentence. Inside a milestone, stories that others depend on come first.

## Seed data

Every attribute the seed data sets (symbols, colors, notes) is something a
story lets the user create in the app. Otherwise snapshots show features
no one can use.

## Leave things out

Drop what exists only for other people or for the vendor: accounts,
sharing, teams, integrations, upgrade prompts, gamification. List them
under `## Dropped`, one line each, so the decision is visible.

## UX notes

For each M1 story that adds a screen, an action, or words, call the Skill
tool with `ux-design`. It adds a `UX:` block under the acceptance lines and
starts `docs/GLOSSARY.md`, so every story uses the same names. Later
milestones get their UX notes in `improve-loop`, just before they are built.

## Size check

M1 has 5 to 10 stories. Over 60 stories in total means version one is too
big: move stories to `## Later`.

Done when every main job in the brief, every "Version one: yes" row in the
research matrix, and every screen in the index maps to a story or a
`Dropped` line; every story has `Acceptance:`, `Status:`, and `Source:`;
the overview table matches the `Status:` lines; the file has `## Later` and
`## Dropped`; and every M1 story with UI has a `UX:` block.
