#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use WWW::DNSMadeEasy;
use MockUA;

# records() must follow pagination. The v2 record list is returned one page at a
# time ({ data => [...], page => N, totalPages => M }); a single GET silently
# truncates at the server's page size. This proves every page is fetched and the
# records are aggregated. Always offline (MockUA), regardless of any live creds.

my $dme = WWW::DNSMadeEasy->new({
    api_key     => 'test-api-key',
    secret      => 'test-secret',
    api_version => '2.0',
});
$dme->{_http_agent} = MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures");

my $domain = $dme->get_managed_domain('paginated.example.com');
is($domain->id, 200002, 'paginated domain id resolved from fixture');

my @records = $domain->records;

# page 1 fixture carries 3 records, page 2 carries 2 -> 5 total
is(scalar(@records), 5, 'records() aggregates every record across both pages');

isa_ok($_, 'WWW::DNSMadeEasy::ManagedDomain::Record') for @records;

my @ids = sort { $a <=> $b } map { $_->id } @records;
is_deeply(\@ids, [3001, 3002, 3003, 3004, 3005],
    'records from every page are present (no truncation)');

done_testing;
