#!/usr/bin/perl

use strict;

($#ARGV+2) ==5 || die
"Usage: get_max_drawdown.pl file.txt isHeader colDate colPL
       Compute max drawdown for given pl
       Output: tmp_drawdown.txt has drawdown numbers
               (format: ... cumPL drawdown prePeakDate)\n";

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $isHeader=$ARGV[1];
my $colDate=$ARGV[2];
my $colPL=$ARGV[3]; # pl


my @PLs;
my @dates;
my @cumPLs;
my @allRows;


my @line;
my $count=0;
my $cumPL=0;
my $header;
while(<INFILE>)
{
    chomp($_);
    @line =split;
    my $str=$_;

    $count++;
    if($isHeader && $count==1)
    {
       $header=$str;
       next;
    }

    my $date=$line[$colDate-1];
    my $PL=$line[$colPL-1];
    $cumPL+=$PL;

    push(@dates,$date);
    push(@PLs,$PL);
    push(@cumPLs,$cumPL);
    push(@allRows,$str);

}
close(INFILE);



## loop cumPL and find mdd
my $neginf = -9**9**9;
my $MDD = 0;
my $peak = $neginf;
my @NAV=@cumPLs;
my $size=$#dates+1;
my @DDs=(0)x$size; 
my @peakLocs=(0)x$size; 

my $prePeakLoc=-1;
my $maxPeakLoc=-1;
my $mddLoc=-1;

foreach my $i (0..$#dates)
{

  if ($NAV[$i] > $peak) # peak will be the maximum value seen so far (0 to i)
  {
    $peak = $NAV[$i];
    $prePeakLoc=$i;
  }
  $peakLocs[$i]=$prePeakLoc;


  $DDs[$i] =  ($peak - $NAV[$i]);
  if ($DDs[$i] > $MDD) # Same idea as peak variable, 
  {                   #MDD keeps track of the maximum drawdown so far.
     $MDD = $DDs[$i];
     $maxPeakLoc=$prePeakLoc;
     $mddLoc=$i;
  }
}


## display: a). drawdowns in tmp_drawdown.txt file
##          b). max drawdown displayed
open(OUTFILE, ">tmp_drawdown.txt.$filename") || die "Couldn't open tmp_drawdown.txt.$filename\n";
foreach my $i (0..$#dates)
{
   my $thisLine=$allRows[$i];
   my $cumPL=$cumPLs[$i];
   my $DD=$DDs[$i];
   my $peakLoc=$peakLocs[$i];
   my $peakDate=$dates[$peakLoc];
   printf OUTFILE "$thisLine $cumPL %.7f $peakDate\n", $DD;
}
close(OUTFILE);


## regular pl std
my ($min,$max,$mean,$std,$count2)=get_min_max_mean_std(\@PLs);

my $shp=$mean/$std;
my $shpPA=$shp*sqrt(252);

my $maxPeakDate=$dates[$maxPeakLoc];
my $mddDate=$dates[$mddLoc];
printf "maxDrawDown= %.7f from $maxPeakDate to $mddDate\n",$MDD;
printf "PL: min= $min max= $max mean= %.7f std= %.7f count= $count2 shp= %.7f shp.pa= %.7f\n",$mean,$std,$shp,$shpPA;
printf "MDD/plSTD ratios:\n";
printf "MDD/plSTD=             %.7f\n",$MDD/$std;
printf "MDD/[plSTD*sqrt(12)]=  %.7f\n",$MDD/$std/sqrt(12);
printf "MDD/[plSTD*sqrt(21)]=  %.7f\n",$MDD/$std/sqrt(21);
printf "MDD/[plSTD*sqrt(252)]= %.7f\n",$MDD/$std/sqrt(252);
printf "drawdown file =tmp_drawdown.txt.$filename\n";






sub get_min_max_mean_std
#one pass:
# input a ref to an arry of Xs
# return: min max mean std count
{
   my ($refX ) = @_;
   my $count=$#$refX+1;


   my $inf = 9**9**9;
   my $neginf = -9**9**9;


   my $min=$inf;
   my $max=$neginf;
   my $mean;
   my $std;

   if($count<1) # empty
   {
     return (0,0,0,0,0);
   }

   #print "count=$count\n";
   my $xsum=0;
   my $x2sum=0;
   foreach my $x (@$refX)
   {
     $xsum+=$x;
     $x2sum+=($x*$x);

     if($x<$min){$min=$x;}

     if($x>$max){$max=$x;}

   }
   my $var=0; # if only one ob
   if($count >1)
   { 
     $var=($x2sum-$xsum*$xsum/$count)/($count-1);
   }
   $std=sqrt($var);
   $mean=$xsum/$count;

   return ($min,$max,$mean,$std,$count);
}

