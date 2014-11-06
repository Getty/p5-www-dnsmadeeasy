package WWW::DNSMadeEasy::ManagedDomain;
# ABSTRACT: A managed domain in the DNSMadeEasy API

use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;
use WWW::DNSMadeEasy::ManagedDomain::Record;

has dme => (
    is       => 'ro',
    required => 1,
    handles  => {
        request => 'request',
        path    => 'domain_path',
    }
);

has name     => (is => 'ro', required => 1);
has response => (is => 'rw', builder  => 1, lazy => 1);

sub _build_response {
    my ($self) = @_;
    $self->request(GET => $self->path . 'id/' . $self->name)->data;
}

sub active_third_parties  { shift->response->{activeThirdParties}  }
sub created               { shift->response->{created}             }
sub delegate_name_servers { shift->response->{delegateNameServers} }
sub folder_id             { shift->response->{folderId}            }
sub gtd_enabled           { shift->response->{gtdEnabled}          }
sub id                    { shift->response->{id}                  }
sub name_servers          { shift->response->{nameServers}         }
sub pending_action_id     { shift->response->{pendingActionId}     }
sub process_multi         { shift->response->{processMulti}        }
sub updated               { shift->response->{updated}             }

sub delete {
    my ($self) = @_;
    $self->request(DELETE => $self->path . $self->id);
}

sub update {
    my ($self, $data) = @_;
    my $res = $self->request(PUT => $self->path . $self->id, $data)->data;
    $self->response($res);
}

sub wait_for_delete {
    my ($self) = @_;
    while (1) {
        eval { $self->response($self->_build_response) };
        last if $@ && $@ =~ /404/;
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

#
# RECORDS
#

sub records_path { $_[0]->path . $_[0]->id . '/records/' }

sub create_record {
    my ( $self, %data ) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

	my $response = $self->request(POST => $self->records_path, \%req)->data;
	return WWW::DNSMadeEasy::ManagedDomain::Record->new(
        response => $response,
        domain   => $self,
    );
}

# TODO - do multiple gets when max number of records is reached
sub records {
    my ($self) = @_;
    my $data   = $self->request(GET => $self->records_path)->data->{data};

    my @records;
    for my $response (@$data) {
        push @records, WWW::DNSMadeEasy::ManagedDomain::Record
            ->new(response => $response, domain => $self);
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


