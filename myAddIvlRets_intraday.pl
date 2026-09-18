#!/usr/bin/perl

use strict;

($#ARGV+2)==6 || die 
"Usage: myAddIvlRets_intraday.pl isHeader=1 colSym colDate colIvl colPL2NO
        Add ivlRets from PL2NO
        For last ivl, ivlRet=PL2NO, otherwise, ivlRet=PL2NO_this - PL2NO_next
        Assume always have a header
        output: ..xxx... ivlRet\n";


my $isHeader=$ARGV[0]; 
my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colIvl=$ARGV[3];
my $colPL2NO=$ARGV[4];



my @allRows = (<STDIN>) ;
my $ysize=$#allRows+1;
#print "ysize=$ysize\n";
my $header=($allRows[0]);
chomp($header);

my $first=0;
if($isHeader)
{
   $first=1;
}





print "$header ivlRet\n";

## Step 1: compute ivlRet=PL2NO(i)-PL2NO(i+1)
##         for last ivl, ivtRet=PL2NO
my @ivlRets;
push(@ivlRets,0);# fill 0 header row
for (my $j=1;$j < $ysize;$j++)
{

   my $row=$allRows[$j];
   chomp($row);
   my @line =split(' ',$row);

   my $sym = $line[$colSym-1];
   my $date = $line[$colDate-1];
   my $PL2NO= $line[$colPL2NO-1];
 

   my $ivlRet=$PL2NO;
   if($j < $ysize-1)
   {
      my $rowNext=$allRows[$j+1];
      chomp($rowNext);
      my @lineNext =split(' ',$rowNext);

      my $symNext = $lineNext[$colSym-1];
      my $dateNext = $lineNext[$colDate-1];
      my $PL2NONext= $lineNext[$colPL2NO-1];

      if($sym eq $symNext && $date==$dateNext)
      {
	  $ivlRet=$PL2NO-$PL2NONext;
      }
   }

   $ivlRet=nearest_junf(-7,$ivlRet);
   #push(@ivlRets,$ivlRet);
   print "$row $ivlRet\n";

}

sub nearest_junf()
# emulate Math::Round's nearest function, but elimiate extra zeros from $.4f notation
# input: -4, 3.56789 (max to 4th decimal digits                                      
# output: 3.568                                                                      
#
#more examples: first argu=-4
#0         -> 0
#0.1       -> 0.1
#0.11      -> 0.11
#0.111     -> 0.111
#0.1111111 -> 0.1111
{
    my ($pow10, $x) = @_;
    my $a = 10 ** $pow10;

    return (int($x / $a + (($x < 0) ? -0.5 : 0.5)) * $a);
}


__END__
