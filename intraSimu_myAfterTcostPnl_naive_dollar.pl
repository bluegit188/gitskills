#!/usr/bin/perl

use strict;

($#ARGV+2)==10 || die 
"Usage: intraSimu_myAfterTcostPnl_naive_dollar.pl isHeader=0/1 colSym colDate colIvl colIvlRet colPos(inLots) tcost(1side) tcostI colFVOOD
        #naive method, no opt entry/exit: pos=fcst, pnl=pos*y*FVOOD-tcost*abs(lot chg)*FVOOD
        use tcost or tcostI depending on if ivl=1 or not
        output: .. pnl(noTcost) pnlTcost\n";


my $isHeader=$ARGV[0];
my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colIvl=$ARGV[3];

my $colIvlRet=$ARGV[4];
my $colFcst=$ARGV[5];


my $tcost=$ARGV[6];
my $tcostI=$ARGV[7];

my $colFVOOD=$ARGV[8];


my $count=0;
my @line;

my $preSym="NA";
my $preFcst=0;
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;


    if($isHeader==1 && $count==1 ) # print header
    {
      print "$str pos pnlNTcost pnlTcost\n";
      next;
    }

    my $sym = $line[$colSym-1];
    my $date = $line[$colDate-1];
    my $ivl = $line[$colIvl-1];

    my $fcst = $line[$colFcst-1];
    my $ivlRet = $line[$colIvlRet-1];
    my $fvood = $line[$colFVOOD-1];

    my $yvar=$ivlRet;

    if($sym ne $preSym) # reset prePos to 0 for new sym
    {
      $preFcst=0;
    }

    my $curTcost=$tcostI;
    if($ivl==1)
    {
      $curTcost=$tcost;
    }


    my $fcstNet=$fcst; # naive method, no opt entry
    $fcstNet=nearest_junf(-7,$fcstNet);

    my $pnl=$yvar*$fcstNet*$fvood;
    my $pnlAdj=$yvar*$fcstNet*$fvood-abs($fcst-$preFcst)*$curTcost*$fvood; # after tcost

    $pnl=nearest_junf(-7,$pnl);
    $pnlAdj=nearest_junf(-7,$pnlAdj);

    print "$_ $fcstNet $pnl $pnlAdj\n";

    $preFcst=$fcst;
    $preSym=$sym;
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
