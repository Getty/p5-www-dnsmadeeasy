package WWW::DNSMadeEasy::ManagedDomain::Record;
# ABSTRACT: A managed domain record in the DNSMadeEasy API
our $VERSION = '0.101';
use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;
use WWW::DNSMadeEasy::Monitor;

has domain     => (is => 'ro', required => 1, handles => {path => 'records_path'});
has dme        => (is => 'lazy', handles => ['request']);
has as_hashref => (is => 'rw', builder => 1, lazy => 1, clearer => 1);
has response   => (is => 'rw');

sub _build_dme        { shift->domain->dme }
sub _build_as_hashref { shift->response->as_hashref }

sub description   { shift->as_hashref->{description}  }
sub dynamic_dns   { shift->as_hashref->{dynamicDns}   }
sub failed        { shift->as_hashref->{failed}       }
sub failover      { shift->as_hashref->{failover}     }
sub gtd_location  { shift->as_hashref->{gtdLocation}  }
sub hard_link     { shift->as_hashref->{hardLink}     }
sub id            { shift->as_hashref->{id}           }
sub keywords      { shift->as_hashref->{keywords}     }
sub monitor       { shift->as_hashref->{monitor}      }
sub mxLevel       { shift->as_hashref->{mxLevel}      }
sub name          { shift->as_hashref->{name}         }
sub password      { shift->as_hashref->{password}     }
sub port          { shift->as_hashref->{port}         }
sub priority      { shift->as_hashref->{priority}     }
sub redirect_type { shift->as_hashref->{redirectType} }
sub source        { shift->as_hashref->{source}       }
sub source_id     { shift->as_hashref->{source_id}    }
sub title         { shift->as_hashref->{title}        }
sub ttl           { shift->as_hashref->{ttl}          }
sub type          { shift->as_hashref->{type}         }
sub value         { shift->as_hashref->{value}        }
sub weight        { shift->as_hashref->{weight}       }

sub delete {
    my ($self) = @_;
    $self->request('DELETE', $self->path . $self->id);
}

sub update {
    my ($self, %data) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    $req{id}   //= $self->id;
    $req{name} //= $self->name;

    my $id   = $self->id;
    my $type = $self->type;
    my $name = $self->name;
    $self->clear_as_hashref;
    $self->request(PUT => $self->path . $id, \%req);

    # GRR DME doesn't return the updasted record and there is no way to get a
    # single record by id
    $name = $req{name} if $req{name};
    my @records = $self->domain->records(type => $type, name => $name);
    for my $record (@records) {
        next unless $record->id eq $id;
        $self->as_hashref($record->as_hashref);
    }
}

sub monitor_path { 'monitor/' . shift->id  }

sub get_monitor {
    my ($self) = @_;
    return WWW::DNSMadeEasy::Monitor->new(
        response => $self->request(GET => $self->monitor_path),
        dme      => $self->dme,
        record   => $self,
    );
}

sub create_monitor {
    my ($self, %data) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    my $monitor = WWW::DNSMadeEasy::Monitor->new(
        response => $self->request(PUT => $self->monitor_path, \%req),
        dme      => $self->dme,
        record   => $self,
    );
}

1;

=encoding utf8

=head1 METHODS

=method delete()

=method update(%data)

Can't update id, name, type, or gtd_location.

=method response()

Returns this object as a hashreference.

=method get_monitor()

Returns a L<WWW::DNSMadeEasy::Monitor> object which deals with dns failover and system monitoring.

=head1 RECORD ATTRIBUTES

=method description

=method dynamic_dns

=method failed

=method failover

=method gtd_location

=method hard_link

=method id

=method keywords

=method monitor

=method mxLevel

=method name

=method password

=method port

=method priority

=method redirect_type

=method source

=method source_id

=method title

=method ttl

=method type

=method value

=method weight

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues


