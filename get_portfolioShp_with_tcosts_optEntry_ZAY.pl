#!/usr/bin/perl

use strict;

($#ARGV+2)==9 || die 
"Usage: get_portfolioShp_with_tcosts_optEntry_ZAY.pl file.txt colSym colDate colY colFcst sizeX sizeY tcost(0.02)
       Compute porfolio shp and per commodity shp assuming linear tcost: use optZAY method
       For optZAY, when decreasing in same direction, use sizeY as opposed to sizeX as in optZA \n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];

my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colY=$ARGV[3];
my $colFcst=$ARGV[4];

my $entry=$ARGV[5]; # sizeX
my $exit=$ARGV[6];  # sizeY
my $tcost=$ARGV[7];

 my $cmd0="
head -1 $filename |mygetcols.pl $colFcst
";
 my $res0=`$cmd0`;
 chomp($res0);
my $indName=$res0;



 my $cmd0a="
head -1 $filename |wc|mygetcols.pl 2
";
 my $res0a=`$cmd0a`;
 chomp($res0a);
my $numCols=$res0a;

my $colFcstNet= $numCols+1; # relative to rawinput file cols


my $colPL= $numCols+3;

# used after  myAfterTcostPnl_naive.pl input always has 4 cols only: DATE SYM ooF1D fcstNet
my $colNet=7;
my $colGross=6;

### netShps
print "Portfolio shp(netZAY): file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1="
cat $filename |myFcstSubtractTcostNew_optZAY_general.pl 1 $colSym $colDate $colFcst $entry $exit|mygetcols.pl $colSym $colDate $colY $colFcstNet > $filename.fcstNetZAY
cat $filename.fcstNetZAY | myAfterTcostPnl_naive.pl 1 1 2 3 4 $tcost |fgrep -v DATE|mygetcols.pl 2 1 $colNet | myAddHeader.sh \"DATE SYM PL\" >pls.txt.$indName.netZAY
compute_fcst_turnover.pl $filename.fcstNetZAY 4 |gawk '{print \"netZAYTover:\",\$0}'
compute_fcst_unit_turnover.pl $filename.fcstNetZAY 4 |gawk '{print \"netZAYUtover:\",\$0}'
get_avg_hold_easy.pl $filename.fcstNetZAY 1 2 4 20 |gawk '{print \"netZAYAvgHold:\",\$0}'


";
 #print "$cmd1\n";
   system("$cmd1");
my $pplFile="ppls.txt.$indName.netZAY";
my $nPcShp;
compute_shps_return_pcShp("pls.txt.$indName.netZAY", $pplFile,\$nPcShp);
#print "nPcShp=$nPcShp\n";


## gross shps
print " ### Gross shps(grossZAY) ###: file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1="
cat $filename.fcstNetZAY | myAfterTcostPnl_naive.pl 1 1 2 3 4 $tcost |fgrep -v DATE|mygetcols.pl 2 1 $colGross | myAddHeader.sh \"DATE SYM PL\" >pls.txt.$indName.grossZAY
";
# print "$cmd1\n";
   system("$cmd1");
$pplFile="ppls.txt.$indName.grossZAY";

my $gPcShp;
compute_shps_return_pcShp("pls.txt.$indName.grossZAY", $pplFile,\$gPcShp);
#print "gPcShp=$gPcShp\n";
#pcSlip
my $pcSlip=$nPcShp-$gPcShp;
print "pcSlip = $pcSlip nPcShp = $nPcShp gPcShp = $gPcShp\n";





## pos and neg fcsts gross shp
print "\n\n ### Gross shps(grossZAY) +ive fcsts ###: file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1="
cat $filename.fcstNetZAY |myRmOutliersSimple.pl 1 4 0.00001 100000 1 |gawk '{if(NR==1){print \$0,\"pnl\"}else{print \$0,\$3*\$4}}' >tmp_data_pos
getstats_fast.pl tmp_data_pos 1|myStatsToShp.sh
";
# print "$cmd1\n";
   system("$cmd1");

print " ### Gross shps(grossZAY) -ive fcsts ###: file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1n="
cat $filename.fcstNetZAY |myRmOutliersSimple.pl 1 4 -100000 -0.00001 1 |gawk '{if(NR==1){print \$0,\"pnl\"}else{print \$0,\$3*\$4}}' >tmp_data_neg
getstats_fast.pl tmp_data_neg 1|myStatsToShp.sh
";
# print "$cmd1n\n";
   system("$cmd1n");

