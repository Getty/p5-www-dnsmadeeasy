package WWW::DNSMadeEasy;
# ABSTRACT: Accessing DNSMadeEasy API

use feature qw/say/;

use Moo;
use DateTime;
use DateTime::Format::HTTP;
use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use LWP::UserAgent;
use HTTP::Request;
use JSON;

use WWW::DNSMadeEasy::Domain;
use WWW::DNSMadeEasy::ManagedDomain;
use WWW::DNSMadeEasy::Response;

our $VERSION ||= '0.0development';

has api_key         => (is => 'ro', required => 1);
has secret          => (is => 'ro', required => 1);
has sandbox         => (is => 'ro', default => sub { 0 });
has last_response   => (is => 'rw');
has _http_agent     => (is => 'lazy');
has http_agent_name => (is => 'lazy');
has api_version     => (
    isa => sub {
        $_ && (
            $_ eq '1.2' or
            $_ eq '2.0'
        )
    },
    is => 'ro',
    default => sub { '1.2' },
);

sub _build__http_agent {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->agent($self->http_agent_name);
    return $ua;
}

sub _build_http_agent_name { __PACKAGE__.'/'.$VERSION }

sub api_endpoint {
    my ( $self ) = @_;
    if ($self->sandbox) {
        return 'http://api.sandbox.dnsmadeeasy.com/V'.$self->api_version.'/';
    } else {
        return 'http://api.dnsmadeeasy.com/V'.$self->api_version.'/';
    }
}

sub get_request_headers {
    my ( $self, $dt ) = @_;
    $dt = DateTime->now->set_time_zone( 'GMT' ) if !$dt;
    my $date_string = DateTime::Format::HTTP->format_datetime($dt);
    return {
        'x-dnsme-requestDate' => $date_string,
        'x-dnsme-apiKey' => $self->api_key,
        'x-dnsme-hmac' => hmac_sha1_hex($date_string, $self->secret),
    };
}

sub request {
    my ( $self, $method, $path, $data ) = @_;
    my $url = $self->api_endpoint.$path;
    say "$method $url" if $ENV{WWW_DME_DEBUG};
    my $request = HTTP::Request->new( $method => $url );
    my $headers = $self->get_request_headers;
    $request->header($_ => $headers->{$_}) for (keys %{$headers});
    $request->header('Accept' => 'application/json');
    if (defined $data) {
        $request->header('Content-Type' => 'application/json');
        $request->content(encode_json($data));
        use DDP; p $data if $ENV{WWW_DME_DEBUG};
    }
    my $res = $self->_http_agent->request($request);
    $res = WWW::DNSMadeEasy::Response->new( http_response => $res );
    say $res->content if $ENV{WWW_DME_DEBUG};
    $self->last_response($res);
    die ' HTTP request failed: ' . $res->status_line . "\n" unless $res->is_success;
    return $res;
}

sub requests_remaining {
    my ( $self ) = @_;
    return $self->last_response ? $self->last_response->requests_remaining : undef;
}

sub last_request_id {
    my ( $self ) = @_;
    return $self->last_response ? $self->last_response->request_id : undef;
}

sub request_limit {
    my ( $self ) = @_;
    return $self->last_response ? $self->last_response->request_limit : undef;
}

#
# V1 DOMAINS (TODO - move this into a role)
#

sub path_domains { 'domains' }

sub create_domain {
    my ( $self, $domain_name ) = @_;

    my $params = { dme => $self };
    if (ref $domain_name eq 'HASH') {
        $params->{obj} = $domain_name;
        $params->{name} = $domain_name->{name}; # name is required
    } else {
        $params->{name} = $domain_name;
    }

    return WWW::DNSMadeEasy::Domain->create($params);
}

sub domain {
    my ( $self, $domain_name ) = @_;
    return WWW::DNSMadeEasy::Domain->new({
        name => $domain_name,
        dme => $self,
    });
}

sub all_domains {
    my ( $self ) = @_;
    my $data = $self->request('GET',$self->path_domains)->data;
    return if !$data->{list};
    my @domains;
    for (@{$data->{list}}) {
        push @domains, WWW::DNSMadeEasy::Domain->new({
            dme => $self,
            name => $_,
        });
    }
    return @domains;
}

