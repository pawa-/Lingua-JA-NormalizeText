package Lingua::JA::NormalizeText;

use 5.008_001;
use strict;
use warnings;
use utf8;

use Carp ();
use Exporter           qw/import/;
use Sub::Install       ();
use Unicode::Normalize ();
use HTML::Entities     ();
use HTML::Scrubber     ();
use Lingua::JA::Regular::Unicode ();
use Lingua::JA::Dakuon ();
use Lingua::JA::Moji   ();

our $VERSION   = '0.31';
our @EXPORT    = qw();
our @EXPORT_OK = qw(nfkc nfkd nfc nfd decode_entities strip_html
alnum_z2h alnum_h2z space_z2h space_h2z katakana_z2h katakana_h2z
katakana2hiragana hiragana2katakana wave2tilde tilde2wave
wavetilde2long wave2long tilde2long fullminus2long dashes2long
drawing_lines2long unify_long_repeats nl2space unify_long_spaces
unify_whitespaces unify_nl trim ltrim rtrim old2new_kana old2new_kanji
tab2space remove_controls remove_spaces dakuon_normalize
handakuon_normalize all_dakuon_normalize
square2katakana circled2kana circled2kanji);

our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

my %AVAILABLE_OPTS;
@AVAILABLE_OPTS{ (qw/lc uc/, @EXPORT_OK) } = ();

our $SCRUBBER = HTML::Scrubber->new;

# this does not work on Perl 5.8.8
# - couldn't find subroutine named lc in package CORE
# - Undefined subroutine &CORE::lc called
#Sub::Install::install_sub({ code => 'lc',                   from => 'CORE',                         into => __PACKAGE__, as => 'lc'                   });
#Sub::Install::install_sub({ code => 'uc',                   from => 'CORE',                         into => __PACKAGE__, as => 'uc'                   });
#Sub::Install::install_sub({ code =>  \&CORE::lc,                                                    into => __PACKAGE__, as => 'lc'                   });
#Sub::Install::install_sub({ code =>  \&CORE::uc,                                                    into => __PACKAGE__, as => 'uc'                   });

Sub::Install::install_sub({ code => 'NFKC',                 from => 'Unicode::Normalize',           into => __PACKAGE__, as => 'nfkc'                 });
Sub::Install::install_sub({ code => 'NFKD',                 from => 'Unicode::Normalize',           into => __PACKAGE__, as => 'nfkd'                 });
Sub::Install::install_sub({ code => 'NFC',                  from => 'Unicode::Normalize',           into => __PACKAGE__, as => 'nfc'                  });
Sub::Install::install_sub({ code => 'NFD',                  from => 'Unicode::Normalize',           into => __PACKAGE__, as => 'nfd'                  });
Sub::Install::install_sub({ code => 'decode_entities',      from => 'HTML::Entities',               into => __PACKAGE__, as => 'decode_entities'      });
Sub::Install::install_sub({ code => 'alnum_z2h',            from => 'Lingua::JA::Regular::Unicode', into => __PACKAGE__, as => 'alnum_z2h'            });
Sub::Install::install_sub({ code => 'alnum_h2z',            from => 'Lingua::JA::Regular::Unicode', into => __PACKAGE__, as => 'alnum_h2z'            });
Sub::Install::install_sub({ code => 'space_z2h',            from => 'Lingua::JA::Regular::Unicode', into => __PACKAGE__, as => 'space_z2h'            });
Sub::Install::install_sub({ code => 'space_h2z',            from => 'Lingua::JA::Regular::Unicode', into => __PACKAGE__, as => 'space_h2z'            });
Sub::Install::install_sub({ code => 'katakana_z2h',         from => 'Lingua::JA::Regular::Unicode', into => __PACKAGE__, as => 'katakana_z2h'         });
Sub::Install::install_sub({ code => 'katakana_h2z',         from => 'Lingua::JA::Regular::Unicode', into => __PACKAGE__, as => 'katakana_h2z'         });
Sub::Install::install_sub({ code => 'katakana2hiragana',    from => 'Lingua::JA::Regular::Unicode', into => __PACKAGE__, as => 'katakana2hiragana'    });
Sub::Install::install_sub({ code => 'hiragana2katakana',    from => 'Lingua::JA::Regular::Unicode', into => __PACKAGE__, as => 'hiragana2katakana'    });
Sub::Install::install_sub({ code => 'dakuon_normalize',     from => 'Lingua::JA::Dakuon',           into => __PACKAGE__, as => 'dakuon_normalize'     });
Sub::Install::install_sub({ code => 'handakuon_normalize',  from => 'Lingua::JA::Dakuon',           into => __PACKAGE__, as => 'handakuon_normalize'  });
Sub::Install::install_sub({ code => 'all_dakuon_normalize', from => 'Lingua::JA::Dakuon',           into => __PACKAGE__, as => 'all_dakuon_normalize' });
Sub::Install::install_sub({ code => 'square2katakana',      from => 'Lingua::JA::Moji',             into => __PACKAGE__, as => 'square2katakana'      });
Sub::Install::install_sub({ code => 'circled2kana',         from => 'Lingua::JA::Moji',             into => __PACKAGE__, as => 'circled2kana'         });
Sub::Install::install_sub({ code => 'circled2kanji',        from => 'Lingua::JA::Moji',             into => __PACKAGE__, as => 'circled2kanji'        });

