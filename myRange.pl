#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: myRange.pl isHeader=0/1 colX
        Find min and max of the Xs\n";


my $isHeader=$ARGV[0];
my $colX=$ARGV[1];

my $inf = 9**9**9;
my $neginf = -9**9**9;

my $min=$inf;
my $max=$neginf;

my $colXName="NA";
if($isHeader==0)
{
   $colXName="col#"."$colX";
}

my $count=0;
my @line; 
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;
    my $x = $line[$colX-1];

    if($isHeader==1 && $count==1 ) # print header
    {
      #print "$str MOY\n";
      $colXName=$x;
      next;
    }

     if($x<$min){$min=$x;}

     if($x>$max){$max=$x;}


}

print "$colXName: min= $min max= $max\n";