#
# V2 Managed domains (TODO - move this into a role)
#

sub domain_path {'dns/managed/'}

sub create_managed_domain {
    my ($self, $name) = @_;
    my $data     = {name => $name};
    my $response = $self->request(POST => $self->domain_path, $data);
    return WWW::DNSMadeEasy::ManagedDomain->new(
        dme        => $self,
        name       => $response->as_hashref->{name},
        as_hashref => $response->as_hashref,
    );
}

sub get_managed_domain {
    my ($self, $name) = @_;
    return WWW::DNSMadeEasy::ManagedDomain->new(
        name => $name,
        dme  => $self,
    );
}

sub managed_domains {
    my ($self) = @_;
    my $data   = $self->request(GET => $self->domain_path)->as_hashref->{data};

    my @domains;
    push @domains, WWW::DNSMadeEasy::ManagedDomain->new({
        dme  => $self,
        name => $_->{name},
    }) for @$data;

    return @domains;
}


1;


=encoding utf8

=head1 SYNOPSIS

    use WWW::DNSMadeEasy; # or WWW::DME as shortname
  
    # v2 api examples
    my $dme = WWW::DNSMadeEasy->new({
        api_key     => '1c1a3c91-4770-4ce7-96f4-54c0eb0e457a',
        secret      => 'c9b5625f-9834-4ff8-baba-4ed5f32cae55',
        sandbox     => 1,     # defaults to 0
        api_version => '2.0', # defaults to '1.0'
    });
    my @managed_domains = $dme->managed_domains;
    my $managed_domain  = $dme->get_managed_domain('example.com');
    my @records         = $domain->records;
    my $record          = $domain->create_record(
        ttl          => 120,
        gtd_location => 'DEFAULT',
        name         => 'www',
        data         => '1.2.3.4',
        type         => 'A',
    );
    $record->delete;
    $domain->delete;
  
    # v1 api examples
    my $dme = WWW::DNSMadeEasy->new({
        api_key => '1c1a3c91-4770-4ce7-96f4-54c0eb0e457a',
        secret  => 'c9b5625f-9834-4ff8-baba-4ed5f32cae55',
        sandbox => 1, # defaults to 0
    });
    my @domains = $dme->all_domains;
    my $domain  = $dme->create_domain('example.com');
    my @records = $domain->all_records;
    my $record = $domain->create_record({
        ttl => 120,
        gtdLocation => 'DEFAULT',
        name => 'www',
        data => '1.2.3.4',
        type => 'A',
    });
    $record->delete;
    $domain->delete;

=head1 DESCRIPTION

This distribution gives you easy access to the DNSMadeEasy API. You require a business or corporate account to use this. You can't use it with the free test account neither with the small business account. This module doesnt check any input values, I suggest so far that you know what you do.

=head1 ATTRIBUTES

=attr api_key

The API key which you can obtain from this page L<https://cp.dnsmadeeasy.com/account/info>.

=attr secret

The secret can be found on the same page as the API key.

=attr sandbox

If set to true, this will activate the usage of the sandbox, instead of the live system.

=attr http_agent_name

Here you can set a different http useragent for the requests, it defaults to the package name including the distribution version.

=head1 METHODS FOR API V2

=method create_managed_domain($name)

Creates the domain $name and returns a L<WWW::DNSMadeEasy::ManagedDomain> object.

=method get_managed_domain($name)

Searches for a domain with the name $name and returns a L<WWWW::DNSMadeEasy::ManagedDomain> object.

=method managed_domains()

Returns a list of L<WWWW::DNSMadeEasy::ManagedDomain> objects representing all domains.

=head1 METHODS FOR API V1

=method $obj->create_domain

Arguments: $name

Return value: L<WWW::DNSMadeEasy::Domain>

Will be creating the domain $name on your account and returns the L<WWW::DNSMadeEasy::Domain> for this domain.

=method $obj->domain

Arguments: $name

Return value: L<WWW::DNSMadeEasy::Domain>

Returns the L<WWW::DNSMadeEasy::Domain> of the domain with name $name.

=method $obj->all_domains

Arguments: None

Return value: Array of L<WWW::DNSMadeEasy::Domain>

Returns an array of L<WWW::DNSMadeEasy::Domain> objects of all domains listed on this account.

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues


