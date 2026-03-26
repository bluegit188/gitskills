#!/usr/bin/perl

use strict;

($#ARGV+2)==7 || die 
"Usage: myAfterTcostPnl_naive.pl isHeader=0/1 colSym colDate colY colFcst tcost(1side)
        naive method, no opt entry/exit: pos=fcst, pnl=fcst*y-tcost*abs(fcst chg)
        output: .. pnl(noTcost) pnlTcost\n";


my $isHeader=$ARGV[0];
my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colY=$ARGV[3];
my $colFcst=$ARGV[4];


my $tcost=$ARGV[5];


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
      print "$str fcstNet pnlNTcost pnlTcost\n";
      next;
    }

    my $sym = $line[$colSym-1];
    my $date = $line[$colDate-1];
    my $fcst = $line[$colFcst-1];
    my $yvar = $line[$colY-1];


    if($sym ne $preSym) # reset prePos to 0 for new sym
    {
      $preFcst=0;
    }

    #my $tcost=0.01;
    #my $fcstNet=0;
    #if(abs($fcst) > $tcost)
    #{
    #  $fcstNet=sign($fcst)* ( abs($fcst) - $tcost);
    #}

    my $fcstNet=$fcst; # naive method, no opt entry
    $fcstNet=nearest_junf(-7,$fcstNet);

    my $pnl=$yvar*$fcst;
    my $pnlAdj=$yvar*$fcstNet-abs($fcst-$preFcst)*$tcost; # after ctost

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
