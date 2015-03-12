#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::LoadAllModules;

BEGIN {
    use_ok('WWW::DME');
    all_uses_ok(
        search_path => 'WWW::DNSMadeEasy',
        lib         => ['lib'],
    );
}

done_testing;
