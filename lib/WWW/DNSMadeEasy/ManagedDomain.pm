package WWW::DNSMadeEasy::ManagedDomain;
# ABSTRACT: A managed domain in the DNSMadeEasy API
our $VERSION = '0.101';
use Moo;
use Carp qw( croak );
use URI;
use String::CamelSnakeKebab qw/lower_camel_case/;
use WWW::DNSMadeEasy::ManagedDomain::Record;

use constant WAIT_TIMEOUT  => 300;
use constant WAIT_INTERVAL => 10;

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
    my ( $self, %args ) = @_;
    my $timeout  = $args{timeout}  // WAIT_TIMEOUT;
    my $interval = $args{interval} // WAIT_INTERVAL;
    my $deadline = time + $timeout;

    while (1) {
        $self->clear_response;
        $self->clear_as_hashref;
        eval { $self->response() };
        if ( my $error = $@ ) {
            # A deleted domain answers with 404, a delete that is still
            # running with the expected 400 - both end the wait. Every other
            # error (401 after a key rotation, 429 rate limit, a network
            # error) says nothing about the delete and is rethrown instead of
            # being polled on forever.
            my $code = $self->_last_status_code;
            return 1 if defined $code && ( $code == 404 || $code == 400 );
            die $error;
        }

        # The domain is still there.
        if ( time >= $deadline ) {
            croak 'wait_for_delete: timeout of '.$timeout.' seconds reached, '.$self->name.' is still there';
        }
        sleep $interval;
    }
}

sub wait_for_pending_action {
    my ( $self, %args ) = @_;
    my $timeout  = $args{timeout}  // WAIT_TIMEOUT;
    my $interval = $args{interval} // WAIT_INTERVAL;
    my $deadline = time + $timeout;

    while (1) {
        $self->clear_response;
        $self->clear_as_hashref;
        my $pending;
        eval { $pending = $self->pending_action_id };
        if ( my $error = $@ ) {
            my $code = $self->_last_status_code;
            return 1 if defined $code && ( $code == 404 || $code == 400 );
            die $error;
        }

        # An undefined pendingActionId means the API reports no pending
        # action - that is nothing pending, not an error.
        return 1 if !$pending;

        if ( time >= $deadline ) {
            croak 'wait_for_pending_action: timeout of '.$timeout.' seconds reached, '.$self->name.' still has a pending action';
        }
        sleep $interval;
    }
}

# The status of the last response, or undef if there was none - a network
# error never produces a response.
sub _last_status_code {
    my ( $self ) = @_;
    my $response = $self->dme->last_response;
    return unless $response;
    return $response->code;
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
# - save the request as part of the Record obj
sub records {
    my ($self, %args) = @_;

    # Deterministic (ordered) query params: DME v2 uses recordName / type, plus
    # page for pagination below. URI->query_form does the assembly and encoding;
    # a relative URI stringifies straight into request()'s api_endpoint.$path.
    my @query;
    push @query, ( recordName => $args{name} ) if defined $args{name};
    push @query, ( type       => $args{type} ) if defined $args{type};

    my $uri = URI->new($self->records_path);
    $uri->query_form(@query) if @query;

    # The record list is paginated: the first GET (no page param) returns page 1
    # and reports the current page and totalPages. Follow every further page,
    # otherwise records past the server's page size are silently lost.
    my $data = $self->request(GET => $uri)->data;
    my @arrayref = @{$data->{data}};

    my $page        = $data->{page}       // 1;
    my $total_pages = $data->{totalPages} // 1;
    for my $next ($page + 1 .. $total_pages) {
        my $page_uri = URI->new($self->records_path);
        $page_uri->query_form(@query, page => $next);
        push @arrayref, @{$self->request(GET => $page_uri)->data->{data}};
    }

    my @records;
    for my $hashref (@arrayref) {
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

=method wait_for_delete(%args)

Waits until the domain is gone. The wait ends when the API answers with 404
(the domain is gone) or with the expected 400 (the delete is still running).
Every other error is rethrown.

    $domain->wait_for_delete(timeout => 60);

=method wait_for_pending_action(%args)

Waits until the domain has no pending action left. A pendingActionId that the
API does not report counts as no pending action.

    $domain->wait_for_pending_action(timeout => 60);

Both methods take these optional arguments:

    timeout   - seconds to wait at most (default 300)
    interval  - seconds between two polls (default 10)

They croak when the timeout is reached and return true when the wait ended as
expected.

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


