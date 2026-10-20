#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use WWW::DNSMadeEasy;
use MockUA;

# A failed request has to say why it failed: the status line plus the error
# texts the API puts into the body. The wait helpers must not spin forever -
# they take a timeout and abort on errors that do not mean "the domain is
# gone". Always offline (MockUA), regardless of any live creds.

my $fixtures = "$FindBin::Bin/fixtures";

sub client {
    my (%args) = @_;
    my $dme = WWW::DNSMadeEasy->new({
        api_key     => 'test-api-key',
        secret      => 'test-secret',
        api_version => '2.0',
    });
    $dme->{_http_agent} = MockUA->new(fixtures_dir => $fixtures, %args);
    return $dme;
}

# A wait that never returns would stall the whole suite - turn it into a
# failed test instead of a hang.
sub within {
    my ( $seconds, $code ) = @_;
    local $SIG{ALRM} = sub {
        alarm 1;
        die "the wait did not return within $seconds seconds\n";
    };
    alarm $seconds;
    my @result = eval { $code->() };
    my $error = $@;
    alarm 0;
    die $error if $error;
    return wantarray ? @result : $result[0];
}

# A wait that ends as expected is a passed test, a wait that hangs or dies is
# a failed one.
sub wait_ok {
    my ( $label, $code ) = @_;
    my $ok = eval { within(5, $code); 1 };
    ok($ok, $label) or diag($@);
    return $ok;
}

#
# the failure message of request()
#

my $dme = client(responses => {
    'GET /V2.0/dns/managed/id/example.com' => [
        400,
        '{"error":["Record with this type, name, and value already exists.","Second problem"]}',
    ],
});

my $error = '';
eval { $dme->get_managed_domain('example.com')->id; 1 } or $error = $@;

like($error, qr/400 Bad Request/,
    'the failure message carries the status line');
like($error, qr/\QRecord with this type, name, and value already exists.\E/,
    'the failure message carries the first error text of the API');
like($error, qr/Second problem/,
    'the failure message carries every error text of the API');

#
# wait_for_delete
#

$dme = client(responses => {
    'GET /V2.0/dns/managed/id/gone.example.com' =>
        [ 404, '{"error":["Domain not found"]}' ],
});
my $domain = $dme->get_managed_domain('gone.example.com');
wait_ok('wait_for_delete ends when the domain is gone (404)',
    sub { $domain->wait_for_delete(timeout => 5) });

$dme = client(responses => {
    'GET /V2.0/dns/managed/id/unauthorized.example.com' =>
        [ 401, '{"error":["Authentication failed"]}' ],
});
$domain = $dme->get_managed_domain('unauthorized.example.com');
$error = '';
eval { within(5, sub { $domain->wait_for_delete(timeout => 5) }); 1 } or $error = $@;
like($error, qr/401 Unauthorized/,
    'wait_for_delete aborts on a 401 instead of polling on');
like($error, qr/Authentication failed/,
    'the abort of wait_for_delete carries the error text of the API');

$dme = client();
$domain = $dme->get_managed_domain('example.com');
$error = '';
eval { within(5, sub { $domain->wait_for_delete(timeout => 0) }); 1 } or $error = $@;
like($error, qr/timeout/i,
    'wait_for_delete gives up when the timeout is reached');

$dme = client(sequence => {
    'GET /V2.0/dns/managed/id/slow.example.com' => [
        [ 200, '{"id":200005,"name":"slow.example.com","pendingActionId":0}' ],
        [ 404, '{"error":["Domain not found"]}' ],
    ],
});
$domain = $dme->get_managed_domain('slow.example.com');
wait_ok('wait_for_delete polls until the domain is gone',
    sub { $domain->wait_for_delete(timeout => 5, interval => 0) });
is(scalar(@{$dme->{_http_agent}->requests}), 2,
    'wait_for_delete polled again while the domain was still there');

#
# wait_for_pending_action
#

$dme = client();
$domain = $dme->get_managed_domain('example.com');
wait_ok('wait_for_pending_action ends when no action is pending',
    sub { $domain->wait_for_pending_action(timeout => 5) });

$dme = client();
$domain = $dme->get_managed_domain('nopending.example.com');
my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    wait_ok('wait_for_pending_action ends when the API reports no pending action',
        sub { $domain->wait_for_pending_action(timeout => 5) });
}
is_deeply(\@warnings, [],
    'no warning about an undefined pendingActionId');

$dme = client(responses => {
    'GET /V2.0/dns/managed/id/unauthorized.example.com' =>
        [ 401, '{"error":["Authentication failed"]}' ],
});
$domain = $dme->get_managed_domain('unauthorized.example.com');
$error = '';
eval { within(5, sub { $domain->wait_for_pending_action(timeout => 5) }); 1 } or $error = $@;
like($error, qr/401 Unauthorized/,
    'wait_for_pending_action aborts on a 401');

$dme = client();
$domain = $dme->get_managed_domain('pending.example.com');
$error = '';
eval { within(5, sub { $domain->wait_for_pending_action(timeout => 0) }); 1 } or $error = $@;
like($error, qr/timeout/i,
    'wait_for_pending_action gives up when the timeout is reached');

#
# Response::error
#

$dme = client();
my $response = $dme->request(GET => 'dns/managed/id/example.com');
@warnings = ();
my @errors;
{
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    @errors = $response->error;
}
is_deeply(\@errors, [],
    'no error texts when the body carries no error');
is_deeply(\@warnings, [],
    'no warning when the body carries no error key');

done_testing;
