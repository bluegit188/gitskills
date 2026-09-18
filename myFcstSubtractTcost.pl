#!/usr/bin/perl

use strict;

($#ARGV+2)==4 || die 
"Usage: myFcstSubtractTcost.pl isHeader=0/1 colSym colFcst
        Compute fcstnet from raw fcst, tcost is hardcoded in the code for now
        most=0.01, STW=TY=C=SNI=0.02 ED=LEU=0.05
        output: .. fcstNet\n";


my $isHeader=$ARGV[0];
my $colSym=$ARGV[1];
my $colFcst=$ARGV[2];

my $count=0;
my @line; 
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

    my $tcost=0.01;
    if($sym eq "STW" ||
      $sym eq "TY"||
      $sym eq "C"||
      $sym eq "SNI")
    {
	#$tcost=0.02;
	$tcost=0.015;
    }
    if($sym eq "ED" || $sym eq "LEU")
    {
      $tcost=0.05;
    }

    my $fcstNet=0;
    if(abs($fcst) > $tcost)
    {
      $fcstNet=sign($fcst)* ( abs($fcst) - $tcost);
    }

    print "$_ ",  nearest_junf(-7,$fcstNet),"\n";

}
close(INFILE);

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
