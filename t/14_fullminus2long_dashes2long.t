use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/fullminus2long dashes2long/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $minus = chr(hex("2212"));
my $dash  = chr(hex("2014"));
my $long  = chr(hex("30FC"));

my $normalizer = Lingua::JA::NormalizeText->new(qw/fullminus2long dashes2long/);
my $minus_dash_long = "$minus$dash$long";

is(fullminus2long($minus_dash_long x 2), "$long$dash$long"  x 2);
is(dashes2long($minus_dash_long x 2),    "$minus$long$long" x 2);
is($normalizer->normalize($minus_dash_long x 2), $long x 6);

my $dashes = "\x{2012}\x{2013}\x{2014}\x{2015}";
is(dashes2long($dashes), $long x length $dashes);

done_testing;
