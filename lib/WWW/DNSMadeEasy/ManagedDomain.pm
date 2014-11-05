package WWW::DNSMadeEasy::ManagedDomain;
# ABSTRACT: A managed domain in the DNSMadeEasy API

use Moo;
use WWW::DNSMadeEasy::ManagedDomain::Record;
use feature qw/say/;

has dme      => (is => 'ro', required => 1);
has name     => (is => 'ro', required => 1);
has response => (is => 'rw', builder  => 1, lazy => 1);

sub _build_response {
    my ($self) = @_;
	$self->dme->request(GET => $self->path . 'id/' . $self->name)->data;
}

sub path                   {'dns/managed/'}
sub active_third_parties   { shift->response->{activeThirdParties} }
sub created                { shift->response->{created} }
sub delegate_name_servers  { shift->response->{delegateNameServers} }
sub folder_id              { shift->response->{folderId} }
sub gtd_enabled            { shift->response->{gtdEnabled} }
sub id                     { shift->response->{id} }
sub name_servers           { shift->response->{nameServers} }
sub pending_action_id      { shift->response->{pendingActionId} }
sub process_multi          { shift->response->{processMulti} }
sub updated                { shift->response->{updated} }

sub create {
	my ($class, %args) = @_;
	my $self = $class->new(%args);
    delete $args{dme};
	my $response = $self->dme->request(POST => $self->path, \%args)->data;
    $self->response($response);
	return $self;
}

sub delete {
	my ($self) = @_;
	$self->dme->request(DELETE => $self->path . $self->id);
}

sub update {
	my ($self, $data) = @_;
	my $res = $self->dme->request(PUT => $self->path . $self->id, $data)->data;
    $self->response($res);
}

sub wait_for_delete {
    my ($self) = @_;
    while (1) {
        eval { $self->response($self->_build_response) };
        last unless $@ && $@ =~ /404/;
        sleep 5;
    }
}

sub wait_for_pending_action {
    my ($self) = @_;
    while (1) {
        $self->response($self->_build_response);
        last unless $self->pending_action_id;
        sleep 5;
    }
}

sub path_records { shift->path . $self->id . '/records' }

sub create_record {
	my ( $self, $data ) = @_;

	my $post_response = $self->dme->request('POST',$self->path_records,$data);

	return WWW::DNSMadeEasy::ManagedDomain::Record->new({
		domain => $self,
		id => $post_response->data->{id},
		response => $post_response,
	});
}

sub records {
	my ( $self ) = @_;

	my $response = $self->dme->request('GET',$self->path_records);

	my @response_records = @{$response->data};
	my @records;
	for (0..$#response_records) {
		push @records, WWW::DNSMadeEasy::ManagedDomain::Record->new({
			domain => $self,
			id => $response_records[$_]->{id},
			response => $response,
			response_index => $_,
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


