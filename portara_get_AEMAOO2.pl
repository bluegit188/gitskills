#!/usr/bin/perl

use strict;

($#ARGV+2) ==2 || die
"Usage: portara_get_AEMAOO2.pl SYM
       Compute AEMAOO
       Output: SYM DATE EMAOO2 AEMAOO2
       Add rth files loc:
	config.txt 
	RTH_DIR = /home/jgeng/notebooks/portara_1min_to_daily_rth/CCFixRTH

       Output: SYM DATE ooP1D(normed) FV\n";\n";


my $sym=$ARGV[0];

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
#0=today, 1=yest,
my @line0;
my @line1;
#my $a=0.975;

my $a=0.915;
    
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

}




#3). compute AEMAOO

#header
print "SYM DATE EMAOO AEMAOO\n";


my $a=0.75;

my $ema=$ema0;

foreach my $i (21..$#dates)
{

   my $curDate=$dates[$i];

   my $startLoc=$i+1-22;

   my $emaoo=0;
   my $count=0;
   for (my $j=$i-2;$j>=$startLoc;$j--)
   {
       my $curOOP1D=$ooP1Ds[$j];
       $emaoo+=$curOOP1D*($a**$count);
       $count++;
   }

   $emaoo*=(1-$a);

   my $AEMAOO=abs($emaoo);
   if($AEMAOO> 1.2){$AEMAOO=1.2;}

    #### printing
    print "$sym $curDate";
    printf " %.6f",$emaoo;
    printf " %.6f",$AEMAOO;
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

