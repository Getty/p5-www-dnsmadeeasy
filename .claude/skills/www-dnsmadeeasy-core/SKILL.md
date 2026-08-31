---
name: www-dnsmadeeasy-core
description: "Load on any WWW::DNSMadeEasy edit — the two-API-version split (v1.2 domains vs v2.0 managed domains), the request/HMAC chokepoint, the lazy-response resource pattern, snake_case→lowerCamelCase translation, and the MockUA fixture harness."
---

# WWW::DNSMadeEasy — Architecture & Invariants

Moo-based Perl client for the DNSMadeEasy REST API. `WWW::DME` is a thin
`extends 'WWW::DNSMadeEasy'` alias — the shorter package name, no behaviour of its own.
Moo/house-Perl conventions live in `getty-perl-moo` / `getty-perl-core`; this skill is
only what is specific to this distribution.

## The central fact: two API versions, two parallel object trees

One client class serves **both** API versions, chosen by the `api_version` attribute
(`isa` allows only `'1.2'` or `'2.0'`; default `'2.0'`). The two versions are *not*
unified — each has its own resource classes and its own conventions. Know which tree you
are in before touching anything:

| | v1.2 (`api_version => '1.2'`) | v2.0 (default) |
|---|---|---|
| entry methods | `all_domains`, `domain($name)`, `create_domain` | `managed_domains`, `get_managed_domain($name)`, `create_managed_domain` |
| domain class | `WWW::DNSMadeEasy::Domain` | `WWW::DNSMadeEasy::ManagedDomain` |
| record class | `WWW::DNSMadeEasy::Domain::Record` | `WWW::DNSMadeEasy::ManagedDomain::Record` |
| monitor/failover | — | `WWW::DNSMadeEasy::Monitor` |
| base path | `domains` (`path_domains`) | `dns/managed/` (`domain_path`) |
| write-arg style | **HASHREF of raw camelCase** keys | **`%hash` of snake_case**, auto-translated |

Both version blocks in `WWW::DNSMadeEasy.pm` carry `TODO - move this into a role`; they
are still plain methods on the client, not yet rolified. Don't rolify casually — it is a
public-surface change.

## The request chokepoint

`WWW::DNSMadeEasy::request($method, $path, $data)` is the single HTTP path; every resource
method funnels through it (directly, or via a Moo `handles => { request => 'request' }`
delegation from the resource's `dme`). It:

- builds the URL as `api_endpoint . $path` — `api_endpoint` is
  `https://api[.sandbox].dnsmadeeasy.com/V<api_version>/`, the `sandbox` flag switching
  the host;
- JSON-encodes `$data` when present, sets Accept/Content-Type;
- wraps the reply in `WWW::DNSMadeEasy::Response`, stores it in `last_response`;
- **`die`s on any non-success status** — callers assume success past the call.

Add cross-cutting HTTP behaviour here, not in resource classes.

### Authentication — HMAC over the date, not the body

`get_request_headers` signs the **RFC-1123 date string** with `hmac_sha1_hex($date,
$secret)` and sends three headers: `x-dnsme-requestDate`, `x-dnsme-apiKey`,
`x-dnsme-hmac`. The signature covers the timestamp only — never the payload.
`t/05-hmac-doc-example.t` pins the exact hmac for a fixed date/key against the vendor's
documentation example; any change to header construction must keep that test green.

### Response wrapper

`WWW::DNSMadeEasy::Response` wraps `HTTP::Response` (delegates `is_success`, `content`,
`status_line`, `code`, `header`, …). `as_hashref` decodes the JSON body and **returns
`undef` for empty content** — DELETE returns `200` with no body, so guard for that.
`data` is an alias for `as_hashref`. Rate-limit state (`requests_remaining`,
`request_limit`, `request_id`) is read off `last_response` via the `x-dnsme-*` headers.

## The lazy-response resource pattern

Every resource object (`Domain`, `ManagedDomain`, both `Record`s, `Monitor`) is a **thin
lazy proxy**, not a data struct:

- it holds a back-reference (`dme`, or `domain` which itself handles `dme`) plus its
  identity (`name` / `id`);
- `response` and `as_hashref` are `is => 'lazy'` (or builder+lazy) — **constructing the
  object hits no network**; the first attribute accessor triggers `_build_response` → a
  `GET`, which `_build_as_hashref` decodes;
- field accessors are one-liners: `sub ttl { shift->as_hashref->{ttl} }`. Add a field by
  adding one such line reading the wire key.
- after a mutating call, the cache is invalidated with `clear_as_hashref` /
  `clear_response` so the next read re-fetches.

## The v2 key-translation convention (do not break)

v2 write methods (`ManagedDomain::create_record`, `ManagedDomain::Record::update`,
`Monitor::update`, `create_monitor`) accept a **snake_case `%hash`** and translate every
key through `String::CamelSnakeKebab::lower_camel_case` before sending. So the public v2
API is snake_case-in while the wire is `lowerCamelCase`. Any new v2 write method must run
its args through the same translation. (v1 does **no** translation — the caller passes a
hashref of raw camelCase keys like `gtdLocation`.)

## Documented server quirks encoded in the code — preserve them

- **`ManagedDomain::records(%args)`** builds its query string (`?type=` / `?recordName=`
  / combined) by hand; a `TODO` notes moving to `URI->query_form` needs a `request()`
  signature change.
- **`ManagedDomain::Record::update`** (`# GRR ...`): DME returns nothing on a record PUT
  and offers no get-single-record-by-id, so `update` re-fetches via
  `records(type => …, name => …)` and matches by `id` to refresh `as_hashref`. This
  re-fetch is load-bearing, not redundant.
- **`ManagedDomain::wait_for_delete` / `wait_for_pending_action`** poll with `sleep 10`;
  they are only meaningful against the live API.
- **`Monitor`**: `protocol_id` → name via an in-module `%PROTOCOL` table; `create` is an
  alias for `update`; `disable` PUTs `failover/monitor => 'false'` then re-GETs.

## Testing — the MockUA fixture harness

Default `prove` runs **offline**. `t/lib/MockUA.pm` maps `method + URI path` to a file in
`t/fixtures/*.json` and returns it as an `HTTP::Response` (with the `x-dnsme-*` headers);
tests inject it with `$dme->{_http_agent} = MockUA->new(fixtures_dir => …)`, bypassing the
lazy real UA. **Adding an endpoint means adding both** a `MockUA` path-regex branch and a
fixture JSON file — a missing fixture returns `404` (except DELETE, which MockUA fakes as
empty-200).

Live tests activate only when `TEST_WWW_DNSMADEEASY_API_KEY` + `TEST_WWW_DNSMADEEASY_API_SECRET`
are set; `TEST_WWW_DNSMADEEASY_WRITE=1` enables create/delete; `TEST_WWW_DNSMADEEASY_SANDBOX=1`
targets the sandbox host. (The older `t/v1.2` and `t/v2.0` subdir tests gate on a
different, legacy env-var pair — `WWW_DNSMADEEASY_TEST_APIKEY` / `_SECRET` — and skip
without it.)

**Recursion trap:** `t/` has subdirectories (`t/v1.2/`, `t/v2.0/`). `prove -l t/` is
**non-recursive** and silently skips them — use `prove -lr t/`. `dzil test` runs the full
tree.

`WWW_DME_DEBUG=1` makes `request()` print each `METHOD URL`, the outgoing data (via
`Data::Printer`), and the response body — the fastest way to see what actually went to
the wire.
