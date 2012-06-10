use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/nl2space/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/nl2space/);

is(nl2space("あ\nい\nう"), 'あ い う');
is($normalizer->normalize("あ\n\nい\n\nう"), 'あ  い  う');

done_testing;
