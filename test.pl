# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Imager::Plot;
use Imager qw(:handy);
$loaded = 1;
print "ok 1\n";


@X  = linspace(-5, 10, 100);
@Y  = map { sin($_) } @X;
@XY = map { [$_, sin($_/2)+sin($_/4) ] } linspace(-2, 13, 15);

$plot = Imager::Plot->new(Width  => 600,
			  Height => 400,
			  LeftMargin   => 30,
			  BottomMargin => 30,
#			  GlobalFont => 'arial.ttf');
			  GlobalFont => 'ImUgly.ttf');

$plot->AddDataSet(X  => \@X, Y => \@Y);
$plot->AddDataSet(XY => \@XY, style=>{marker=>{size=>4,
					       symbol=>'circle',
					       color=>NC(0,120,0)
					      },
				      line=>{
					     color=>NC(255,0,0)
					    }
				     });

# These are lacking a proper api, and the functionality should
# be moved from the Axis to the Plot

$plot->Set(Xlabel=> "time [sec]" );
$plot->Set(Ylabel=> "Amplitude [mV]" );
$plot->Set(Title => "Patheticity measured in millivolts" );

$plot->GetAxis()->{BackGround} = undef;

$img = Imager->new(xsize=>600, ysize => 400)->box(filled=>1, color=>Imager::Color->new(190,220,255));
#$img->read(file=>"fluffy.jpg");
#$img->read(file=>"skjald.jpg");

$plot->Render(Image => $img, Xoff =>0+2, Yoff => 400+3);

$new = $img->convert(matrix=>[ [ 0.6, 0.3, 0.3 ],
			       [ 0.3, 0.6, 0.3 ],
			       [ 0.3, 0.3, 0.6 ] ]);

$new->filter(type=>'gaussian', stddev => 2.5) or die $new->errstr;

$plot->Render(Image => $new, Xoff =>0, Yoff => 400);


$new->write(file => "testout.ppm");
#$img->write(file => "example.png");

print "ok 2\n";





sub linspace {
  my ($min,$max,$N) = @_;
  map { $_ * ($max-$min) / ($N-1) + $min } 0..$N-1;
}
