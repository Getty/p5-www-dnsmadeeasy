package WWW::DNSMadeEasy::Monitor;
# ABSTRACT: DNS Failover and System Monitoring configuration

use Moo;
use String::CamelSnakeKebab qw/lower_camel_case/;

use feature qw/say/;

has dme        => (is => 'ro', required => 1, handles => ['request']);
has record     => (is => 'ro', required => 1, handles => {path => 'monitor_path'});
has as_hashref => (is => 'rw', builder  => 1, lazy => 1, clearer => 1);
has response   => (is => 'rw');

sub _build_as_hashref { shift->response->as_hashref }

sub auto_failover      { shift->as_hashref->{autoFailover}      }
sub contact_list_id    { shift->as_hashref->{contactListId}     }
sub failover           { shift->as_hashref->{failover}          }
sub http_file          { shift->as_hashref->{httpFile}          }
sub http_fqdn          { shift->as_hashref->{httpFqdn}          }
sub http_query_string  { shift->as_hashref->{httpQueryString}   }
sub ip1                { shift->as_hashref->{ip1}               }
sub ip1_failed         { shift->as_hashref->{ip1Failed}         }
sub ip2                { shift->as_hashref->{ip2}               }
sub ip2_failed         { shift->as_hashref->{ip2Failed}         }
sub ip3                { shift->as_hashref->{ip3}               }
sub ip3_failed         { shift->as_hashref->{ip3Failed}         }
sub ip4                { shift->as_hashref->{ip4}               }
sub ip4_failed         { shift->as_hashref->{ip4Failed}         }
sub ip5                { shift->as_hashref->{ip5}               }
sub ip5_failed         { shift->as_hashref->{ip5Failed}         }
sub max_emails         { shift->as_hashref->{maxEmails}         }
sub monitor            { shift->as_hashref->{monitor}           }
sub port               { shift->as_hashref->{port}              }
sub protocol_id        { shift->as_hashref->{protocolId}        }
sub record_id          { shift->as_hashref->{recordId}          }
sub sensitivity        { shift->as_hashref->{sensitivity}       }
sub source             { shift->as_hashref->{source}            }
sub source_id          { shift->as_hashref->{sourceId}          }
sub system_description { shift->as_hashref->{systemDescription} }

sub ips {
    my ($self) = @_;
    my @ips;
    push @ips, $self->ip1 if $self->ip1;
    push @ips, $self->ip2 if $self->ip2;
    push @ips, $self->ip3 if $self->ip3;
    push @ips, $self->ip4 if $self->ip4;
    push @ips, $self->ip5 if $self->ip5;
    return @ips;
}

my %PROTOCOL = (
    1 => 'TCP',
    2 => 'UDP',
    3 => 'HTTP',
    4 => 'DNS',
    5 => 'SMTP',
    6 => 'HTTPS',
);

sub protocol { $PROTOCOL{shift->protocol_id} }

sub create { shift->update(@_) }

sub disable {
    my ($self) = @_;
    $self->update(
        port        => $self->port,
        failover    => 'false',
        monitor     => 'false',
        sensitivity => $self->sensitivity,
    );

    my $res = $self->request(GET => $self->path);
    $self->response($res);
}

sub update {
    my ($self, %data) = @_;

    my %req;
    for my $old (keys %data) {
        my $new = lower_camel_case($old);
        $req{$new} = $data{$old};
    }

    $self->clear_as_hashref;
    my $res = $self->request(PUT => $self->path, \%req);
    $self->response($res);
}


1;

=encoding utf8

=head1 METHODS

=method disable()

Disables dns failover and system monitoring.

=method update(%data)

=method response()

Returns the response for this object

=method as_hashref()

Returns json response data as a hashref

=method record()

Returns a L<WWW::DNSMadeEasy::ManagedDomain::Record> object.

=method ips()

Returns a list of failover ips (ip1, ip2, ...).

=method protocol()

Returns the protocol being monitored.  

    protocol_id    protocol
         1      =>    TCP
         2      =>    UDP
         3      =>    HTTP
         4      =>    DNS
         5      =>    SMTP
         6      =>    HTTP

=head1 MONITOR ATTRIBUTES

=method auto_failover()

=method contact_list_id()

=method failover()

=method http_file()

=method http_fqdn()

=method http_query_string()

=method ip1()

=method ip1_failed()

=method ip2()

=method ip2_failed()

=method ip3()

=method ip3_failed()

=method ip4()

=method ip4_failed()

=method ip5()

=method ip5_failed()

=method max_emails()

=method monitor()

=method port()

=method protocol_id()

=method record_id()

=method sensitivity()

=method source()

=method source_id()

=method system_description()

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net and highlight Getty or /msg me.

Repository

  http://github.com/Getty/p5-www-dnsmadeeasy
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-dnsmadeeasy/issues


