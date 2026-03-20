#!/usr/bin/perl

use strict;

( ($#ARGV+2) ==3 || ($#ARGV+2) ==4 ) || die
"Usage: portara_get_ooRets.pl SYM retRype [opt: X-day]
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


my $dir="/home/jgeng/RawData/portara/JunfCC/CCFixRTH";

if(-e "config.txt")
{
   my %hash_config=read_file_by_key("config.txt");
   my $dir_loc=$hash_config{"RTH_DIR"}[2];
   #$print "dir_loc=$dir_loc\n";
   $dir=$dir_loc;
}





my $filename="$dir/".$ARGV[0].".txt";
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $retType=$ARGV[1];

if($retType > 42)
{
   print "Error:wrong retType\n";
   exit(0);
}

if( ($retType == 14 || $retType == 15|| $retType == 18 || $retType == 36 ) &&($#ARGV+2)==3 )
{
   print "Error:for retType=14,15,18,36 needs to specify X-day\n";
   exit(0);
}


my $X=0;
if( ($#ARGV+2)==4 )
{
  $X=$ARGV[2];
}


########################################
#1). reads in fixed RTH file
# get regular std
#################################

my @allRows=read_file($filename); # note, no header for file
#print join("\n",@allRows),"\n";

my @OOs;
#regular std
#0=today, 1=yest, 2=day before yest
my @line0;
my @line1;
foreach my $i (1..$#allRows)
{

    my $lineStr0=$allRows[$i];
    my $lineStr1=$allRows[$i-1];

    @line0 =split(' ',$lineStr0); #' ' is correct to remove one or more white spaces
    @line1 =split(' ',$lineStr1);

    #tc=trade counts
    my($date0,$open0,$high0,$low0,$close0,$tc0,$vol0,$oi0,$sym0,$ym0,$spd0,$cumSpd0)=@line0;
    my($date1,$open1,$high1,$low1,$close1,$tc1,$vol1,$oi1,$sym1,$ym1,$spd1,$cumSpd1)=@line1;

    # ajust cumSpd
    $open0-=$cumSpd0;$high0-=$cumSpd0;$low0-=$cumSpd0;$close0-=$cumSpd0;
    $open1-=$cumSpd1;$high1-=$cumSpd1;$low1-=$cumSpd1;$close1-=$cumSpd1;

    my $OO=($open0-$open1);
    push(@OOs,$OO);
}
my $std=get_std(\@OOs);





##################################
#2). compute FVOO
###############################


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

#0=today, 1=yest,
my @line0;
my @line1;
my @line2;
my @lineF1;

my @lineFX;
my @lineFX1; # one day before FX


#my $a=0.975;

my $a=0.915;


my $ema0=$std;
my $ema=$ema0;

my $start=1;
my $end=$#allRows;

#if($retType==1 ||$retType==16 ||$retType==17  ) # ooF1D
#{
#  $end=$#allRows-1;
#}


if($retType==1   ||$retType==16 ||$retType==17 ||$retType==39  ||$retType==41  ) # ooF1D, FOC, FGAP, FOC2,ccF1D
{
  $end=$#allRows-1;
}

if($retType==40   ||$retType==42  ) # FGAP2, ccF2D
{
  $end=$#allRows-2;
}



if($retType==5 || $retType==6 || $retType==7
   || $retType==10 || $retType==11 || $retType==12 || $retType==13|| $retType==37 || $retType==38) # ccP1D, HH, LL, O/H/L/C, GAP2, OC2
{
  $start=2;
}

if($retType==14 || $retType==15|| $retType==18) # ooFxD or ooFDx  ooFxDPct
{
  $end=$#allRows-$X;
}

if($retType==36) # ccPxD, lagged
{
  $start=$X+1;
  $end=$#allRows;
}


my $lineStr2;
my $lineStrF1;

my $lineStrFX;
my $lineStrFX1;

foreach my $i ($start..$end)
{

    my $lineStr0=$allRows[$i];
    my $lineStr1=$allRows[$i-1];


    @line0 =split(' ',$lineStr0); #' ' is correct to remove one or more white spaces
    @line1 =split(' ',$lineStr1);


    #tc=trade counts
    my($date0,$open0,$high0,$low0,$close0,$tc0,$vol0,$oi0,$sym0,$ym0,$spd0,$cumSpd0)=@line0;
    my($date1,$open1,$high1,$low1,$close1,$tc1,$vol1,$oi1,$sym1,$ym1,$spd1,$cumSpd1)=@line1;


    # ajust cumSpd
    $open0-=$cumSpd0;$high0-=$cumSpd0;$low0-=$cumSpd0;$close0-=$cumSpd0;
    $open1-=$cumSpd1;$high1-=$cumSpd1;$low1-=$cumSpd1;$close1-=$cumSpd1;

    #   HILO=yest high - yest low
    my $HILO=($high1-$low1);
    #   GAP=open today - close yest
    my $AGAP=abs($open0-$close1);
    #HILOADJ=0.453*(HILO+1.17*AGAP)
    # 1.29 is to adjust FV such that sd(ooP1D)=1
    my $HILOADJ=(0.45*$HILO+0.55*$AGAP)*(1.29);


    $ema=$a*$ema+(1-$a)*$HILOADJ;
    my $FV=$ema;



    my $x=0;
    if($retType==0) # ooP1D
    {
      my $OO=$open0-$open1;
      $x=$OO;
    }


    if($retType==32) # HO
    {
      my $HO=$open0-$high1;
      $x=$HO;
    }

    if($retType==33) # LO
    {
      my $LO=$open0-$low1;
      $x=$LO;
    }



    if($retType==30) # ooDif
    {
      my $OODif=$open0-$open1;
      $x=$OODif;
    }


    if($retType==22) # ccP1DNL
    {
      my $ccP1DNL=$close0-$close1;
      $x=$ccP1DNL;
    }

    if($retType==31) # ccDif
    {
      my $ccDif=$close0-$close1;
      $x=$ccDif;
    }


    if($retType==23) # ccP1DPctNL, pct ret
    {
      my $close1Unadj=$close1+$cumSpd1;
      my $ccP1DPctNL= ($close0-$close1)/$close1Unadj;
      $x=$ccP1DPctNL;
    }




    if($retType==1) # ooF1D
    {
      $lineStrF1=$allRows[$i+1];
      @lineF1 =split(' ',$lineStrF1);
      my($dateF1,$openF1,$highF1,$lowF1,$closeF1,$tcF1,$volF1,$oiF1,$symF1,$ymF1,$spdF1,$cumSpdF1)=@lineF1;
      $openF1-=$cumSpdF1;$highF1-=$cumSpdF1;$lowF1-=$cumSpdF1;$closeF1-=$cumSpdF1;
      my $OOF1D=$openF1-$open0;
      $x=$OOF1D;
    }


    if($retType==16) # FOC
    {
      $lineStrF1=$allRows[$i+1];
      @lineF1 =split(' ',$lineStrF1);
      my($dateF1,$openF1,$highF1,$lowF1,$closeF1,$tcF1,$volF1,$oiF1,$symF1,$ymF1,$spdF1,$cumSpdF1)=@lineF1;
      $openF1-=$cumSpdF1;$highF1-=$cumSpdF1;$lowF1-=$cumSpdF1;$closeF1-=$cumSpdF1;
      my $FOC=$close0-$open0;
      $x=$FOC;
    }

    if($retType==17) # FGAP
    {

      if($i==$end)
      {
	next;
      }

      $lineStrF1=$allRows[$i+1];
      @lineF1 =split(' ',$lineStrF1);
      my($dateF1,$openF1,$highF1,$lowF1,$closeF1,$tcF1,$volF1,$oiF1,$symF1,$ymF1,$spdF1,$cumSpdF1)=@lineF1;
      $openF1-=$cumSpdF1;$highF1-=$cumSpdF1;$lowF1-=$cumSpdF1;$closeF1-=$cumSpdF1;
      my $FGAP=$openF1-$close0;
      $x=$FGAP;
    }


    if($retType==14) # ooFxD
    {
      $lineStrFX=$allRows[$i+$X];
      @lineFX =split(' ',$lineStrFX);
      my($dateFX,$openFX,$highFX,$lowFX,$closeFX,$tcFX,$volFX,$oiFX,$symFX,$ymFX,$spdFX,$cumSpdFX)=@lineFX;
      $openFX-=$cumSpdFX;$highFX-=$cumSpdFX;$lowFX-=$cumSpdFX;$closeFX-=$cumSpdFX;
      my $OOFXD=$openFX-$open0;
      $x=$OOFXD;
    }


    if($retType==36) # ccPxD, lagged
    {
      my $p2=$close1;
      #close from x days ago
      $lineStrFX=$allRows[$i-1-$X];
      @lineFX =split(' ',$lineStrFX);
      my($dateFX,$openFX,$highFX,$lowFX,$closeFX,$tcFX,$volFX,$oiFX,$symFX,$ymFX,$spdFX,$cumSpdFX)=@lineFX;
      my $p1=$closeFX-$cumSpdFX;
      $x=$p2-$p1;
    }


    if($retType==37) # GAP2
    {
      my $p2=$open1;
      #close from x days ago
      $lineStrFX=$allRows[$i-1-1];
      @lineFX =split(' ',$lineStrFX);
      my($dateFX,$openFX,$highFX,$lowFX,$closeFX,$tcFX,$volFX,$oiFX,$symFX,$ymFX,$spdFX,$cumSpdFX)=@lineFX;
      my $p1=$closeFX-$cumSpdFX;
      $x=$p2-$p1;
    }

    if($retType==38) # OC2
    {

      #close from x days ago
      $lineStrFX=$allRows[$i-1-1];
      @lineFX =split(' ',$lineStrFX);
      my($dateFX,$openFX,$highFX,$lowFX,$closeFX,$tcFX,$volFX,$oiFX,$symFX,$ymFX,$spdFX,$cumSpdFX)=@lineFX;
      my $p1=$openFX-$cumSpdFX;
      my $p2=$closeFX-$cumSpdFX;

      $x=$p2-$p1;
    }


    if($retType==18) # ooFxDPct
    {

      my $open0Unadj=$open0+$cumSpd0;

      $lineStrFX=$allRows[$i+$X];
      @lineFX =split(' ',$lineStrFX);
      my($dateFX,$openFX,$highFX,$lowFX,$closeFX,$tcFX,$volFX,$oiFX,$symFX,$ymFX,$spdFX,$cumSpdFX)=@lineFX;
      $openFX-=$cumSpdFX;$highFX-=$cumSpdFX;$lowFX-=$cumSpdFX;$closeFX-=$cumSpdFX;
      my $OOFXD=($openFX-$open0)/$open0Unadj;
      $x=$OOFXD;
    }


    if($retType==15) # ooFDx
    {
      $lineStrFX=$allRows[$i+$X];
      @lineFX =split(' ',$lineStrFX);
      my($dateFX,$openFX,$highFX,$lowFX,$closeFX,$tcFX,$volFX,$oiFX,$symFX,$ymFX,$spdFX,$cumSpdFX)=@lineFX;
      $openFX-=$cumSpdFX;$highFX-=$cumSpdFX;$lowFX-=$cumSpdFX;$closeFX-=$cumSpdFX;

      #FX1 is one day before FX
      $lineStrFX1=$allRows[$i+$X-1];
      @lineFX1 =split(' ',$lineStrFX1);
      my($dateFX1,$openFX1,$highFX1,$lowFX1,$closeFX1,$tcFX1,$volFX1,$oiFX1,$symFX1,$ymFX1,$spdFX1,$cumSpdFX1)=@lineFX1;
      $openFX1-=$cumSpdFX1;$highFX1-=$cumSpdFX1;$lowFX1-=$cumSpdFX1;$closeFX1-=$cumSpdFX1;

      my $OOFDX=$openFX-$openFX1;
      $x=$OOFDX;
    }



    if($retType==2) # GAP
    {
      my $GAP=$open0-$close1;
      $x=$GAP;
    }


    if($retType==3) # YOC
    {
      my $YOC=$close1-$open1;
      $x=$YOC;
    }

    if($retType==4) # YHILO
    {
      my $YHILO=$high1-$low1;
      $x=$YHILO;
    }

    if($retType==5 || $retType==6 || $retType==7  
       || $retType==10 || $retType==11 || $retType==12 || $retType==13) # ccP1D, HH, LL, O/H/L/C
    {
      $lineStr2=$allRows[$i-2];
      @line2 =split(' ',$lineStr2);
      my($date2,$open2,$high2,$low2,$close2,$tc2,$vol2,$oi2,$sym2,$ym2,$spd2,$cumSpd2)=@line2;
      # ajust cumSpd
      $open2-=$cumSpd2;$high2-=$cumSpd2;$low2-=$cumSpd2;$close2-=$cumSpd2;
      my $ccP1D=$close1-$close2;
      my $HH=$high1-$high2;
      my $LL=$low1-$low2;

      if($retType==5) #ccP1D
      {
	$x=$ccP1D;
      }
      if($retType==6) #HH
      {
	$x=$HH;
      }
      if($retType==7) #LL
      {
	$x=$LL;
      }


      if($retType==10) # normalized open
      {
	 my $O=$open1-$close2;
	$x=$O;
      }

      if($retType==11) # normalized high
      {
	my $H=$high1-$close2;
	$x=$H;
      }

      if($retType==12) # normalized low
      {
	my $L=$low1-$close2;
	$x=$L;
      }

      if($retType==13) # normalized close, ie, ccP1D
      {
	my $C=$close1-$close2;
	$x=$C;
      }

    }

    if($retType==8) # YLC
    {
      my $YLC=$close1-$low1;
      $x=$YLC;
    }

    if($retType==9) # YHC
    {
      my $YHC=$close1-$high1;
      $x=$YHC;
    }

    if($retType==21) # YMC
    {
       my $YMC=$close1-($high1+$low1)/2.0;
       $x=$YMC;

       # same result if using unadjusted values
       #my $close1UA=$close1+$cumSpd1; # unadjusted values
       #my $high1UA=$high1+$cumSpd1;
       #my $low1UA=$low1+$cumSpd1;
       #my $YMC=$close1UA-($high1UA+$low1UA)/2.0;
       #$x=$YMC;

    }


    if($retType==24) # FHC
    {
      my $FHC=$close0-$high0;
      $x=$FHC;
    }
    if($retType==25) # FLC
    {
      my $FLC=$close0-$low0;
      $x=$FLC;
    }

    if($retType==26) # FMC
    {
      my $FMC=$close0-($high0+$low0)/2;
      $x=$FMC;
    }

    if($retType==27) # FOM
    {
      my $FOM=($high0+$low0)/2-$open0;
      $x=$FOM;
    }


    if($retType==28) # FOH
    {
      my $FOH=$high0-$open0;
      $x=$FOH;
    }

    if($retType==29) # FOL
    {
      my $FOL=$low0-$open0;
      $x=$FOL;
    }

    if($retType==34) # CL
    {
      $x=$close0+$cumSpd0;
    }
    if($retType==35) # CLAdj
    {
      $x=$close0;
    }
    
    if($retType==39) # FOC2
    {
      $lineStrF1=$allRows[$i+1];
      @lineF1 =split(' ',$lineStrF1);
      my($dateF1,$openF1,$highF1,$lowF1,$closeF1,$tcF1,$volF1,$oiF1,$symF1,$ymF1,$spdF1,$cumSpdF1)=@lineF1;
      $openF1-=$cumSpdF1;$highF1-=$cumSpdF1;$lowF1-=$cumSpdF1;$closeF1-=$cumSpdF1;
      my $FOC2=$closeF1-$openF1;
      $x=$FOC2;
    }

    if($retType==40) # FGAP2
    {
      $lineStrF1=$allRows[$i+1];
      @lineF1 =split(' ',$lineStrF1);
      my($dateF1,$openF1,$highF1,$lowF1,$closeF1,$tcF1,$volF1,$oiF1,$symF1,$ymF1,$spdF1,$cumSpdF1)=@lineF1;
      $openF1-=$cumSpdF1;$highF1-=$cumSpdF1;$lowF1-=$cumSpdF1;$closeF1-=$cumSpdF1;

      $lineStrFX=$allRows[$i+2];
      @lineFX =split(' ',$lineStrFX);
      my($dateFX,$openFX,$highFX,$lowFX,$closeFX,$tcFX,$volFX,$oiFX,$symFX,$ymFX,$spdFX,$cumSpdFX)=@lineFX;
      $openFX-=$cumSpdFX;$highFX-=$cumSpdFX;$lowFX-=$cumSpdFX;$closeFX-=$cumSpdFX;
     
      my $FGAP2=$openFX-$closeF1;
      $x=$FGAP2;
    }

    if($retType==41) # ccF1D
    {
      $lineStrF1=$allRows[$i+1];
      @lineF1 =split(' ',$lineStrF1);
      my($dateF1,$openF1,$highF1,$lowF1,$closeF1,$tcF1,$volF1,$oiF1,$symF1,$ymF1,$spdF1,$cumSpdF1)=@lineF1;
      $openF1-=$cumSpdF1;$highF1-=$cumSpdF1;$lowF1-=$cumSpdF1;$closeF1-=$cumSpdF1;
      my $ccF1D=$closeF1-$close0;
      $x=$ccF1D;
    }

    if($retType==42) # ccF2D
    {
      $lineStrF1=$allRows[$i+1];
      @lineF1 =split(' ',$lineStrF1);
      my($dateF1,$openF1,$highF1,$lowF1,$closeF1,$tcF1,$volF1,$oiF1,$symF1,$ymF1,$spdF1,$cumSpdF1)=@lineF1;
      $openF1-=$cumSpdF1;$highF1-=$cumSpdF1;$lowF1-=$cumSpdF1;$closeF1-=$cumSpdF1;

      $lineStrFX=$allRows[$i+2];
      @lineFX =split(' ',$lineStrFX);
      my($dateFX,$openFX,$highFX,$lowFX,$closeFX,$tcFX,$volFX,$oiFX,$symFX,$ymFX,$spdFX,$cumSpdFX)=@lineFX;
      $openFX-=$cumSpdFX;$highFX-=$cumSpdFX;$lowFX-=$cumSpdFX;$closeFX-=$cumSpdFX;
     
      my $ccF2D=$closeFX-$close0;
      $x=$ccF2D;
    }


    my $xNorm=0;
    if($FV > 0)
    {
      $xNorm=$x/$FV;
    }
    #print "line=$lineStr0\n";
    #### printing

    if($retType==23 || $retType==18) # for pct ret, don't scale
    {
      $xNorm=$x;
    }

    if($retType==30 || $retType==31) # for OODif and CCDif, don't scale
    {
      $xNorm=$x;
    }

    if($retType==34 || $retType==35) # for CL and CLAdj, don't scale
    {
      $xNorm=$x;
    }

    print "$sym0 $date0";
    printf " %.6f",$xNorm;
    printf " %.6f",$FV;
    printf "\n";
}


sub read_file
# input: filename
# return: ref to array of rows
{
   my ($filename)=@_;

   open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";
   my @allRows=(<INFILE>);
   chomp@allRows; # remove new lines at each row
   close(INFILE);
   return @allRows;
}


sub min
#input: x1, x2
# output: smaller one
{
  my ($x1,$x2) = @_;

  if($x1<=$x2)
  {
    return $x1;
  }

  return $x2;
}

sub max
#input: x1, x2
# output: bigger one
{
  my ($x1,$x2) = @_;

  if($x1 >= $x2)
  {
    return $x1;
  }

  return $x2;
}

sub nearest_junf()
# emulate Math::Round's nearest function, but elimiate extra zeros from $.4f notation
# input: -4, 3.56789 (max to 4th decimal digits
# output: 3.568
#
#more examples: -4
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


sub get_std
#one pass
{
   my ($refX ) = @_;
   my $count=$#$refX+1;
   if($count<1){return 0;}

   #print "count=$count\n";
   my $xsum=0;
   my $x2sum=0;
   foreach my $x (@$refX)
   {
     $xsum+=$x;
     $x2sum+=($x*$x);
   }
   my $var=0; # count=1
   if($count >1)
   {
     $var=($x2sum-$xsum*$xsum/$count)/($count-1);
   }
   return sqrt($var);
}

sub read_file_by_key
# input: filename,  
# file format:  ID x1 x1 x2
# return: ref to hash: ID->ref to array
### usage:
# my %hash=read_file_by_key($decimalFile);
# my $pMult=$hash{"ES"}[1];
{
   my ($filename)=@_;
   open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";
   my %hash;
   while (<INFILE>)
   {
       chomp;
       my $str=$_;

       #ignore comment line
       if(substr($str,0,1) eq "#")
       {
	  next;
       }

       my @line= split;
       my $key=$line[0];
       my $value=$str;
       #$hash{$key} .= exists $hash{$key} ? ",$value" : $value;
       $hash{$key} =\@line;

    }
   close(INFILE);
   return %hash;
}


__END__


#modify array in place
my @a=(2,3,4,5);
foreach(@a)
{ $_ -= 1; }
print "a=",join(" ",@a),"\n";

