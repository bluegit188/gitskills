#!/usr/bin/perl

use strict;



($#ARGV+2) ==3 || die 
"Usage: compute_fcst_unit_turnover.pl file.txt(header) colFcst
       Compute unit turnover, similar to turnover for binary postions.
       A 100% unitTover means 50% postions will change sign next day
       turnover4 = abs(binary position changes) / abs(binary positions)
       binary positions = { 0 if NetPos=0, 1 if NetPos >0, -1 if NetPos < 0 }
       prePos must be non-zero to count
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

    #convert X to binary
    $x=sign($x);

    if($count==2)
    {
      $preFcst=$x;
      next;
    }

    my $fcstChg=$x-$preFcst;


    #if($preFcst!=0)# prePos must be non-zero to count
    # I think for tover, we should count prevPos=0
    {
      $sumAbsChg+=abs($fcstChg);
      $sumAbsFcst+=abs($preFcst);
    }

    $preFcst=$x;

}
close(INFILE);

my $meanFcst=$sumAbsFcst/($count-2);
my $meanChg=$sumAbsChg/($count-2);

my $count2=$count-2;
my $tover=$meanChg/$meanFcst;
printf "$header unitTover: meanAbsChg= %.7f meanAbsFcst= %.7f count= $count2 unitTover= %.7f\n",$meanChg, $meanFcst, $tover;


sub sign()
{
    my ($x) = @_;

    if($x>0)
    {
      return 1;
    }
    elsif($x<0)
    {
      return -1;
    }
    else
    {
      return 0;
    }

}

