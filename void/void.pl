#!/usr/bin/env perl

use strict;
use Jcode;
use List::Util qw(first);
use Getopt::Std;
use IO::File;

use utf8;
use Encode;

Getopt::Std::getopts 'tv' => my $opt = {};
# t: except trans-saturnians
# v: verbose

my @file = @ARGV or die "usage: $0 <file> <file> ...";

# header
my $result = << "END";
BEGIN:VCALENDAR
VERSION:2.0
X-WR-CALNAME:ボイド
PRODID:VoidCal
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VTIMEZONE
TZID:Asia/Tokyo
BEGIN:STANDARD
DTSTART:19371231T150000
TZOFFSETTO:+0900
TZOFFSETFROM:+0000
TZNAME:JST
END:STANDARD
END:VTIMEZONE
END

# event
my $cnt  = 0;
my $seen = {};
for my $file (@file) {
  my $fh = IO::File->new;
  $fh->open($file) or die $!;
  while (<$fh>) {
    next if not /^ *\d{4}/o;

    $_ = Encode::decode_utf8($_);

    #  2007年01月02日19:05:56双子 (180)冥 ---  2007年01月03日00:13:41　蟹ing(05h07m)
    #  2007年01月17日06:28:25射手 (  0)冥
    my ( $from, $to ) = split /\s*[\-～]+\s+/o, $_;
    $from =~ s/\s+(\d+)/$1/g;

    next if exists $seen->{$from};
    $seen->{$from} = 1;

    my $start_date;
    my $planet;
    do {
      if ( ( my $date = $from ) =~ /^(\d{4})年(\d{2})月(\d{2})日(\d{2}):(\d{2}):(\d{2})([^ ]+) \(\s*(\d{1,3})\)(.+)\s*/ ) {
        $start_date = sprintf "%04d%02d%02dT%02d%02d%02d", $1, $2, $3, $4, $5, $6;
        $planet     = $9;
      }
      else {
        die "failed to parse from: $_";
      }
    };

    my $end_date;
    my ( $h, $m );
    do {
      if ( ( my $date = $to ) =~ /^(\d{4})年(\d{2})月(\d{2})日(\d{2}):(\d{2}):(\d{2})([^ ]+)ing\((\d{2,})h(\d{2})m\)/ ) {
        $end_date = sprintf "%04d%02d%02dT%02d%02d%02d", $1, $2, $3, $4, $5, $6;
        $h        = int $8;
        $m        = int $9;
      }
      else {
        die "failed to parse to: $_";
      }
    };

    my $t;
    if ( $h > 0 ) {
      $t = sprintf "約%s時間%s分・%s", &two_byte( int $h ), &two_byte($m), $planet;
    }
    else {
      $m ||= 1;
      $t = sprintf "約%s分・%s", &two_byte( int $m ), $planet;
    }

    next
      if defined $opt->{t} && first { $planet eq $_ } ( '天', '海', '冥' );

    printf STDERR "%s -> %s (%s) on %s \n", $start_date, $end_date, $t, $planet
      if defined $opt->{v};

    $result .= <<"END";
BEGIN:VEVENT
SUMMARY:ボイド
DESCRIPTION:ボイド時間帯（$t）
DTSTART;TZID=Asia/Tokyo:$start_date
DTEND;TZID=Asia/Tokyo:$end_date
END:VEVENT
END

    $cnt++;
  }
}

$result .= "END:VCALENDAR\n";

print Encode::encode_utf8($result);

printf STDERR "total %d lines.\n", $cnt;

sub two_byte {
  my $str = shift;

  $str =~ tr/0-9a-zA-Z/０-９ａ-ｚＡ-Ｚ/;

  return $str;
}
