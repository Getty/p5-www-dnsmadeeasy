#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use WWW::DNSMadeEasy;
use MockUA;

# records() builds its list query with URI->query_form, so a record name that
# carries characters which are special in a query string travels
# percent-encoded instead of raw. This pins that encoding: the query is the
# DME form (recordName then type), the name is encoded, and it still decodes
# back to the value that was handed in. Always offline (MockUA), regardless of
# any live creds.

my $mock = MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures");
my $dme  = WWW::DNSMadeEasy->new({
    api_key     => 'test-api-key',
    secret      => 'test-secret',
    api_version => '2.0',
});
$dme->{_http_agent} = $mock;

my $domain = $dme->get_managed_domain('example.com');
my @records = $domain->records(type => 'A', name => 'my domain + co');
ok(@records, 'records(type => A, name => "my domain + co") returned records');

# Locate the record-list GET among everything MockUA saw (resolving ->id fires a
# domain-lookup request first).
my ($records_uri) = grep { $_->path =~ m{/records/?$} } @{$mock->requests};
ok($records_uri, 'a record-list request was made');

is(
    $records_uri->query,
    'recordName=my+domain+%2B+co&type=A',
    'the record name travels percent-encoded in the query (space as +, + as %2B)',
);

my %form = $records_uri->query_form;
is($form{recordName}, 'my domain + co', 'the encoded name decodes back to the given value');
is($form{type},       'A',               'the type param is unaffected by the encoding');

unlike($records_uri->query, qr/ /, 'the query carries no unencoded space');
is(scalar(() = $records_uri->query =~ /&/g), 1, 'the query has exactly one parameter separator');

done_testing;
