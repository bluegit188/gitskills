#!/usr/bin/perl

use strict;

($#ARGV+2) >=2 || die 
"Usage: mygetcols.pl n1 n2 n3 5:7 20:30:2 ...
       5:7 will produce 5 6 7
       20:30:2 will produce 20 22 24 26 28 30 in step=2\n";





my @n;
foreach my $i (0..$#ARGV)
{
  my $str=$ARGV[$i];
  my @tokens=split(':',$str);
  if($#tokens==0)
  {
    push(@n,$str);         # the n's
  }
  elsif($#tokens==1)
  {
     foreach my $k ( ($tokens[0])..($tokens[1]))
     {
       push(@n,$k);
     }
  }
  else # with step specified
  {
     my $step=$tokens[2];
     for (my $k= $tokens[0];$k<=$tokens[1];$k+=$step)
     {
       push(@n,$k);
     }
  }
}

#print join(" ", @n), "\n";



my @line; 
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;

    my $str;

    foreach my $j (0..$#n)
    {
        my $k=$n[$j];
        #print "k=$k\n";
        my $thisStr=$line[$k-1];
        $str=$str."$thisStr ";
    }
    #chomp $str;  # remove the last space
    # remove last space
    $str=~s/\s+$//;
    print "$str\n";

}


