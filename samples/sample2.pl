#!/usr/bin/perl -w

use lib qw(blib/lib blib/arch);

use Imager;
use Imager::Plot;

@X  = linspace(-5, 10, 100);
@Y  = map { sin($_) } @X;
@XY = map { [$_, sin($_/2)+sin($_/4) ] } linspace(-2, 13, 15);

$plot = Imager::Plot->new(Width  => 600,
			  Height => 400,
                          LeftMargin   => 30,
                          BottomMargin => 40,
                          TopMargin => 30,
			  GlobalFont => 'ImUgly.ttf');

$plot->AddDataSet(X  => \@X, Y => \@Y);
$plot->AddDataSet(XY => \@XY, style=>{marker=>{size=>4,
					       symbol=>'circle',
					       color=>Imager::Color->new(0,120,0),
					      },
				      line=>{
					     color=>Imager::Color->new(255,0,0)
					    }
				     });


$plot->GetAxis()->{BackGround} = undef;

$plot->Set(Xlabel=> "time [sec]" );
$plot->Set(Ylabel=> "Amplitude [mV]" );
$plot->Set(Title => "Patheticity measured in millivolts" );

$img = Imager->new(xsize=>600, ysize => 400)->box(filled=>1, color=>Imager::Color->new(190,220,255));

$plot->Render(Image => $img, Xoff =>0+2, Yoff => 400+3);

$new = $img->convert(matrix=>[ [ 0.6, 0.3, 0.3 ],
			       [ 0.3, 0.6, 0.3 ],
			       [ 0.3, 0.3, 0.6 ] ]);

$new->filter(type=>'gaussian', stddev => 2.5) or die $new->errstr;

$plot->Render(Image => $new, Xoff =>0, Yoff => 400);

mkdir("sampleout", 0777) unless -d "sampleout";
$new->write(file => "sampleout/sample2.ppm");






sub linspace {
  my ($min,$max,$N) = @_;
  map { $_ * ($max-$min) / ($N-1) + $min } 0..$N-1;
}

