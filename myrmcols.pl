#!/usr/bin/perl

use strict;

($#ARGV+2) >=2 || die 
"Usage: myrmcols.pl n1 n2 n3 5:7 ...\n";





my @n;
foreach my $i (0..$#ARGV)
{
  my $str=$ARGV[$i];
  my @tokens=split(':',$str);
  if($#tokens==0)
  {
    push(@n,$str);         # the n's
  }
  else
  {
     foreach my $k ( ($tokens[0])..($tokens[1]))
     {
       push(@n,$k);
     }
  }
}

#print join(" ", @n), "\n";

#build a hash from the array
my %hash;
foreach (@n)
{
    $hash{$_} = 1;
};



my @line;
my @n2; # the cols to keep
my $count=0;
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;

    if($count==1)
    {
         foreach my $j (1..$#line+1)
	 {
	   if( ! exists $hash{$j})
	   {
	     push(@n2,$j);
	   }
	 }

	 #print join(" ", @n2), "\n";
    }

    my $str;

    foreach my $j (0..$#n2)
    {
        my $k=$n2[$j];
        #print "k=$k\n";
        my $thisStr=$line[$k-1];
        $str=$str."$thisStr ";
    }
    #chomp $str;  # remove the last space
    # remove last space
    $str=~s/\s+$//;
    print "$str\n";

}


