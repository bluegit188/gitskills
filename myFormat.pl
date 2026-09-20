#!/usr/bin/perl

use strict;

($#ARGV+2) ==3 || die 
"Usage: myFormat.pl w1:w2:w3 n1:n2:n3\n";


my $wStr=$ARGV[0];
my $nStr=$ARGV[1];

my @ws=split(':',$wStr);
my @ns=split(':',$nStr);

$#ns == $#ws || die "W str and n str doesn't match\n";

my @line;
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;

    my $str;

    foreach my $j (0..$#ns)
    {
        my $k=$ns[$j];
        my $w=$ws[$j];

        my $thisStr=$line[$k-1];

        $str=$str."$thisStr"." ";
        printf "%$w\s ",$thisStr;
    }

    print "\n";

}


