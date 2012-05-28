package Lingua::JA::NormalizeText;

use 5.008_001;
use strict;
use warnings;
use utf8;

use Carp ();
use Exporter           qw/import/;
use Unicode::Normalize qw/NFKC NFKD NFC NFD/;
use HTML::Entities     qw/decode_entities/;

our $VERSION     = '0.00_1';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(nfkc nfkd nfc nfd decode_entities);
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

my @AVAILABLE_OPTS = qw/lc nfkc nfkd nfc nfd decode_entities/;


sub new
{
    my ($class, @opts) = @_;
    my $self = bless {}, $class;

    $self->{converters} = [];

    my %set = map { $_ => 1 } @opts;

    Carp::croak("at least one option is needed") unless scalar @opts;

    for my $available_opt (@AVAILABLE_OPTS)
    {
        if (delete $set{$available_opt})
        {
            push(@{ $self->{converters} }, $available_opt);
        }
    }

    Carp::croak( "unknown option(s): " . join(', ', keys %set) ) if keys %set;

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

=begin
sub wavetilde2long
{
    my $tilde = chr(hex("FF5E"));
    my $wave  = chr(hex("301C"));
    my $long  = chr(hex("30FC"));

    my $text = shift;
    $text =~ s/[$wave$tilde]/$long/eg;

    return $text;
}
=end
=cut

{
    no warnings 'redefine';
    sub decode_entities { HTML::Entities::decode_entities(shift); }
}

1;

__END__

=head1 NAME

Lingua::JA::NormalizeText - normalizes text

=head1 SYNOPSIS

  use Lingua::JA::NormalizeText;

=head1 DESCRIPTION

Lingua::JA::NormalizeText normalizes text.

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
