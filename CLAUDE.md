# WWW::DNSMadeEasy

Moo-based Perl client for the DNSMadeEasy REST API (`WWW::DME` is the short-name alias).
One client class serves **both** API v1.2 (`Domain` tree) and v2.0 (`ManagedDomain`
tree, default), selected by the `api_version` attribute.

## Build / Test

```bash
prove -lr t/      # run tests offline (MockUA fixtures); -r is REQUIRED — t/v1.2 and
                  # t/v2.0 are subdirs a plain `prove -l t/` silently skips
dzil build        # build the distribution
dzil test         # full test tree
```

Live-API tests activate only with `TEST_WWW_DNSMADEEASY_API_KEY` +
`TEST_WWW_DNSMADEEASY_API_SECRET` set (`_WRITE=1` / `_SANDBOX=1` optional).
`dzil release` is maintainer-only — see the rules file.

## Delegation

Delegate behaviour-relevant code to the right agent instead of touching it yourself — the
principle and lanes are in `.claude/rules/www-dnsmadeeasy-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug client code | `www-dnsmadeeasy-worker` (default) |
| Write/extend fixture-backed tests | `www-dnsmadeeasy-test-writer` |
| Pre-release CPAN audit | `www-dnsmadeeasy-release-manager` |

The agents carry their conventions via `briefing.skills` (see `.claude/agents/`); the
main agent delegates rather than loading them. Skill sources live under `.claude/skills/`
(`www-dnsmadeeasy-core` for architecture; `getty-perl-*` for house Perl/Moo/release
conventions). Coordination runs on the `karr` board (`refs/karr/*`).
