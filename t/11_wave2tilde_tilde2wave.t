use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/wave2tilde tilde2wave/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $tilde = chr(hex("FF5E"));
my $wave  = chr(hex("301C"));

my $normalizer_w2t = Lingua::JA::NormalizeText->new(qw/wave2tilde/);
my $normalizer_t2w = Lingua::JA::NormalizeText->new(qw/tilde2wave/);

is(wave2tilde($wave),  $tilde);
is(wave2tilde($tilde), $tilde);
is($normalizer_w2t->normalize($wave),  $tilde);
is($normalizer_w2t->normalize($tilde), $tilde);

is(tilde2wave($wave),  $wave);
is(tilde2wave($tilde), $wave);
is($normalizer_t2w->normalize($wave),  $wave);
is($normalizer_t2w->normalize($tilde), $wave);

$tilde = $tilde . 'あ' . $tilde;
$wave  = $wave  . 'あ' . $wave;

is(wave2tilde($wave), $tilde);
is(wave2tilde($tilde), $tilde);
is($normalizer_w2t->normalize($wave),  $tilde);
is($normalizer_w2t->normalize($tilde), $tilde);

is(tilde2wave($wave), $wave);
is(tilde2wave($tilde), $wave);
is($normalizer_t2w->normalize($wave),  $wave);
is($normalizer_t2w->normalize($tilde), $wave);

done_testing;