print " ### Gross shps(grossZAY) zero fcsts ###: file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1n="
cat $filename.fcstNetZAY |myRmOutliersSimple.pl 1 4 -0.00001 0.00001 1 |gawk '{if(NR==1){print \$0,\"pnl\"}else{print \$0,\$3*\$4}}' >tmp_data_zero
getstats_fast.pl tmp_data_zero 1|myStatsToShp.sh
";
# print "$cmd1n\n";
   system("$cmd1n");




sub compute_shps()
#input:
#      pnlFile: DATE SYM PL
#output: pplFile name
{
    my ($pnlFile, $pplFile) = @_;

    my $cmd2="
#pcShp
getstat_fast.pl $pnlFile 1 3|fgrep -v std|gawk '{print \$0,\$4/\$5,\$4/\$5*sqrt(252) }'|myAddHeader.sh \"colName   min   max   mean    std    count   shp   shp.pa\"|gawk '{print \"pcShp= \",\$0}' >tmp_pcShp.txt
 #portShp
getMeanStdByDate.pl $pnlFile 1 1 3|gawk '{print \$1,\$4*\$6,\$6}' |myAddHeader.sh \"DATE PPL count\" >$pplFile
getstat_fast.pl $pplFile 1 2|fgrep -v std|gawk '{print \$0,\$4/\$5,\$4/\$5*sqrt(252)}'|myAddHeader.sh \"colName min max mean std count shp shp.pa\" |gawk '{print \"portShp= \",\$0}' >tmp_portShp.txt
cat tmp_pcShp.txt tmp_portShp.txt |myFormatAuto.pl 1
";
  # print "$cmd2\n";
   system("$cmd2");

 my $cmd3="
cat tmp_pcShp.txt|fgrep -v colName|mygetcols.pl 8
#0.0420067
";
 my $res3=`$cmd3`;
 chomp($res3);
my $pcShp=$res3;


 my $cmd4="
cat tmp_portShp.txt|fgrep -v colName|mygetcols.pl 8
#0.0420067
";
 my $res4=`$cmd4`;
 chomp($res4);
my $portShp=$res4;
my $divNum=$portShp/$pcShp;
printf "divNum = portShp/pcShp= $portShp / $pcShp = %.7f\n",$divNum;

}



sub compute_shps_return_pcShp()
#input:
#      pnlFile: DATE SYM PL
#output: pplFile name
{
    my ($pnlFile, $pplFile, $refPcShp) = @_;

    my $cmd2="
#pcShp
getstat_fast.pl $pnlFile 1 3|fgrep -v std|gawk '{print \$0,\$4/\$5,\$4/\$5*sqrt(252) }'|myAddHeader.sh \"colName   min   max   mean    std    count   shp   shp.pa\"|gawk '{print \"pcShp= \",\$0}' >tmp_pcShp.txt
 #portShp
getMeanStdByDate.pl $pnlFile 1 1 3|gawk '{print \$1,\$4*\$6,\$6}' |myAddHeader.sh \"DATE PPL count\" >$pplFile
getstat_fast.pl $pplFile 1 2|fgrep -v std|gawk '{print \$0,\$4/\$5,\$4/\$5*sqrt(252)}'|myAddHeader.sh \"colName min max mean std count shp shp.pa\" |gawk '{print \"portShp= \",\$0}' >tmp_portShp.txt
cat tmp_pcShp.txt tmp_portShp.txt |myFormatAuto.pl 1
";
  # print "$cmd2\n";
   system("$cmd2");

 my $cmd3="
cat tmp_pcShp.txt|fgrep -v colName|mygetcols.pl 8
#0.0420067
";
 my $res3=`$cmd3`;
 chomp($res3);
my $pcShp=$res3;

$$refPcShp=$pcShp;

 my $cmd4="
cat tmp_portShp.txt|fgrep -v colName|mygetcols.pl 8
#0.0420067
";
 my $res4=`$cmd4`;
 chomp($res4);
my $portShp=$res4;
my $divNum=$portShp/$pcShp;
printf "divNum = portShp/pcShp= $portShp / $pcShp = %.7f\n",$divNum;

}


__END__
