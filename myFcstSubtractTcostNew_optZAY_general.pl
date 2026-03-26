#!/usr/bin/perl

use strict;

($#ARGV+2)==7 || die 
"Usage: myFcstSubtractTcost_optZA.pl isHeader=0/1 colSym colDate colFcst sizeX sizeY
        Compute fcstnet from raw fcst,
        optZAY: similar to optZA, but use sizeY when decrease in same direction
        output: .. fcstNet\n";


my $isHeader=$ARGV[0];
my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colFcst=$ARGV[3];

my $sizeX=$ARGV[4];
my $sizeY=$ARGV[5];

my $count=0;
my @line;
my $prevPos=0;
my $prevSym="NA";
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;

    my $sym = $line[$colSym-1];
    my $fcst = $line[$colFcst-1];


    if($isHeader==1 && $count==1 ) # print header
    {
      print "$str fcstNet\n";
      next;
    }

    if($sym ne $prevSym)
    {
      $prevPos=0;
    }

    my $fcstNet=0; # optZAY method
    $fcstNet=optZAY($sizeX,$sizeY,$prevPos,$fcst);

    print "$_ ",  nearest_junf(-7,$fcstNet),"\n";

    $prevPos=$fcstNet;
    $prevSym=$sym;
}
close(INFILE);


sub optZAY()
#(double sizeX, double sizeY, double prevPos, double newFcst)
#given X and currentFcst, return netFcst
{

   my ($sizeX, $sizeY, $prevPos,$newFcst) = @_;

   my $fcstNet;


   #if ( abs($prevPos)!=0 && $prevPos*$newFcst >=0 && abs($newFcst)>0.005 && abs($newFcst)< abs($prevPos)) # if reduce in same direction
    #if ( abs($prevPos)!=0 && $prevPos*$newFcst >=0 && abs($newFcst)< abs($prevPos)) # if reduce in same direction
  # small fix 20221217,  newFcst must be > 0.001
  if ( abs($prevPos)!=0 && $prevPos*$newFcst >=0 && abs($newFcst)< abs($prevPos) && abs($newFcst)>0.001 ) # if reduce in same direction
   {
      if($prevPos >0) #reduce a prev long
      {
	  $fcstNet=$newFcst+$sizeY;
	  if($fcstNet > $prevPos)
	  {
	    $fcstNet=$prevPos;
	  }
      }
      if($prevPos <0) #reduce a prev short
      {
	  $fcstNet=$newFcst-$sizeY;
	  if($fcstNet < $prevPos)
	  {
	    $fcstNet=$prevPos;
	  }
      }

   }
   else                                                     # otherwise, same as optZA
   {
      $fcstNet=optZA($sizeX,$prevPos,$newFcst);
   }

   return $fcstNet;

}


sub optZA()
#(double sizeX, double prevFcst, double newFcst)
#given X and currentFcst, return netFcst
{

   my ($sizeX, $prevFcst,$newFcst) = @_;

   my $fcstNet;

   if($newFcst > $prevFcst)
   {
      $fcstNet=$newFcst-$sizeX;
      if($fcstNet < $prevFcst)
      {
        $fcstNet=$prevFcst;
      }
   }

   if($newFcst <= $prevFcst)
   {
      $fcstNet=$newFcst+$sizeX;
      if($fcstNet > $prevFcst)
      {
        $fcstNet=$prevFcst;
      }
   }

   #small fix, see 20221217 report 
   if($fcstNet*$newFcst < 0 || abs($newFcst)< 0.001)
   #if($fcstNet*$newFcst < 0)
   {
     $fcstNet=0;
   }

   return $fcstNet;
}



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
