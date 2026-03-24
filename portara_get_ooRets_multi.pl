#!/usr/bin/perl

use File::Basename;
use strict;


my $DEBUG=0;

( ($#ARGV+2) ==3 || ($#ARGV+2) ==4 ) || die
"Usage: portara_get_ooRets_multi.pl list_sym retRype  [opt: X-day]
       Compute FV scaled ret
       Type:
       0 = ooP1D = today open - yest open
       1 = ooF1D
       2 = GAP =today open - yest close
       3 = YOC = yest close - yest open
       4 = YHILO =yest high - yest cl
       5 = ccP1D = yest close - the day before yest close
       6 = HH = yest high - the day before yest high
       7 = LL = yest low - the day before yest low
       8 = YLC = yest close - yest low
       9 = YHC = yest close - yest high
       ###normalized o/h/l/c
       10 = O = yest open - the day before yest close
       11 = H = yest high - the day before yest close
       12 = L = yest low - the day before yest close
       13 = C = yest close - the day before yest close
       ## some yvars
       14 = ooFxD, needs to specify X, open x days from now  - today open
       15 = ooFDx, needs to specify X, open x days from now - open x-1 days from now
       16 = FOC, today close - today open
       17 = FGAP, tommorrow open to today close
       18 = ooFxDPct, needs to specify X, open x days from now  - today open
       ## others
       21 = YMC = yest close - (yest high+yest low)/2
       22 = ccP1DNL (no lag) = today close - yest close
       23 = ccP1DPctNL ( no lag) = (today close adj - yest close adj)/yest close, in pct
       ## biased inds
       24 = FHC, today close - today high
       25 = FLC, today close - today low
       26 = FMC, today close - (today high + today low)/2
       27 = FOM, (today high + today low)/2 - today open
       28 = FOH, today high  - today open
       29 = FOL, today low - today open
       ##
       30 = OODif, just today open - yest open, no FV scaling
       31 = CCDif(no lag), just today close  - yest close, no FV scaling
       ##
       32 = HO = open - yest high
       33 = LO = open - yest low
       ##
       34 = CL, level of close
       35 = CLAdj, level of close, minus cumSpd
       ##
       36 = ccPxD, need to specify x, yest close - close x days ago (already lagged)
       37 = GAP2 = yest open - the day before yest close
       38 = OC2 = the day before yest close - the day before yest open

       39 = FOC2, tommorrow close - tommorrow open
       40 = FGAP2, the day after tommorrow open - tommorrow close
       41 = ccF1D, tmrw close -today close
       42 = ccF2D, close in 2 days  - today close

       Add rth files loc:
	config.txt 
	RTH_DIR = /home/jgeng/notebooks/portara_1min_to_daily_rth/CCFixRTH

       Output: SYM DATE ooP1D(normed) FV\n";


my $retType=$ARGV[1];



if($retType > 42)
{
   print "Error:wrong retType\n";
   exit(0);
}

if( ($retType == 14 || $retType == 15 || $retType == 18 || $retType == 36 ) &&($#ARGV+2)==3 )
{
   print "Error:for retType=14,15, needs to specify X-day\n";
   exit(0);
}


my $X=0;
if( ($#ARGV+2)==4 )
{
  $X=$ARGV[2];
}


#header
my $xStr;
if($retType== 0)
{
  $xStr="ooP1D";
}
elsif($retType==1)
{
  $xStr="ooF1D";
}
elsif($retType==2)
{
  $xStr="GAP";
}
elsif($retType==3)
{
  $xStr="YOC";
}
elsif($retType==4)
{
  $xStr="YHILO";
}
elsif($retType==5)
{
  $xStr="ccP1D";
}

elsif($retType==6)
{
  $xStr="HH";
}
elsif($retType==7)
{
  $xStr="LL";
}
elsif($retType==8)
{
  $xStr="YLC";
}
elsif($retType==9)
{
  $xStr="YHC";
}
elsif($retType==10)
{
  $xStr="O";
}
elsif($retType==11)
{
  $xStr="H";
}
elsif($retType==12)
{
  $xStr="L";
}
elsif($retType==13)
{
  $xStr="C";
}
elsif($retType==14)
{
  $xStr="ooF"."$X"."D";
}
elsif($retType==15)
{
  $xStr="ooFD"."$X";
}
elsif($retType==16)
{
  $xStr="FOC";
}
elsif($retType==17)
{
  $xStr="FGAP";
}
elsif($retType==18)
{
  $xStr="ooF"."$X"."DPct";
}

elsif($retType==21)
{
  $xStr="YMC";
}
elsif($retType==22)
{
  $xStr="ccP1DNL";
}
elsif($retType==23)
{
  $xStr="ccP1DPctNL";
}
elsif($retType==24)
{
  $xStr="FHC";
}
elsif($retType==25)
{
  $xStr="FLC";
}
elsif($retType==26)
{
  $xStr="FMC";
}
elsif($retType==27)
{
  $xStr="FOM";
}
elsif($retType==28)
{
  $xStr="FOH";
}
elsif($retType==29)
{
  $xStr="FOL";
}
elsif($retType==30)
{
  $xStr="OODif";
}
elsif($retType==31)
{
  $xStr="CCDif";
}
elsif($retType==32)
{
  $xStr="HO";
}
elsif($retType==33)
{
  $xStr="LO";
}
elsif($retType==34)
{
  $xStr="CL";
}
elsif($retType==35)
{
  $xStr="CLAdj";
}
elsif($retType==36)
{
  $xStr="ccP"."$X"."D";
}
elsif($retType==37)
{
  $xStr="GAP2";
}
elsif($retType==38)
{
  $xStr="OC2";
}
elsif($retType==39)
{
  $xStr="FOC2";
}
elsif($retType==40)
{
  $xStr="FGAP2";
}
elsif($retType==41)
{
  $xStr="ccF1D";
}
elsif($retType==42)
{
  $xStr="ccF2D";
}
else
{
  #;
}

print "SYM DATE $xStr FV\n";


my $filename=$ARGV[0]; # portara text file
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";
my @line; 
while(<INFILE>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;

    my $sym=$line[0];
    my $cmd1="
    portara_get_ooRets.pl $sym $retType|fgrep -v DATE
";
   # print "$cmd1\n";
    if(($#ARGV+2)==4)
    {
      $cmd1="
    portara_get_ooRets.pl $sym $retType $X|fgrep -v DATE";
    }
    

    system("$cmd1");


}
close(INFILE);









__END__


--cmd:
time cat /mnt/wbox1/portara/Futures/Continuous\ Contracts/Intraday\ Database/1\ Minute\ 24Hr/EU.001 | sed s/,/\ /g|fgrep -v DATE|gawk '{if($1>=20150115 && $1<=20150115){print $1,$2,$7}}' > /tmp/tmpVol.txt
# 35 sec
cat /tmp/tmpVol.txt|myPortaraAddMissingMinutes.pl 1 2 3|mygetcols.pl 1 2 6 >/tmp/tmpVolNorm.txt 
timesXmgr.pl /tmp/tmpVolNorm.txt 2 0|mygetcols.pl 1 4 2 3  >/tmp/tmpForplot.txt
xmgrByTime /tmp/tmpForplot.txt&


