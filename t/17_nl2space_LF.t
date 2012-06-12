use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/nl2space/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/nl2space/);

open(my $fh, '<:encoding(utf8)', './t/LF') or die $!;
my $text = do { local $/; <$fh> };
close($fh);

my $nl = "\x{000A}";

is($text, "あ${nl}い${nl}う${nl}");
is(nl2space($text), 'あ い う ');
is($normalizer->normalize($text), 'あ い う ');

done_testing;
