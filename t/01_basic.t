use strict;
use warnings;
use Lingua::JA::NormalizeText;
use Test::More;
use Test::Fatal;
use Test::Warn;


my @subs = qw/new normalize lc nfkc nfkd nfc nfd decode_entities/;
can_ok('Lingua::JA::NormalizeText', @subs);

my $exception = exception{ Lingua::JA::NormalizeText->new; };
like($exception, qr/at least/, 'at least one option exception');

$exception = exception{ Lingua::JA::NormalizeText->new(qw/cl ld/); };
like($exception, qr/unknown option\(s\): cl, ld/, 'unknown option exception');

$exception = exception{ Lingua::JA::NormalizeText->new(qw/lc cl/); };
like($exception, qr/unknown option\(s\): cl/, 'unknown option exception');

$exception = exception{ Lingua::JA::NormalizeText->new(qw/lc nfc/); };
is($exception, undef, 'no exception');


my $normalizer = Lingua::JA::NormalizeText->new(qw/lc/);
isa_ok($normalizer, 'Lingua::JA::NormalizeText');

my $result;
warning_is { $result = $normalizer->normalize($result); } 'undefined text',
'undefined text warning';
is($result, undef, 'result of normalizing undefined text');

$result = $normalizer->normalize('');
is($result, '', 'result of normalizing empty undefined text');

done_testing;
