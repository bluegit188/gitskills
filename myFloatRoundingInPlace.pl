#!/usr/bin/perl

use strict;

($#ARGV+2)==4 || die 
"Usage: myFloatRoundingInPlace.pl isHeader colX numDigits
       Make given column value rounded to n digits after decimal points\n";


my $isHeader=$ARGV[0];

my $colX=$ARGV[1];

my $N=$ARGV[2];


my $count=0;
my @line;
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    $count++;
    my $str=$_;

    if($isHeader && $count==1)
    {
      print "$str\n";
      next;
    }


    @line =split;
    my $x = $line[$colX-1];

    $line[$colX-1]=sprintf("%.${N}f",$x);

    print join(" ",@line),"\n";

}
close(INFILE);

