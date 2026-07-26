#!/usr/bin/perl

use File::Basename;
use strict;


my $DEBUG=0;

($#ARGV+2)==2 || die
"Usage: onemin_24hr_ooF1D_ex5_2hr_v2_multi.pl list_sym.txt
       Compute ooF1DEx5min
       Output: SYM DATE ooDif FVOO\n";

my $filename=$ARGV[0]; # portara text file

#header
print "DATE SYM TIME ivl isOpenMin oT cT open close lastPrice cumAdj FVOO nextOpen GAP YOC ooP1D YHC YLC YMC YHL PL2C PL2NO PL2NC PLCO PL2NOEx1 PL2NOEx2 PL2NOEx5 PL2NOEx10 PL2NOEx15 PL2NOEx30 PL2NOEx45 PL2NOEx60 PL2NOEx90 PL2NOEx120 F1M F2M F5M F10M F15M F30M F45M F60M F90M F120M CHGSO1M CHGSO2M CHGSO5M CHGSO10M CHGSO15M CHGSO30M CHGSO45M CHGSO60M CHGSO90M CHGSO120M HSO1M HSO2M HSO5M HSO10M HSO15M HSO30M HSO45M HSO60M HSO90M HSO120M LSO1M LSO2M LSO5M LSO10M LSO15M LSO30M LSO45M LSO60M LSO90M LSO120M THC TLC TOC\n";

open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

my @line; 
while(<INFILE>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;

    my $sym=$line[0];
    my $cmd1="
    onemin_24hr_ooF1D_ex5_2hr_v2 $sym|fgrep -v DATE
";
   # print "$cmd1\n";
    system("$cmd1");


}
close(INFILE);









__END__


--cmd:
time cat /mnt/wbox1/portara/Futures/Continuous\ Contracts/Intraday\ Database/1\ Minute\ 24Hr/EU.001 | sed s/,/\ /g|fgrep -v DATE|gawk '{if($1>=20150115 && $1<=20150115){print $1,$2,$7}}' > /tmp/tmpVol.txt
# 35 sec
cat /tmp/tmpVol.txt|myPortaraAddMissingMinutes.pl 1 2 3|mygetcols.pl 1 2 6 >/tmp/tmpVolNorm.txt 
timesXmgr.pl /tmp/tmpVolNorm.txt 2 0|mygetcols.pl 1 4 2 3  >/tmp/tmpForplot.txt
xmgrByTime /tmp/tmpForplot.txt&


