use strict;
use warnings;
use Lingua::JA::NormalizeText;
use Test::More;

my $normalizer = Lingua::JA::NormalizeText->new(qw/uc/);

ok($normalizer->normalize("DdD"), 'DDD');

done_testing;
