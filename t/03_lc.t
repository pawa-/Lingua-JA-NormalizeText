use strict;
use warnings;
use Lingua::JA::NormalizeText;
use Test::More;

my $normalizer = Lingua::JA::NormalizeText->new(qw/lc/);

is($normalizer->normalize("DdD"), 'ddd');

done_testing;
