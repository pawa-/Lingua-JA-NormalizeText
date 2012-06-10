use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/drawing_lines2long/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer    = Lingua::JA::NormalizeText->new(qw/drawing_lines2long/);
my @drawing_lines = qw/2500 2501 254C 254D 2574 2576 2578 257A 2212/;
my $long  = chr(hex("30FC"));

my $text;
for (@drawing_lines) { $text .= chr(hex($_)); }

is(drawing_lines2long($text),     ($long x (scalar @drawing_lines - 1)) . chr(hex("2212")));
is($normalizer->normalize($text), ($long x (scalar @drawing_lines - 1)) . chr(hex("2212")));

done_testing;
