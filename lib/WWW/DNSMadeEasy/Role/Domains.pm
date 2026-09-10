package WWW::DNSMadeEasy::Role::Domains;
# ABSTRACT: API v1.2 domain entry methods for the DNSMadeEasy client
our $VERSION = '0.101';
use Moo::Role;
use WWW::DNSMadeEasy::Domain;

requires 'request';

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

1;
