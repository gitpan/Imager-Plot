use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	   => 'Imager::Plot',
    'VERSION_FROM' => 'Plot.pm', # finds $VERSION
    'PREREQ_PM'    => { Imager => 0.39 }
);
