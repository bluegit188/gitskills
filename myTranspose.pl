#!/usr/bin/perl

use strict;

($#ARGV+2)==1 || die 
"Usage: myTranspose
        Transpose a matrix and print to screen\n";


my @dataRows = (<STDIN>) ;
my $ysize=$#dataRows+1;
#print "ysize=$ysize\n";

my @line;
my $row1=($dataRows[0]);
chomp($row1);
#print "row1=$row1\n";
@line =split(' ',$row1);
my $xsize=$#line+1;

# put data into matrix
my @matrix;
foreach my $j (0..$ysize-1)
{
   my $row=$dataRows[$j];
   chomp($row);
   my @lineNew=split(' ',$row);
   push(@matrix,@lineNew);
}

#print "xsize=$xsize, ysize=$ysize\n";
#print matrix transpose

foreach my $i (0..$xsize-1)
{
   my $strOut="";
   foreach my $j (0..$ysize-1)
   {
     my $x=$matrix[$j*$xsize+$i];
     #print "x=$x|\n";
     $strOut=$strOut."$x"." ";
     #print $x," ";
   }
   $strOut=~s/\s+$//; # remove trailing spaces

   print "$strOut\n";
}


