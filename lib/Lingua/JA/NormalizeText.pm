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

our $VERSION     = '0.03';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(nfkc nfkd nfc nfd decode_entities strip_html
alnum_z2h alnum_h2z space_z2h space_h2z katakana_z2h katakana_h2z
katakana2hiragana hiragana2katakana unify_3dots wave2tilde tilde2wave
wavetilde2long wave2long tilde2long fullminus2long dashes2long
drawing_lines2long unify_long_repeats nl2space unify_long_spaces
remove_head_space remove_tail_space modernize_kana_usage);

our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

my @AVAILABLE_OPTS = (qw/lc uc/, @EXPORT_OK);
my $SCRUBBER;


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
            # List::MoreUtils::any is slower.
            if ( grep { $_ eq $opt } @AVAILABLE_OPTS )
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

    if (!defined $text)
    {
        Carp::carp('undefined value');
        return;
    }

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

sub strip_html { $SCRUBBER = HTML::Scrubber->new unless defined $SCRUBBER; $SCRUBBER->scrub(shift); }

sub alnum_z2h         { Lingua::JA::Regular::Unicode::alnum_z2h(shift);         }
sub alnum_h2z         { Lingua::JA::Regular::Unicode::alnum_h2z(shift);         }
sub space_z2h         { Lingua::JA::Regular::Unicode::space_z2h(shift);         }
sub space_h2z         { Lingua::JA::Regular::Unicode::space_h2z(shift);         }
sub katakana_z2h      { Lingua::JA::Regular::Unicode::katakana_z2h(shift);      }
sub katakana_h2z      { Lingua::JA::Regular::Unicode::katakana_h2z(shift);      }
sub katakana2hiragana { Lingua::JA::Regular::Unicode::katakana2hiragana(shift); }
sub hiragana2katakana { Lingua::JA::Regular::Unicode::hiragana2katakana(shift); }

sub unify_3dots    { local $_ = shift; s/\.{2,}/…/g; s/。{2,}/…/g; s/・{2,}/…/g; s/．{2,}/…/g; $_; }
#sub unify_3dots    { local $_ = shift; s/(?:\.{2,}|。{2,}|・{2,}|．{2,})/…/g; $_; } slower!

sub wave2tilde           { local $_ = shift; tr/\x{301C}/\x{FF5E}/; $_; }
sub tilde2wave           { local $_ = shift; tr/\x{FF5E}/\x{301C}/; $_; }
sub wavetilde2long       { local $_ = shift; tr/\x{301C}\x{FF5E}/\x{30FC}/; $_; }
sub wave2long            { local $_ = shift; tr/\x{301C}/\x{30FC}/; $_; }
sub tilde2long           { local $_ = shift; tr/\x{FF5E}/\x{30FC}/; $_; }
sub fullminus2long       { local $_ = shift; tr/\x{2212}/\x{30FC}/; $_; }
sub dashes2long          { local $_ = shift; tr/\x{2012}\x{2013}\x{2014}\x{2015}/\x{30FC}/; $_; }
sub drawing_lines2long   { local $_ = shift; tr/\x{2500}\x{2501}\x{254C}\x{254D}\x{2574}\x{2576}\x{2578}\x{257A}/\x{30FC}/; $_; }
sub unify_long_repeats   { local $_ = shift; tr/\x{30FC}/\x{30FC}/s; $_; }
sub nl2space             { local $_ = shift; s/\x{000D}\x{000A}/ /g; tr/\x{000D}\x{000A}/ /; $_; }
sub unify_long_spaces    { local $_ = shift; tr/\x{0020}/\x{0020}/s; tr/\x{3000}/\x{3000}/s; $_; }
sub remove_head_space    { local $_ = shift; s/^\s+//gm; $_; }
sub remove_tail_space    { local $_ = shift; s/\s+$//gm; $_; }
sub modernize_kana_usage { local $_ = shift; tr/ゐヰゑヱ/いイえエ/; $_; }

1;

__END__

=encoding utf8

=head1 NAME

Lingua::JA::NormalizeText - text normalizer

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

  my $text = '鳥が㌧㌦でありんす&hearts;';
  print dearinsu_to_desu( decode_entities( nfkc($text) ) );
  # -> 鳥がトンドルです♥

  sub dearinsu_to_desu
  {
      my $text = shift;
      $text =~ s/でありんす/です/g;

      return $text;
  }


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
  nl2space               \n                  (space)
  unify_long_spaces      (space)(space)      (space)
  remove_head_space      (space)あ(space)あ  あ(space)あ
  remove_tail_space      ああ(space)(space)  ああ
  modernize_kana_usage   ゐヰゑヱ            いイえエ

The order these options are applied is according to the order of
the elements of @options.
(i.e., The first element is applied first, and the last element is applied finally.)

External functions are also addable.
(See dearinsu_to_desu function of SYNOPSIS section)

=head2 normalize($text)

normalizes $text.

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
