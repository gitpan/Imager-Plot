package Imager::Plot::DataSet;

use strict;
use Imager;

use Imager;
use Imager::Plot::Util;


sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);

  my %opts = @_;
  if ($opts{Y}) {
    $self->{Y} = [@{$opts{Y}}];
    if ($opts{X}) {
      $self->{X} = [@{$opts{X}}];
    } else {
      @{$self->{X}} = 1..@{$opts{Y}};
    }
  }

  if ($opts{XY}) {
    my $nx = $#{$self->{Y}} = $#{$self->{X}} = $#{$opts{XY}};
    ($self->{X}[$_], $self->{Y}[$_]) = @{$opts{XY}->[$_]} for 0..$nx;
  }

  $self->{'style'} = $opts{style} ||
    { line=>{ color => Imager::Color->new("#0000FF"), antialias=>1 } };

  $self->{name} = $opts{name} if exists $opts{name};

  return $self;
}

sub data_bbox {
  my $self = shift;
  return (minmax(@{$self->{X}}), minmax(@{$self->{Y}}) );
}



sub Draw {
  my $self = shift;
  my %opts = @_;
  my $img = $opts{Image};

  use Data::Dumper;

  my %style = %{$self->{'style'}};

  my @x = $opts{Xmapper}->(@{$self->{X}});
  my @y = $opts{Ymapper}->(@{$self->{Y}});

  #  print "TX=@x\n";
  #  print "TY=@y\n";

  my @ox = @{$self->{X}};
  my @oy = @{$self->{Y}};

#  print "X=@ox\n";
#  print "Y=@oy\n";

  if ($style{line}) {
    $img->polyline(x=>\@x,
		   y=>\@y,
		   color=>$style{line}->{color},
		   antialias=>$style{line}->{antialias});
  }

  if ($style{marker}) {
    die "symbol must be circle for now!\n" unless $style{marker}->{symbol} eq "circle";
    my $l = $#x;
    my $size = $style{marker}->{size} || 1.5;
    for(0..$l) {
      Imager::i_circle_aa($img->{IMG}, 0.5+$x[$_], 0.5+$y[$_], $size, $style{marker}->{color});

      # Non AA version
      #      $img->circle(x => $x[$_],
      #		   y => $y[$_],
      #		   color => $style{marker}->{color},
      #		   r => 3);
    }
  }

}





1;
__END__

put docs here!
