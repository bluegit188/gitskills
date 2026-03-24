#!/usr/bin/perl

use strict;

( ($#ARGV+2)==2 ||($#ARGV+2)==3 ) || die 
"Usage: myShiftDateRowToFirstRow.pl colDate [optStr]
       Shift row with DATE to first row.
       Optinally, can shift row with optStr,e g, SYM to first row\n";

my $colDate=$ARGV[0];

my $dateStr="DATE";

if( ($#ARGV+2)==3 )
{
  $dateStr=$ARGV[1];
}

my @lines;
my @line;
my $headerRow="NA";
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    my $str=$_;
    @line =split;
    my $curDateStr = $line[$colDate-1];

    if($curDateStr eq $dateStr)
    {
      $headerRow=$str;
      next;
    }
    push(@lines,$str);
}

#header
print "$headerRow\n";
foreach my $item (@lines)
{
    print "$item\n";
}
