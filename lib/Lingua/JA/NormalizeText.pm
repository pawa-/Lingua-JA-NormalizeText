package Lingua::JA::NormalizeText;

use 5.008_001;
use strict;
use warnings;
use utf8;

use Carp ();
use Exporter           qw/import/;
use Unicode::Normalize ();
use HTML::Entities     ();
use HTML::Scrubber     ();
use Lingua::JA::Regular::Unicode ();
use Lingua::JA::Dakuon ();

our $VERSION   = '0.21';
our @EXPORT    = qw();
our @EXPORT_OK = qw(nfkc nfkd nfc nfd decode_entities strip_html
alnum_z2h alnum_h2z space_z2h space_h2z katakana_z2h katakana_h2z
katakana2hiragana hiragana2katakana wave2tilde tilde2wave
wavetilde2long wave2long tilde2long fullminus2long dashes2long
drawing_lines2long unify_long_repeats nl2space unify_long_spaces
unify_whitespaces unify_nl trim ltrim rtrim old2new_kana old2new_kanji
tab2space remove_controls remove_spaces dakuon_normalize
handakuon_normalize all_dakuon_normalize);

our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

my %AVAILABLE_OPTS;
@AVAILABLE_OPTS{ (qw/lc uc/, @EXPORT_OK) } = ();

our $SCRUBBER = HTML::Scrubber->new;


