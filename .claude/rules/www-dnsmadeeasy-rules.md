# WWW::DNSMadeEasy House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Perl client for the DNSMadeEasy API. Read first: the request chokepoint
(`WWW::DNSMadeEasy::request`), the `Response` wrapper, and the resource class you are touching.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug client code | `www-dnsmadeeasy-worker` (default) |
| Write/extend fixture-backed tests | `www-dnsmadeeasy-test-writer` |
| Commits, `Changes`, card → done, pre-release CPAN audit | `www-dnsmadeeasy-release-manager` |
| Read-only research, audit, gap analysis | `www-dnsmadeeasy-worker` ("read-only, change nothing") |

Behaviour-relevant = runtime behaviour, the public API of the client and resource classes, the
request/HMAC layer, error handling, tests, and the MockUA fixtures. Pure prose docs and
`Changes` notes are not.

## Hazards

- **Test recursion.** `t/` has subdirs (`t/v1.2/`, `t/v2.0/`). `prove -l t/` is non-recursive
  and silently skips them, so a green run can hide failures. Always `prove -lr t/`, or
  `dzil test`.
- **Two API versions, opposite write conventions.** v1.2 (`Domain`) takes raw camelCase
  hashrefs; v2.0 (`ManagedDomain`) takes snake_case and translates to lowerCamelCase. Editing
  one tree with the other's convention produces wrong wire payloads that mock fixtures won't
  catch — details in skill `www-dnsmadeeasy-core`.
- **The HMAC test is a tripwire.** `t/05-hmac-doc-example.t` pins the exact auth signature
  against the vendor example; if it goes red, the header code changed meaning — do not "fix"
  it by editing the expected value.

## Perl / Moo specifics — reference, don't restate

Module loading, class patterns and house style live in skills `getty-perl-core`,
`getty-perl-moo`, and (release metadata) `getty-perl-release-author-getty` /
`perl-release-dist-ini` — force-loaded for `www-dnsmadeeasy-*` agents.
