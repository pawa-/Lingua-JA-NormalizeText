use strict;
use warnings;
use Lingua::JA::NormalizeText;
use Test::More;

my $normalizer = Lingua::JA::NormalizeText->new(qw/lc/);

ok($normalizer->normalize("DdD"), 'ddd');

done_testing;