sub new
{
    my ($class, @opts) = @_;
    my $self = bless {}, $class;

    Carp::croak("at least one option is required") unless scalar @opts;

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

sub lc   { lc(shift); }
sub uc   { uc(shift); }

sub nfkc { Unicode::Normalize::NFKC(shift); }
sub nfkd { Unicode::Normalize::NFKD(shift); }
sub nfc  { Unicode::Normalize::NFC(shift);  }
sub nfd  { Unicode::Normalize::NFD(shift);  }

sub decode_entities { HTML::Entities::decode_entities(shift); }

sub strip_html { $SCRUBBER->scrub(shift); }

sub alnum_z2h         { Lingua::JA::Regular::Unicode::alnum_z2h(shift);         }
sub alnum_h2z         { Lingua::JA::Regular::Unicode::alnum_h2z(shift);         }
sub space_z2h         { Lingua::JA::Regular::Unicode::space_z2h(shift);         }
sub space_h2z         { Lingua::JA::Regular::Unicode::space_h2z(shift);         }
sub katakana_z2h      { Lingua::JA::Regular::Unicode::katakana_z2h(shift);      }
sub katakana_h2z      { Lingua::JA::Regular::Unicode::katakana_h2z(shift);      }
sub katakana2hiragana { Lingua::JA::Regular::Unicode::katakana2hiragana(shift); }
sub hiragana2katakana { Lingua::JA::Regular::Unicode::hiragana2katakana(shift); }

sub dakuon_normalize     { Lingua::JA::Dakuon::dakuon_normalize(shift);     }
sub handakuon_normalize  { Lingua::JA::Dakuon::handakuon_normalize(shift);  }
sub all_dakuon_normalize { Lingua::JA::Dakuon::all_dakuon_normalize(shift); }

sub wave2tilde           { local $_ = shift; return unless defined $_; tr/\x{301C}/\x{FF5E}/; $_; }
sub tilde2wave           { local $_ = shift; return unless defined $_; tr/\x{FF5E}/\x{301C}/; $_; }
sub wavetilde2long       { local $_ = shift; return unless defined $_; tr/\x{301C}\x{FF5E}/\x{30FC}/; $_; }
sub wave2long            { local $_ = shift; return unless defined $_; tr/\x{301C}/\x{30FC}/; $_; }
sub tilde2long           { local $_ = shift; return unless defined $_; tr/\x{FF5E}/\x{30FC}/; $_; }
sub fullminus2long       { local $_ = shift; return unless defined $_; tr/\x{2212}/\x{30FC}/; $_; }
sub dashes2long          { local $_ = shift; return unless defined $_; tr/\x{2012}\x{2013}\x{2014}\x{2015}/\x{30FC}/; $_; }
sub drawing_lines2long   { local $_ = shift; return unless defined $_; tr/\x{2500}\x{2501}\x{254C}\x{254D}\x{2574}\x{2576}\x{2578}\x{257A}/\x{30FC}/; $_; }
sub unify_long_repeats   { local $_ = shift; return unless defined $_; tr/\x{30FC}/\x{30FC}/s; $_; }
sub unify_long_spaces    { local $_ = shift; return unless defined $_; tr/\x{0020}/\x{0020}/s; tr/\x{3000}/\x{3000}/s; s/[\x{0020}\x{3000}]{2,}/\x{0020}/g; $_; }
sub unify_whitespaces    { local $_ = shift; return unless defined $_; tr/\x{000B}\x{000C}\x{0085}\x{00A0}\x{1680}\x{180E}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}/\x{0020}/; $_; }
sub trim                 { local $_ = shift; return unless defined $_; s/^\s+//g; s/\s+$//g; $_; }
sub ltrim                { local $_ = shift; return unless defined $_; s/^\s+//g; $_; }
sub rtrim                { local $_ = shift; return unless defined $_; s/\s+$//g; $_; }
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

Lingua::JA::NormalizeText - Text Normalizer

=head1 SYNOPSIS

  use Lingua::JA::NormalizeText;
  use utf8;

  my @options = ( qw/nfkc decode_entities/, \&dearinsu_to_desu );
  my $normalizer = Lingua::JA::NormalizeText->new(@options);

  print $normalizer->normalize('鳥が㌧㌦でありんす&hearts;');
  # -> 鳥がトンドルです♥

  sub dearinsu_to_desu
  {
      my $text = shift;
      $text =~ s/でありんす/です/g;

      return $text;
  }

# or

  use Lingua::JA::NormalizeText qw/old2new_kanji/;
  use utf8;

  print old2new_kanji('惡の華');
  # -> 悪の華


=head1 DESCRIPTION

Lingua::JA::NormalizeText normalizes text.

=head1 METHODS

=head2 new(@options)

Creates a new Lingua::JA::NormalizeText instance.

The following options are available:

  OPTION                 SAMPLE INPUT           OUTPUT FOR SAMPLE INPUT
  ---------------------  ---------------------  -----------------------
  lc                     DdD                    ddd
  uc                     DdD                    DDD
  nfkc                   ㌦                     ドル (length: 2)
  nfkd                   ㌦                     ドル (length: 3)
  nfc
  nfd
  decode_entities        &hearts;               ♥
  strip_html             <em>あ</em>                あ    
  alnum_z2h              ＡＢＣ１２３           ABC123
  alnum_h2z              ABC123                 ＡＢＣ１２３
  space_z2h
  space_h2z
  katakana_z2h           ハァハァ               ﾊｧﾊｧ
  katakana_h2z           ｽｰﾊｰｽｰﾊｰ               スーハースーハー
  katakana2hiragana      パンツ                 ぱんつ
  hiragana2katakana      ぱんつ                 パンツ
  wave2tilde             〜                     ～
  tilde2wave             ～                     〜
  wavetilde2long         〜, ～                 ー
  wave2long              〜                     ー
  tilde2long             ～                     ー
  fullminus2long         −                      ー
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
  dakuon_normalize       さ\x{3099}             ざ
  handakuon_normalize    は\x{309A}             ぱ
  all_dakuon_normalize   さ\x{3099}は\x{309A}   ざぱ

The order in which these options are applied is according to the order of
the elements of @options.
(i.e., The first element is applied first, and the last element is applied last.)

External functions are also addable.
(See dearinsu_to_desu function of the SYNOPSIS section.)


=head2 normalize($text)

normalizes $text.


=head1 OPTIONS

=head2 dashes2long

Note that this option does not convert hyphens into long.

=head2 unify_long_spaces

Note that this option unifies only SPACE(U+0020) and IDEOGRAPHIC SPACE(U+3000).

=head2 remove_controls

Note that this option does not remove the following characters:

  CHARACTER TABULATION
  LINE FEED
  CARRIAGE RETURN

=head2 remove_spaces

  Note that this option removes only SPACE(U+0020) and IDEOGRAPHIC SPACE(U+3000).

=head2 unify_whitespaces

This option converts the following chars into SPACE(U+0020).

  LINE TABULATION
  FORM FEED
  NEXT LINE
  NO-BREAK SPACE
  OGHAM SPACE MARK
  MONGOLIAN VOWEL SEPARATOR
  EN QUAD
  EM QUAD
  EN SPACE
  EM SPACE
  THREE-PER-EM SPACE
  FOUR-PER-EM SPACE
  SIX-PER-EM SPACE
  FIGURE SPACE
  PUNCTUATION SPACE
  THIN SPACE
  HAIR SPACE
  LINE SEPARATOR
  PARAGRAPH SEPARATOR
  NARROW NO-BREAK SPACE
  MEDIUM MATHEMATICAL SPACE

Note that this does not convert the following chars:

  CHARACTER TABULATION
  LINE FEED
  CARRIAGE RETURN
  IDEOGRAPHIC SPACE


=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

新旧字体表: L<http://www.asahi-net.or.jp/~ax2s-kmtn/ref/old_chara.html>

L<Lingua::JA::Regular::Unicode>

L<Lingua::JA::Dakuon>

L<Lingua::JA::Moji>

L<Unicode::Normalize>

L<HTML::Entities>

L<HTML::Scrubber>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
