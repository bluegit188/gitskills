--latest US daily model: about 1.2 shp.


rep.txt.20240115
lbox2
/home/jgeng/projects/FcstsCheck/20151120_checkBktestDollarPPL/Check_20160503_svm_vs_nn/TEST8_bt1_v91_components/LTTest_V91/TEST8_dollarPnlsUpdates_smallu_20240115_v2_allFcsts/TEST2_return_display


--intra dollar pnl simu:

cp /home/jgeng/projects/FcstsCheck/20151120_checkBktestDollarPPL/Check_20160503_svm_vs_nn/TEST8_bt1_v91_components/LTTest_V91/TEST8_dollarPnlsUpdates_smallu_20240115_v2_allFcsts/rawFcst_newUniv_bt1_perf_backtest_easy_v96_highEntry_withTcost.pl .
 mv rawFcst_newUniv_bt1_perf_backtest_easy_v96_highEntry_withTcost.pl  intraSimu_rawFcst_newUniv_bt1_perf_backtest_easy_v96_highEntry_withTcost.pl 


#ivl fcst and rets(PL2NO)
more ../../fcsts_HFT_smallu3_20240131.txt.adj1 |mygetcols.pl 2 1 4 6 16 >Y_X.txt

1 DATE
2 SYM
3 ivl
4 PL2NO
5 fcstCombo62Adj2

  ## cmds:
  # get fcstNet with optZAIntra
  cat Y_X.txt |myFcstSubtractTcostNew_optZA_general_intraday.pl 1 2 1 3 5 0.04 0.04|mygetcols.pl 1 2 3 4 6 >Y_X.txt.fcstNet
  # get ivlRet
 cat Y_X.txt.fcstNet|myAddIvlRets_intraday.pl 1 2 1 3 4 |mygetcols.pl 1 2 3 6 5 >Y_X.txt.fcstNet.ivlRet



intraSimu_analyze_portfolioPerf_dollarPct_byLotsSmallCap_withTcost.pl Y_X.txt.fcstNet.ivlRet 1 2 3 4 103000 10000000 FVOOD.txt 1 2 3 4 -0.02 0.03 0.04 0.02


#cmd:
cat Y_X.txt.fcstNet.ivlRet |mygetcols.pl  2 1 3 4 5 >tmp_a1
cat FVOOD.txt |mygetcols.pl 1 2 3 4 >tmp_a2
combine_match2.pl tmp_a1 tmp_a2  |mygetcols.pl 1 2 3 4 5 8 9 >tmp_Y_X.txt.subset.FVOOD


 cat tmp_Y_X.txt.subset.FVOOD|intraSimu_myComputeLotsFromFcst_smallcap.pl  1 1 2 3 4 5 6 7 103000 10000000 -0.03 0.03 >tmp_lots_detail.txt.ivl


cat tmp_lots_detail.txt.ivl |intraSimu_myAfterTcostPnl_naive_dollar.pl 1 1 2 3 4 11 0.04 0.02 8 >tmp_lots_detail.txt.ivl.afterTcost

#ivl pnl to daily pnl
cat tmp_lots_detail.txt.ivl.afterTcost|mygetcols.pl 1 2 15| sed s/\\ /:/ >/tmp/tmp_ivlPnl.txt

getMeanStdByDate.pl /tmp/tmp_ivlPnl.txt 1 1 3|fgrep -v DATE|sed s/:/\\ /|gawk '{print \$1, \$2,\$5*\$7,\$7}'|sort -k2,2 -k1,1g|mygetcols.pl 1 2 3 | myAddHeader.sh \"DATE SYM PL\" >pls.txt.$indName.netZA




--misc info: 20240206


 head -3 Y_X.txt|myFormatAuto.pl 1
     DATE SYM ivl     PL2NO fcstCombo62Adj2
 20151027  BC   1 -0.422209        0.049171
 20151027  BC   2  -0.35966        0.039794

head -3 Y_X.txt.fcstNet|myFormatAuto.pl 1
     DATE SYM ivl     PL2NO  fcstNet
 20151027  BC   1 -0.422209 0.009171
 20151027  BC   2  -0.35966 0.009171

head -2 Y_X.txt.fcstNet.ivlRet|myFormatAuto.pl 1
     DATE SYM ivl    ivlRet  fcstNet
 20151027  BC   1 -0.062549 0.009171



daily model is here:
lbox2
/home/jgeng/projects/FcstsCheck/20151120_checkBktestDollarPPL/Check_20160503_svm_vs_nn/TEST8_bt1_v91_components/LTTest_V91/TEST8_dollarPnlsUpdates_smallu_20240115_v2_allFcsts/TEST3_smallu3_AFBILimits



--final intra simu:

#10M usd, 5%

time ./intraSimu_rawFcst_newUniv_bt1_perf_backtest_easy_v96_highEntry_withTcost.pl 20150101 20231231 0.039 0.04 0.02 0.04 1  list_sym_smallu3 >perfByLots.txt.fcstNet.HE.tcost
date;


-- yearly pct returns:
20240206

smallu3, US intra model

cat pplsPct.txt.fcstNet|myYear.pl 1 1 >a
getMeanStdByDate.pl a 1 5 4|gawk '{print $1,$4*$6,$5*sqrt(252)}' |myAddHeader.sh "year ret vol"|myFormatAuto.pl 1
 year        ret       vol
 2015 -0.0031274 0.0221685
 2016  0.0683692 0.0337771
 2017  0.0457462 0.0289263
 2018   0.025225  0.043833
 2019   0.113286  0.039805
 2020   0.158211 0.0739164
 2021    0.15583 0.0581543
 2022   0.126203 0.0653859
 2023  0.0482194  0.039015





intraSimu: sizeX=0.04 sizeXI=0.04
######## pcShp and portShp(by lots),  yvar=ivlRet fcst= fcstNet ###############
Number of symbols: 16 , Date range: 20151027 20231018
Portfolio shp in dollars(from lots):
file= Y_X.txt.fcstNet.ivlRet, fcst= fcstNet RPS= 85888 initCap= 10000000 fcstCutL= -0.02 fcstCutH= 0.03 tcost=0.039 tcostI=0.02:
   pcShp= colName     min    max         mean           std count       shp   shp.pa
   pcShp=      PL -103607 135368  266.6531289  6309.1249740 27675 0.0422647 0.670931
 portShp= colName     min    max         mean           std count       shp   shp.pa       total
 portShp=     PPL -232211 333849 3732.7387902 31915.6966546  1977  0.116956  1.85662 7.37962e+06
divNum = portShp/pcShp= 0.116956 / 0.0422647 = 2.7672266
Portfolio retPct:
 pplPct= colName        min       max      mean       std count      shp  shp.pa    ret.pa    std.pa    total
 pplPct=  retPct -0.0232211 0.0333849 0.0003733 0.0031916  1977 0.116963 1.85673 0.0940716 0.0506651 0.738014
