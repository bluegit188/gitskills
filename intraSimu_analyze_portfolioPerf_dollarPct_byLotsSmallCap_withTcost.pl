#!/usr/bin/perl

use strict;

($#ARGV+2)==18 || die 
"Usage: intraSimu_analyze_portfolioPerf_dollarPct_byLotsSmallCap_withTcost.pl file.txt colSym colDate colIvl colIvlRet(y) colFcst RPS initCap  fileFVOO colSym2 colDate2 colFVOO colPvUSD fcstCutL(-0.03) fcstCutH(0.03) tcost tcostI
       Compute a few portfolio stats:
        pcShp and portShp
        shp by year
        shp by symbol\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];

my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colIvl=$ARGV[3];
my $colIvlRet=$ARGV[4];# colY
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

 my $cmd01="
head -1 $filename |mygetcols.pl $colIvlRet
";
 my $res01=`$cmd01`;
 chomp($res01);
my $yName=$res01;


# num of syms
 my $cmd001="
check_duplicate.pl $filename $colSym|fgrep -v SYM|mygetcols.pl 1|wc|mygetcols.pl 1
#26
";
 my $res001=`$cmd001`;
 chomp($res001);
my $numSyms=$res001;



# date range
 my $cmd002="
check_duplicate.pl  $filename $colDate|fgrep -v DATE|mygetcols.pl 1|myRange.pl 0 1|mygetcols.pl 3 5
#20070102 20160531

";
 my $res002=`$cmd002`;
 chomp($res002);
my $dateRange=$res002;






print "######## pcShp and portShp(by lots),  yvar=$yName fcst= $indName ###############\n";
print "Number of symbols: $numSyms , Date range: $dateRange\n";

    my $cmd1="
intraSimu_get_portfolioShp_dollarPct_byLotsSmallCap_withTcost.pl $filename  $colSym $colDate $colIvl $colIvlRet $colFcst $RPS $initCap $fileFVOO  $colSym2 $colDate2 $colFVOO $colPvUSD $fcstCutL $fcstCutH $tcost $tcostI
";
# print "$cmd1\n";
   system("$cmd1");

print "\n\n######## shp by year, fcst= $indName ###############\n";
    my $cmd2="
get_portfolioShp_byYear_pct.pl plsPct.txt.$indName
";
# print "$cmd2\n";
   system("$cmd2");

print "\n\n######## shp by yearmon, fcst= $indName ###############\n";
    my $cmd2="
get_portfolioShp_byYearMon.pl plsPct.txt.$indName
";
# print "$cmd2\n";
   system("$cmd2");



print "\n\n######## shp by symbol, fcst= $indName ###############\n";
    my $cmd3="
get_portfolioShp_bySym.pl plsPct.txt.$indName
";
  # print "$cmd3\n";
   system("$cmd3");


print "\n\n######## max drawdown, daily ret, fcst= $indName ###############\n";
    my $cmd3="
get_max_drawdown_new.pl pplsPct.txt.$indName  1 0 1 4
";
  # print "$cmd3\n";
   system("$cmd3");


print "\n\n######## max drawdown, monthly ret, fcst= $indName ###############\n";
    my $cmd3="
getMeanStdByDate.pl tmp_ppls_yearmon.txt 0 4 2|gawk '{print \$1, \$4*\$6,\$6}' >tmp_ppl_monthlyRet_yeanmon.txt
get_max_drawdown_new.pl tmp_ppl_monthlyRet_yeanmon.txt 0 1 1 2
";
  # print "$cmd3\n";
   system("$cmd3");




print "\n\n######## shp by asset ###############\n";
    my $cmd5="
get_portfolioShp_byAsset_new.pl plsPct.txt.fcstNet
";
  # print "$cmd5\n";
   system("$cmd5");

