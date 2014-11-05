use Test::Most;
use WWW::DNSMadeEasy;

my $dme = WWW::DNSMadeEasy->new(
    api_key     => $ENV{WWW_DNSMADEEASY_TEST_APIKEY},
    secret      => $ENV{WWW_DNSMADEEASY_TEST_SECRET},
    sandbox     => 0,
    api_version => '1.2',
);

isa_ok($dme,'WWW::DNSMadeEasy');

my @domains = $dme->all_domains;
#is scalar @domains, 0, "no domains";

foreach my $domain (@domains) {
    next unless $domain->name eq 'duckduckgo.com';
    my @records = $domain->all_records;
    last;
}

#$dme->create_domain('example.com');
#@domains = $dme->all_domains;
#is scalar @domains, 1, "created a domain";

#use DDP; p @domains;
    

done_testing;
