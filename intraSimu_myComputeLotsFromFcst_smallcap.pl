#!/usr/bin/perl

use strict;

($#ARGV+2)==13 || die 
"Usage: intraSimu_myComputeLotsFromFcst_smallcap.pl isHeader=0/1 colSym colDate colIvl colIvlRet colFcst colFVOO colPvUSD RPF initCap fcstCutL(-0.03) fcstCutH(0.03)
       From fcst to lots, deal with small cap issues
       If fcst < fcstCutL, or fcst> fcstCutH, put on 1 lot
       Method: regular lots roundoff + 1 lot for DAX if fcst is high \n";


my $isHeader=$ARGV[0];


my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colIvl=$ARGV[3];
my $colIvlRet=$ARGV[4]; # Y
my $colFcst=$ARGV[5];

my $colFVOO=$ARGV[6];
my $colPvUSD=$ARGV[7];

my $RPS=$ARGV[8];
my $initCap=$ARGV[9];


my $fcstCutL=$ARGV[10];
my $fcstCutH=$ARGV[11];


my $count=0;
my @line; 
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;
    if($isHeader==1 && $count==1 ) # print header
    {
      print "$str FVOOD lotFrac lotRound lotRoundAdj pnlDol\n";
      next;
    }

    #print "str=$str\n";

    my $ivlRet = $line[$colIvlRet-1];
    my $fcst = $line[$colFcst-1];

    my $FVOO = $line[$colFVOO-1];
    my $pvUSD = $line[$colPvUSD-1];

    ### calculations
    my $FVOOD=$FVOO*$pvUSD;
    my $lotFrac=nearest_junf(-5,$fcst*$RPS/$FVOOD);

    my $lotRound=nearest_junf(0,$lotFrac);
    my $lotRoundAdj=$lotRound;

    #### one simple rule to trade large-FVOO contracts like DAX for 1 lot
    if(abs($lotRound) <0.001 && (  $fcst < $fcstCutL || $fcst> $fcstCutH ) )
    {
      $lotRoundAdj=sign($fcst)*1;
    }

    # this is pnls
    my $pnlDol=$ivlRet*$FVOO*$pvUSD*$lotRoundAdj;

    print "$str $FVOOD $lotFrac $lotRound $lotRoundAdj $pnlDol\n";

}
close(INFILE);


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
