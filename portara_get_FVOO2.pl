#!/usr/bin/perl

use strict;

($#ARGV+2) ==2 || die
"Usage: portara_get_FVOO2.pl SYM
       Compute FVOO2
       Output: SYM DATE FVOO2\n";


my $sym=$ARGV[0];

my $dir="/home/jgeng/RawData/portara/JunfCC/CCFixRTH/";
my $filename="$dir".$ARGV[0].".txt";
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

#1). reads in fixed RTH file
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
#print "std=$std\n";


#2). compute FVOO and ooP1Ds
my @ooP1Ds;
my @dates;
my @FVOOs;
my @GAPs; # raw GAPs
my @HILOs;  # raw HILOs

#0=today, 1=yest,
my @line0;
my @line1;
my $a=0.975;
my $ema0=$std;
my $ema=$ema0;

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

    my $OO=$open0-$open1;
    #   HILO=yest high - yest low
    my $HILO=($high1-$low1);

    #   GAP=open today - close yest
    my $GAP=($open0-$close1);
    my $AGAP=abs($GAP);

    #double $X=5;
    #if($AGAP> $X*$std){$AGAP= $X*$std;}
    #if($HILO> $X*$std){$HILO= $X*$std;}

    #HILOADJ=0.453*(HILO+1.17*AGAP)
    # 1.29 is to adjust FV such that sd(ooP1D)=1
    my $HILOADJ=(0.45*$HILO+0.55*$AGAP)*(1.29);

    $ema=$a*$ema+(1-$a)*$HILOADJ;

    #print "line=$lineStr0\n";
    #### printing

    my $ooP1D=$OO/$ema;
    if($ooP1D>3){$ooP1D=3;}
    if($ooP1D< -3){$ooP1D=-3;}
    push(@ooP1Ds,$ooP1D);
    push(@dates,$date0);

    push(@FVOOs,$ema);
    push(@GAPs,$GAP);
    push(@HILOs,$HILO);
}




#3). compute FVOO2

#header
print "SYM DATE FVOO2 FVOO\n";

#0=today, 1=yest,
my $a=0.85;
my $ema0=1;
my $ema=$ema0;

foreach my $i (1..$#allRows)
{

    my $lineStr0=$allRows[$i];

    @line0 =split(' ',$lineStr0); #' ' is correct to remove one or more white spaces

    #tc=trade counts
    my($date0,$open0,$high0,$low0,$close0,$tc0,$vol0,$oi0,$sym0,$ym0,$spd0,$cumSpd0)=@line0;


    my $HILO=$HILOs[$i-1];
    my $GAP=$GAPs[$i-1];
    my $FVOO=$FVOOs[$i-1];

    #scl by FVOO
    my $AGAP=abs($GAP)/$FVOO;
    my $HILO=abs($HILO)/$FVOO;


    if($AGAP> 7){$AGAP= 7;}
    if($HILO> 7){$HILO= 7;}

    #HILOADJ=0.453*(HILO+1.17*AGAP)
    # 1.29 is to adjust FV such that sd(ooP1D)=1
    my $HILOADJ=(0.45*$HILO+0.55*$AGAP)*(1.29);

    $ema=$a*$ema+(1-$a)*$HILOADJ;

    #print "line=$lineStr0\n";
    #### printing

    print "$sym0 $date0";
    printf " %.6f",$ema;
    printf " %.6f",$FVOO;
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


__END__


#modify array in place
my @a=(2,3,4,5);
foreach(@a)
{ $_ -= 1; }
print "a=",join(" ",@a),"\n";

