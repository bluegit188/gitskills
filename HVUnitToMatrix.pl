#!/usr/bin/perl

use strict;

($#ARGV+2) ==6 || die 
"Usage: HVUnitToMatrix.pl file.txt isHeader colSYM colDate colX
       Input:
SYM DATE X
AA  1  0.1
AA  2  0.2
BB  2  0.2
BB  3  0.3
BB  4  0.4
CC  2  0.1
CC  3  0.2
CC  4  0.3
CC  5  0.4
       Output:
DATE X.AA X.BB X.CC
1    0.1  NA   NA
2    0.2  0.2  0.1
3    NA   0.3  0.2
4    NA   0.4  0.3
5    NA   NA   0.4\n";



my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

my $isHeader=$ARGV[1];

my $colSym=$ARGV[2];
my $colDate=$ARGV[3];
my $colX=$ARGV[4];



my %hash1; # date-> 1
my %hash2; # sym-> 1
my %hash3; # sym:date -> value



my $xName="X";
my @line;
my $count=0;
while(<INFILE>)
{
    chomp($_);
    @line =split;
    my $str=$_;


    #chomp the new line at the end
    chomp($_);
    @line =split;


    $count++;
    if($count==1 && $isHeader==1)
    {
      #$header=$str;
      $xName=$line[$colX-1];
      next;
    }


    my $curDate=$line[$colDate-1];
    my $sym=$line[$colSym-1];
    my $x=$line[$colX-1];

    my $key="$sym:$curDate";

    $hash1{$curDate}=1;
    $hash2{$sym}=1;
    $hash3{$key}=$x;


}
close(INFILE);


my @sortedDates=sort keys %hash1;
#print join("\n",@sortedDates),"\n";


my @sortedSyms=sort keys %hash2;
#print join("\n",@sortedSyms),"\n";



## create matrix by loop over date and sym

#header
print "DATE";
foreach my $curSym (@sortedSyms)
{
  print " $xName.$curSym";
}
print "\n";
#body
foreach my $curDate (@sortedDates)
{
    print "$curDate";
    foreach my $curSym (@sortedSyms)
    {

       my $key="$curSym:$curDate";

       my $val="NA";
       if( exists $hash3{$key} ) # not in hash2
       {
          $val=$hash3{$key};
       }

       print " $val";
    }
    print "\n";
}




