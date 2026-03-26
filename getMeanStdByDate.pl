#!/usr/bin/perl

use strict;



($#ARGV+2) ==5 || die 
"Usage: getMeanStdByDate.pl file.txt isHeader colDate colX
       Compute mean/std/min/max for each key
       Output: Date min max mean std count\n";

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

my $isHeader=$ARGV[1];

my $colDate=$ARGV[2];
my $colX=$ARGV[3];

my %hash; # date-> array of Xs

my @line;
my $count=0;
while(<INFILE>)
{
    chomp($_);
    @line =split;
    my $str=$_;

    $count++;
    if($count==1 && $isHeader==1)
    {
      #$header=$str;
      next;
    }


    #chomp the new line at the end
    chomp($_);
    @line =split;

    my $curDate=$line[$colDate-1];
    my $x=$line[$colX-1];

      if( ! exists $hash{$curDate} ) # not in hash
      {
          my @curDateArray;
          push(@curDateArray,$x);
          $hash{$curDate}=\@curDateArray;
       }
       else                               # date already in hash
       {
           my $refCurDateArray=$hash{$curDate};
           # add new entry
           push(@$refCurDateArray,$x);
       }


}
close(INFILE);


my @sortedDates=sort keys %hash;
#print join("\n",@sortedDates),"\n";


foreach my $curDate (@sortedDates)
{
   my $refArray=$hash{$curDate};

   my ($min, $max,$mean,$std,$count)=get_min_max_mean_std($refArray);
   print "$curDate $min $max $mean $std $count\n";
}



sub get_min_max_mean_std
#one pass:
# input a ref to an arry of Xs
# return: min max mean std count
{
   my ($refX ) = @_;
   my $count=$#$refX+1;


   my $inf = 9**9**9;
   my $neginf = -9**9**9;


   my $min=$inf;
   my $max=$neginf;
   my $mean;
   my $std;

   if($count<1) # empty
   {
     return (0,0,0,0,0);
   }

   #print "count=$count\n";
   my $xsum=0;
   my $x2sum=0;
   foreach my $x (@$refX)
   {
     $xsum+=$x;
     $x2sum+=($x*$x);

     if($x<$min){$min=$x;}

     if($x>$max){$max=$x;}

   }
   my $var=0; # if only one ob
   if($count >1)
   {
     $var=($x2sum-$xsum*$xsum/$count)/($count-1);
   }
   $std=0;
   if($var >=0)
   {
     $std=sqrt($var);
   }
   $mean=$xsum/$count;

   return ($min,$max,$mean,$std,$count);
}
