#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: mySampleAB.pl isHeader=0/1 colDate
        sample A or B, where year+mon=even is A, else B\n";

my $isHeader = $ARGV[0];
my $colDate  = $ARGV[1];

my $count = 0;
while (<STDIN>) {
    chomp;
    $count++;
    my @line = split;
    my $date = $line[$colDate - 1];

    if ($isHeader == 1 && $count == 1) {
        print "$_ sampleTag\n";
        next;
    }

    my $YYYY = int($date / 10000);
    my $MMDD = $date % 10000;
    my $MM   = int($MMDD / 100);

    my $sample = (($YYYY + $MM) % 2 == 0) ? "A" : "B";

    print "$_ $sample\n";
}

