package Imager::Plot::Axis;

use strict;
use vars qw();

use Imager;

use Imager::Plot::Util;
use Imager::Plot::DataSet;


############################################
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
#_                                         #
#                                          #
# |    |   |   |   |   |   |   |   |   |   #
############################################

my $black = Imager::Color->new(0,0,0,255);
my $blue  = Imager::Color->new(0,0,70,255);
my $white = Imager::Color->new(255,255,255,255);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %temp = @_;
  my $fname = $temp{'GlobalFont'};

  my %opts=(
	    Width          => undef,   # width includes axis drawing
	    Height         => undef,   # height and the endpoints
	    XRANGE         => undef,
	    YRANGE         => undef,
	    XDRANGE        => undef,
	    YDRANGE        => undef,
	    DATASETS       => [],
	    XGRIDLIST      => [],
	    YGRIDLIST      => [],
	    grid           => 1,
	    make_decor     => \&make_decor,
	    make_ranges    => \&make_ranges,
	    make_xrange    => \&make_xrange,
	    make_yrange    => \&make_yrange,
	    make_xticklist => \&nothing,
	    make_yticklist => \&nothing,
	    make_xgridlist => \&MakeXGridList,
	    make_ygridlist => \&MakeYGridList,
	    XtickFont      => Imager::Font->new(file => $fname, size=>10,color=>$black),
	    YtickFont      => Imager::Font->new(file => $fname, size=>10,color=>$black),
	    BackGround     => $white,
	    FrameColor     => $black,
	    Title          => "",
	    @_);
  my $self  = \%opts;

  bless ($self, $class);
  return $self;
}

sub AddDataSet {
  my $self = shift;
  my $dataset = shift;
  push(@{$self->{DATASETS}}, $dataset);
  return $dataset;
}


sub setparm {
  my $self = shift;
  my %np=@_;
  for (keys %np) {
    $self->{$_}=$np{$_};
  }
}

sub CheckValues {
  my $self = shift;
}

# gets the cumulative bounding box

sub data_bbox {
  my $self = shift;
  my @tbox = map { [ $_->data_bbox() ] } @{$self->{DATASETS}};
  my @bbox = @{shift @tbox};
  for my $cb (@tbox) {
    $bbox[0]= $cb->[0] if $cb->[0]<$bbox[0];
    $bbox[1]= $cb->[1] if $cb->[1]>$bbox[1];
    $bbox[2]= $cb->[2] if $cb->[2]<$bbox[2];
    $bbox[3]= $cb->[3] if $cb->[3]>$bbox[3];
  }
  return @bbox;
}

sub MakeMap {
  my ($oldmin, $oldmax, $newmin, $newmax) = @_;
  return sub { map { ($_-$oldmin)/($oldmax-$oldmin)*($newmax-$newmin)+$newmin } @_; }
}

# Axis Rendering routines

# Axis::render calls render_tick and RenderGrid
#

# render


sub Render {
  my $self = shift;
  my %opts = (%{$self},@_);
  my ($xs, $ys, $xmin,$ymin,$xmax,$ymax);

  my $img = $opts{Image};

  $xmin = $opts{Xoff};
  $xmax = $opts{Xoff} + $self->{Width};
  $ymin = $opts{Yoff} - $self->{Height};
  $ymax = $opts{Yoff};

  $self->{make_decor}->($self);

  my $Xmapper = MakeMap(@{$self->{XRANGE}}, $xmin, $xmax);
  my $Ymapper = MakeMap(@{$self->{YRANGE}}, $ymax, $ymin);

  if ($self->{BackGround}) {
    $img->box(color => $self->{BackGround},
	      xmin  => $xmin,
	      ymin  => $ymin,
	      xmax  => $xmax,
	      ymax  => $ymax,
	      filled=> 1);
  }

  $self->RenderGrid(Image  => $img,
		    Xmapper=> $Xmapper,
		    Ymapper=> $Ymapper,
		    Xoff   => $opts{Xoff},
		    Yoff   => $opts{Yoff});

  if ($self->{FrameColor}) {
    $img->box(color => $self->{FrameColor},
	      xmin  => $xmin,
	      ymin  => $ymin,
	      xmax  => $xmax,
	      ymax  => $ymax,
	      filled=> 0);
  }

  for my $DataSet (@{$self->{DATASETS}}) {
    $DataSet->Draw(Image   => $img,
		   Xmapper => $Xmapper,
		   Ymapper => $Ymapper);
  }

  $self->RenderTickLabels(Image  => $img,
			  Xmapper=> $Xmapper,
			  Ymapper=> $Ymapper,
			  Xoff   => $opts{Xoff},
			  Yoff   => $opts{Yoff});


}

sub myround {
  0+sprintf("%.2f",shift);
}


sub trn {
  sprintf("%g",sprintf("%.0e",shift));
}


