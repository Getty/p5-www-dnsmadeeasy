# WWW::DNSMadeEasy House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. No abstractions for
   single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code or
   formatting. Match existing style.
4. **Read before you write** — Before new code, read the request chokepoint
   (`WWW::DNSMadeEasy::request`), the `Response` wrapper, and the resource class you are
   touching. "Looks orthogonal" is dangerous.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other. Don't blend.
6. **Tests verify intent** — Reproduce a bug before fixing it; leave a regression test.
   A test that can't fail when the logic changes is wrong.
7. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
   wrong if any subdir tests were skipped (see the recursion trap below).

## Delegation

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behaviour-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run
  tests, edit non-behavioural docs. Why: only the `www-dnsmadeeasy-*` agents
  get their skills force-loaded via `briefing.skills`; you get no briefing and would
  touch internals with too little context. Lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug client code | `www-dnsmadeeasy-worker` (default) |
  | Write/extend fixture-backed tests | `www-dnsmadeeasy-test-writer` |
  | Pre-release CPAN audit | `www-dnsmadeeasy-release-manager` |

- **You cannot spawn subagents** (you ARE a `www-dnsmadeeasy-*` agent): The lock does not
  apply — implement, refactor, debug and test per these rules.

Behaviour-relevant = runtime behaviour, the public API of the client and resource
classes, the request/HMAC layer, error handling, tests, and the MockUA fixtures. Pure
prose docs and `Changes` notes are not.

**Only `www-dnsmadeeasy-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `www-dnsmadeeasy-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — just
use it (skill `kanban-issues-karr-coordination` for the command surface). Git-native kanban; state
lives in `refs/karr/*`; this repo has its own board.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --body '…'` · `karr move ID in-progress --claim NAME`
  · `karr handoff ID --claim NAME --note "…"`

**Serialize board mutations when fanning out.** Keep implementation parallel if you like,
but collect results and loop `karr move`/`handoff`/`sync` sequentially — N landing at
once is a resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` / `prove` are fine anytime. `dzil release` and any CPAN upload
are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan or
STATUS document lists "release" as the next step. Everything releases together on the
maintainer's word; the CPAN state of any dependency is never a blocker and never a
ticket. For anything heading toward release: stop and ask.

## Public issues — never act without instruction

This repo has a public GitHub issue tracker (`Getty/p5-www-dnsmadeeasy`). **karr** is the
internal agent work board, churned freely; **GitHub issues** carry real users' reports,
written under the maintainer's account. Never read, list, comment on, edit, close or open
a public issue on your own initiative — only when the user explicitly points at a specific
one. It is not a queue to drain.

## Project-specific hazards

- **Test recursion.** `t/` has subdirs (`t/v1.2/`, `t/v2.0/`). `prove -l t/` is
  non-recursive and silently skips them, so a green run can hide failures. Always
  `prove -lr t/`, or `dzil test`.
- **Two API versions, opposite write conventions.** v1.2 (`Domain`) takes raw camelCase
  hashrefs; v2.0 (`ManagedDomain`) takes snake_case and translates to lowerCamelCase.
  Editing one tree with the other's convention produces wrong wire payloads that mock
  fixtures won't catch. Details in skill `www-dnsmadeeasy-core`.
- **The HMAC test is a tripwire.** `t/05-hmac-doc-example.t` pins the exact auth
  signature against the vendor example; if it goes red, the header code changed
  meaning — do not "fix" it by editing the expected value.

## Perl / Moo specifics — reference, don't restate

Module loading, class patterns and house style live in skills `getty-perl-core`,
`getty-perl-moo`, and (release metadata) `getty-perl-release-author-getty` /
`perl-release-dist-ini` — force-loaded for `www-dnsmadeeasy-*` agents. Do not duplicate
that content here.
