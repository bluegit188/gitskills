#!/usr/bin/perl

use strict;


( ($#ARGV+2)==8 || ($#ARGV+2)==9 ) || die
"Usage: bt1_perf_backtest_easy_v96_highEntry_withTcost.pl startDate endDate tcost sizeX tcostI sizeXI isOptZA=0 [opt:list_sym]
       Compute bt1 strat perf. for 26-sym univ for given date range(inclusive)
       Assume raw_fcsts.txt file is already pre-computed
       opt: list_sym -> use user supplied universe
       output:
        a). Port. daily pnls:  ppls.txt.fcstNet
        b). Per-com daily pnls:  pls.txt.fcstNet
        c). Port. monthly pnl in pct:   tmp_ppl_monthlyRet_yeanmon.txt
        d). posSize: tmp_lots_detail.txt
        d2). isOptZA=0 for optXT, 1 for optZA
        e). Afterwards, run: compare_prod_bktest_positions.pl to check bktest vs prod. positions
\n";



my $startDate=$ARGV[0];
my $endDate=$ARGV[1];

my $tcost=$ARGV[2];
my $sizeX=$ARGV[3];

my $tcostI=$ARGV[4];
my $sizeXI=$ARGV[5];


my $isOptZA=$ARGV[6];


my $univFile="/home/jgeng/bin/list_sym_newUniv";
if( ($#ARGV+2)==9 )
{
  $univFile=$ARGV[7];
}

#print "sizeX= $sizeX\n";

# default is optXT
my $cmdFcstNetStr=
"# high entry tcost
 #cat Y_X.txt |myFcstSubtractTcostNew.pl 1 2 4 $sizeX|mygetcols.pl 2 1 3 5 >Y_X.txt.fcstNet";

if($isOptZA)
{
  $cmdFcstNetStr=
 "# high entry tcost
  #cat Y_X.txt |myFcstSubtractTcostNew_optZA.pl 1 2 4 $sizeX|mygetcols.pl 2 1 3 5 >Y_X.txt.fcstNet
   cat Y_X.txt |myFcstSubtractTcostNew_optZA_general_intraday.pl 1 2 1 3 5 $sizeX $sizeXI|mygetcols.pl 1 2 3 4 6 >Y_X.txt.fcstNet";

}

#print "cmdFcstNetStr=$cmdFcstNetStr\n";

print "intraSimu: sizeX=$sizeX sizeXI=$sizeXI\n";

my $cmd="
# rawFcst_newUniv_bt1_fcst_backtest_easy_v96.pl $startDate $endDate  $univFile|egrep -v -E -e\"  LEU | ED | S \" > fcsts.txt
# yvar
#  portara_get_ooRets_multi.pl  $univFile 1 |mygetcols.pl 2 1 3 |myRmOutliersSimple.pl 1 1 $startDate $endDate 1 >yvars.txt
# combine
# combine_match2.pl fcsts.txt yvars.txt |mygetcols.pl 1 2 6 3 >Y_X.txt
# subtract tcost
#  cat Y_X.txt |myFcstSubtractTcost.pl 1 2 4|mygetcols.pl 2 1 3 5 >Y_X.txt.fcstNet
# high entry tcost
# cat Y_X.txt |myFcstSubtractTcostNew.pl 1 2 4 $sizeX|mygetcols.pl 2 1 3 5 >Y_X.txt.fcstNet

$cmdFcstNetStr

#compute ivlRets
cat Y_X.txt.fcstNet|myAddIvlRets_intraday.pl 1 2 1 3 4 |mygetcols.pl 1 2 3 6 5 >Y_X.txt.fcstNet.ivlRet


# get FVOOD
check_duplicate.pl Y_X.txt.fcstNet.ivlRet 2|mygetcols.pl 1|fgrep -v SYM >tmp_list_sym
# FVOOD=FVOO*pvUSD=FVOO*pv*fx
# I use a more accuarte vesion of fx here o match the prod as much as possible
portara_get_FVOOD_multi.pl tmp_list_sym |mygetcols.pl 1 2 4 9 6 >FVOOD.txt
#
#
# run simu
# due to high entry, increase RPF

#analyze_portfolioPerf_dollarPct_byLotsSmallCap_withTcost.pl Y_X.txt.fcstNet 1 2 3 4 65000 6500000 FVOOD.txt 1 2 3 4 -0.02 0.03 $tcost
#5MM USD AUM, adj for comm cost
#analyze_portfolioPerf_dollarPct_byLotsSmallCap_withTcost.pl Y_X.txt.fcstNet 1 2 3 4 96100 5000000 FVOOD.txt 1 2 3 4 -0.02 0.03 $tcost
#analyze_portfolioPerf_dollarPct_byLotsSmallCap_withTcost.pl Y_X.txt.fcstNet 1 2 3 4 79531 5000000 FVOOD.txt 1 2 3 4 -0.02 0.03 $tcost
#5MM USD AUM, adj for comm cost
#analyze_portfolioPerf_dollarPct_byLotsSmallCap_withTcost.pl Y_X.txt.fcstNet 1 2 3 4 96100 5000000 FVOOD.txt 1 2 3 4 -0.02 0.03 $tcost
#10M usd 5%
#intraSimu_analyze_portfolioPerf_dollarPct_byLotsSmallCap_withTcost.pl Y_X.txt.fcstNet.ivlRet 2 1 3 4 5 103000 10000000 FVOOD.txt 1 2 3 4 -0.02 0.03 $tcost $tcostI
intraSimu_analyze_portfolioPerf_dollarPct_byLotsSmallCap_withTcost.pl Y_X.txt.fcstNet.ivlRet 2 1 3 4 5 85888 10000000 FVOOD.txt 1 2 3 4 -0.02 0.03 $tcost $tcostI


";

#print ("$cmd");

system("$cmd");

#9.6/11.6*96100
#[1] 79531.03


__END__






more tmp_lots_detail.txt|myFormatAuto.pl 1|egrep -E -e"DATE|20151119"|myRmOutliersSimple.pl 1 10 -0.1 0.1 0
 SYM     DATE     ooF1D    fcstNet       FVOO    PVUSD            FVOOD   lotFrac lotRound lotRoundAdj            pnlDol
  ED 20151119  0.000000 -0.0199784   0.020211     2500          50.5275  -5.14016       -5          -5                 0
 ESX 20151119  0.020794  0.0367525  48.089654   10.656    512.443353024   0.93236        1           1  10.6557470827811
  LC 20151119  0.014798 -0.0579278   1.689459      400         675.7836  -1.11435       -1          -1    -10.0002457128
 LEU 20151119  0.887543   0.031747   0.011267     2664        30.015288  13.75003       14          14  372.958022603376
  NG 20151119 -2.233530  0.0303799   0.059099    10000           590.99   0.66827        1           1     -1319.9938947
 SNI 20151119 -0.244235  0.0832771 266.137053  4.04565 1076.69736846945   1.00548        1           1 -262.967181788136
 STW 20151119  0.576920  0.0756699   3.986685      100         398.6685   2.46749        2           2      459.99966204
   W 20151119  0.538268  0.0211769   8.824599       50        441.22995   0.62394        1           1    237.4999627266

B). from prod.
/roottransfer/jgeng/Prod/fcsts/Logs/byDate


displayTradesFile.sh trades.txt.20151119.20151119.100507 |myRmOutliersSimple.pl 1 5 -0.1 0.1 0|myFcstSubtractTcost.pl 1 1 2
 SYM    fcstDM EODPos trades tgtPos   tsDate tsTime flag fcstNet
  ED -0.057742      0     -2     -2 20151119 081958   OK -0.007742
 ESX  0.046785     -1      2      1 20151119 030002   OK 0.036785
  LC -0.072345     -2      1     -1 20151119 100508   OK -0.062345
  NG  0.039956      0      1      1 20151119 090002   OK 0.029956
 SNI  0.098164      0      1      1 20151118 184508   OK 0.083164
 STW  0.087697      0      2      2 20151118 194508   OK 0.072697

=> They match each other more or less between prod. and simulations






bt1_fcst_backtest /home/jgeng/bin/list_sym 20151104 20151104|mygetcols.pl 1 2 10|sort -k2,2

20151104 KC open= 120.5 spd= 0 cumSpd= 204.75 bt1Fcst.dm= 0.00808794 bt1Fcst= 0.0180879 svmFcst= 0.0445655 nnFcst= -0.00596933 FVOO= 2.62167 DateDif= 1 preDate= 20151103 today= 20151104 preOpen= 118.05 GAP= 0.0572154 OO1= -0.362364 OO2= 1.28209 OO3= -0.359493 OO4= -0.653746 OO5= 0.561185


 my $cmd="wc test.txt| head -1 |mygetcols.pl 1";
 my $res=`$cmd`;
 chomp($res);

