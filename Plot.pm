# This Source Code and Perl Module Copyright by Arnar M. Hrafnkelsson
# (addi@umich.edu) 2001 (C) This source is released under the same
# terms as Perl, that is GPL and Artistic.  For details see the Perl
# License and the files Copying and Artistic in this Distribution.



# Imager::Plot
#
# Manages the axis position and global labels
#
#

package Imager::Plot;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Imager;
use Imager::Plot::Util;
use Imager::Plot::Axis;


require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '0.05';


# Preloaded methods go here.

BEGIN {
  Imager::init_log("Plot.log",1);
}



# Plot generation process:
#
# 1. Make all axis.
# 2. Arrange all axis onto plot surface according to hints and coderef
# 3. draw all axis and data in order.
#

# Size determination method:

# If axis is given:
# Ysize = title+topmargin+yaxis+bottommargin+xlabel
# Xsize = ylabel+leftmargin+xaxis+rightmargin
#
# else
# yaxis = Ysize - (title+topmargin+bottommargin+xlabel)
# xaxis = Xsize - (leftmargin+rightmargin)
#







sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %opts=(
	    Width  => 400, # default size if no image is given
	    Height => 300,
	    Image    => undef,
	    LeftMargin   => 10,  # This is global 'extra' space, nothing should be painted in it
	    RightMargin  => 10,
	    TopMargin    => 10,
	    BottomMargin => 10,
	    TitleMargin  => 15,
	    XLabelMargin => 10,
	    YLabelMargin => 10,
	    Title        => "",
	    GlobalFont   => undef,

	    Xlabel       => "",
	    Ylabel       => "",

	    @_);

  my $fname = $opts{GlobalFont};
  my $black = Imager::Color->new(0,0,0,0);

  $opts{XlabelFont} = Imager::Font->new(file => $fname, size=>12,color=>$black)
    if !$opts{XlabelFont};
	
  $opts{YlabelFont} = Imager::Font->new(file => $fname, size=>12,color=>$black)
    if !$opts{YlabelFont};

  $opts{TitleFont}  = Imager::Font->new(file => $fname, size=>16,color=>$black)
    if !$opts{TitleFont};
	
  my $self  = \%opts;
  bless ($self, $class);
  return $self;
}


# sub axis_new {
#   my $self = shift;
#   my %opts = @_;
#   my $n = $opts{subplot}->[0] || 1;
#   my $m = $opts{subplot}->[1] || 1;
#   my $ax = Imager::Plot::Axis->new();
#   if ($ax) { $self->{SubPlot}->[$n-1]->[$m-1] = $ax; return $ax; }
#   return ();
# }


sub Set {
  my $self = shift;
  my %np=@_;
  for (keys %np) {
    $self->{$_}=$np{$_};
  }
}


sub SetDimensions {
  my $self = shift;
  if ($self->{Image}) {
    $self->{Width}  = $self->{Image}->getwidth();
    $self->{Height} = $self->{Image}->getheight();
  }

  if ($self->{XAxis} and !$self->{Width}) {
    $self->{Width}  = $self->{XAxis} + $self->{LeftMargin} + $self->{RightMargin} + $self->{YLabelMargin};
  }
  if ($self->{Width} and !$self->{XAxis}) {
    $self->{XAxis} = $self->{Width} - ( $self->{LeftMargin} + $self->{RightMargin} + $self->{YLabelMargin} );
  }

  if ($self->{YAxis} and !$self->{Height}) {
    $self->{Height} = $self->{YAxis} + $self->{TitleMargin} + $self->{TopMargin} + $self->{BottomMargin};
  }
  if ($self->{Height} and !$self->{YAxis}) {
    $self->{YAxis} = $self->{Height} -( $self->{TitleMargin} + $self->{TopMargin} + $self->{BottomMargin} );
  }

}

sub GetAxis {
  my $self = shift;
  $self->SetDimensions();
  if (!defined($self->{AXIS})) {
    $self->{AXIS} = Imager::Plot::Axis->new(Width      => $self->{XAxis},
					    Height     => $self->{YAxis},
					    GlobalFont => $self->{GlobalFont});
  }

  return $self->{AXIS};
}



sub AddDataSet {
  my $self = shift;
  my $dataset = Imager::Plot::DataSet->new(@_);
  if ($dataset) {
    $self->GetAxis->AddDataSet($dataset);
    return $dataset;
  }
  return;
}


