#!/usr/bin/perl

use strict;

( ($#ARGV+2) ==2 || ($#ARGV+2) ==3 ) || die
"Usage: displayTradesFile.pl trades.txt [opt:flag:0/1/2]
       Display trades.txt file in a viewable format
       Falg: 0=all lines, 1=OK only, 2=NA only
       Split the input file into N equal size subsets\n";


my $filename=$ARGV[0];




my $OKOnly=0;

if(($#ARGV+2) ==3 )
{
  $OKOnly=$ARGV[1];
}

my $filter="SYM|";
if($OKOnly==1)
{
   $filter="SYM|OK";
}


if($OKOnly==2)
{
   $filter="SYM|NA\$";
}



    my $cmd="
cat $filename | sed -e \"s/[,|:]/\\ /g\"|myAddHeader.sh \"SYM trades fcstDM prevPos tgtPos tsDate tsTime flag tradeType\"|mygetcols.pl 1 3 4 2 5:9| myFormatAuto.pl 0  |egrep -E -e\"$filter\"";

  #  print "$cmd\n";
   system("$cmd");


__END__
cat $1 | sed -e "s/[,|:]/\ /g"|myAddHeader.sh "SYM trades fcstDM EODPos tgtPos tsDate tsTime flag"|mygetcols.pl 1 3 4 2 5:8| myFormatAuto.pl 0

