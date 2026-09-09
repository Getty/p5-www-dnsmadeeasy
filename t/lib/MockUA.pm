package MockUA;
use strict;
use warnings;
use Path::Tiny;
use HTTP::Response;

sub new {
  my ($class, %args) = @_;
  return bless {
    fixtures_dir => $args{fixtures_dir} // 't/fixtures',
    requests     => [],
  }, $class;
}

sub agent { }

# Every URI seen, newest last — lets a test assert what was actually put on the
# wire (e.g. the query string built by ManagedDomain::records).
sub requests { $_[0]->{requests} }
sub last_uri { $_[0]->{requests}[-1] }

sub request {
  my ($self, $http_request) = @_;
  my $method = $http_request->method;
  my $uri = $http_request->uri;
  my $path = $uri->path;

  push @{$self->{requests}}, $uri;

  my $fixture_file;

  # V2 API endpoints
  if ($path =~ m{^/V2\.0/dns/managed/id/([^/]+)$}) {
    $fixture_file = "v2-managed-domain-$1.json";
  } elsif ($path =~ m{^/V2\.0/dns/managed/(\d+)/records/(\d+)$}) {
    if ($method eq 'DELETE') {
      $fixture_file = 'v2-record-deleted.json';
    } elsif ($method eq 'PUT') {
      $fixture_file = 'v2-record-updated.json';
    }
  } elsif ($path =~ m{^/V2\.0/dns/managed/(\d+)/records/?}) {
    my $domain_id = $1;
    if ($method eq 'POST') {
      $fixture_file = 'v2-create-record.json';
    } elsif ($domain_id eq '200002') {
      # Paginated record list (regression fixture for records() pagination):
      # ?page=2 is routed to the second page, the first GET to page 1.
      my $query = $uri->query // '';
      $fixture_file = $query =~ /(?:\A|&)page=2(?:&|\z)/
        ? 'v2-records-page2.json'
        : 'v2-records-page1.json';
    } else {
      $fixture_file = 'v2-records.json';
    }
  } elsif ($path =~ m{^/V2\.0/dns/managed/(\d+)$}) {
    if ($method eq 'DELETE') {
      $fixture_file = 'v2-domain-deleted.json';
    } elsif ($method eq 'PUT') {
      $fixture_file = 'v2-domain-updated.json';
    }
  } elsif ($path =~ m{^/V2\.0/dns/managed/$}) {
    if ($method eq 'POST') {
      $fixture_file = 'v2-create-domain.json';
    } else {
      $fixture_file = 'v2-managed-domains.json';
    }
  } elsif ($path =~ m{^/V2\.0/monitor/(\d+)$}) {
    if ($method eq 'PUT') {
      $fixture_file = 'v2-monitor-updated.json';
    } else {
      $fixture_file = 'v2-monitor.json';
    }
  }
  # V1 API endpoints
  elsif ($path =~ m{^/V1\.2/domains/([^/]+)/records/(\d+)$}) {
    if ($method eq 'DELETE') {
      $fixture_file = 'v1-record-deleted.json';
    } elsif ($method eq 'PUT') {
      $fixture_file = 'v1-record-updated.json';
    }
  } elsif ($path =~ m{^/V1\.2/domains/([^/]+)/records$}) {
    if ($method eq 'POST') {
      $fixture_file = 'v1-create-record.json';
    } else {
      $fixture_file = 'v1-records.json';
    }
  } elsif ($path =~ m{^/V1\.2/domains/([^/]+)$}) {
    if ($method eq 'DELETE') {
      $fixture_file = 'v1-domain-deleted.json';
    } elsif ($method eq 'PUT') {
      $fixture_file = 'v1-domain-created.json';
    } else {
      $fixture_file = 'v1-domain.json';
    }
  } elsif ($path =~ m{^/V1\.2/domains$}) {
    if ($method eq 'POST') {
      $fixture_file = 'v1-create-domain.json';
    } else {
      $fixture_file = 'v1-domains.json';
    }
  }

  unless ($fixture_file) {
    return HTTP::Response->new(404, "No fixture for: $method $path");
  }

  my $file = path($self->{fixtures_dir}, $fixture_file);

  unless ($file->is_file) {
    # Für DELETE-Operationen ist eine leere Response OK
    if ($method eq 'DELETE') {
      my $response = HTTP::Response->new(200, 'OK');
      $response->content('');
      $response->header('Content-Type' => 'application/json');
      $response->header('x-dnsme-requestId' => '12345');
      $response->header('x-dnsme-requestLimit' => '150');
      $response->header('x-dnsme-requestsRemaining' => '149');
      return $response;
    }
    return HTTP::Response->new(404, "Fixture not found: $fixture_file");
  }

  my $content = $file->slurp_utf8;
  my $response = HTTP::Response->new(200, 'OK');
  $response->content($content);
  $response->header('Content-Type' => 'application/json');
  $response->header('x-dnsme-requestId' => '12345');
  $response->header('x-dnsme-requestLimit' => '150');
  $response->header('x-dnsme-requestsRemaining' => '149');

  return $response;
}

1;