sub new
{
    my ($class) = shift;

    my @opts = (ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_);

    Carp::croak("at least one option is required") unless scalar @opts;

    my $self = bless {}, $class;

    $self->{converters} = [];

    my @unavailable_opts;

    for my $opt (@opts)
    {
        if (ref $opt ne 'CODE')
        {
            if ( exists $AVAILABLE_OPTS{$opt} )
            {
                push( @{ $self->{converters} }, $opt );
            }
            else { push(@unavailable_opts, $opt); }
        }
        else
        {
            # external function
            push( @{ $self->{converters} }, $opt );
        }
    }

    Carp::croak( "unknown option(s): " . join(', ', @unavailable_opts) ) if scalar @unavailable_opts;

    return $self;
}

sub normalize
{
    my ($self, $text) = @_;

    if (defined $text)
    {
        no strict 'refs';
        $text = $_->($text) for @{ $self->{converters} };
    }

    return $text;
}

sub lc { return defined $_[0] ? CORE::lc $_[0] : undef; }
sub uc { return defined $_[0] ? CORE::uc $_[0] : undef; }

sub strip_html { $SCRUBBER->scrub(shift); }

sub wave2tilde           { local $_ = shift; return unless defined $_; tr/\x{301C}\x{3030}/\x{FF5E}/; $_; }
sub tilde2wave           { local $_ = shift; return unless defined $_; tr/\x{FF5E}/\x{301C}/; $_; }
sub wavetilde2long       { local $_ = shift; return unless defined $_; tr/\x{301C}\x{3030}\x{FF5E}/\x{30FC}/; $_; }
sub wave2long            { local $_ = shift; return unless defined $_; tr/\x{301C}\x{3030}/\x{30FC}/; $_; }
sub tilde2long           { local $_ = shift; return unless defined $_; tr/\x{FF5E}/\x{30FC}/; $_; }
sub fullminus2long       { local $_ = shift; return unless defined $_; tr/\x{FF0D}/\x{30FC}/; $_; }
sub dashes2long          { local $_ = shift; return unless defined $_; tr/\x{2012}\x{2013}\x{2014}\x{2015}/\x{30FC}/; $_; }
sub drawing_lines2long   { local $_ = shift; return unless defined $_; tr/\x{2500}\x{2501}\x{254C}\x{254D}\x{2574}\x{2576}\x{2578}\x{257A}/\x{30FC}/; $_; }
sub unify_long_repeats   { local $_ = shift; return unless defined $_; tr/\x{30FC}/\x{30FC}/s; $_; }
sub unify_long_spaces    { local $_ = shift; return unless defined $_; tr/\x{0020}/\x{0020}/s; tr/\x{3000}/\x{3000}/s; s/[\x{0020}\x{3000}]{2,}/\x{0020}/g; $_; }
sub unify_whitespaces    { local $_ = shift; return unless defined $_; tr/\x{000B}\x{000C}\x{0085}\x{00A0}\x{1680}\x{180E}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}/\x{0020}/; $_; }
sub trim                 { local $_ = shift; return unless defined $_; s/^\s+//; s/\s+$//; $_; }
sub ltrim                { local $_ = shift; return unless defined $_; s/^\s+//; $_; }
sub rtrim                { local $_ = shift; return unless defined $_; s/\s+$//; $_; }
sub nl2space             { local $_ = shift; return unless defined $_; s/\x{000D}\x{000A}/\x{0020}/g; tr/\x{000D}\x{000A}/\x{0020}/; $_; }
sub unify_nl             { local $_ = shift; return unless defined $_; s/\x{000D}\x{000A}/\n/g;       tr/\x{000D}\x{000A}/\n/; $_;       }
sub tab2space            { local $_ = shift; return unless defined $_; tr/\x{0009}/\x{0020}/; $_; }
sub old2new_kana         { local $_ = shift; return unless defined $_; tr/ゐヰゑヱ/いイえエ/; s/ヸ/イ\x{3099}/g; s/ヹ/エ\x{3099}/g; $_; }
sub remove_controls      { local $_ = shift; return unless defined $_; tr/\x{0000}-\x{0008}\x{000B}\x{000C}\x{000E}-\x{001F}\x{007F}-\x{009F}//d; $_; }
sub remove_spaces        { local $_ = shift; return unless defined $_; tr/\x{0020}\x{3000}//d; $_; }

sub old2new_kanji
{
    local $_ = shift;
    return unless defined $_;
    tr/亞惡壓圍爲醫壹逸稻飮隱營榮衞驛謁圓緣艷鹽奧應橫歐毆黃溫穩假價禍畫會壞悔懷海繪慨槪擴殼覺學嶽樂喝渴褐勸卷寬歡漢罐觀關陷顏器既歸氣祈龜僞戲犧舊據擧虛峽挾狹鄕響曉勤謹區驅勳薰徑惠揭溪經繼莖螢輕鷄藝擊缺儉劍圈檢權獻硏縣險顯驗嚴效廣恆鑛號國穀黑濟碎齋劑櫻册殺雜參慘棧蠶贊殘祉絲視齒兒辭濕實舍寫煮社者釋壽收臭從澁獸縱祝肅處暑緖署諸敍奬將涉燒祥稱證乘剩壤孃條淨狀疊讓釀囑觸寢愼眞神盡圖粹醉隨髓數樞瀨聲靜齊攝竊節專戰淺潛纖踐錢禪曾祖僧雙壯層搜插巢爭瘦總莊裝騷增憎臟藏贈卽屬續墮體對帶滯臺瀧擇澤單嘆擔膽團彈斷癡遲晝蟲鑄著廳徵懲聽敕鎭塚遞鐵轉點傳都黨盜燈當鬭德獨讀突屆繩難貳惱腦霸廢拜梅賣麥發髮拔繁晚蠻卑碑祕濱賓頻敏甁侮福拂佛倂塀竝變邊勉辨瓣辯舖步穗寶襃豐墨沒飜每萬滿免麵默餠戾彌藥譯豫餘與譽搖樣謠來賴亂欄覽隆龍虜兩獵綠壘淚類勵禮隸靈齡曆歷戀練鍊爐勞廊朗樓郞錄灣堯巖晉槇渚猪琢瑤祐祿禎穰聰遙/亜悪圧囲為医壱逸稲飲隠営栄衛駅謁円縁艶塩奥応横欧殴黄温穏仮価禍画会壊悔懐海絵慨概拡殻覚学岳楽喝渇褐勧巻寛歓漢缶観関陥顔器既帰気祈亀偽戯犠旧拠挙虚峡挟狭郷響暁勤謹区駆勲薫径恵掲渓経継茎蛍軽鶏芸撃欠倹剣圏検権献研県険顕験厳効広恒鉱号国穀黒済砕斎剤桜冊殺雑参惨桟蚕賛残祉糸視歯児辞湿実舎写煮社者釈寿収臭従渋獣縦祝粛処暑緒署諸叙奨将渉焼祥称証乗剰壌嬢条浄状畳譲醸嘱触寝慎真神尽図粋酔随髄数枢瀬声静斉摂窃節専戦浅潜繊践銭禅曽祖僧双壮層捜挿巣争痩総荘装騒増憎臓蔵贈即属続堕体対帯滞台滝択沢単嘆担胆団弾断痴遅昼虫鋳著庁徴懲聴勅鎮塚逓鉄転点伝都党盗灯当闘徳独読突届縄難弐悩脳覇廃拝梅売麦発髪抜繁晩蛮卑碑秘浜賓頻敏瓶侮福払仏併塀並変辺勉弁弁弁舗歩穂宝褒豊墨没翻毎万満免麺黙餅戻弥薬訳予余与誉揺様謡来頼乱欄覧隆竜虜両猟緑塁涙類励礼隷霊齢暦歴恋練錬炉労廊朗楼郎録湾尭巌晋槙渚猪琢瑶祐禄禎穣聡遥/;
    $_;
}

1;

__END__

=encoding utf8

=head1 NAME

Lingua::JA::NormalizeText - All-in-One Japanese text normalizer

=head1 SYNOPSIS

  use Lingua::JA::NormalizeText;
  use utf8;

  my @options = ( qw/nfkc decode_entities/, \&dearinsu_to_desu );
  my $normalizer = Lingua::JA::NormalizeText->new(@options);

  my $text = $normalizer->normalize('鳥が㌧㌦でありんす&hearts;'); # => '鳥がトンドルです♥'

  sub dearinsu_to_desu
  {
      my $text = shift;
      $text =~ s/でありんす/です/g;

      return $text;
  }

# or

  use Lingua::JA::NormalizeText qw/old2new_kanji/;
  use utf8;

  my $text = old2new_kanji('惡の華'); # => '悪の華'


=head1 DESCRIPTION

All-in-One Japanese text normalizer.

=head1 METHODS

=head2 new(@options)

Creates a new Lingua::JA::NormalizeText instance.

The following options are available:

  OPTION                 SAMPLE INPUT           OUTPUT FOR SAMPLE INPUT
  ---------------------  ---------------------  -----------------------
  lc                     DdD                    ddd
  uc                     DdD                    DDD
  nfkc                   ｶﾞ                     ガ (U+30AC)
  nfkd                   ｶﾞ                     ガ (U+30AB. U+3099)
  nfc                    ド                     ド (U+30C9)
  nfd                    ド                     ド (U+30C8, U+3099)
  decode_entities        &hearts;               ♥
  strip_html             <em>あ</em>                あ    
  alnum_z2h              ＡＢＣ１２３           ABC123
  alnum_h2z              ABC123                 ＡＢＣ１２３
  space_z2h              \x{3000}               \x{0020}
  space_h2z              \x{0020}               \x{3000}
  katakana_z2h           ハァハァ               ﾊｧﾊｧ
  katakana_h2z           ｽｰﾊｰｽｰﾊｰ               スーハースーハー
  katakana2hiragana      パンツ                 ぱんつ
  hiragana2katakana      ぱんつ                 パンツ
  wave2tilde             〜, 〰                 ～
  tilde2wave             ～                     〜
  wavetilde2long         〜, 〰, ～             ー
  wave2long              〜, 〰                 ー
  tilde2long             ～                     ー
  fullminus2long         －                     ー
  dashes2long            —                      ー
  drawing_lines2long     ─                      ー
  unify_long_repeats     ヴァーーー             ヴァー
  nl2space               (LF)(CR)(CRLF}         (space)(space)(space)
  unify_nl               (LF)(CR)(CRLF)         \n\n\n
  unify_long_spaces      あ(space)(space)あ     あ(space)あ
  unify_whitespaces      \x{00A0}               (space)
  trim                   (space)あ(space)あ(space)  あ(space)あ
  ltrim                  (space)あ(space)       あ(space)
  rtrim                  ああ(space)(space)     ああ
  old2new_kana           ゐヰゑヱヸヹ           いイえエイ゙エ゙
  old2new_kanji          亞逸鬭                 亜逸闘
  tab2space              (tab)(tab)             (space)(space)
  remove_controls        あ\x{0000}あ           ああ
  remove_spaces          \x{0020}あ\x{3000}あ\x{0020}  ああ
  dakuon_normalize       さ\x{3099}             ざ (U+3056)
  handakuon_normalize    は\x{309A}             ぱ (U+3071)
  all_dakuon_normalize   さ\x{3099}は\x{309A}   ざぱ (U+3056, U+3071)
  square2katakana        ㌢                     センチ
  circled2kana           ㋙㋛㋑㋟㋑             コシイタイ
  circled2kanji          ㊩㊫㊚㊒㊖             医学男有財

The order in which these options are applied is according to the order of
the elements of @options.
(i.e., The first element is applied first, and the last element is applied last.)

External functions are also addable.
(See dearinsu_to_desu function of the SYNOPSIS section.)


=head2 normalize($text)

normalizes $text.


=head1 OPTIONS

=head2 lc, uc

These options are the same as CORE::lc and CORE::uc.

=head2 nfkc, nfkd, nfc, nfd

See L<Unicode::Normalize>.

=head2 decode_entities

See L<HTML::Entities>.

=head2 strip_html

Strips the HTML tags from the given text.

=head2 alnum_z2h, alnum_h2z

Converts English alphabet, numbers and symbols ZENKAKU <-> HANKAKU.

ZENKAKU:

  ＇［ｖｏ，～４ｃ９Ｆｕ＿ＭＧＴＷＰｑ￣｠ＶｉＩｒ：ＺＸ］ｌ＞
  ｝￦！｜ｘ６％ｔ＾８ｅＤＫ５ｊ－￠ｈ１｛Ｕ２ＮＨ＆０＃Ｏｎ￢
  ＠｟ｆ３ＱａｐＪ￥？Ａｗ＼＄＂ＢｍＣ７；￤＝ｙ＋ｇＹＲｂＬｋ
  ）Ｓ｀Ｅ（￡＊．ｚｓ／＜ｄ

HANKAKU:

  '[vo,~4c9Fu_MGTWPq¯⦆ViIr:ZX]l>
  }₩!|x6%t^8eDK5j-¢h1{U2NH&0#On¬
  @⦅f3QapJ¥?Aw\$"BmC7;¦=y+gYRbLk
  )S`E(£*.zs/<d


=head2 space_z2h, space_h2z

SPACE (U+0020) <-> IDEOGRAPHIC SPACE (U+3000)

=head2 katakana_z2h, katakana_h2z

Converts katakanas ZENKAKU <-> HANKAKU.

See L<Lingua::JA::Regular::Unicode>.


=head2 hiragana2katakana

INPUT:

  ぷゔにむていでべゞゐふとおりげそづよはつざしゃのっねひぃたょ
  けまれびやがぽぬぺくぞぱごをへずかぴゅゎあきゖぇどだろもえわ
  んぶぜめなちばぢるすぁゕぼらぉゝぐほさゑぎみせじこぅゆう

OUTPUT FOR INPUT:

  プヴニムテイデベヾヰフトオリゲソヅヨハツザシャノッネヒィタョ
  ケマレビヤガポヌペクゾパゴヲヘズカピュヮアキヶェドダロモエワ
  ンブゼメナチバヂルスァヵボラォヽグホサヱギミセジコゥユウ


=head2 katakana2hiragana

INPUT:

  ﾘボズシｷｭﾙﾈグネキｪヱテｸニﾄﾛドェコヽﾁガﾍトｩダヤレ
  ﾆチソノｿｻパヨｧﾉﾊゴゲｫヮモヰルヲムｱﾃゼポフハャサッラ
  ﾏアィョｳｵオクメﾕゥヂギﾒウﾅスｽﾗｾザブﾌヘｺｶペカｲヾ
  エﾜヴンﾀｬﾎｮﾖツゾバプﾓセﾑｹリデﾐミホケイヒｯユﾂマヵ
  タﾚピジｼﾇビヅヌｨﾝｴァォヶナｦュﾔロﾋベワ

OUTPUT FOR INPUT:

  りぼずしきゅるねぐねきぇゑてくにとろどぇこゝちがへとぅだやれ
  にちそのそさぱよぁのはごげぉゎもゐるをむあてぜぽふはゃさっら
  まあぃょうおおくめゆぅぢぎめうなすすらせざぶふへこかぺかいゞ
  えわゔんたゃほょよつぞばぷもせむけりでみみほけいひっゆつまゕ
  たれぴじしぬびづぬぃんえぁぉゖなをゅやろひべわ


=head2 wave2tilde

Converts WAVE DASH (U+301C) and WAVY DASH (U+3030) into tilde (U+FF5E).

=head2 tilde2wave

Converts tilde (U+FF5E) into wave (U+301C).

=head2 wavetilde2long

Converts WAVE DASH (U+301C), WAVY DASH (U+3030) and tilde (U+FF5E) into long (U+30FC).

=head2 wave2long

Converts WAVE DASH (U+301C) and WAVY DASH (U+3030) into long (U+30FC).

=head2 tilde2long

Converts tilde (U+FF5E) into long (U+30FC).

=head2 fullminus2long

Converts FULLWIDTH HYPHEN-MINUS (U+FF0D) into long (U+30FC).

=head2 dashes2long

Converts the following characters into long (U+30FC).

  U+2012  FIGURE DASH
  U+2013  EN DASH
  U+2014  EM DASH
  U+2015  HORIZONTAL BAR

Note that this option does not convert hyphens into long.


=head2 drawing_line2long

Converts the following characters into long (U+30FC).

  U+2500  BOX DRAWINGS LIGHT HORIZONTAL
  U+2501  BOX DRAWINGS HEAVY HORIZONTAL
  U+254C  BOX DRAWINGS LIGHT DOUBLE DASH HORIZONTAL
  U+254D  BOX DRAWINGS HEAVY DOUBLE DASH HORIZONTAL
  U+2574  BOX DRAWINGS LIGHT LEFT
  U+2576  BOX DRAWINGS LIGHT RIGHT
  U+2578  BOX DRAWINGS HEAVY LEFT
  U+257A  BOX DRAWINGS HEAVY RIGHT


=head2 unify_long_repeats

Unifies long (U+30FC) repeats.

=head2 nl2space

Converts new lines (LF, CR, CRLF) into SPACE (U+0020).

=head2 unify_nl

Unifies new lines.

=head2 unify_long_spaces

Unifies long spaces (U+0020 and U+3000).

=head2 unify_whitespaces

Converts the following characters into SPACE (U+0020).

  U+000B  LINE TABULATION
  U+000C  FORM FEED
  U+0085  NEXT LINE
  U+00A0  NO-BREAK SPACE
  U+1680  OGHAM SPACE MARK
  U+180E  MONGOLIAN VOWEL SEPARATOR
  U+2000  EN QUAD
  U+2001  EM QUAD
  U+2002  EN SPACE
  U+2003  EM SPACE
  U+2004  THREE-PER-EM SPACE
  U+2005  FOUR-PER-EM SPACE
  U+2006  SIX-PER-EM SPACE
  U+2007  FIGURE SPACE
  U+2008  PUNCTUATION SPACE
  U+2009  THIN SPACE
  U+200A  HAIR SPACE
  U+2028  LINE SEPARATOR
  U+2029  PARAGRAPH SEPARATOR
  U+202F  NARROW NO-BREAK SPACE
  U+205F  MEDIUM MATHEMATICAL SPACE

Note that this option does not convert the following characters:

  U+0009  CHARACTER TABULATION
  U+000A  LINE FEED
  U+000D  CARRIAGE RETURN
  U+3000  IDEOGRAPHIC SPACE


=head2 trim

Removes leading and trailing whitespace.

=head2 ltrim

Removes only leading whitespace.

=head2 rtrim

Removes only trailing whitespace.

=head2 old2new_kana

  INPUT  OUTPUT FOR INPUT
  -----  --------------------
  ゐ     い
  ヰ     イ
  ゑ     え
  ヱ     エ
  ヸ     イ゙ (U+30A4, U+3099)
  ヹ     エ゙ (U+30A8, U+3099)


=head2 old2new_kanji

INPUT:

  亞惡壓圍爲醫壹逸稻飮隱營榮衞驛謁圓緣艷鹽奧應橫歐毆黃溫穩假價
  禍畫會壞悔懷海繪慨槪擴殼覺學嶽樂喝渴褐勸卷寬歡漢罐觀關陷顏器
  既歸氣祈龜僞戲犧舊據擧虛峽挾狹鄕響曉勤謹區驅勳薰徑惠揭溪經繼
  莖螢輕鷄藝擊缺儉劍圈檢權獻硏縣險顯驗嚴效廣恆鑛號國穀黑濟碎齋
  劑櫻册殺雜參慘棧蠶贊殘祉絲視齒兒辭濕實舍寫煮社者釋壽收臭從澁
  獸縱祝肅處暑緖署諸敍奬將涉燒祥稱證乘剩壤孃條淨狀疊讓釀囑觸寢
  愼眞神盡圖粹醉隨髓數樞瀨聲靜齊攝竊節專戰淺潛纖踐錢禪曾祖僧雙
  壯層搜插巢爭瘦總莊裝騷增憎臟藏贈卽屬續墮體對帶滯臺瀧擇澤單嘆
  擔膽團彈斷癡遲晝蟲鑄著廳徵懲聽敕鎭塚遞鐵轉點傳都黨盜燈當鬭德
  獨讀突屆繩難貳惱腦霸廢拜梅賣麥發髮拔繁晚蠻卑碑祕濱賓頻敏甁侮
  福拂佛倂塀竝變邊勉辨瓣辯舖步穗寶襃豐墨沒飜每萬滿免麵默餠戾彌
  藥譯豫餘與譽搖樣謠來賴亂欄覽隆龍虜兩獵綠壘淚類勵禮隸靈齡曆歷
  戀練鍊爐勞廊朗樓郞錄灣堯巖晉槇渚猪琢瑤祐祿禎穰聰遙

OUTPUT FOR INPUT:

  亜悪圧囲為医壱逸稲飲隠営栄衛駅謁円縁艶塩奥応横欧殴黄温穏仮価
  禍画会壊悔懐海絵慨概拡殻覚学岳楽喝渇褐勧巻寛歓漢缶観関陥顔器
  既帰気祈亀偽戯犠旧拠挙虚峡挟狭郷響暁勤謹区駆勲薫径恵掲渓経継
  茎蛍軽鶏芸撃欠倹剣圏検権献研県険顕験厳効広恒鉱号国穀黒済砕斎
  剤桜冊殺雑参惨桟蚕賛残祉糸視歯児辞湿実舎写煮社者釈寿収臭従渋
  獣縦祝粛処暑緒署諸叙奨将渉焼祥称証乗剰壌嬢条浄状畳譲醸嘱触寝
  慎真神尽図粋酔随髄数枢瀬声静斉摂窃節専戦浅潜繊践銭禅曽祖僧双
  壮層捜挿巣争痩総荘装騒増憎臓蔵贈即属続堕体対帯滞台滝択沢単嘆
  担胆団弾断痴遅昼虫鋳著庁徴懲聴勅鎮塚逓鉄転点伝都党盗灯当闘徳
  独読突届縄難弐悩脳覇廃拝梅売麦発髪抜繁晩蛮卑碑秘浜賓頻敏瓶侮
  福払仏併塀並変辺勉弁弁弁舗歩穂宝褒豊墨没翻毎万満免麺黙餅戻弥
  薬訳予余与誉揺様謡来頼乱欄覧隆竜虜両猟緑塁涙類励礼隷霊齢暦歴
  恋練錬炉労廊朗楼郎録湾尭巌晋槙渚猪琢瑶祐禄禎穣聡遥


=head2 tab2space

Converts CHARACTER TABULATION (U+0009) into SPACE (U+0020).

=head2 remove_controls

Removes the following characters:

  U+0000 - U+0008
  U+000B
  U+000C
  U+000E - U+001F
  U+007E - U+009F

Note that this option does not remove the following characters:

  U+0009  CHARACTER TABULATION
  U+000A  LINE FEED
  U+000D  CARRIAGE RETURN


=head2 remove_spaces

Removes SPACE (U+0020) and IDEOGRAPHIC SPACE (U+3000).

=head2 dakuon_normalize, handakuon_normalize, all_dakuon_normalize

See L<Lingua::JA::Dakuon>.

=head2 square2katakana, circled2kana, circled2kanji

See L<Lingua::JA::Moji>.


=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

新旧字体表: L<http://www.asahi-net.or.jp/~ax2s-kmtn/ref/old_chara.html>

L<Lingua::JA::Regular::Unicode>

L<Lingua::JA::Dakuon>

L<Lingua::JA::Moji>

L<Unicode::Normalize>

L<Unicode::Number>

L<HTML::Entities>

L<HTML::Scrubber>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
