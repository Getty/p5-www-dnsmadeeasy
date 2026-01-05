package WWW::DNSMadeEasy::Domain::Record;
# ABSTRACT: A domain record in the DNSMadeEasy API
our $VERSION = '0.101';
use Moo;
use Carp;

has id => (
    is => 'ro',
    required => 1,
);

has domain => (
    is => 'ro',
    required => 1,
);

has response_index => (
    is => 'rw',
    predicate => 'has_response_index',
);

has as_hashref => (is => 'rw', builder => 1, lazy => 1);
has response   => (is => 'rw', builder => 1, lazy => 1);

sub _build_as_hashref { shift->response->as_hashref }
sub _build_response   { $_[0]->domain->dme->request(GET => $_[0]->path) }

sub ttl           { shift->as_hashref->{ttl}          }
sub gtd_location  { shift->as_hashref->{gtdLocation}  }
sub name          { shift->as_hashref->{name}         }
sub data          { shift->as_hashref->{data}         }
sub type          { shift->as_hashref->{type}         }
sub password      { shift->as_hashref->{password}     }
sub description   { shift->as_hashref->{description}  }
sub keywords      { shift->as_hashref->{keywords}     }
sub title         { shift->as_hashref->{title}        }
sub redirect_type { shift->as_hashref->{redirectType} }
sub hard_link     { shift->as_hashref->{hardLink}     }

sub path {
    my ( $self ) = @_;
    $self->domain->path_records.'/'.$self->id;
}

sub delete {
    my ( $self ) = @_;
    $self->domain->dme->request('DELETE',$self->path);
}

sub put { shift->update(@_) }

sub update {
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

=method $obj->update

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


