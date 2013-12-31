use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
pawa
pawapawa@cpan.org
Lingua::JA::NormalizeText
HANKAKU
ZENKAKU
LF
ltrim
rtrim
nfc
nfd
nfkc
nfkd
FULLWIDTH
fullminus
hiragana
katakana
katakanas
wavetilde
nl
