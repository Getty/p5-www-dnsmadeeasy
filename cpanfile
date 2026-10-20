requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'Digest::HMAC';
requires 'HTTP::Request';
requires 'JSON';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Moo';
requires 'String::CamelSnakeKebab';
requires 'URI';

on test => sub {
  requires 'Test::More', '0.96';
  requires 'Test::Most';
  requires 'Path::Tiny';
};
