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

has name       => (is => 'ro', required => 1);
has as_hashref => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);
has response   => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);

sub _build_as_hashref { shift->response->as_hashref }
sub _build_response { $_[0]->request(GET => $_[0]->path . 'id/' . $_[0]->name) }

sub active_third_parties  { shift->as_hashref->{activeThirdParties}  }
sub created               { shift->as_hashref->{created}             }
sub delegate_name_servers { shift->as_hashref->{delegateNameServers} }
sub folder_id             { shift->as_hashref->{folderId}            }
sub gtd_enabled           { shift->as_hashref->{gtdEnabled}          }
sub id                    { shift->as_hashref->{id}                  }
sub name_servers          { shift->as_hashref->{nameServers}         }
sub pending_action_id     { shift->as_hashref->{pendingActionId}     }
sub process_multi         { shift->as_hashref->{processMulti}        }
sub updated               { shift->as_hashref->{updated}             }

sub delete {
    my ($self) = @_;
    $self->request(DELETE => $self->path . $self->id);
}

sub update {
    my ($self, $data) = @_;
    $self->clear_as_hashref;
    my $res = $self->request(PUT => $self->path . $self->id, $data);
    $self->response($res);
}

sub wait_for_delete {
    my ($self) = @_;
    while (1) {
        $self->clear_response;
        $self->clear_as_hashref;
        eval { $self->response() };
        last if $@ && $@ =~ /(404|400)/;
        sleep 10;
    }
}

sub wait_for_pending_action {
    my ($self) = @_;
    while (1) {
        $self->clear_response;
        $self->clear_as_hashref;
        last if $self->pending_action_id == 0;
        sleep 10;
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

	return WWW::DNSMadeEasy::ManagedDomain::Record->new(
        response => $self->request(POST => $self->records_path, \%req),
        domain   => $self,
    );
}

# TODO 
# - do multiple gets when max number of records is reached
# - save the request as part of the Record obj
sub records {
    my ($self, %args) = @_;

    my $path = $self->records_path;
    $path .= '?type='       . $args{type} if $args{type} && !$args{name};
    $path .= '?recordName=' . $args{name} if $args{name} && !$args{type};
    $path .= '?recordName=' . $args{name} .
             '&type='       . $args{type} if $args{name} &&  $args{type};

    my $arrayref = $self->request(GET => $path)->data->{data};

    my @records;
    for my $hashref (@$arrayref) {
        push @records, WWW::DNSMadeEasy::ManagedDomain::Record
            ->new(as_hashref => $hashref, domain => $self);
    }

    return @records;
}

1;

=encoding utf8

=head1 METHODS

=method delete()

=method update(%data)

=method records(%data)

    my @records = $domain->records();                # Returns all records
    my @records = $domain->records(type => 'CNAME'); # Returns all CNAME records
    my @records = $domain->records(name => 'www');   # Returns all wwww records

Returns a list of L<WWW::DNSMadeEasy::ManagedDomain::Record> objects.

=method response

Returns the response for this object

=method as_hashref

Returns json response data as a hashref

=head1 MANAGED DOMAIN ATTRIBUTES

=method name

=method active_third_parties

=method created

=method delegate_name_servers

=method folder_id

=method gtd_enabled

=method id

=method name_servers

=method pending_action_id

=method process_multi

=method updated

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues


