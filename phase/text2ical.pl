#!/usr/bin/env perl
#
# usage: ./moonphase2ical > 2007.ics

use strict;
use DateTime;
use Path::Class qw(file);

use utf8;
use Encode;

my @file = @ARGV or die "usage: $0 <file> <file> ...";

my $cal_name = "月齢";
my $prop_id  = "moon-phase";

my @ics;
push @ics, "BEGIN:VCALENDAR";
push @ics, sprintf "PRODID:%s", $prop_id;
push @ics, "VERSION:2.0";
push @ics, "METHOD:PUBLISH";
push @ics, "CALSCALE:GREGORIAN";
push @ics, sprintf "X-WR-CALNAME:%s", $cal_name;
push @ics, sprintf "X-WR-CALDESC:%s", $cal_name;
push @ics, "X-WR-TIMEZONE:Asia/Tokyo";

my $id = 1;

for my $file (@file) {
  printf STDERR "=> %s\n", $file;
  my $fh = file($file)->openr or die $!;
  while ( defined( my $line = $fh->getline ) ) {
    next if length $line < 4;
    my ( $type, $epoch ) = split /\t/o, $line;

    my $date = DateTime->from_epoch( time_zone => 'local', epoch => $epoch );
    &make_entry( $type, $date );
  }
}

push @ics, "END:VCALENDAR";

my $result = join "\n", @ics;
print Encode::encode_utf8($result), "\n";
exit 0;

sub make_entry {
  my ( $type, $date ) = @_;

  #	printf STDERR "=> %s: %s %02d:%02d\n", $type, $date->ymd("-"), $date->hour, $date->minute;

  my $summary;
  if ( $type eq 'new' ) {
    $summary = q/新月/,;
  }
  elsif ( $type eq 'first' ) {
    $summary = q/上弦/,;
  }
  elsif ( $type eq 'full' ) {
    $summary = q/満月/,;
  }
  elsif ( $type eq 'last' ) {
    $summary = q/下弦/,;
  }

  my $description = sprintf "%s : %02d:%02d", $summary, $date->hour, $date->minute;

  my $uid     = $id++;
  my $dtstart = sprintf "%sT%s", $date->ymd(""), $date->hms("");

  push @ics, "BEGIN:VEVENT";
  push @ics, sprintf "UID:%s", $uid;
  push @ics, sprintf "SUMMARY:%s", $summary;
  push @ics, sprintf "DTSTART:%s", $dtstart;
  push @ics, sprintf "DESCRIPTION:%s", $description;
  push @ics, "END:VEVENT";
}
