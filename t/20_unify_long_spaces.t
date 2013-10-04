use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/unify_long_spaces/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/unify_long_spaces/);

is(unify_long_spaces("  (´・ω・｀)  "), ' (´・ω・｀) ');
is(unify_long_spaces("< 　 　>" x 2), '< >< >');
is(unify_long_spaces("<　 　 >" x 2), '< >< >');
is(unify_long_spaces("< 　　 >" x 2), '< >< >');
is($normalizer->normalize("　　(  ･`ω･´)　　　"), '　( ･`ω･´)　');

done_testing;
