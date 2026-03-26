#!/usr/bin/perl

use strict;

(($#ARGV+2) ==3  ||  ($#ARGV+2) ==4 ) || die 
"Usage: get_prev_row.pl file.txt(header) n=1/2/3/.. [opt:adjHeader=0/1]
       Input: SYM DATE ...
       option: adjHeader=0 by default, 1=add .pre to the colNames
       Output(if n=1): SYM DATE .. SYM YEST..\n";



my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $n=$ARGV[1];


my $adjHeader=0;

if( ($#ARGV+2) ==4 )
{
 $adjHeader=$ARGV[2];
}


my @syms;
my @dates;
my @lines;

my @line;
my $header;
my $count=0;
while(<INFILE>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);

    if($count==1)
    {
      $header=$_;
      next;
    }


    @line =split;

    my $sym=$line[0];
    my $date=$line[1];
    my $str=$_;

    push(@syms,$sym);
    push(@dates,$date);
    push(@lines,$str);

}
close(INFILE);

my $headerPre=$header;

if($adjHeader==1)
{
  $headerPre=~s/\s+/.pre\ /g;
  $headerPre=~s/$/.pre/;
}

# header
print "$header $headerPre\n";


foreach my $i (0..$#dates)
{
    my $curSym=$syms[$i];
    my $curDate=$dates[$i];
    my $curStr=$lines[$i];

    my $startLoc=$i-$n;

    if($startLoc <0){next;}

    my $startSym=$syms[$startLoc];
    my $starDate=$dates[$startLoc];

    if($startSym ne $curSym ){next;}

    my $prevStr=$lines[$startLoc];
    print "$curStr $prevStr\n";

}