sub Render {
  my $self = shift;
  my %opts = @_;

  my $Axis = $self->GetAxis();
  $Axis->Render(Image=>$opts{Image},
		Xoff => $opts{Xoff}+$self->{LeftMargin},
		Yoff => $opts{Yoff}-$self->{BottomMargin});


  $self->RenderLabels(Image  => $opts{Image},
		      Xoff   => $opts{Xoff}+$self->{LeftMargin},
		      Yoff   => $opts{Yoff}-$self->{BottomMargin});


}



sub RenderLabels {

  my $self = shift;
  my %opts  = @_;
  my $img    = $opts{Image};

  my $ymin = $opts{Yoff} - $self->GetAxis()->{Height};
  my $ymax = $opts{Yoff};
  my $xmin = $opts{Xoff};
  my $xmax = $opts{Xoff} + $self->GetAxis()->{Width};

  my $xx = ($xmin+$xmax)/2;

  my $string = $self->{Xlabel};
  my $font   = $self->{XlabelFont};

  my ($neg_width,
      $global_descent,
      $pos_width,
      $global_ascent,
      $descent,
      $ascent) = $font->bounding_box(string=>$string);

  $img->string(font  => $font,
	       text  => $string,
	       x     => $xx-($neg_width+$pos_width)/2,
	       y     => $ymax+$global_ascent+$self->GetAxis()->{'XtickFont'}->{'size'}+5,
	       aa    => 1);


  $string = $self->{Ylabel};
  $font   = $self->{YlabelFont};

  ($neg_width,
   $global_descent,
   $pos_width,
   $global_ascent,
   $descent,
   $ascent) = $font->bounding_box(string=>$string);

  $img->string(font  => $font,
	       text  => $string,
	       x     => $xmin-10,    # XXX: Fudge factor
	       y     => $ymin-3,     # more fudge
	       aa    => 1);


  $string = $self->{Title};
  $font   = $self->{TitleFont};

  ($neg_width,
   $global_descent,
   $pos_width,
   $global_ascent,
   $descent,
   $ascent) = $font->bounding_box(string=>$string);

  $img->string(font  => $font,
	       text  => $string,
	       x     => ($xmin+$xmax)/2-($neg_width+$pos_width)/2,
	       y     => $ymin-$self->{'YlabelFont'}->{'size'},
	       aa    => 1);



}






sub PutText {
  my ($self, $x, $y, $string) = @_;
  my $len=length($string);
  my $img = $self->{BImage};

  $img->string(font=>$self->{FONT}, string=>$string, x=>$x, y=>$y) or die $img->errstr;
}





# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
  # Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Imager::Plot - Perl extension for generating 24 or 8 bit plots.

=head1 SYNOPSIS

  use Imager;
  use Imager::Plot;

  $plot = Imager::Plot->new(Width  => 400,
                            Height => 300,
                            GlobalFont => 'ImUgly.ttf');

  $plot->AddDataSet(X  => \@X, Y => \@Y);
  $plot->AddDataSet(XY => \@XY,
    style=>{marker=>{size   => 4,
                     symbol => 'circle',
                     color  => NC(0,120,0)
                    },
            line=>{color=>NC(255,0,0)}
           });

  $img = Imager->new(xsize=>600, ysize => 400);
  $img->box(filled=>1, color=>Imager::Color->new(190,220,255));

  $plot->Render(Image => $img, Xoff => 30, Yoff => 340);
  $img->write(file => "testout.png");




=head1 DESCRIPTION

*** This module is in development, Don't depend on   ***
*** your script to work with the next version (or    ***
*** even this version for that matter.               ***

This is a module for generating fancy raster plots in color.
The plot is generated in a few phases.  First the initial
plot object is generated and contains defaults at that
point.  Then datasets are added with specifications.

Look at the test for more hints on making this work.

=head1 AUTHOR

Arnar M. Hrafnkelsson, addi@umich.edu

=head1 SEE ALSO
Imager, perl(1).

=cut










##########################################
#             Overall title              #
#                                        #
#     subtitle 1,1      subtitle 1,2     #
#  #################  #################  #
#  #               #  #               #  #
#  #  subplot 1,1  #  # subplot 1,2   #  #
#  #               #  #               #  #
#  #               #  #               #  #
#  #               #  #               #  #
#  #               #  #               #  #
#  #               #  #               #  #
#  #################  #################  #
#                                        #
#     subtitle 1,1      subtitle 1,2     #
#  #################  #################  #
#  #               #  #               #  #
#  #  subplot 2,1  #  # subplot 2,2   #  #
#  #               #  #               #  #
#  #               #  #               #  #
#  #               #  #               #  #
#  #               #  #               #  #
#  #               #  #               #  #
#  #################  #################  #
#                                        #
##########################################

