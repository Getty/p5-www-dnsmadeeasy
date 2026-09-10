#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Behaviour-preserving refactor guard: the version-specific entry methods were
# moved out of WWW::DNSMadeEasy into two Moo roles. The public surface must be
# byte-for-byte unchanged for consumers — same method names on the same class,
# still reachable on the WWW::DME alias, path constants unchanged. Offline only:
# nothing here touches the network (functional equivalence against mocked
# responses is covered by t/10-api-v2.t and t/11-api-v1.t).

use WWW::DNSMadeEasy;
use WWW::DME;

my %ENTRY_METHODS = (
    'WWW::DNSMadeEasy::Role::Domains' => [
        qw(path_domains create_domain domain all_domains),
    ],
    'WWW::DNSMadeEasy::Role::ManagedDomains' => [
        qw(domain_path create_managed_domain get_managed_domain managed_domains),
    ],
);

my @all_methods = map { @$_ } values %ENTRY_METHODS;

subtest 'methods physically live in their roles' => sub {
    for my $role (sort keys %ENTRY_METHODS) {
        for my $method (@{$ENTRY_METHODS{$role}}) {
            ok($role->can($method), "$role provides $method");
        }
    }
};

subtest 'client composes both roles' => sub {
    for my $class (qw(WWW::DNSMadeEasy WWW::DME)) {
        my $obj = $class->new(api_key => 'k', secret => 's');
        for my $role (sort keys %ENTRY_METHODS) {
            ok($obj->does($role), "$class does $role");
        }
    }
};

subtest 'public surface unchanged — all entry methods reachable' => sub {
    my $dme = WWW::DNSMadeEasy->new(api_key => 'k', secret => 's');
    my $dme_alias = WWW::DME->new(api_key => 'k', secret => 's');
    for my $method (@all_methods) {
        ok(WWW::DNSMadeEasy->can($method), "WWW::DNSMadeEasy->can('$method')");
        ok($dme->can($method),             "instance can $method");
        ok($dme_alias->can($method),       "WWW::DME instance can $method");
    }
};

subtest 'path constants preserved' => sub {
    my $dme = WWW::DNSMadeEasy->new(api_key => 'k', secret => 's');
    is($dme->path_domains, 'domains',      'path_domains unchanged (v1.2)');
    is($dme->domain_path,  'dns/managed/', 'domain_path unchanged (v2.0)');
};

done_testing;
