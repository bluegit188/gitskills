#!/usr/bin/perl

use strict;

($#ARGV+2) ==2 || die
"Usage: portara_get_FVOOD.pl SYM
       Compute forecasted volatility FVOO in local currency and in US dollars.
       FVOOD=FVOOL*fx=(FVOO*pv)*fx=FVOO*pv*fx
       pvUSD=pv*fxRate
       Output: SYM DATE ooDif FVOO FVOOL FVOOD DENOM PV PVUSD fxRate fxDate\n";


my $sym=$ARGV[0];


#Step 1: reads in the fxDenom and pv config file
my $filePV="/home/jgeng/bin/pv_prod.txt";
my $colDenom=2;
my $colPV=3;
#SYM Currency PointValue
# BC      USD       1000
# C       USD         50
my %hashPVs=read_file_by_key($filePV);
if(! exists $hashPVs{$sym})
{
   print "Error: $sym was not found in the pointValue config file: $filePV.\n";
   exit(0);
}

#print join(" ",sort keys %hashPVs),"\n";
my $denom=$hashPVs{$sym}[$colDenom-1];
my $PV=$hashPVs{$sym}[$colPV-1];
#print "denom=$denom PV=$PV\n";

#Step 2: reads in RTH file
my $dir="/home/jgeng/RawData/portara/JunfCC/CCFixRTH/";
my $filenameRTH="$dir".$sym.".txt";
my @allRowsRTH=read_file($filenameRTH); # note, no header for file
#print join("\n",@allRowsRTH),"\n";

#Step 3: read in fx file if needed
my $isUSD=1;
my @allRowsFX;
if($denom ne "USD")
{
   $isUSD=0;
   my $fxSym=$denom."USD"; # EURUSD
   my $filenameFX="/home/jgeng/RawData/Norgate/ForexFix/".$fxSym.".txt";
   @allRowsFX=read_file($filenameFX); # note, no header for file
   #print join("\n",@allRowsFX),"\n";

}

#Step 3: extract FX date and closes for nonUS currency
my @datesFX; # FX date and closes
my @closesFX;
my @line0;
if( ! $isUSD)
{
   foreach my $i (0..$#allRowsFX)
   {
       my $lineStr0=$allRowsFX[$i];
       @line0 =split(' ',$lineStr0); #' ' is correct to remove one or more white spaces
       #tc=trade counts
       my($date,$open,$high,$low,$close,$tc,$vol,$oi,$sym,$ym,$spd,$cumSpd)=@line0;
       push(@datesFX,$date);
       push(@closesFX,$close);
       #print "$denom $date $close\n";
  }
}

# Step 4: below we compute FVOO, and FVOOL/FVOODs etc
# 4.1 )
my @OOs;
#regular std
#0=today, 1=yest, 2=day before yest
my @line0;
my @line1;
foreach my $i (1..$#allRowsRTH)
{

    my $lineStr0=$allRowsRTH[$i];
    my $lineStr1=$allRowsRTH[$i-1];

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
#print "std=$std\n";



#4.2). compute FVOO,FVOOL and FVOOD
# FVOOD=FVOOL*fx=(FVOO*pv)*fx=FVOO*pv*fx

#header
print "SYM DATE ooDif FVOO FVOOL FVOOD DENOM PV PVUSD fxRate fxDate\n";
#0=today, 1=yest,
my @line0;
my @line1;
my $a=0.975;
my $ema0=$std;
my $ema=$ema0;

my $startLoc=-1; # unknown start loc

foreach my $i (1..$#allRowsRTH)
{

    my $lineStr0=$allRowsRTH[$i];
    my $lineStr1=$allRowsRTH[$i-1];

    @line0 =split(' ',$lineStr0); #' ' is correct to remove one or more white spaces
    @line1 =split(' ',$lineStr1);


    #tc=trade counts
    my($date0,$open0,$high0,$low0,$close0,$tc0,$vol0,$oi0,$sym0,$ym0,$spd0,$cumSpd0)=@line0;
    my($date1,$open1,$high1,$low1,$close1,$tc1,$vol1,$oi1,$sym1,$ym1,$spd1,$cumSpd1)=@line1;


    # ajust cumSpd
    $open0-=$cumSpd0;$high0-=$cumSpd0;$low0-=$cumSpd0;$close0-=$cumSpd0;
    $open1-=$cumSpd1;$high1-=$cumSpd1;$low1-=$cumSpd1;$close1-=$cumSpd1;

    my $OO=$open0-$open1;
    #   HILO=yest high - yest low
    my $HILO=($high1-$low1);

    #   GAP=open today - close yest
    my $GAP=($open0-$close1);
    my $AGAP=abs($GAP);
    #HILOADJ=0.453*(HILO+1.17*AGAP)
    # 1.29 is to adjust FV such that sd(ooP1D)=1
    my $HILOADJ=(0.45*$HILO+0.55*$AGAP)*(1.29);

    $ema=$a*$ema+(1-$a)*$HILOADJ;
    #print "line=$lineStr0\n";


    my $FVOO=$ema;
    my $fxRate=1;
    my $fxRateDate=$date0;#"NA";
    my $loc=-1;
    if( ! $isUSD)
    {

        if($date0 <= $datesFX[0]) # ignore if RTH date is earlier than first fxRate Date
	{
	   next;
	}

        #print "$sym $date0\n";
        $loc=fine_loc_most_recent_date_ex_fast(\@datesFX,$date0,$startLoc);
	#print "loc=$loc\n";
	
        if($loc != -1)
	{
          $fxRate=$closesFX[$loc];
	  $fxRateDate=$datesFX[$loc];
	}
     }


    # for debug
    #print "   $sym $date0 $denom loc=$loc fx=$fxRate fxDate=$fxRateDate\n";



    if( (!$isUSD && $loc != -1 ) || $isUSD) # if USD or nonUSD but loc！=-1
    {

       my $FVOOL=$FVOO*$PV;
       my $FVOOD=$FVOOL*$fxRate;
       my $pvUSD=$PV*$fxRate;
       #### printing
       print "$sym0 $date0";
       printf " %.6f",$OO;
       printf " %.6f",$FVOO;
       printf " %.6f",$FVOOL;
       printf " %.6f",$FVOOD;
       printf " $denom $PV $pvUSD $fxRate $fxRateDate";
       printf "\n";
    }

    $startLoc=$loc;

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


sub fine_loc_most_recent_date_ex
# input: a dates vec, an user date=dateUser
# output: find the loc of a dateX, such that dateUser > dateX ( not dateUser >=dateX)
{

   my ($refDates,$dateUser) = @_;

   my $i;
   my $match_idx=-1;
   for ($i = 0; $i <= $#$refDates; $i++)
   {
      my $curDate=$$refDates[$i];
      my $nextDate;
      if($i == $#$refDates)
      {
	 $nextDate=999999999; # set as a really big number
      }
      else
      {
         $nextDate =$$refDates[$i+1];
      }

      if ($dateUser > $curDate && $dateUser <= $nextDate)
      {
         $match_idx = $i;    # save the index
	 last;
       }
   }

   return $match_idx;

}


sub fine_loc_most_recent_date_ex_fast
# this is a faster verion: but need to provide a startingLoc （ set to -1 if unknown)
# input: a dates vec, an user date=dateUser
# output: find the loc of a dateX, such that dateUser > dateX ( not dateUser >=dateX)
{

   my ($refDates,$dateUser, $startLoc) = @_;

   my $first=0;
   my $size= $#$refDates+1;
   if($startLoc >0 && $startLoc < $size  ) # must be a valid startLoc
   {
      $first=$startLoc;
   }

   my $i;
   my $match_idx=-1;
   for ($i = $first; $i < $size; $i++)
   {
      my $curDate=$$refDates[$i];
      my $nextDate;
      if($i >= $size-1)
      {
	 $nextDate=999999999; # set as a really big number
      }
      else
      {
         $nextDate =$$refDates[$i+1];
      }

      if ($dateUser > $curDate && $dateUser <= $nextDate)
      {
         $match_idx = $i;    # save the index
	 last;
       }
   }

   return $match_idx;

}




__END__


#modify array in place
my @a=(2,3,4,5);
foreach(@a)
{ $_ -= 1; }
print "a=",join(" ",@a),"\n";

