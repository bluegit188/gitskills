#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: myKeepUniqueFirstAndLast.pl colKey colDate
       For given key(e.g, symbol), keep the row with smallest and largest date value; output on the same row: left=small right=big\n";


# open file and put column specified into a hash
#my $filename=$ARGV[0];
#open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $colKey=$ARGV[0];
my $colDate=$ARGV[1];


my %dicts=(); # key -> line # smallest
my %dicts2=(); # key -> line # largest



my @uniqueSyms;

my @line;
my $prevSym="NA";
while(<STDIN>)
{
    #chomp the new line at the end
    # some lines has \r\n, replace by \n if any
    $_=~s/\r\n/\n/;
    chomp($_);
    @line =split;
    my $str = $_;

    my $curSym=$line[$colKey-1];
    my $curDate=$line[$colDate-1];

    #print "key=$curSym date= $curDate\n";

    if($curSym ne $prevSym)
    {
       push(@uniqueSyms,$curSym);
       #print "$curSym\n";
    }

    ## smallest
    if(exists $dicts{$curSym})
    {
        my $tmpStr= $dicts{$curSym};
	@line =split(/ /,$tmpStr);
	my $tmpDate=$line[$colDate-1];
	#print "tmpDate=$tmpDate\n";

	if($curDate < $tmpDate)
	{
  	   $dicts{$curSym}=$str;
        }
    }
    else
    {
      $dicts{$curSym}=$str;
    }



    ## largest
    if(exists $dicts2{$curSym})
    {
        my $tmpStr= $dicts2{$curSym};
	@line =split(/ /,$tmpStr);
	my $tmpDate=$line[$colDate-1];
	#print "tmpDate=$tmpDate\n";

	if($curDate > $tmpDate)
	{
  	   $dicts2{$curSym}=$str;
        }
    }
    else
    {
      $dicts2{$curSym}=$str;
    }



    $prevSym=$curSym;
}


#print join(" ", sort keys %dicts),"\n";
#print join(" ", sort keys %dicts2),"\n";
#print join(" ", @uniqueSyms),"\n";


foreach my $key (@uniqueSyms)
{
    my $str="NA";
#=$dicts{$key};
    my $str2="NA";
#=$dicts2{$key};

    if(exists $dicts{$key})
    {
      $str =$dicts{$key};
    }

    if(exists $dicts2{$key})
    {
      $str2 =$dicts2{$key};
    }


    #print "key=$key|\n";
    #print "str=$str|\n";
    #print "str2=$str2|\n";
    #print "key=$key str=$str |str2=$str2\n";
    print "$str | $str2\n";
}
