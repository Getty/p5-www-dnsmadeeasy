use Test::Most;
use Carp::Always;
use DDP;

use WWW::DNSMadeEasy;

my $dme = WWW::DNSMadeEasy->new(
    api_key     => $ENV{WWW_DNSMADEEASY_TEST_APIKEY},
    secret      => $ENV{WWW_DNSMADEEASY_TEST_SECRET},
    sandbox     => 1,
    api_version => '2.0',
);

isa_ok($dme,'WWW::DNSMadeEasy');

subtest setup => sub {
    my @domains = $dme->managed_domains;
    $_->delete for @domains;
    $_->wait_for_delete for @domains;
};

subtest 'managed_domains()' => sub {
    my @domains = $dme->managed_domains;
    is scalar @domains, 0, "no domains";
}

subtest 'create_managed_domain()' => sub {
    $dme->create_managed_domain('boop.com');
    my @domains = $dme->managed_domains;
    $_->wait_for_pending_action for @domains;
    is scalar @domains, 1, "created a domain";
};

done_testing;
