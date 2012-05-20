package WWW::DNSMadeEasy::Domain::Record;
# ABSTRACT: A domain record in the DNSMadeEasy API

use Moo;

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

has obj => (
	# isa => 'HashRef',
	is => 'ro',
	builder => '_build_obj',
	lazy => 1,
);

sub _build_obj {
	my ( $self ) = @_;
	$self->domain->dme->request('GET',$self->path);
}

sub ttl { shift->obj->{ttl} }
sub gtd_location { shift->obj->{gtdLocation} }
sub name { shift->obj->{name} }
sub data { shift->obj->{data} }
sub type { shift->obj->{type} }
sub password { shift->obj->{password} }
sub description { shift->obj->{description} }
sub keywords { shift->obj->{keywords} }
sub title { shift->obj->{title} }
sub redirect_type { shift->obj->{redirectType} }
sub hard_link { shift->obj->{hardLink} }

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
    foreach my $k (keys %data) {
        $self->obj->{$k} = $data{$k};
    }
    $self->domain->dme->request('PUT', $self->path, $self->obj);
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


