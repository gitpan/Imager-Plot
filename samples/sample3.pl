#!/usr/bin/perl -w

use lib qw(blib/lib blib/arch);

use Imager;
use Imager::Plot::Axis;

# Create our dummy data
@X = -10..10;
@Y = map { $_**3 } @X;

# Create Axis object

$Axis = Imager::Plot::Axis->new(Width => 200, Height => 180, GlobalFont=>"ImUgly.ttf");
$Axis->AddDataSet(X => \@X, Y => \@Y);

$Axis->{XgridShow} = 1;  # Xgrid enabled
$Axis->{YgridShow} = 0;  # Ygrid disabled

$Axis->{Border} = "lrb"; # left right and bottom edges

# See Imager::Color manpage for color specification
$Axis->{BackGround} = "#cccccc";

# Override the default function that chooses the x range
# of the graph, similar exists for y range

$Axis->{make_xrange} = sub {
    $self = shift;
    my $min = $self->{XDRANGE}->[0]-1;
    my $max = $self->{XDRANGE}->[1]+1;
    $self->{XRANGE} = [$min, $max];
};

$img = Imager->new(xsize=>240, ysize => 230);
$img->box(filled=>1, color=>"white");

$Axis->Render(Xoff=>30, Yoff=>200, Image=>$img);

mkdir("sampleout", 0777) unless -d "sampleout";
$img->write(file => "sampleout/sample3.ppm")
    or die $img->errstr;
