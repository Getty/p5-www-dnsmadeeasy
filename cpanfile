requires 'Moo';
requires 'LWP';
requires 'JSON';
requires 'Digest::HMAC';
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'Data::Printer';
requires 'String::CamelSnakeKebab';
requires 'URI';

on test => sub {
  requires 'Test::More', '0.96';
  requires 'Test::Most';
  requires 'Path::Tiny';
};
