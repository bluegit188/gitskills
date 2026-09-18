#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: myPositiveMonthsCount.pl isHeader=0/1 colRet
        Count the number of positive values in the column
        output: countPos countNeg totol countPos/total\n";


my $isHeader=$ARGV[0];
my $colRet=$ARGV[1];

my $count=0;
my @line; 

my $countTotal=0;
my $countPos=0;
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;
    my $ret = $line[$colRet-1];

    if($isHeader==1 && $count==1 ) # print header
    {
      #print "$str YYYYMM\n";
      next;
    }

    $countTotal+=1;
    if($ret> 0)
    {
      $countPos+=1; 
    }

}

print "countPos total countPosPct\n";
printf "$countPos $countTotal %.1f\%\n", $countPos/$countTotal*100;
