use Test::Most;
use Carp::Always;
use DDP;
use feature qw/say/;

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
    $_->delete          for @domains;
    $_->wait_for_delete for @domains;
    pass 'setup complete';
};

subtest 'managed_domains()' => sub {
    my @domains = $dme->managed_domains;
    is scalar @domains, 0, "no domains";
};

subtest 'create_managed_domain()' => sub {
    my $domain  = $dme->create_managed_domain('boop.com');
    my @domains = $dme->managed_domains;
    $_->wait_for_pending_action for @domains;
    is scalar @domains, 1, "created a domain";
};

subtest 'records()' => sub {
    my $domain = $dme->get_managed_domain('boop.com');
    like $domain->created, qr/\d+/, 'get_managed_domain()';

    my @records = $domain->records;
    $_->delete for @records;

    my %args = (
        name         => 'boop',
        type         => 'A',
        value        => '1.1.1.1',
        gtd_location => 'DEFAULT',
        ttl          => '30',
    );
    my $record = $domain->create_record(%args);
    is $record->$_, $args{$_}, $_ for keys %args;

};

done_testing;
