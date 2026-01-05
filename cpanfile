requires 'Moo', '0.009013';
requires 'LWP', '0';
requires 'JSON', '2.50';
requires 'URI', '1.58';
requires 'Digest::HMAC', '1.03';
requires 'DateTime', '0';
requires 'DateTime::Format::HTTP', '0.40';
requires 'Data::Printer', '0.35';
requires 'String::CamelSnakeKebab', '0.03';

on test => sub {
  requires 'Test::More', '0.96';
  requires 'Test::Most', '0.34';
};
