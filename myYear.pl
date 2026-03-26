#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: myYear.pl isHeader=0/1 colDate
        Find year of date\n";


my $isHeader=$ARGV[0];
my $colDate=$ARGV[1];

my $count=0;
my @line; 
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;
    my $date = $line[$colDate-1];

    if($isHeader==1 && $count==1 ) # print header
    {
      print "$str YEAR\n";
      next;
    }

    my $YYYY=int($date/10000);
    my $MMDD=$date%10000;
    my $MM=int($MMDD/100);
    my $DD=$MMDD%100;


    print "$_ $YYYY\n";
}
close(INFILE);
