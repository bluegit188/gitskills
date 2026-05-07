#!/usr/bin/perl

use strict;

use lib "/home/jgeng/bin";
use JunfeiUtil;


($#ARGV+2) ==5 || die 
"Usage: get_rolling_corr_fast.pl file(header) colX colY n_day(20)
       Compute rolling n-day corr. between X and Y.
       Input: SYM DATE.. x.. y..
       Output(:  .. corr\n";

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

my $colX=$ARGV[1];
my $colY=$ARGV[2];
my $n=$ARGV[3];


my @syms;
my @dates;
my @xs;
my @ys;
my @lines;

my $header;
my @line;
my $count=0;
while(<INFILE>)
{
    chomp($_);
    @line =split;
    my $str=$_;

    $count++;
    if($count==1)
    {
      $header=$str;
      next;
    }

    #chomp the new line at the end
    chomp($_);
    @line =split;

    my $sym=$line[0];
    my $date=$line[1];
    my $x=$line[$colX-1];
    my $y=$line[$colY-1];

    push(@syms,$sym);
    push(@dates,$date);
    push(@xs,$x);
    push(@ys,$y);
    push(@lines,$str);

}
close(INFILE);


# header
print "$header corrP${n}D\n";

my $xsum=0;
my $x2sum=0;
my $ysum=0;
my $y2sum=0;
my $xysum=0;


foreach my $i (($n-1)..$#xs)
{
    my $curSym=$syms[$i];
    my $curDate=$dates[$i];
    my $curStr=$lines[$i];
    my $curX=$xs[$i];
    my $curY=$ys[$i];

    my $startLoc=$i+1-$n;

    if($startLoc <0)
    {
      $xsum=0;
      $x2sum=0;
      $ysum=0;
      $y2sum=0;
      $xysum=0;
      next;
    }

    my $startSym=$syms[$startLoc];
    my $starDate=$dates[$startLoc];

    if($startSym ne $curSym )
    {
      next;
    }

    ### for below, valid std can be computed; but some case can reuse previous calculations
    #print "$curStr";
    # get std
    if($startLoc-1 >=0 && $syms[$startLoc-1] eq $curSym) # can use
    {
       my $oldX=$xs[$startLoc-1];
       my $oldY=$ys[$startLoc-1];

       $xsum=$xsum+$curX-$oldX;
       $x2sum=$x2sum+($curX*$curX)-($oldX*$oldX);
       $ysum=$ysum+$curY-$oldY;
       $y2sum=$y2sum+($curY*$curY)-($oldY*$oldY);
       $xysum=$xysum+($curX*$curY)-($oldX*$oldY);

    }
    else # need to compute std bruteforece
    {
      $xsum=0;
      $x2sum=0;
      $ysum=0;
      $y2sum=0;
      $xysum=0;

      for (my $j=$startLoc;$j<=$i;$j++)
      {
	my $x=$xs[$j];
	my $y=$ys[$j];
	$xsum+=$x;
	$x2sum+=($x*$x);
	$ysum+=$y;
	$y2sum+=($y*$y);
	$xysum+=$x*$y;

      }
    }
    #my $std=sqrt( ($x2sum-$xsum*$xsum/$n)/($n-1) );
    #my $mean=get_mean(\@tmpXs);
    #my $std=get_std(\@tmpXs);

    my $dx=0;
    my $a=$n*$x2sum-$xsum*$xsum;
    if($a>0)
    {
      $dx=sqrt($a);
    }
    my $dy=0;
    my $b=$n*$y2sum-$ysum*$ysum;
    if($b>0)
    {
      $dy=sqrt($b);
    }
    my $corr=0;
    if($dx !=0 && $dy != 0)
    {
      $corr=($n*$xysum - $xsum*$ysum)/($dx*$dy);
    }
    printf "$curStr %.6f\n",$corr;



}


__END__


my @y = 0..5;
print join(' ',@y),"\n";
my $y = pdl @y;
# a simple function
my $stdv = $y->stdv_unbiased ;
print "std=$stdv\n";

see here:

http://pdl-stats.sourceforge.net/Basic.htm#stdv
