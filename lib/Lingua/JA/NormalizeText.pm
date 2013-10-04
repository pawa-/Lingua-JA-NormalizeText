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

our $VERSION     = '0.12';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(nfkc nfkd nfc nfd decode_entities strip_html
alnum_z2h alnum_h2z space_z2h space_h2z katakana_z2h katakana_h2z
katakana2hiragana hiragana2katakana unify_3dots wave2tilde tilde2wave
wavetilde2long wave2long tilde2long fullminus2long dashes2long
drawing_lines2long unify_long_repeats nl2space unify_long_spaces
trim ltrim rtrim old2new_kana old2new_kanji tab2space remove_controls
);

our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

my %AVAILABLE_OPTS;
@AVAILABLE_OPTS{ (qw/lc uc/, @EXPORT_OK) } = ();

my $SCRUBBER = HTML::Scrubber->new;


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

sub unify_3dots { local $_ = shift; s/\.{2,}/……/g; s/｡{2,}/……/g; s/。{2,}/……/g; s/･{2,}/……/g; s/・{2,}/……/g; s/．{2,}/……/g; tr/‥/…/; $_; }
#sub unify_3dots  { local $_ = shift; s/(?:\.{2,}|。{2,}|・{2,}|．{2,})/…/g; $_; } slower!

