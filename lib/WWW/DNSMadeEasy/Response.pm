package WWW::DNSMadeEasy::Response;

#  ABSTRACT: DNSMadeEasy Response

use Moo;
use JSON;

has response => (
    is       => 'ro',
    required => 1,
    handle   => ['is_success', 'content', 'decoded_content', 'status_line', 'code', 'header', 'as_string'],
);

sub as_hashref {
    my ($self) = @_;
    return decode_json($self->response->content);
}

sub error {
    my ($self) = @_;
    my $err = $self->as_hashref->{error};
    $err = [$err] unless ref($err) eq 'ARRAY';
    return wantarray ? @$err : join("\n", @$err);
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