sub RenderGrid {
  my $self = shift;
  my %opts  = @_;
  my $xgridc;
  my $ygridc = $xgridc = i_color_new(140,140,140,0);
  my $img = $opts{Image};

  my $ymin = $opts{Yoff} - $self->{Height};
  my $ymax = $opts{Yoff};
  my $xmin = $opts{Xoff};
  my $xmax = $opts{Xoff} + $self->{Width};

  my @XGrid = $opts{Xmapper}->(@{$self->{XGRIDLIST}});
  my @YGrid = $opts{Ymapper}->(@{$self->{YGRIDLIST}});

  for my $xx (@XGrid) {
    $img->polyline(y=>[$ymin,$ymax],x=>[$xx,$xx],color=>$xgridc);
  }

  for my $yy (@YGrid) {
    $img->polyline(y=>[$yy,$yy],x=>[$xmin,$xmax],color=>$xgridc);
  }

}

# now incorrectly uses the Grid points

sub RenderTickLabels {

  my $self = shift;
  my %opts  = @_;
  my $img    = $opts{Image};

  my $ymin = $opts{Yoff} - $self->{Height};
  my $ymax = $opts{Yoff};
  my $xmin = $opts{Xoff};
  my $xmax = $opts{Xoff} + $self->{Width};

  my @XGrid = $opts{Xmapper}->(@{$self->{XGRIDLIST}});
  my @YGrid = $opts{Ymapper}->(@{$self->{YGRIDLIST}});

  my $font   = $self->{XtickFont};

  for my $xi (0..@XGrid-1) {
    my $xx = $XGrid[$xi];
    my $xv = $self->{XGRIDLIST}->[$xi];

    my $string = myround($xv);

    my ($neg_width,
	$global_descent,
	$pos_width,
	$global_ascent,
	$descent,
	$ascent) = $font->bounding_box(string=>$string);

    $img->string(font  => $font,
		 text  => $string,
		 x     => $xx-($neg_width+$pos_width)/2,
		 y     => $ymax+$global_ascent+3,
		 aa    => 1);
  }


  my $font = $self->{YtickFont};

  for my $yi (0..@YGrid-1) {
    my $yy = $YGrid[$yi];
    my $yv = $self->{YGRIDLIST}->[$yi];

    my $string = myround($yv);

    my ($neg_width,
	$global_descent,
	$pos_width,
	$global_ascent,
	$descent,
	$ascent) = $font->bounding_box(string=>$string);

    $img->string(font  => $font,
		 text  => $string,
		 x     => $xmin-$pos_width-3,
		 y     => $yy+($ascent+$descent)/2,
		 aa    => 1);
  }


}








# data set style description:

# $style->{line}->{color=>$color, antialias=>0};
# $style->{marker}->{color=>$color, symbol=>"circle"};
# $style->{text}->{font=>$font, handler=>$coderef};
# coderef decides if text goes with that point



sub make_dranges {
  my $self = shift;
  my @bbox = $self->data_bbox();
  $self->{XDRANGE} = [@bbox[0,1]];
  $self->{YDRANGE} = [@bbox[2,3]];
}

sub make_xrange {
  my $self = shift;
  $self->{XRANGE} = [@{$self->{XDRANGE}}];
}

sub make_yrange {
  my $self = shift;
  $self->{YRANGE} = [@{$self->{YDRANGE}}];
}

sub make_ranges {
  my $self = shift;
  $self->make_dranges();# real member function
  $self->{make_xrange}->($self);
  $self->{make_yrange}->($self);
}

sub nothing {}

sub MakeXGridList {
  my $self = shift;
  my ($min, $max)  = @{$self->{XRANGE}};
  my $d  = ($max-$min)/5;
  my $d2 = trn($d);
  my (@rc,$i);

  $i = sprintf("%.0f",$min/$d2)*$d2;
  while ( 1 ) {
    push(@rc,$i);
    $i+=$d2;
    last if $i > $max;
  }
  $self->{XGRIDLIST} = \@rc;
}

sub MakeYGridList {
  my $self = shift;
  my ($min, $max)  = @{$self->{YRANGE}};
  my $d  = ($max-$min)/5;
  my $d2 = trn($d);
  my (@rc,$i);

  $i = sprintf("%.0f",$min/$d2)*$d2;
  while ( 1 ) {
    push(@rc,$i);
    $i+=$d2;
    last if $i > $max;
  }
  $self->{YGRIDLIST} = \@rc;
}


sub make_decor {
  my $self = shift;
  $self->{make_ranges}   ->($self);
  $self->{make_xticklist}->($self);
  $self->{make_yticklist}->($self);
  $self->{make_xgridlist}->($self);
  $self->{make_ygridlist}->($self);
}



1;


__END__
  # Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Imager::Plot::Axis - Axis handling of Imager::Plot.

=head1 SYNOPSIS

  use Imager::Plot::Axis;
  $Axis = Imager::Plot::Axis->new(Width => 200, Height => 180);
  $Axis->AddDataSet($DataSet1);
  $Axis->AddDataSet($DataSet2);

  $Axis->Render(img => $img, Xoff => 20, Yoff=> 100);


=head1 DESCRIPTION

This part of Imager::Plot takes care of managing the graph area
itself.  It, handles the grid and tickmarks also.

=head1 AUTHOR

Arnar M. Hrafnkelsson, addi@umich.edu

=head1 SEE ALSO
Imager, Imager::Plot, Imager::DataSet
perl(1).

=cut

