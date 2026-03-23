#!/usr/bin/perl

use strict;

(($#ARGV+2) ==2 || ($#ARGV+2) ==3) || die
"Usage: myFormatAuto.pl isHeader [opt:leftJustify=0]
       Format the output based on max width of each column
       Leftjustify: default=0, 1=left justify
       Output: formatted input\n";


my $isHeader=$ARGV[0];

my @lines;
my $ncols;

my %hash; # colNo-> array of Xs

my $isLeft=0;
if($#ARGV+2 ==3)
{
   $isLeft=$ARGV[1];
}


my @line;
my $count=0;
while(<STDIN>)
{
    chomp($_);
    @line =split;
    my $str=$_;
    push(@lines,$str);
    $ncols=$#line+1;

    $count++;

    foreach my $n (0..$#line)
    {
        my $colNo=$n+1;
        my $x=$line[$n];
        my $len=length($x);
        if( ! exists $hash{$colNo} ) # not in hash
        {
          $hash{$colNo}=$len;
        }
        else                               # date already in hash
        {
           my $len0=$hash{$colNo};
           # add new entry
	   if($len>$len0)
	   {
               $hash{$colNo}=$len;
           }
        }
    }

}
close(INFILE);

## create format str
#$len =$hash{$colNo};

for my $str (@lines)
{
    @line =split(' ',$str);

    $ncols=$#line+1;

    foreach my $n (0..$#line)
    {
        my $colNo=$n+1;
        my $x=$line[$n];
        my $len=$hash{$colNo}+1;

	if($isLeft)
	{
	  printf "%-${len}s",$x;
	}
	else
	{
	  printf "%${len}s",$x; 
	}

    }
    print "\n";

}


