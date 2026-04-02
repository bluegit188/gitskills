#!/usr/bin/perl

use strict;
use Text::CSV;

( ($#ARGV+2) ==3 || ($#ARGV+2) ==4  ) || die 
"   Usage: convertCsvToText.pl file.csv deliminator=0/1/2/3 [opt: collapseSpace=0/1]
           Assumes input csv file is space removed,
           convert into either space or tab delimiated txt file.
           deliminator: default 0=tab, 1=space, 2=|, 3=,
           CollapSpace: 1=remove space in header, 0=keep as is
           Fill in NA for empty field\n";


my $fileCsv=$ARGV[0];
open(INFILE, "$fileCsv") || die "Couldn't open $fileCsv: $!\n";


my $delOpt=$ARGV[1];
my $delStr='\t';

if($delOpt == 0)
{
  $delStr='\t';
} 
elsif($delOpt == 1)
{
  $delStr=' ';
} 
elsif($delOpt == 2)
{
  $delStr='|';
}
elsif($delOpt == 3)
{
  $delStr=',';
}
else 
{
  $delStr='\t';
}


my $isCollapse=0;
if( ($#ARGV+2) ==4  )
{
  $isCollapse=$ARGV[2];
}

my $csv = Text::CSV->new ({
binary => 1,
auto_diag => 1,
sep_char => ',' # not really needed as this is the default
});


my $sum = 0;
open(my $data, '<:encoding(utf8)', $fileCsv) or die "Could not open '$fileCsv' $!\n";

my $count=0;
my $NAStr="NA";
# use this to skip header if needed
#  $csv->getline ($fh); # skip header
while (my $fields = $csv->getline( $data )) # ret value is ref to fields
{
    $count++;

    #print "count=$count |",$fields->[0],"\n";
    my @strsArray;
    foreach my $j (0..$#$fields)
    {
        my $thisStr=$fields->[$j];

	if( $isCollapse== 1 && $count==1) # remove space in header
	{
	  $thisStr=~s/\s//g;
	}

	#print "thisStr=$thisStr|\n";
	if($thisStr eq "")
	{
	  $thisStr=$NAStr;
	  #print "NA thisStr=$thisStr|\n";
	}
        push(@strsArray,$thisStr);
    }
    #my $strOut=join('\t',@strsArray);
    #print "strOut=$strOut|\n";
    #chomp $strOut;  # remove the last space
    #print "$strOut|\n";

    local $" = "\t"; #reset separator for array printing
    if($delOpt !=0)
    {
      $" = $delStr;
    }
    print "@strsArray","\n",
    #print join('\t',@strsArray),"|\n";
}
if (not $csv->eof) 
{
  $csv->error_diag();
}
close $data;


__END__


    foreach my $j (0..$#n)
    {
        my $k=$n[$j];
        my $thisStr=$line[$k-1];
        $str=$str."$thisStr"." ";
    }
    chomp $str;  # remove the last space
    print "$str\n";

}
close(INFILE);

