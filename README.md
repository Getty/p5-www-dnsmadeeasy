# WWW::DNSMadeEasy

Perl interface to the DNSMadeEasy API (v1.2 and v2.0).

## Installation

```bash
cpanm WWW::DNSMadeEasy
```

## Synopsis

```perl
use WWW::DNSMadeEasy;  # or WWW::DME as shortname

# API v2.0 (default)
my $dme = WWW::DNSMadeEasy->new({
    api_key => 'your-api-key',
    secret  => 'your-secret',
});

# List all domains
my @domains = $dme->managed_domains;

# Get a specific domain
my $domain = $dme->get_managed_domain('example.com');

# List records
my @records = $domain->records;
my @a_records = $domain->records(type => 'A');
my @www_records = $domain->records(name => 'www');

# Create a record
my $record = $domain->create_record(
    name         => 'www',
    type         => 'A',
    value        => '192.168.1.1',
    ttl          => 300,
    gtd_location => 'DEFAULT',
);

# Delete a record
$record->delete;

# Create a domain
my $new_domain = $dme->create_managed_domain('newdomain.com');

# Delete a domain
$domain->delete;
```

## API Versions

This module supports both API v1.2 and v2.0. Version 2.0 is the default.

```perl
# Use API v1.2
my $dme = WWW::DNSMadeEasy->new({
    api_key     => 'your-api-key',
    secret      => 'your-secret',
    api_version => '1.2',
});

my @domains = $dme->all_domains;
my $domain = $dme->domain('example.com');
my @records = $domain->all_records;
```

## Sandbox Mode

For testing, you can use the sandbox environment:

```perl
my $dme = WWW::DNSMadeEasy->new({
    api_key => 'your-api-key',
    secret  => 'your-secret',
    sandbox => 1,
});
```

## DNS Failover and Monitoring

```perl
my $record = $domain->records(name => 'www', type => 'A')->[0];

# Get monitor configuration
my $monitor = $record->get_monitor;

# Create/update monitor
$record->create_monitor(
    port        => 80,
    protocol_id => 3,  # HTTP
    sensitivity => 5,
    failover    => 'true',
);
```

## Testing

```bash
# Run tests with mock API
prove -l t/

# Run tests with live API (read-only)
TEST_WWW_DNSMADEEASY_API_KEY=xxx \
TEST_WWW_DNSMADEEASY_API_SECRET=yyy \
prove -l t/

# Run tests with live API including write operations
TEST_WWW_DNSMADEEASY_API_KEY=xxx \
TEST_WWW_DNSMADEEASY_API_SECRET=yyy \
TEST_WWW_DNSMADEEASY_WRITE=1 \
prove -l t/

# Use sandbox for live tests
TEST_WWW_DNSMADEEASY_SANDBOX=1 ...
```

## Requirements

- Business or Corporate DNSMadeEasy account (API access required)
- Perl 5.10 or later

## See Also

- [DNSMadeEasy REST API](https://dnsmadeeasy.com/technology/rest-api/)
- [API v2.0 Documentation](https://api-docs.dnsmadeeasy.com/)

## Author

Torsten Raudssus <torsten@raudssus.de>

API v2.0 support by Eric Johnson (KABLAMO)

## License

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
