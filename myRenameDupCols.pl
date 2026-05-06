#!/usr/bin/perl

use strict;

($#ARGV+2) ==2 || die 
"Usage: myRenameDupCols.pl isHeader
      Rename duplicate columns (isHeader must be 1)\n";


my $isHeader=$ARGV[0];


my %dicts=();

my $count=0;
my @line; 
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;
    $count++;

    my $str;


    if($count==1) # this is header line
    {
       foreach my $j (0..$#line)
       {
         my $colName=$line[$j];
	 my $colNum=$j+1;

         ## dup col names
         if(exists $dicts{$colName})
         {
              $line[$j]="$colName".".COL"."$colNum"; # assign new col name
         }
	 else
	 {
	   $dicts{$colName}=1;
	 }

	 my $thisStr=$line[$j];
         $str=$str."$thisStr ";
       }


       #chomp $str;  # remove the last space
       # remove last space
       $str=~s/\s+$//;
       print "$str\n";
    }
    else
    {
      print "$_\n";
    }
}


