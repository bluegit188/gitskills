#!/usr/bin/perl

use strict;

(@ARGV == 3) or die 
"Usage: mySampleSelector.pl isHeader=0/1 colDate tag=A/B/AB
       Select rows based on the user specified sample tag (A, B or AB)\n";

my $isHeader = $ARGV[0];
my $colDate  = $ARGV[1];
my $tag      = uc($ARGV[2]);  # Normalize to uppercase

($tag eq "A" || $tag eq "B" || $tag eq "AB")
    or die "Invalid tag. Must be A, B, or AB.\n";

my $count = 0;

while (<STDIN>) {
    chomp;
    $count++;
    my @line = split;
    my $date = $line[$colDate - 1];

    if ($isHeader == 1 && $count == 1) {
        print "$_\n";
        next;
    }

    my $YYYY = int($date / 10000);
    my $MM   = int(($date % 10000) / 100);

    my $sample = (($YYYY + $MM) % 2 == 0) ? "A" : "B";

    # Only print if it matches desired tag
    if ($tag eq $sample || $tag eq "AB") 
    {
        print "$_\n";
    }
}



