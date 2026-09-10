package WWW::DNSMadeEasy::Role::ManagedDomains;
# ABSTRACT: API v2.0 managed-domain entry methods for the DNSMadeEasy client
our $VERSION = '0.101';
use Moo::Role;
use WWW::DNSMadeEasy::ManagedDomain;

requires 'request';

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
