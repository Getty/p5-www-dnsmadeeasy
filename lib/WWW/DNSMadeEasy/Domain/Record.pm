package WWW::DNSMadeEasy::Domain::Record;
# ABSTRACT: A domain record in the DNSMadeEasy API

use Moo;
use Carp;

has id => (
    # isa => 'Int',
    is => 'ro',
    required => 1,
);

has domain => (
    # isa => 'WWW::DNSMadeEasy::Domain',
    is => 'ro',
    required => 1,
);

has response_index => (
    is => 'rw',
    predicate => 'has_response_index',
);

has response => (
    # isa => 'WWW::DNSMadeEasy::Response',
    is => 'rw',
    builder => 1,
    lazy => 1,
);

sub _build_response {
    my ( $self ) = @_;
    $self->domain->dme->request('GET',$self->path);
}

has response_data => (
    # isa => 'HashRef',
    is => 'ro',
    builder => 1,
    lazy => 1,
);

sub _build_response_data {
    my ( $self ) = @_;
    return {};
    #if ($self->has_response_index) {
    #    $self->response->as_hashref->
    #} else {
  
    #}
}

sub ttl { shift->response_data->{ttl} }
sub gtd_location { shift->response_data->{gtdLocation} }
sub name { shift->response_data->{name} }
sub data { shift->response_data->{data} }
sub type { shift->response_data->{type} }
sub password { shift->response_data->{password} }
sub description { shift->response_data->{description} }
sub keywords { shift->response_data->{keywords} }
sub title { shift->response_data->{title} }
sub redirect_type { shift->response_data->{redirectType} }
sub hard_link { shift->response_data->{hardLink} }

sub path {
    my ( $self ) = @_;
    $self->domain->path_records.'/'.$self->id;
}

sub delete {
    my ( $self ) = @_;
    $self->domain->dme->request('DELETE',$self->path);
}

sub put {
    my $self = shift;
    my %data = ( @_ % 2 == 1 ) ? %{ $_[0] } : @_;
    my $put_response = $self->domain->dme->request('PUT', $self->path, \%data);
    return WWW::DNSMadeEasy::Domain::Record->new({
        domain => $self->domain,
        id => $put_response->data->{id},
        response => $put_response,
    });
}

1;

=encoding utf8

=head1 ATTRIBUTES

=attr id

=attr domain

=attr obj

=head1 METHODS

=method $obj->delete

=method $obj->ttl

=method $obj->gtd_location

=method $obj->name

=method $obj->data

=method $obj->type

=method $obj->password

=method $obj->description

=method $obj->keywords

=method $obj->title

=method $obj->redirect_type

=method $obj->hard_link

=method $obj->put

    $record->put( {
        name => $name,
        type => $type,
        data => $data,
        gtdLocation => $gtdLocation,
        ttl => $ttl
    } );

to update the record

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues


