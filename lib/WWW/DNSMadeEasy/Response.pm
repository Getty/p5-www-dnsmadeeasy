package WWW::DNSMadeEasy::Response;
# ABSTRACT: DNSMadeEasy Response

use Moo;
use JSON;

has http_response => (
    is       => 'ro',
    required => 1,
    handles   => ['is_success', 'content', 'decoded_content', 'status_line', 'code', 'header', 'as_string'],
);

has data => (
    is => 'ro',
    lazy => 1,
    builder => 1,
);

sub _build_as_hashref {
    my ($self) = @_;
    return unless $self->http_response->content; # DELETE return 200 but empty content
    return decode_json($self->http_response->content);
}

sub error {
    my ($self) = @_;
    my $err = $self->data->{error};
    $err = [$err] unless ref($err) eq 'ARRAY';
    return wantarray ? @$err : join("\n", @$err);
}

sub request_id {
  my ( $self ) = @_;
  $self->header('x-dnsme-requestId');
}

sub request_limit {
  my ( $self ) = @_;
  $self->header('x-dnsme-requestLimit');
}

sub requests_remaining {
  my ( $self ) = @_;
  $self->header('x-dnsme-requestsRemaining');
}

1;
__END__

=head1 SYNOPSIS

  my $response = WWW::DNSMadeEasy->new(...)->request(...);
  if ($response->is_success) {
      my $data = $response->as_hashref;
      my $requestsremaining = $response->header('x-dnsme-requestsremaining');
  } else {
      my @errors = $response->error;
  }

=head1 DESCRIPTION

Response object to fetch headers and error data

=head1 METHODS

=method is_success

=method content

=method decoded_content

=method status_line

=method code

=method header

=method as_string

All above are from L<HTTP::Response>

    my $requestsremaining = $response->header('x-dnsme-requestsremaining');
    my $json_data = $response->as_string;

=method as_hashref

    my $data = $response->as_hashref;

convert response JSON to HashRef

=method error

    my @errors = $response->error;

get the detailed request errors

