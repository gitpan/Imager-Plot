package Imager::Plot::Util;

use strict;
use vars qw(@ISA @EXPORT);
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	     min
	     max
	     minmax
	    );

sub min {
  my $rc = shift;
  $rc = ($_<$rc)?$_:$rc for @_;
  return $rc;
}

sub max {
  my $rc = shift;
  $rc = ($_>$rc)?$_:$rc for @_;
  return $rc;
}

sub minmax {
  my $min = shift;
  my $max = $min;
  for (@_) {
    $min = ($_<$min) ? $_ : $min;
    $max = ($_>$max) ? $_ : $max;
  }
  return ($min, $max);
}



1;
__END__

This is Documentation!
