#!/usr/bin/perl

use strict;

($#ARGV+2) ==2 || die 
"Usage: get_avg_hold.pl file.txt(header)
       Input: SYM DATE pos
       Compute holding length
       Output(if n=1): SYM DATE .. SYM YEST..\n";



my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";




my @syms;
my @dates;
my @positions;
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
    my $pos=$line[2];
    my $str=$_;

    push(@syms,$sym);
    push(@dates,$date);
    push(@lines,$str);
    push(@positions,$pos);
}
close(INFILE);



# header
print "$header length flag\n";

my $prevPos="NA";
my $count=0;
my $prevSym="NA";

my $flag="NA"; # new or old pos
foreach my $i (0..$#dates)
{
    my $curSym=$syms[$i];
    my $curDate=$dates[$i];
    my $curStr=$lines[$i];
    my $curPos=$positions[$i];



    if($curSym ne $prevSym )
    {

	 $count=0;
	 $flag="NEW";
	 if($curPos != 0)
	 {
	   $count=1;
	   $flag="NEW";
	 }

    }
    else
    {
       if($curPos *$prevPos > 0)
       {
	 $count++;
	 $flag="OLD";
       }
       else
       {
	 $count=0;
	 $flag="NEW";
	 if($curPos != 0)
	 {
	   $count=1;
	   $flag="NEW";
	 }
       }

    }

    print "$curSym $curDate $curPos $count $flag\n";


    $prevSym=$curSym;
    $prevPos=$curPos;

}
