#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use WWW::DNSMadeEasy;

# api_version ends up in the API URL (https://api.dnsmadeeasy.com/V<version>/).
# An unchecked value only shows up as 404s from the server, so the constructor
# has to reject it — and normalize the numeric spellings, so 2 does not end up
# as /V2/. Always offline, this touches no network at all.

sub dme {
    return WWW::DNSMadeEasy->new({
        api_key => 'test-api-key',
        secret  => 'test-secret',
        @_,
    });
}

is(dme()->api_version, '2.0', 'api_version defaults to 2.0');
is(dme(api_version => '2.0')->api_version, '2.0', 'api_version 2.0 is accepted');
is(dme(api_version => '1.2')->api_version, '1.2', 'api_version 1.2 is accepted');

is(dme(api_version => 2)->api_version, '2.0', 'the number 2 is normalized to 2.0');
is(dme(api_version => 1.2)->api_version, '1.2', 'the number 1.2 is normalized to 1.2');
is(dme(api_version => '2')->api_version, '2.0', 'the string 2 is normalized to 2.0');

is(
    dme(api_version => 2)->api_endpoint,
    'https://api.dnsmadeeasy.com/V2.0/',
    'api_endpoint carries the normalized version',
);

for my $bad ('9.9', 'V2.0', 'v2.0', '1', '2.0.0', '') {
    my $client = eval { dme(api_version => $bad) };
    ok(!$client, "api_version '$bad' is rejected in the constructor");
    like($@, qr/'1\.2'.*'2\.0'/, "the error names both valid versions for '$bad'");
}

done_testing;
