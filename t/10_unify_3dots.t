use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/unify_3dots/;
use Test::Base;
plan tests => 2 * blocks;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/unify_3dots/);

run {
    my $block  = shift;

    is(unify_3dots($block->input), $block->expected);
    is($normalizer->normalize($block->input), $block->expected);
};

__DATA__
=== one big hankaku dot
--- input:    大正野球娘｡
--- expected: 大正野球娘｡

=== one big zenkaku dot
--- input:    大正野球娘。
--- expected: 大正野球娘。

=== one small hankaku dot
--- input:    である.
--- expected: である.

=== one small zenkaku dot
--- input:    である．
--- expected: である．

=== one hankaku middle dot
--- input:    ティロ･フィナーレ
--- expected: ティロ･フィナーレ

=== one zenkaku middle dot
--- input:    ティロ・フィナーレ
--- expected: ティロ・フィナーレ

=== two big hankaku dots
--- input:    ふぅ｡｡
--- expected: ふぅ…

=== two big zenkaku dots
--- input:    ふぅ。。
--- expected: ふぅ…

=== two small hankaku dots
--- input:    ふぅ..
--- expected: ふぅ…

=== two small zenkaku dots
--- input:    ふぅ．．
--- expected: ふぅ…

=== two hankaku middole dots
--- input:    ふぅ･･
--- expected: ふぅ…

=== two zenkaku middole dots
--- input:    ふぅ・・
--- expected: ふぅ…

=== four big hankaku dots
--- input:    ふぅ｡｡｡｡
--- expected: ふぅ…

=== four big zenkaku dots
--- input:    ふぅ。。。。
--- expected: ふぅ…

=== four small hankaku dots
--- input:    ふぅ....
--- expected: ふぅ…

=== four small zenkaku dots
--- input:    ふぅ．．．．
--- expected: ふぅ…

=== four hankaku middle dots
--- input:    ふぅ････
--- expected: ふぅ…

=== four zenkaku middole dots
--- input:    ふぅ・・・・
--- expected: ふぅ…

=== three middle dots x2 type1
--- input:    ・・・・・・
--- expected: …

=== three middole dots x2 type2
--- input:    ・・・ふぅ・・・
--- expected: …ふぅ…

=== different two dots
--- input:    ・。
--- expected: ・。

=== different three dots
--- input:    ｡・。
--- expected: ｡・。

=== many dots type1
--- input:    ・・・・・・・。
--- expected: …。

=== many dots type2
--- input:    ・・・・・・・。。。
--- expected: …

=== many dots type3
--- input:    ・・。。・・
--- expected: …

=== two dots
--- input:    ‥
--- expected: …

=== two dots x2
--- input:    ‥ふぅ‥
--- expected: …ふぅ…
