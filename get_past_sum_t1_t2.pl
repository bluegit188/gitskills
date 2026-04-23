#!/usr/bin/perl

use strict;

use lib "/home/jgeng/bin";
use JunfeiUtil;


($#ARGV+2) ==5 || die 
"Usage: get_past_sum_t1_t2 file.txt(header) colX t1=1 t2=21
        Compute rolling sum from t2 days ago to t1 days ago. For example, t1=1,t2=21 is ooP21D
        Input: SYM DATE.. x(t)..
        Output(:  .. sum.t1Tt2\n";

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

my $colX=$ARGV[1];
my $t1=$ARGV[2];
my $t2=$ARGV[3];


my @syms;
my @dates;
my @xs;
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

    push(@syms,$sym);
    push(@dates,$date);
    push(@xs,$x);
    push(@lines,$str);

}
close(INFILE);


# header
print "$header sum.${t1}t${t2}\n";

my $xsum=0;


my $n=$t2;

foreach my $i (($n-1)..$#xs)
{
    my $curSym=$syms[$i];
    my $curDate=$dates[$i];
    my $curStr=$lines[$i];
    my $curX=$xs[$i];

    my $startLoc=$i+1-$n;

    my $endLoc=$i+1-$t1;

    my $curXEnd=$xs[$endLoc];

    if($startLoc <0)
    {
      $xsum=0;
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

       $xsum=$xsum+$curXEnd-$oldX;
    }
    else # need to compute std bruteforece
    {
      $xsum=0;
      for (my $j=$startLoc;$j<=$endLoc;$j++)
      {
	my $x=$xs[$j];
	$xsum+=$x;
      }
    }
    #my $std=sqrt( ($x2sum-$xsum*$xsum/$n)/($n-1) );

    #my $mean=get_mean(\@tmpXs);
    #my $std=get_std(\@tmpXs);

    printf "$curStr %.7f\n",$xsum;



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
