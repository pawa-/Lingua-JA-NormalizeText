package Lingua::JA::NormalizeText;

use 5.008_001;
use strict;
use warnings;
use utf8;

use Carp ();
use Exporter           qw/import/;
use Unicode::Normalize ();
use HTML::Entities     ();

our $VERSION     = '0.00_1';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(nfkc nfkd nfc nfd decode_entities);
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

my @AVAILABLE_OPTS = (qw/lc/, @EXPORT_OK);


sub new
{
    my ($class, @opts) = @_;
    my $self = bless {}, $class;

    Carp::croak("at least one option is needed") unless scalar @opts;

    $self->{converters} = [];

    my @unavailable_opts;

    for (my $i = 0; $i < scalar @opts; $i++)
    {
        if (ref $opts[$i] ne 'CODE')
        {
            # List::MoreUtils::any のほうが早いかもしれん
            if ( grep { $_ eq $opts[$i] } @AVAILABLE_OPTS )
            {
                push( @{ $self->{converters} }, $opts[$i] );
            }
            else { push(@unavailable_opts, $opts[$i] ); }
        }
        else
        {
            # external function
            push( @{ $self->{converters} }, $opts[$i] );
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
        Carp::carp('undefined text') unless defined $text;
        return;
    }

    {
        no strict 'refs';
        map { $text = $_->($text) } @{ $self->{converters} };
    }

    return $text;
}

sub lc   { lc(shift); }
sub nfkc { Unicode::Normalize::NFKC(shift); }
sub nfkd { Unicode::Normalize::NFKD(shift); }
sub nfc  { Unicode::Normalize::NFC(shift);  }
sub nfd  { Unicode::Normalize::NFD(shift);  }
sub decode_entities { HTML::Entities::decode_entities(shift); }

1;

__END__

=head1 NAME

Lingua::JA::NormalizeText - normalizes text

=head1 SYNOPSIS

  use Lingua::JA::NormalizeText qw/nfkc decode_entities/;
  use utf8;

  my @option = ( qw/nfkc decode_entities/, \&dearinsu_to_desu );
  my $normalizer = Lingua::JA::NormalizeText->new(@option);

  print $normalizer->normalize('鳥が㌧㌦でありんす&hearts;');
  # -> 鳥がトンドルです♥
  # or
  #
  my $text = '鳥が㌧㌦でありんす&hearts;';
  print dearinsu_to_desu( decode_entities( nfkc($text) ) );

  sub dearinsu_to_desu
  {
      my $text = shift;
      $text =~ s/でありんす/です/;

      return $text;
  }

=head1 DESCRIPTION

Lingua::JA::NormalizeText normalizes text.

=head1 METHODS

=head2 normalize(@options)

The following options are available.

  lc nfkc nfkd nfc nfd decode_entities

External functions also available.
(See SYNOPSIS section)

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
