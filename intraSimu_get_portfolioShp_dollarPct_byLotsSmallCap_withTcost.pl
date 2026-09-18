#!/usr/bin/perl

use strict;

($#ARGV+2)==18 || die 
"Usage: intraSimu_get_portfolioShp_dollarPct_byLotsSmallCap_withTcost.pl file.txt colSym colDate colIvl colIvlRet colFcst RPS initCap fileFVOO colSym2 colDate2 colFVOO colPvUSD fcstCutL(-0.03) fcstCutH(0.03) tcost tcostI
       Compute porfolio shp and per commodity shp in percent terms
       Need to specify RPS and intial capital
       Note that: PL\$=PL*RPS according to my derivation\n";


# open file an put column specified into a hash
my $filename=$ARGV[0];

my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colIvl=$ARGV[3];
my $colIvlRet=$ARGV[4];
my $colFcst=$ARGV[5];

my $RPS=$ARGV[6];

my $initCap=$ARGV[7];

my $fileFVOO=$ARGV[8];
my $colSym2=$ARGV[9];
my $colDate2=$ARGV[10];
my $colFVOO=$ARGV[11];
my $colPvUSD=$ARGV[12];
my $fcstCutL=$ARGV[13];
my $fcstCutH=$ARGV[14];

my $tcost=$ARGV[15];
my $tcostI=$ARGV[16];

 my $cmd0="
head -1 $filename |mygetcols.pl $colFcst
";
 my $res0=`$cmd0`;
 chomp($res0);
my $indName=$res0;



print "Portfolio shp in dollars(from lots):\n";
print "file= $filename, fcst= $indName RPS= $RPS initCap= $initCap fcstCutL= $fcstCutL fcstCutH= $fcstCutH tcost=$tcost tcostI=$tcostI:\n";
    my $cmd1="
## compute shp

#combine with fcst, and determine positions
cat $filename |mygetcols.pl  $colSym $colDate $colIvl $colIvlRet $colFcst >tmp_a1
cat $fileFVOO |mygetcols.pl $colSym2 $colDate2 $colFVOO $colPvUSD >tmp_a2
combine_match2.pl tmp_a1 tmp_a2  |mygetcols.pl 1 2 3 4 5 8 9 >tmp_Y_X.txt.subset.FVOOD
cat tmp_Y_X.txt.subset.FVOOD|intraSimu_myComputeLotsFromFcst_smallcap.pl 1  1 2 3 4  5 6 7 $RPS $initCap $fcstCutL $fcstCutH >tmp_lots_detail.txt.ivl

# dollar pnl, after tcost
cat tmp_lots_detail.txt.ivl |intraSimu_myAfterTcostPnl_naive_dollar.pl 1 1 2 3 4 11 $tcost $tcostI 8 >tmp_lots_detail.txt.ivl.afterTcost
#convert ivl pnl to daily pnl (sym_date)
cat tmp_lots_detail.txt.ivl.afterTcost|mygetcols.pl 1 2 3 15| sed s/\\ /:/ >tmp_ivlPnl.txt
getMeanStdByDate.pl tmp_ivlPnl.txt 1 1 3|fgrep -v DATE|sed s/:/\\ /|gawk '{print \$2, \$1,\$5*\$7,\$7}'|sort -k2,2 -k1,1g|mygetcols.pl 1 2 3 | myAddHeader.sh \"DATE SYM PL\" >pls.txt.$indName
#
#
cat pls.txt.$indName|fgrep -v DATE|gawk '{print \$1,\$2,\$3/$initCap}'  |myAddHeader.sh \"DATE SYM PLPct\" >plsPct.txt.$indName
#pcShp
getstat_fast.pl pls.txt.$indName 1 3|fgrep -v std|gawk '{print \$0,\$4/\$5,\$4/\$5*sqrt(252) }'|myAddHeader.sh \"colName   min   max   mean    std    count   shp   shp.pa\"|gawk '{print \"pcShp= \",\$0}' >tmp_pcShp.txt
";
# print "$cmd1\n";
   system("$cmd1");


    my $cmd2="
 #portShp
getMeanStdByDate.pl pls.txt.$indName 1 1 3|gawk '{print \$1,\$4*\$6,\$6}' |myAddHeader.sh \"DATE PPL count\" >ppls.txt.$indName
getstat_fast.pl ppls.txt.$indName 1 2|fgrep -v std|gawk '{print \$0,\$4/\$5,\$4/\$5*sqrt(252),\$4*\$6 }'|myAddHeader.sh \"colName min max mean std count shp shp.pa total\" |gawk '{print \"portShp= \",\$0}' >tmp_portShp.txt
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


### add dollarPct rets at port level
print "Portfolio retPct:\n";

    my $cmd5="
 #portShp
#cat ppls.txt.$indName |fgrep -v DATE|myCum.pl 2|gawk '{print \$0, \$4+$initCap}'|gawk '{print \$0,  log(\$5/((\$5)-(\$2))) }'|gawk '{print \$1,\$2,\$5-\$2,\$6}'|myAddHeader.sh \"DATE PPLDol cap retPct\" > pplsPct.txt.$indName

cat ppls.txt.$indName |fgrep -v DATE|myCum.pl 2|gawk '{print \$0, \$4+$initCap}'|gawk '{print \$0,  \$2/$initCap }'|gawk '{print \$1,\$2,\$5-\$2,\$6}'|myAddHeader.sh \"DATE PPLDol cap retPct\" > pplsPct.txt.$indName

getstat_fast.pl pplsPct.txt.$indName 1 4|fgrep -v std|gawk '{print \$0,\$4/\$5,\$4/\$5*sqrt(252), \$4*252,\$5*sqrt(252), \$4*\$6}'|myAddHeader.sh \"colName min max mean std count shp shp.pa ret.pa std.pa total\" |gawk '{print \"pplPct= \",\$0}' >tmp_pplPctShp.txt
cat tmp_pplPctShp.txt |myFormatAuto.pl 1
";
  # print "$cmd5\n";
   system("$cmd5");



### add dollarPct rets at port level
print "Lots stats by sym:\n";

    my $cmd6="
# compute lots stats, ie, how many lots for each contract
cat tmp_lots_detail.txt.ivl|mygetcols.pl 1 11 |gawk '{print \$1, sqrt(\$2*\$2)}' >tmp_a
getMeanStdByDate.pl tmp_a 1 1 2  |myFloatRoundingInPlace.pl 0 4 1|myFloatRoundingInPlace.pl 0 5 1|myAddHeader.sh \"SYM MIN MAX MEAN STD\"|myFormat.pl 5:8:8:8:8 1:2:3:4:5 >lots_stats.txt
cat lots_stats.txt
";
  # print "$cmd6\n";
   system("$cmd6");





__END__

 more ppls.txt.combo |fgrep -v DATE|myCum.pl 2|gawk '{print $0, $4+1000000}'|gawk '{print $0,  log($5/(($5)-($2))) }'
