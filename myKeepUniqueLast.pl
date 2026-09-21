#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: myKeepUniqueLast.pl colKey colDate
       For given key(e.g, symbol), keep the row with largest date value\n";


# open file and put column specified into a hash
#my $filename=$ARGV[0];
#open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $colKey=$ARGV[0];
my $colDate=$ARGV[1];


my %dicts=(); # key -> line


my @uniqueSyms;

my @line;
my $prevSym="NA";
while(<STDIN>)
{

    #chomp the new line at the end
    # some lines has \r\n, replace by \n if any
    $_=~s/\r\n/\n/;

    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str = $_;

    my $curSym=$line[$colKey-1];
    my $curDate=$line[$colDate-1];

    if($curSym ne $prevSym)
    {
       push(@uniqueSyms,$curSym);
       #print "$curSym\n";
    }

    if(exists $dicts{$curSym})
    {
        my $tmpStr= $dicts{$curSym};
	@line =split(' ',$tmpStr);
	my $tmpDate=$line[$colDate-1];

	if($curDate >$tmpDate)
	{
  	   $dicts{$curSym}=$str;
        }
    }
    else
    {
      $dicts{$curSym}=$str;
    }

    $prevSym=$curSym;
}



foreach my $key (@uniqueSyms)
{
    my $str=$dicts{$key};
    print "$str\n";
}
