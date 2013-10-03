use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/ltrim rtrim/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(
    qw/ltrim rtrim/
);

is( ltrim("    にゃ？ "), "にゃ？ ", "ltrim" );
is( rtrim("   にゃにゃーん！   "), "   にゃにゃーん！", "rtrim" );

my $text;
chomp($text = do { local $/; <DATA> });
is($normalizer->normalize($text), "にゃんだかにゃー\nにゃふん！");

done_testing;

__DATA__
　  	にゃんだかにゃー　　　　
 にゃふん！　
