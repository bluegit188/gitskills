#!/usr/bin/perl

use File::Basename;
use strict;


my $DEBUG=0;

(($#ARGV+2)==7 || ($#ARGV+2)==9 ) || die
"Usage: portara_plot_rolling_corr_by_sym_easy.pl xSYM ySYM xRetType yRetType window xFlag=A/U/D [opt: startDate endDate]
       x/y retType: same as the types in portara_get_ooRets.pl
       xFlag: A=all, U=up, D=down
       Plot rolling correlations for x and y for a given symbol\n";



my $sym=$ARGV[0];
my $symy=$ARGV[1];

my $xType=$ARGV[2];
my $yType=$ARGV[3];

my $window=$ARGV[4];


my $xFlag=$ARGV[5];


my $startDate=0;
my $endDate=99990101;

if(($#ARGV+2)==9)
{
    $startDate=$ARGV[6];
    $endDate=$ARGV[7];
}


    my $cmd="
portara_get_ooRets.pl $symy $yType |mygetcols.pl 2 1 3 > /tmp/yvar.txt
portara_get_ooRets.pl $sym $xType |mygetcols.pl 2 1 3 > /tmp/xvar.txt
combine_match1.pl /tmp/yvar.txt /tmp/xvar.txt|mygetcols.pl 2 1 3 6 |myRmOutliersSimple.pl 1 2 $startDate $endDate 1 > /tmp/tmp_Y_X.txt
";
  system("$cmd");

  my $cmd2="cp /tmp/tmp_Y_X.txt /tmp/tmp_Y_X.txt.2";
  if($xFlag eq "U")
  {
     $cmd2="cat /tmp/tmp_Y_X.txt|gawk '{if(NR==1){print \$0}else{if(\$4> 0){print \$0}else{print \$1,\$2,\$3,\"0\"}}}' > /tmp/tmp_Y_X.txt.2";
  }
  if($xFlag eq "D")
  {
     $cmd2="cat /tmp/tmp_Y_X.txt|gawk '{if(NR==1){print \$0}else{if(\$4< 0){print \$0}else{print \$1,\$2,\$3,\"0\"}}}' > /tmp/tmp_Y_X.txt.2";
  }
  system("$cmd2");


    my $cmd3="
get_rolling_corr_fast.pl  /tmp/tmp_Y_X.txt.2 4 3 $window > /tmp/tmp_corr.txt
datesXmgr.pl /tmp/tmp_corr.txt 2|fgrep -v DATE|mygetcols.pl 1 6 2 3 >/tmp/tmp_forplot
cat /tmp/tmp_corr.txt |head -1|myrmcols.pl 1 2 | sed s/\\ /~/ | sed s/\\ /\\./|gawk '{print \"title \\\"$symy~$sym:\",\$0\".$xFlag\\\"\"}' > /tmp/title.txt
xmgrByDateGrid  -batch /tmp/title.txt /tmp/tmp_forplot&
#full sample corr:
get_corr_matrix_R.pl /tmp/tmp_Y_X.txt.2 2 > /tmp/bb
cat tmp_correlation.txt |myFormatAuto.pl 1
";

    #print "$cmd3\n";
    system("$cmd3");



__END__

portara_get_ooRets.pl ES 1 |mygetcols.pl 1 2 3 > /tmp/yvar.txt
portara_get_ooRets.pl ES 0 |mygetcols.pl 1 2 3 > /tmp/xvar.txt
combine_match2.pl /tmp/yvar.txt /tmp/xvar.txt|mygetcols.pl 1 2 3 6 > /tmp/tmp_Y_X.txt
get_rolling_corr_fast.pl  /tmp/tmp_Y_X.txt 4 3 252 > /tmp/tmp_corr.txt
datesXmgr.pl /tmp/tmp_corr.txt 2|fgrep -v DATE|mygetcols.pl 1 6 2 3 >/tmp/tmp_forplot

cat /tmp/tmp_corr.txt |head -1|myrmcols.pl 1 2 | sed s/\ /~/ | sed s/\ /\./|gawk '{print "title \"ES:",$0"\""}' > /tmp/title.txt

xmgrByDateGrid  -batch /tmp/title.txt /tmp/tmp_forplot&







cat /home/jgeng/RawData/portara/JunfCC/CCFixRTH/ES.txt |gawk '{print $1,$5-$12}' > /tmp/c.txt

datesXmgr.pl /tmp/c.txt 1 |mygetcols.pl 1 3 2 > /tmp/c.txt.plot
xmgrByDate /tmp/c.txt.plot






--cmd:
time cat /mnt/wbox1/portara/Futures/Continuous\ Contracts/Intraday\ Database/1\ Minute\ 24Hr/EU.001 | sed s/,/\ /g|fgrep -v DATE|gawk '{if($1>=20150115 && $1<=20150115){print $1,$2,$7}}' > /tmp/tmpVol.txt
# 35 sec
cat /tmp/tmpVol.txt|myPortaraAddMissingMinutes.pl 1 2 3|mygetcols.pl 1 2 6 >/tmp/tmpVolNorm.txt 
timesXmgr.pl /tmp/tmpVolNorm.txt 2 0|mygetcols.pl 1 4 2 3  >/tmp/tmpForplot.txt
xmgrByTime /tmp/tmpForplot.txt&


