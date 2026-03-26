#!/usr/bin/perl

use strict;
use POSIX;

($#ARGV+2)==4  || die 
"Usage: myDemeanFcstInPlace.pl isHeader colX mean=x/0.02
       Demean fcst in place.
       If mean is specified as x, use fcst mean; otherwise, use this user prodvided mean\n";

my $isHeader=$ARGV[0];
my $colX=$ARGV[1];
my $userMean=$ARGV[2];

my @allRows;
my @Xs;
my $count=0;
my @line;
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    $count++;
    my $str=$_;

    if($count==1 && $isHeader==1)
    {
      print "$str\n";
      next;
    }


    @line =split;
    my $x = $line[$colX-1];

    push(@Xs,$x);
    push(@allRows,$str);
}

my ($min,$max,$mean,$std,$count2)=get_min_max_mean_std(\@Xs);


if ($userMean ne "x" )
{
   $mean=$userMean;
}



# loop again
foreach my $str (@allRows)
{

    @line =split(' ',$str);
    my $x = $line[$colX-1];

    my $xDM=$x-($mean);

    $line[$colX-1]=$xDM;

    print join(" ",@line),"\n";
}


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
   $std=0;
   if($var >=0)
   {
     $std=sqrt($var);
   }
   $mean=$xsum/$count;

   return ($min,$max,$mean,$std,$count);
}



