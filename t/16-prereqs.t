#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Path::Tiny;
use WWW::DNSMadeEasy;

# The API is HTTPS only, so LWP::Protocol::https has to be a runtime prereq —
# without it the first request fails with "501 Protocol scheme 'https' is not
# supported". Data::Printer was only needed for one debug line and must not
# pull in a dependency chain on every use of the module.

my $cpanfile = Path::Tiny->new("$FindBin::Bin/../cpanfile")->slurp_utf8;

like($cpanfile, qr/^requires 'LWP::Protocol::https';/m,
    'LWP::Protocol::https is a runtime prereq');
like($cpanfile, qr/^requires 'LWP::UserAgent';/m,
    'LWP::UserAgent is a runtime prereq');
like($cpanfile, qr/^requires 'HTTP::Request';/m,
    'HTTP::Request is a runtime prereq');
unlike($cpanfile, qr/^requires 'LWP';/m,
    'the LWP meta package is not required');

unlike($cpanfile, qr/Data::Printer/,
    'Data::Printer is not a prereq');
ok(!exists $INC{'Data/Printer.pm'},
    'loading the module does not pull in Data::Printer');

done_testing;
