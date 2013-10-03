use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/
    strip_html nl2space unify_long_spaces
    ltrim rtrim
/);

my $html = do { local $/; <DATA> };

is($normalizer->normalize($html), 'タイトル 見出し ナビゲーション');

done_testing;

__DATA__
<!DOCTYPE html>
<html lang="ja">

<head>
    <meta charset="UTF-8">
    <title>タイトル</title>
</head>

<body>
    <h1>見出し</h1>

    <nav>
        <ul>
            <li>ナビゲーション</li>
        </ul>
    </nav>

    <script type="text/javascript">hoge();</script>
</body>

</html>
