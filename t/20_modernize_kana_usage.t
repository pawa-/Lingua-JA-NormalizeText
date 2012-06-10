use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/modernize_kana_usage/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/modernize_kana_usage/);

is(modernize_kana_usage('ヱヴァンゲリオン'), 'エヴァンゲリオン');
is($normalizer->normalize('ゐヰゑヱ' x 2), 'いイえエ' x 2);

done_testing;
