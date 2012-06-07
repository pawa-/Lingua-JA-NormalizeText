use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText;
use Test::Requires qw/Acme::Ikamusume/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $text = 'アカサ㌍タなのです！';

my $normalizer = Lingua::JA::NormalizeText->new( (qw/nfkc/, \&geso) );
is($normalizer->normalize($text), 'アカサカロリータなのでゲソ!');

done_testing;


sub geso { Acme::Ikamusume->geso(shift); }
