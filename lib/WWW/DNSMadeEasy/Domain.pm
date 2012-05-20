package WWW::DNSMadeEasy::Domain;
# ABSTRACT: A domain in the DNSMadeEasy API

use Moo;
use WWW::DNSMadeEasy::Domain::Record;

has name => (
	# isa => 'Str',
	is => 'ro',
	required => 1,
);

has dme => (
	# isa => 'WWW::DNSMadeEasy',
	is => 'ro',
	required => 1,
);

sub create {
	my ( $class, @args ) = @_;
	my $domain = $class->new(@args);
	$domain->put;
	return $domain;
}

sub path {
	my ( $self ) = @_;
	$self->dme->path_domains.'/'.$self->name;
}

sub delete {
	my ( $self ) = @_;
	$self->dme->request('DELETE',$self->path);
}

sub put {
	my ( $self ) = @_;
	$self->dme->request('PUT',$self->path);
}

sub path_records { shift->path.'/records' }

sub name_server { shift->obj->{nameServer} }
sub gtd_enabled { shift->obj->{gtdEnabled} }
sub vanity_name_servers { shift->obj->{vanityNameServers} }
sub vanity_id { shift->obj->{vanityId} }

has obj => (
	is => 'ro',
	builder => '_build_obj',
	lazy => 1,
);

sub _build_obj {
	my ( $self ) = @_;
	$self->dme->request('GET',$self->path);
}

sub create_record {
	my ( $self, $obj ) = @_;

	my $post_result = $self->dme->request('POST',$self->path_records,$obj);

	return WWW::DNSMadeEasy::Domain::Record->new({
		domain => $self,
		id => $_->{id},
		obj => $post_result,
	});
}

sub post {
	my ( $self ) = @_;
	$self->dme->request('POST',$self->path);
}

sub all_records {
	my ( $self ) = @_;

	my $data = $self->dme->request('GET',$self->path_records);

	my @records;
	for (@{$data}) {
		push @records, WWW::DNSMadeEasy::Domain::Record->new({
			domain => $self,
			id => $_->{id},
			obj => $_,
		});
	}
	return @records;
}

1;

=encoding utf8

=head1 ATTRIBUTES

=attr name

Name of the domain

=attr dme

L<WWW::DNSMadeEasy> object

=attr obj

Hash object representation given by DNSMadeEasy.

=head1 METHODS

=method $obj->put

=method $obj->delete

=method $obj->all_records

=method $obj->create_record

=method $obj->name_server

=method $obj->gtd_enabled

=method $obj->vanity_name_servers

=method $obj->vanity_id

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues


