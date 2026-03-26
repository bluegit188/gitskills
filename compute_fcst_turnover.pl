#!/usr/bin/perl

use strict;



($#ARGV+2) ==3 || die 
"Usage: compute_fcst_turnover.pl file.txt(header) colFcst
       Compute mean/std/min/max for each key
       Output: Date min max mean std count\n";

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $colX=$ARGV[1];

my $header;

my @line;
my $count=0;
my $preFcst=0;

my $sumAbsChg=0;
my $sumAbsFcst=0;

while(<INFILE>)
{
    chomp($_);
    @line =split;
    my $str=$_;

    $count++;
    if($count==1 ) # header
    {
      $header=$line[$colX-1];
      next;
    }

    my $x=$line[$colX-1];


    if($count==2)
    {
      $preFcst=$x;
      next;
    }

    my $fcstChg=$x-$preFcst;


    $sumAbsChg+=abs($fcstChg);
    $sumAbsFcst+=abs($preFcst);


    $preFcst=$x;

}
close(INFILE);

my $meanFcst=$sumAbsFcst/($count-2);
my $meanChg=$sumAbsChg/($count-2);

my $count2=$count-2;
my $tover=$meanChg/$meanFcst;

my $avg_hold_i =99999;
if($tover!=0)
{
    $avg_hold_i=2/$tover; # Derek Du:  avgHold=2*GMV/tradingVolume, implied avg_hold from tover
}
printf "$header tover: meanAbsChg= %.7f meanAbsFcst= %.7f count= $count2 tover= %.7f avg_hold_i= %.7f\n",$meanChg, $meanFcst, $tover,$avg_hold_i;
