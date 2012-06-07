use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/nfkc nfkd nfc nfd/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

is( nfkc('㌦'), 'ドル', 'NFKC' ); # ドル
is( length nfkc('㌦'), 2, 'NFKC' );

is( nfkd('㌦'), 'ドル', 'NFKD' ); # ト U+3099 ル (length: 3)
is( length nfkd('㌦'), 3, 'NFKD' );

is( nfc('Á'), 'Á', 'NFC' );
is( nfc('①'), '①', 'NFC' );

is( nfd('①'), '①', 'NFD' );
is( nfd('Á'), 'Á', 'NFD' );

my $normalizer = Lingua::JA::NormalizeText->new(qw/nfkc/);
is($normalizer->normalize('㌻'), 'ページ', 'NFKC');

done_testing;
