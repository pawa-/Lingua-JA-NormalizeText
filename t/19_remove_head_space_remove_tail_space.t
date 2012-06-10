use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/remove_head_space remove_tail_space/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(
    qw/remove_head_space remove_tail_space/
);

is(remove_head_space("    にゃ？ "), "にゃ？ ");
is(remove_tail_space("   にゃにゃーん！   "), "   にゃにゃーん！");

my $text;
chomp($text = do { local $/; <DATA> });
is($normalizer->normalize($text), "にゃんだかにゃー\nにゃふん！");

done_testing;

__DATA__
　  にゃんだかにゃー　　　　
 にゃふん！　
