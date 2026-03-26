#!/usr/bin/perl

use strict;

($#ARGV+2)==6 || die 
"Usage: myRmOutliersSimple.pl isHeader colX minX maxX opt=0/1
       opt=0: remove rows where x is outside of min/max, exclusive
       opt=1: keep rows where x is within min/max, inclusive\n";


my $isHeader=$ARGV[0];


my $colX=$ARGV[1];

my $min=$ARGV[2];
my $max=$ARGV[3];

my $opt=$ARGV[4];


my $count=0;
my @line;
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    $count++;
    my $str=$_;

    if($isHeader==1 && $count==1 ) # print header
    {
      print "$str\n";
      next;
    }


    @line =split;
    my $x = $line[$colX-1];

    if($opt==0)
    {
       if($x > $max || $x < $min)
       {
	 print "$str\n";
       }
    }
    else
    {
       if($x <= $max && $x >= $min)
       {
	 print "$str\n";
       }
    }

}


