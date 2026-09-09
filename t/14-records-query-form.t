#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use WWW::DNSMadeEasy;
use MockUA;

# records() builds its list query (recordName / type, plus page for pagination)
# via URI->query_form instead of hand-concatenating the string. This pins the
# exact wire query so a future regression in the query build — a dropped param,
# the wrong DME key, a malformed separator, or non-deterministic ordering — is
# caught offline. Always offline (MockUA), regardless of any live creds.

my $mock = MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures");
my $dme  = WWW::DNSMadeEasy->new({
    api_key     => 'test-api-key',
    secret      => 'test-secret',
    api_version => '2.0',
});
$dme->{_http_agent} = $mock;

my $domain = $dme->get_managed_domain('example.com');
my @records = $domain->records(type => 'A', name => 'www');
ok(@records, 'records(type => A, name => www) returned records');

# Locate the record-list GET among everything MockUA saw (resolving ->id fires a
# domain-lookup request first).
my ($records_uri) = grep { $_->path =~ m{/records/?$} } @{$mock->requests};
ok($records_uri, 'a record-list request was made');

is(
    $records_uri->query,
    'recordName=www&type=A',
    'query is the deterministic DME form (recordName then type, & separated)',
);

my %form = $records_uri->query_form;
is($form{recordName}, 'www', 'name arg is sent as the DME recordName param');
is($form{type},       'A',   'type arg is sent as the DME type param');
ok(!exists $form{name}, 'the raw name arg is not put on the wire verbatim');

done_testing;
