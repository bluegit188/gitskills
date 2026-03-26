#!/usr/bin/perl

use strict;

($#ARGV+2)==5 || die 
"Usage: myConstraintSimpleNew.pl isHeader colX min max
       Constraint X in place between min and max\n";

my $isHeader=$ARGV[0];

my $colX=$ARGV[1];

my $min=$ARGV[2];
my $max=$ARGV[3];


my $count=0;
my @line;
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    $count++;
    my $str=$_;


    if($count==1 && $isHeader==1)
    {
      print "$str\n";
      next;
    }


    @line =split;
    my $x = $line[$colX-1];
    if($x>$max)
    {
      $x=$max;
    }
    elsif ($x<$min)
    {
      $x=$min;
    }
    else
    {
      $x=$x;
    }
    $line[$colX-1]=$x;
    print join(" ",@line),"\n";

}
close(INFILE);

