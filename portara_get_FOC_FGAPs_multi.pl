#!/usr/bin/perl

use File::Basename;
use strict;


my $DEBUG=0;

($#ARGV+2)==2 || die
"Usage: portara_get_FOC_FGAPs_multi.pl list_sym
       Compute ooF1D and FOC/FGAP rets
       Output: SYM DATE ooF1D FOC FGAP\n";

my $filename=$ARGV[0]; # portara text file


    my $cmd1="
#cmd:
portara_get_ooRets_multi.pl $filename  1|mygetcols.pl 1 2 3 >/tmp/ooF1Ds.txt
portara_get_ooRets_multi.pl $filename 16|mygetcols.pl 1 2 3 >/tmp/FOCs.txt
portara_get_ooRets_multi.pl $filename 17|mygetcols.pl 1 2 3 >/tmp/FGAPs.txt
combine_match2.pl /tmp/ooF1Ds.txt /tmp/FOCs.txt >/tmp/a1
combine_match2.pl /tmp/a1 /tmp/FGAPs.txt >/tmp/a2
cat /tmp/a2|mygetcols.pl 1 2 3 6 9
";
   # print "$cmd1\n";
    system("$cmd1");










__END__


--cmd:
time cat /mnt/wbox1/portara/Futures/Continuous\ Contracts/Intraday\ Database/1\ Minute\ 24Hr/EU.001 | sed s/,/\ /g|fgrep -v DATE|gawk '{if($1>=20150115 && $1<=20150115){print $1,$2,$7}}' > /tmp/tmpVol.txt
# 35 sec
cat /tmp/tmpVol.txt|myPortaraAddMissingMinutes.pl 1 2 3|mygetcols.pl 1 2 6 >/tmp/tmpVolNorm.txt 
timesXmgr.pl /tmp/tmpVolNorm.txt 2 0|mygetcols.pl 1 4 2 3  >/tmp/tmpForplot.txt
xmgrByTime /tmp/tmpForplot.txt&


