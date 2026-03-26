#!/usr/bin/perl

use strict;

($#ARGV+2) ==3 || die
"Usage: getstats_fast.pl file.txt isHeader
       Compute simple stats for each column
       Output: xName min max mean std\n";

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $isHeader=$ARGV[1];
my $colX=$ARGV[2];


my @xs;
my @xNames;
my $ncols;

my %hash; # colNo-> array of Xs


my @line;
my $count=0;
while(<INFILE>)
{
    chomp($_);
    @line =split;
    my $str=$_;
    $ncols=$#line+1;

    $count++;
    if($isHeader && $count==1)
    {
       foreach my $j (@line)
       {
         push(@xNames,$j);
       }
       next;

    }

    foreach my $n (0..$#line)
    {
        my $colNo=$n+1;
        my $x=$line[$n];

       if( ! exists $hash{$colNo} ) # not in hash
       {
          my @tmpArray;
          push(@tmpArray,$x);
          $hash{$colNo}=\@tmpArray;
       }
       else                               # date already in hash
       {
           my $refTmpArray=$hash{$colNo};
           # add new entry
           push(@$refTmpArray,$x);
       }

    }


}
close(INFILE);

## loop each col and output
print "colName min max mean std count\n";
foreach my $n (1..$ncols)
{
    my $colNo=$n;
    my $colName="Col"."$colNo";
    if($isHeader)
    {  
       $colName=$xNames[$n-1];
    }

    my $refTmpArray=$hash{$colNo};
    my ($min,$max,$mean,$std,$count2)=get_min_max_mean_std($refTmpArray);
    printf "$colName %.7f %.7f %.7f %.7f $count2\n",$min,$max,$mean,$std;
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
   if($var>0)
   {
     $std=sqrt($var);
   }
   $mean=$xsum/$count;

   return ($min,$max,$mean,$std,$count);
}


__END__


my @y = 0..5;
print join(' ',@y),"\n";
my $y = pdl @y;
# a simple function
my $stdv = $y->stdv_unbiased ;
print "std=$stdv\n";

see here:

http://pdl-stats.sourceforge.net/Basic.htm#stdv
