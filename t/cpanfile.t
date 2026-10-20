#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Path::Tiny;
use Test::More;

# The cpanfile is what the installer reads. A module the code loads but the
# cpanfile does not name is not missing at build time, it is missing when the
# library is loaded on a machine where the module is not installed yet.
#
# The lists below name the module the code loads and, behind it, the names the
# cpanfile may carry for it. Where module and distribution differ, the
# distribution counts: Digest::HMAC_SHA1 comes with Digest::HMAC,
# HTTP::Request and HTTP::Response come with HTTP::Message and Moo::Role
# comes with Moo.

my $cpanfile = Path::Tiny->new("$FindBin::Bin/../cpanfile");

plan skip_all => 'cpanfile is not part of the distribution'
    unless $cpanfile->is_file;

my ( %runtime, %test );
my ( @runtime_order, @test_order );
my $phase = 'runtime';

for my $line ( $cpanfile->lines ) {
    if ( $line =~ /^\s*on\s+(\w+)\s*=>\s*sub\s*\{/ ) {
        $phase = $1;
        next;
    }
    next unless $line =~ /^\s*requires\s+'([^']+)'/;
    my $module = $1;
    if ( $phase eq 'test' ) {
        $test{$module} = 1;
        push @test_order, $module;
    }
    else {
        $runtime{$module} = 1;
        push @runtime_order, $module;
    }
}

my %runtime_prereq = (
    'DateTime'                => [qw( DateTime )],
    'DateTime::Format::HTTP'  => [qw( DateTime::Format::HTTP )],
    'Digest::HMAC_SHA1'       => [qw( Digest::HMAC Digest::HMAC_SHA1 )],
    'HTTP::Request'           => [qw( HTTP::Request HTTP::Message )],
    'JSON'                    => [qw( JSON )],
    'LWP::Protocol::https'    => [qw( LWP::Protocol::https )],
    'LWP::UserAgent'          => [qw( LWP::UserAgent )],
    'Moo'                     => [qw( Moo Moo::Role )],
    'String::CamelSnakeKebab' => [qw( String::CamelSnakeKebab )],
    'URI'                     => [qw( URI )],
);

my %test_prereq = (
    'HTTP::Response' => [qw( HTTP::Response HTTP::Message HTTP::Request )],
    'Path::Tiny'     => [qw( Path::Tiny )],
    'Test::Most'     => [qw( Test::Most )],
    'Test::More'     => [qw( Test::More )],
);

# A runtime prerequisite belongs to the runtime phase: an entry that stands in
# the test phase alone is not installed when the distribution is applied.
for my $module ( sort keys %runtime_prereq ) {
    ok(
        ( grep { $runtime{$_} } @{ $runtime_prereq{$module} } ),
        "$module is a declared runtime prerequisite"
    );
}

# A test prerequisite is accepted in the test phase and in the runtime phase,
# the runtime phase is installed anyway.
for my $module ( sort keys %test_prereq ) {
    ok(
        ( grep { $runtime{$_} || $test{$_} } @{ $test_prereq{$module} } ),
        "$module is a declared prerequisite for the tests"
    );
}

# The prereqs of a phase stand in alphabetical order.
for my $phase ( 'runtime', 'test' ) {
    my @declared = $phase eq 'test' ? @test_order : @runtime_order;
    is_deeply(
        \@declared,
        [ sort { lc $a cmp lc $b } @declared ],
        "the $phase prereqs stand in alphabetical order"
    );
}

done_testing;
