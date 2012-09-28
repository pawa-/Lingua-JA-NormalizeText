use strict;
use warnings;
use Lingua::JA::NormalizeText;
use Test::More;

my $normalizer = Lingua::JA::NormalizeText->new(qw/uc/);

is($normalizer->normalize("DdD"), 'DDD');

done_testing;
