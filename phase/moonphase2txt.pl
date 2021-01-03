#!/usr/bin/env perl
#
# usage: ./moonphase2ical 2009 > 2009.txt

use strict;
use DateTime;
use Clone qw(clone);
use Jcode;
use Astro::MoonPhase ();

use utf8;
use Encode;

$| = 1;

my $is_near = 0;
my $year    = shift @ARGV || DateTime->now->year;

my $date = DateTime->new( time_zone => 'Asia/Tokyo', year => $year,     month => 1, day => 1, hour => 0, minute => 0 );
my $end  = DateTime->new( time_zone => 'Asia/Tokyo', year => $year + 1, month => 1, day => 1, hour => 0, minute => 0 );

my ( @new, @full, @first, @last );

for ( 1; $date->epoch <= $end->epoch; &date_proceed($date) ) {
  my $phase = &get_phase( $date->epoch );

  # new
  if ( $phase > 0.9998 or $phase < 0.0002 ) {
    push @new, clone $date;
  }
  elsif ( scalar @new ) {
    &make_entry( 'new', @new );
    @new = ();
  }

  # first-quarter
  if ( $phase > 0.2498 and $phase < 0.2502 ) {
    push @first, clone $date;
  }
  elsif ( scalar @first ) {
    &make_entry( 'first', @first );
    @first = ();
  }

  # full
  if ( $phase > 0.4998 and $phase < 0.5002 ) {
    push @full, clone $date;
  }
  elsif ( scalar @full ) {
    &make_entry( 'full', @full );
    @full = ();
  }

  # last-quarter
  if ( $phase > 0.7498 and $phase < 0.7502 ) {
    push @last, clone $date;
  }
  elsif ( scalar @last ) {
    &make_entry( 'last', @last );
    @last = ();
  }
}

sub date_proceed {
  my $date = shift;

  my $phase = &get_phase( $date->epoch );

  if ( ( $phase > 0.01 and $phase < 0.24 )
    or ( $phase > 0.26 and $phase < 0.49 )
    or ( $phase > 0.51 and $phase < 0.74 )
    or ( $phase > 0.76 and $phase < 0.99 )
  ) {
    $date->add( hours => 6 );
  }
  else {
    $date->add( minutes => 1 );
  }
}

sub make_entry {
  my ( $type, @d ) = @_;

  my $date = $d[ int( $#d / 2 ) ] or die "cannot get date from array.";

  printf STDERR "=> %s: %s %02d:%02d\n", $type, $date->ymd("-"), $date->hour, $date->minute;

  printf "%s\n", Encode::encode_utf8( join "\t", ( $type, $date->epoch ) );
}

sub get_phase {
  my ( $phase, $illu, $age, $dist, $angle ) = Astro::MoonPhase::phase(shift);
  return $phase;
}