sub wave2tilde           { local $_ = shift; tr/\x{301C}/\x{FF5E}/; $_; }
sub tilde2wave           { local $_ = shift; tr/\x{FF5E}/\x{301C}/; $_; }
sub wavetilde2long       { local $_ = shift; tr/\x{301C}\x{FF5E}/\x{30FC}/; $_; }
sub wave2long            { local $_ = shift; tr/\x{301C}/\x{30FC}/; $_; }
sub tilde2long           { local $_ = shift; tr/\x{FF5E}/\x{30FC}/; $_; }
sub fullminus2long       { local $_ = shift; tr/\x{2212}/\x{30FC}/; $_; }
sub dashes2long          { local $_ = shift; tr/\x{2012}\x{2013}\x{2014}\x{2015}/\x{30FC}/; $_; }
sub drawing_lines2long   { local $_ = shift; tr/\x{2500}\x{2501}\x{254C}\x{254D}\x{2574}\x{2576}\x{2578}\x{257A}/\x{30FC}/; $_; }
sub unify_long_repeats   { local $_ = shift; tr/\x{30FC}/\x{30FC}/s; $_; }
sub unify_long_spaces    { local $_ = shift; tr/\x{0020}/\x{0020}/s; tr/\x{3000}/\x{3000}/s; $_; }
sub trim                 { local $_ = shift; s/^\s+//gm; s/\s+$//gm; $_; }
sub ltrim                { local $_ = shift; s/^\s+//gm; $_; }
sub rtrim                { local $_ = shift; s/\s+$//gm; $_; }
sub nl2space             { local $_ = shift; s/\x{000D}\x{000A}/ /g; tr/\x{000D}\x{000A}/ /; $_; }
sub tab2space            { local $_ = shift; tr/\x{0009}/\x{0020}/; $_; }
sub old2new_kana         { local $_ = shift; tr/ゐヰゑヱ/いイえエ/; s/ヸ/イ\x{3099}/g; s/ヹ/エ\x{3099}/g; $_; }
sub remove_controls      { local $_ = shift; tr/\x{0000}-\x{0008}\x{000B}\x{000C}\x{000E}-\x{001F}\x{007F}-\x{009F}//d; $_; }

sub old2new_kanji
{
    local $_ = shift;
    tr/\x{4E9E}\x{60E1}\x{58D3}\x{570D}\x{7232}\x{91AB}\x{58F9}\x{FA67}\x{7A3B}\x{98EE}\x{96B1}\x{71DF}\x{69AE}\x{885E}\x{9A5B}\x{FA62}\x{5713}\x{7DE3}\x{8277}\x{9E7D}\x{5967}\x{61C9}\x{6A6B}\x{6B50}\x{6BC6}\x{9EC3}\x{6EAB}\x{7A69}\x{5047}\x{50F9}\x{FA52}\x{756B}\x{6703}\x{58DE}\x{FA3D}\x{61F7}\x{FA45}\x{7E6A}\x{FA3E}\x{69EA}\x{64F4}\x{6BBC}\x{89BA}\x{5B78}\x{5DBD}\x{6A02}\x{FA36}\x{6E34}\x{FA60}\x{52F8}\x{5377}\x{5BEC}\x{6B61}\x{FA47}\x{7F50}\x{89C0}\x{95DC}\x{9677}\x{984F}\x{FA38}\x{FA42}\x{6B78}\x{6C23}\x{FA4E}\x{9F9C}\x{50DE}\x{6232}\x{72A7}\x{820A}\x{64DA}\x{64E7}\x{865B}\x{5CFD}\x{633E}\x{72F9}\x{9115}\x{FA69}\x{66C9}\x{FA34}\x{FA63}\x{5340}\x{9A45}\x{52F3}\x{85B0}\x{5F91}\x{60E0}\x{63ED}\x{6EAA}\x{7D93}\x{7E7C}\x{8396}\x{87A2}\x{8F15}\x{9DC4}\x{85DD}\x{64CA}\x{7F3A}\x{5109}\x{528D}\x{5708}\x{6AA2}\x{6B0A}\x{737B}\x{784F}\x{7E23}\x{96AA}\x{986F}\x{9A57}\x{56B4}\x{6548}\x{5EE3}\x{6046}\x{945B}\x{865F}\x{570B}\x{FA54}\x{9ED1}\x{6FDF}\x{788E}\x{9F4B}\x{5291}\x{6AFB}\x{518C}\x{F970}\x{96DC}\x{53C3}\x{6158}\x{68E7}\x{8836}\x{8D0A}\x{6B98}\x{FA4D}\x{7D72}\x{FA61}\x{9F52}\x{5152}\x{8FAD}\x{6FD5}\x{5BE6}\x{820D}\x{5BEB}\x{FA48}\x{FA4C}\x{FA5B}\x{91CB}\x{58FD}\x{6536}\x{FA5C}\x{5F9E}\x{6F81}\x{7378}\x{7E31}\x{FA51}\x{8085}\x{8655}\x{FA43}\x{7DD6}\x{FA5A}\x{FA22}\x{654D}\x{596C}\x{5C07}\x{6D89}\x{71D2}\x{FA1A}\x{7A31}\x{8B49}\x{4E58}\x{5269}\x{58E4}\x{5B43}\x{689D}\x{6DE8}\x{72C0}\x{758A}\x{8B93}\x{91C0}\x{56D1}\x{89F8}\x{5BE2}\x{613C}\x{771E}\x{FA19}\x{76E1}\x{5716}\x{7CB9}\x{9189}\x{96A8}\x{9AD3}\x{6578}\x{6A1E}\x{7028}\x{8072}\x{975C}\x{9F4A}\x{651D}\x{7ACA}\x{FA56}\x{5C08}\x{6230}\x{6DFA}\x{6F5B}\x{7E96}\x{8E10}\x{9322}\x{79AA}\x{66FE}\x{FA50}\x{FA31}\x{96D9}\x{58EF}\x{FA3B}\x{641C}\x{63D2}\x{5DE2}\x{722D}\x{7626}\x{7E3D}\x{838A}\x{88DD}\x{9A37}\x{589E}\x{FA3F}\x{81DF}\x{85CF}\x{FA65}\x{537D}\x{5C6C}\x{7E8C}\x{58AE}\x{9AD4}\x{5C0D}\x{5E36}\x{6EEF}\x{81FA}\x{7027}\x{64C7}\x{6FA4}\x{55AE}\x{FA37}\x{64D4}\x{81BD}\x{5718}\x{5F48}\x{65B7}\x{7661}\x{9072}\x{665D}\x{87F2}\x{9444}\x{FA5F}\x{5EF3}\x{5FB5}\x{FA40}\x{807D}\x{6555}\x{93AD}\x{FA10}\x{905E}\x{9435}\x{8F49}\x{9EDE}\x{50B3}\x{FA26}\x{9EE8}\x{76DC}\x{71C8}\x{7576}\x{9B2D}\x{5FB7}\x{7368}\x{8B80}\x{FA55}\x{5C46}\x{7E69}\x{FA68}\x{8CB3}\x{60F1}\x{8166}\x{9738}\x{5EE2}\x{62DC}\x{FA44}\x{8CE3}\x{9EA5}\x{767C}\x{9AEE}\x{62D4}\x{FA59}\x{665A}\x{883B}\x{FA35}\x{FA4B}\x{7955}\x{6FF1}\x{FA64}\x{FA6A}\x{FA41}\x{7501}\x{FA30}\x{FA1B}\x{62C2}\x{4F5B}\x{5002}\x{FA39}\x{7ADD}\x{8B8A}\x{908A}\x{FA33}\x{8FA8}\x{74E3}\x{8FAF}\x{8216}\x{6B65}\x{7A57}\x{5BF6}\x{8943}\x{8C50}\x{FA3A}\x{6C92}\x{98DC}\x{6BCF}\x{842C}\x{6EFF}\x{FA32}\x{9EB5}\x{9ED8}\x{9920}\x{623E}\x{5F4C}\x{85E5}\x{8B6F}\x{8C6B}\x{9918}\x{8207}\x{8B7D}\x{6416}\x{6A23}\x{8B20}\x{4F86}\x{8CF4}\x{4E82}\x{F91D}\x{89BD}\x{F9DC}\x{9F8D}\x{F936}\x{5169}\x{7375}\x{7DA0}\x{58D8}\x{6DDA}\x{F9D0}\x{52F5}\x{79AE}\x{96B8}\x{9748}\x{9F61}\x{66C6}\x{6B77}\x{6200}\x{FA57}\x{934A}\x{7210}\x{52DE}\x{F928}\x{F929}\x{6A13}\x{90DE}\x{9304}\x{7063}\x{582F}\x{5DD6}\x{6649}\x{69C7}\x{FA46}\x{FA16}\x{FA4A}\x{7464}\x{FA4F}\x{797F}\x{FA53}\x{7A70}\x{8070}\x{9059}/\x{4E9C}\x{60AA}\x{5727}\x{56F2}\x{70BA}\x{533B}\x{58F1}\x{9038}\x{7A32}\x{98F2}\x{96A0}\x{55B6}\x{6804}\x{885B}\x{99C5}\x{8B01}\x{5186}\x{7E01}\x{8276}\x{5869}\x{5965}\x{5FDC}\x{6A2A}\x{6B27}\x{6BB4}\x{9EC4}\x{6E29}\x{7A4F}\x{4EEE}\x{4FA1}\x{798D}\x{753B}\x{4F1A}\x{58CA}\x{6094}\x{61D0}\x{6D77}\x{7D75}\x{6168}\x{6982}\x{62E1}\x{6BBB}\x{899A}\x{5B66}\x{5CB3}\x{697D}\x{559D}\x{6E07}\x{8910}\x{52E7}\x{5DFB}\x{5BDB}\x{6B53}\x{6F22}\x{7F36}\x{89B3}\x{95A2}\x{9665}\x{9854}\x{5668}\x{65E2}\x{5E30}\x{6C17}\x{7948}\x{4E80}\x{507D}\x{622F}\x{72A0}\x{65E7}\x{62E0}\x{6319}\x{865A}\x{5CE1}\x{631F}\x{72ED}\x{90F7}\x{97FF}\x{6681}\x{52E4}\x{8B39}\x{533A}\x{99C6}\x{52F2}\x{85AB}\x{5F84}\x{6075}\x{63B2}\x{6E13}\x{7D4C}\x{7D99}\x{830E}\x{86CD}\x{8EFD}\x{9D8F}\x{82B8}\x{6483}\x{6B20}\x{5039}\x{5263}\x{570F}\x{691C}\x{6A29}\x{732E}\x{7814}\x{770C}\x{967A}\x{9855}\x{9A13}\x{53B3}\x{52B9}\x{5E83}\x{6052}\x{9271}\x{53F7}\x{56FD}\x{7A40}\x{9ED2}\x{6E08}\x{7815}\x{658E}\x{5264}\x{685C}\x{518A}\x{6BBA}\x{96D1}\x{53C2}\x{60E8}\x{685F}\x{8695}\x{8CDB}\x{6B8B}\x{7949}\x{7CF8}\x{8996}\x{6B6F}\x{5150}\x{8F9E}\x{6E7F}\x{5B9F}\x{820E}\x{5199}\x{716E}\x{793E}\x{8005}\x{91C8}\x{5BFF}\x{53CE}\x{81ED}\x{5F93}\x{6E0B}\x{7363}\x{7E26}\x{795D}\x{7C9B}\x{51E6}\x{6691}\x{7DD2}\x{7F72}\x{8AF8}\x{53D9}\x{5968}\x{5C06}\x{6E09}\x{713C}\x{7965}\x{79F0}\x{8A3C}\x{4E57}\x{5270}\x{58CC}\x{5B22}\x{6761}\x{6D44}\x{72B6}\x{7573}\x{8B72}\x{91B8}\x{5631}\x{89E6}\x{5BDD}\x{614E}\x{771F}\x{795E}\x{5C3D}\x{56F3}\x{7C8B}\x{9154}\x{968F}\x{9AC4}\x{6570}\x{67A2}\x{702C}\x{58F0}\x{9759}\x{6589}\x{6442}\x{7A83}\x{7BC0}\x{5C02}\x{6226}\x{6D45}\x{6F5C}\x{7E4A}\x{8DF5}\x{92AD}\x{7985}\x{66FD}\x{7956}\x{50E7}\x{53CC}\x{58EE}\x{5C64}\x{635C}\x{633F}\x{5DE3}\x{4E89}\x{75E9}\x{7DCF}\x{8358}\x{88C5}\x{9A12}\x{5897}\x{618E}\x{81D3}\x{8535}\x{8D08}\x{5373}\x{5C5E}\x{7D9A}\x{5815}\x{4F53}\x{5BFE}\x{5E2F}\x{6EDE}\x{53F0}\x{6EDD}\x{629E}\x{6CA2}\x{5358}\x{5606}\x{62C5}\x{80C6}\x{56E3}\x{5F3E}\x{65AD}\x{75F4}\x{9045}\x{663C}\x{866B}\x{92F3}\x{8457}\x{5E81}\x{5FB4}\x{61F2}\x{8074}\x{52C5}\x{93AE}\x{585A}\x{9013}\x{9244}\x{8EE2}\x{70B9}\x{4F1D}\x{90FD}\x{515A}\x{76D7}\x{706F}\x{5F53}\x{95D8}\x{5FB3}\x{72EC}\x{8AAD}\x{7A81}\x{5C4A}\x{7E04}\x{96E3}\x{5F10}\x{60A9}\x{8133}\x{8987}\x{5EC3}\x{62DD}\x{6885}\x{58F2}\x{9EA6}\x{767A}\x{9AEA}\x{629C}\x{7E41}\x{6669}\x{86EE}\x{5351}\x{7891}\x{79D8}\x{6D5C}\x{8CD3}\x{983B}\x{654F}\x{74F6}\x{4FAE}\x{798F}\x{6255}\x{4ECF}\x{4F75}\x{5840}\x{4E26}\x{5909}\x{8FBA}\x{52C9}\x{5F01}\x{5F01}\x{5F01}\x{8217}\x{6B69}\x{7A42}\x{5B9D}\x{8912}\x{8C4A}\x{58A8}\x{6CA1}\x{7FFB}\x{6BCE}\x{4E07}\x{6E80}\x{514D}\x{9EBA}\x{9ED9}\x{9905}\x{623B}\x{5F25}\x{85AC}\x{8A33}\x{4E88}\x{4F59}\x{4E0E}\x{8A89}\x{63FA}\x{69D8}\x{8B21}\x{6765}\x{983C}\x{4E71}\x{6B04}\x{89A7}\x{9686}\x{7ADC}\x{865C}\x{4E21}\x{731F}\x{7DD1}\x{5841}\x{6D99}\x{985E}\x{52B1}\x{793C}\x{96B7}\x{970A}\x{9F62}\x{66A6}\x{6B74}\x{604B}\x{7DF4}\x{932C}\x{7089}\x{52B4}\x{5ECA}\x{6717}\x{697C}\x{90CE}\x{9332}\x{6E7E}\x{5C2D}\x{5DCC}\x{664B}\x{69D9}\x{6E1A}\x{732A}\x{7422}\x{7476}\x{7950}\x{7984}\x{798E}\x{7A63}\x{8061}\x{9065}/;
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

  use Lingua::JA::NormalizeText qw/nfkc decode_entities/;
  use utf8;

  my $text = '㈱㋰㋫㋫&hearts;';
  print decode_entities( nfkc($text) );
  # -> (株)ムフフ♥



=head1 DESCRIPTION

Lingua::JA::NormalizeText normalizes text.

=head1 METHODS

=head2 new(@options)

Creates a new Lingua::JA::NormalizeText instance.

The following options are available.

  OPTION                 SAMPLE INPUT        OUTPUT FOR SAMPLE INPUT
  ---------------------  ------------------  -----------------------
  lc                     DdD                 ddd
  uc                     DdD                 DDD
  nfkc                   ㌦                  ドル (length: 2)
  nfkd                   ㌦                  ドル (length: 3)
  nfc
  nfd
  decode_entities        &hearts;            ♥
  strip_html             <em>あ</em>             あ    
  alnum_z2h              ＡＢＣ１２３        ABC123
  alnum_h2z              ABC123              ＡＢＣ１２３
  space_z2h
  space_h2z
  katakana_z2h           ハァハァ            ﾊｧﾊｧ
  katakana_h2z           ｽｰﾊｰｽｰﾊｰ            スーハースーハー
  katakana2hiragana      パンツ              ぱんつ
  hiragana2katakana      ぱんつ              パンツ
  unify_3dots            はぁ。。。          はぁ…
  wave2tilde             〜                  ～
  tilde2wave             ～                  〜
  wavetilde2long         〜, ～              ー
  wave2long              〜                  ー
  tilde2long             ～                  ー
  fullminus2long         −                   ー
  dashes2long            —                   ー
  drawing_lines2long     ─                   ー
  unify_long_repeats     ヴァーーー          ヴァー
  nl2space               (new line)          (space)
  unify_long_spaces      (space)(space)      (space)
  remove_head_space      (space)あ(space)あ  あ(space)あ
  remove_tail_space      ああ(space)(space)  ああ
  old2new_kana           ゐヰゑヱ            いイえエ
  old2new_kanji          亞逸鬭              亜逸闘
  tab2space              (tab)(tab)          (space)(space)
  remove_controls        あ\x{0000}あ        ああ

The order in which these options are applied is according to the order of
the elements of @options.
(i.e., The first element is applied first, and the last element is applied last.)

External functions are also addable.
(See dearinsu_to_desu function of SYNOPSIS section.)

=head3 remove_controls

Note that this option does not remove the following chars:

  CHARACTER TABULATION(tab)
  LINE FEED(LF)
  CARRIAGE RETURN(CR)

=head2 normalize($text)

normalizes $text.

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

新旧字体表: L<http://www.asahi-net.or.jp/~ax2s-kmtn/ref/old_chara.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
