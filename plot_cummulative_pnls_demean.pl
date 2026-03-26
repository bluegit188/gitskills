#!/usr/bin/perl

use strict;

($#ARGV+2) >=13 || die 
"Usage: plot_cummulative_pnls_demean.pl file.txt startDate endDate colSym colDate colY colFcst  fmin:fmax mean=x/0.02 beta  A/B/AB [all/stock/bond/curr/phy/sir/smallu3/allexphy/allexstock/aisa/europe/america/Index_Asia/eurIBC/nonEurIBC  or symbols]
       Compute cummulative pnls for given asset class or given symbols
       beta: default=1, if beta=-1, will multiply beta*fcst to create new fcst first, before applying min/max constrains and demean
       Usage:
       plot_cummulative_pnls_demean.pl file.txt 1 2 3 4  x:x x stock
       plot_cummulative_pnls_demean.pl file.txt 1 2 3 4  x:x x all
       plot_cummulative_pnls_demean.pl file.txt 1 2 3 4  x:x x SNI STW ESX DAX LFT ES NQ
       plot_cummulative_pnls_demean.pl file.txt 1 2 3 4  x:x x BC CL NG KC C W SB LC HG GC CT
       plot_cummulative_pnls_demean.pl file.txt 1 2 3 4  x:x x TY US LLG GBL GBM CGB
       plot_cummulative_pnls_demean.pl file.txt 1 2 3 4  x:x x  EC JY CD
\n";

print "cmd=$0 @ARGV\n";

# open file an dput column specified into a hash
my $filename=$ARGV[0];

my $startDate=$ARGV[1];
my $endDate=$ARGV[2];

my $colSym=$ARGV[3];
my $colDate=$ARGV[4];
my $colY=$ARGV[5];
my $colFcst=$ARGV[6];


my $fminmaxStr=$ARGV[7];
my $xmin=-999999;
my $xmax= 999999;
my ($a1,$a2) =split(':',$fminmaxStr);
if($a1 ne "x")
{
  $xmin=$a1;
  $xmax=$a2;
}

my $userMean=$ARGV[8];

my $beta=$ARGV[9];

my $sampleTag=$ARGV[10];



my @n;
foreach my $i (11..$#ARGV)
{
  my $str=$ARGV[$i];
  my @tokens=split(':',$str);
  if($#tokens==0)
  {
    push(@n,$str);         # the n's
  }
  elsif($#tokens==1)
 {
     foreach my $k ( ($tokens[0])..($tokens[1]))
     {
       push(@n,$k);
     }
  }
  else # with step specified
  {
     my $step=$tokens[2];
     for (my $k= $tokens[0];$k<=$tokens[1];$k+=$step)
     {
       push(@n,$k);
     }
  }
}

my $filterStr=join("|", @n);
$filterStr=$filterStr." ";

$filterStr=~s/\s+$//; # remove trailing spaces
#print "str=$filterStr\n";


#### create subset data file
#by syms
my $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -w -E -e\"DATE|$filterStr\"|mygetcols.pl 1 2 3 4  | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}' >/tmp/subset.txt";


if($n[0] eq "all")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst  | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}' >/tmp/subset.txt";
}

#by asset
if($n[0] eq "stock")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|Index\"|mygetcols.pl 1 2 3 4  | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}' >/tmp/subset.txt";
}


if($n[0] eq "bond")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|Financial\"|mygetcols.pl 1 2 3 4  | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}' >/tmp/subset.txt";
}

if($n[0] eq "phy")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|Physical\"|mygetcols.pl 1 2 3 4  | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}' >/tmp/subset.txt";
}


if($n[0] eq "curr")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|Currency\"|mygetcols.pl 1 2 3 4 | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}'  >/tmp/subset.txt";
}



if($n[0] eq "sir")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|SIR\"|mygetcols.pl 1 2 3 4  | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}' >/tmp/subset.txt";
}


if($n[0] eq "allexphy")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|Index|Financial|Currency\"|mygetcols.pl 1 2 3 4 | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}'  >/tmp/subset.txt";
}


if($n[0] eq "asia")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|Asia\"|mygetcols.pl 1 2 3 4 | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}'  >/tmp/subset.txt";
}

if($n[0] eq "europe")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|Europe\"|mygetcols.pl 1 2 3 4 | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}'  >/tmp/subset.txt";
}

if($n[0] eq "america")
{
  $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|America\"|mygetcols.pl 1 2 3 4 | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}'  >/tmp/subset.txt";
}

# by asset session
my $firstSym = $n[0];
if( $firstSym =~ /^(\w+)_(\w+)$/) # Index_America
{
   #no strict 'refs';
   my($asset, $session) = split /_/, $firstSym;
   #print ("asset/session= $asset $session\n");
   
   $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|$session $asset\"|mygetcols.pl 1 2 3 4 | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}'  >/tmp/subset.txt";
   
}

if($n[0] eq "eurIBC")
{
   $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -E -e\"DATE|Europe Index|Europe Financial|Europe Currency|Europe SIR\"|mygetcols.pl 1 2 3 4 | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}'  >/tmp/subset.txt";
}

if($n[0] eq "nonEurIBC")
{
   $cmdSub="cat $filename |mygetcols.pl $colSym $colDate $colY $colFcst |myAssetSession_four_aseets.pl 1 1|egrep -v -E -e\"Europe Index|Europe Financial|Europe Currency|Europe SIR\"|mygetcols.pl 1 2 3 4 | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}'  >/tmp/subset.txt";
}



if($n[0] eq "smallu3")
{
  $cmdSub="cat $filename |mygetcols.pl $colDate $colSym $colY $colFcst |egrep -E -e\"DATE| BC | CL | NG | KC | C | W | SB | LC | HG | GC | CT | S | BO | TY | NQ | ES \"|mygetcols.pl 2 1 3 4  | gawk '{if(NR==1){print \$0}else{print \$1,\$2,\$3,$beta*\$4}}' >/tmp/subset.txt";
}

# cat ~/bin/list_sym_smallu3 |myTranspose.pl| sed s/\ /\ \|\ /g
#BC | CL | NG | KC | C | W | SB | LC | HG | GC | CT | S | BO | TY | NQ | ES



# print "$cmdSub\n";
system("$cmdSub");


#



my $subfilename="/tmp/subset.txt";


 my $cmd0="
head -1 $filename |mygetcols.pl $colFcst
";
 my $res0=`$cmd0`;
 chomp($res0);
my $indName=$res0;

 my $cmd01="
head -1 $filename |mygetcols.pl $colY
";
 my $res01=`$cmd01`;
 chomp($res01);
my $yName=$res01;




#############################################
###############################################
## below for plotting cumPnl and DOW effect


my $cmda0="
cat /tmp/subset.txt |myRmOutliersSimple.pl 1 2 $startDate $endDate 1 |fgrep -v DATE|gawk '{print \$2,\$1,\$3,\$4}'|myAddHeader.sh \"DATE SYM $yName $indName\"   |mySampleSelector.pl 1 1 $sampleTag > /tmp/raw_y_x.txt.v0
cat /tmp/raw_y_x.txt.v0  |myConstraintSimple.pl 4 $xmin $xmax   >/tmp/raw_y_x.txt";
#print "$cmda0\n";
system("$cmda0");


#fcsts stats
my $cmd201="
echo \"\#\#Fcsts Stats (raw fcst before demean):\"
getstats_fast.pl /tmp/raw_y_x.txt 1|myFormatAuto.pl 1
";
system("$cmd201");



########################
#demean and constrain fcsts and check stats again
my $cmd2012="
#cat  /tmp/raw_y_x.txt|myDemeanFcstInPlace.pl 1 4 $userMean |gawk '{ if( NR==1){print \$0,\"pnl\"}else{print \$0,\$3*\$4}}'  > /tmp/y_x.txt
cat /tmp/raw_y_x.txt.v0 |myDemeanFcstInPlace.pl 1 4 $userMean  |myConstraintSimple.pl 4 $xmin $xmax  |gawk '{ if( NR==1){print \$0,\"pnl\"}else{print \$0,\$3*\$4}}'  > /tmp/y_x.txt
echo \"\#\#Fcsts Stats (demean fcst):\"
getstats_fast.pl /tmp/y_x.txt 1|myFormatAuto.pl 1
";
system("$cmd2012");

#get first date
my $cmd2012x="
check_duplicate.pl /tmp/y_x.txt 1|fgrep -v DATE|head -1|mygetcols.pl 1
#19871007
";
 my $res2012x=`$cmd2012x`;
 chomp($res2012x);
my $firstDate=$res2012x;


#tover
my $cmd20="
compute_fcst_turnover.pl /tmp/y_x.txt 4
";
system("$cmd20");


my $withInter=1;
if($xmin==$xmax)
{
    $withInter=0;
}

print "\n\n######## tSP ###############\n";
    my $cmd5x="
cp  /tmp/y_x.txt tmp_y_x.txt
compute_tSP_easy.pl  tmp_y_x.txt 3 4 1 $withInter 0 >/tmp/tsp_summary.txt
cat /tmp/tsp_summary.txt
echo \"\n\#reg by year:\"
cat /tmp/results.txt
";
  # print "$cmd5x\n";
   system("$cmd5x");

# getN, beta, tSP for later use
 my $cmd02xx="
cat /tmp/tsp_summary.txt|mygetcols.pl 11 6 9|tail -1
";
 my $res02xx=`$cmd02xx`;
 chomp($res02xx);
 my ($NObs,$betaFull,$tSP) =split(' ',$res02xx);



#comb
my $cmd2="
get_corr_matrix_R.pl /tmp/y_x.txt 0 >/tmp/a0
#cat tmp_correlation.txt |fgrep \"$indName\"|fgrep -v ooF1D|mygetcols.pl 3
cat tmp_correlation.txt |fgrep \"$indName \"|fgrep -v \"$yName \"|mygetcols.pl 3
#0.0988
";
 my $res=`$cmd2`;
 chomp($res);
my $corr=$res;





   my $cmd3="
cat   /tmp/y_x.txt |mygetcols.pl 1 2 5 > pls.txt
getMeanStdByDate.pl  /tmp/y_x.txt 1 1 5|gawk '{print \$1,\$4*\$6,\$6}'  |myAddHeader.sh \"DATE PPL count\" > /tmp/ppls.txt
 cat /tmp/ppls.txt|myRange.pl 1 1|mygetcols.pl 3 5| sed s/\\ /:/
";
 my $res3=`$cmd3`;
 chomp($res3);
my $dateRange=$res3;


print "\n###   Univ= $filterStr y= $yName x= $indName dateRange= $dateRange \n";


   my $cmd4="
echo \"\#\#Corr:\"
 cp /tmp/y_x.txt  /tmp/y_x.txt.gc
 get_corr_matrix_R.pl /tmp/y_x.txt.gc 0 >/tmp/a
 cat tmp_correlation.txt |myFormatAuto.pl 1";

   #print "$cmd4\n";
   system("$cmd4");

print "\n\n######## corr (w/o deman) ###############\n";
    my $cmd6x="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_R.pl tmp_y_x.txt 1 3 4 >tmp_corrZM
cat tmp_corrZM |fgrep all|mygetcols.pl 2
";
  # print "$cmd6x\n";
 my $res6x=`$cmd6x`;
 chomp($res6x);
my $corZM=$res6x;

    my $cmd6x2="
cat tmp_corrZM
";
   #print "$cmd6x2\n";
   system("$cmd6x2");



    my $cmd6x3="
head -1  /tmp/y_x.txt|mygetcols.pl 3
";
 my $res6x3=`$cmd6x3`;
 chomp($res6x3);
my  $yvarName=$res6x3;


my $entry=0.0;
my $tcost=0.02;

############### naive method with plot ##########
print "\n\n######## netShp, naive method, entry=0 tcost=$tcost fcst= $indName ###############\n";
   my $cmd1bnaive="
get_portfolioShp_with_tcosts_optEntry_naive.pl  tmp_y_x.txt  2 1 3 4 0 $tcost
";
 print "cmd= $cmd1bnaive\n";
   system("$cmd1bnaive");


print "\n\n######## max drawdown, daily ret, pplFile= ppls.txt.$indName.grossNaive ###############\n";
    my $cmd3y1="
get_max_drawdown.pl ppls.txt.$indName.grossNaive  1 1 2 > /tmp/mdd.txt
cat /tmp/mdd.txt
";
  # print "$cmd3y1\n";
   system("$cmd3y1");

    my $cmd6x3xx="
cat /tmp/mdd.txt|egrep -E -e\"PL:\"|mygetcols.pl 15
";
 my $res6x3xx=`$cmd6x3xx`;
 chomp($res6x3xx);
my  $rshp= sprintf("%.4f", $res6x3xx);

    my $cmd6x3yy="
cat /tmp/mdd.txt|egrep -E -e\"sqrt\\(252\"|mygetcols.pl 2
";
 my $res6x3yy=`$cmd6x3yy`;
 chomp($res6x3yy);
my  $mdd=sprintf("%.4f", $res6x3yy);



my $xmgrCmdStr="xmgrByDateGrid";
if($firstDate < 20000101)
{
  $xmgrCmdStr="xmgrByDateGrid5Y";
}
print "\n\nfirstDate=$firstDate xmgrCmdStr=$xmgrCmdStr\n";

   my $cmd32="
datesXmgr.pl /tmp/ppls.txt 1 |fgrep -v DATE|gawk '{print \$1,\$3}'|myCum.pl 2 |mygetcols.pl 1 3 > /tmp/forplot 
echo \"title size 0.9\ntitle \\\"$filterStr (xmin:xmax=$xmin:$xmax userMean=$userMean beta=$beta sam=$sampleTag): \\n$yName~$indName corr=$corr corrZM=$corZM dates=$dateRange rshp=$rshp mdd=$mdd\\\"\ns0 symbol 2\ns0 symbol size 0.1\ns0 symbol fill 1\" > /tmp/title.txt
$xmgrCmdStr  -batch /tmp/title.txt /tmp/forplot  1>/dev/null 2>/dev/null &
echo \"\n\#\#PPLShp:\"
getstats_fast.pl /tmp/ppls.txt 1|myStatsToShp.sh
";

   #print "$cmd32\n";
   system("$cmd32");


   my $cmd41="
#DOW
echo \"\n\#\#by DOW\"
cat /tmp/y_x.txt.gc |myDayOfWeek.pl 1 1 >/tmp/a2
getMeanStdByDate.pl /tmp/a2 1 6 5|myStatsToShp.sh
";

   #print "$cmd41\n";
   system("$cmd41");



my $substr="$yName~$indName";
    
print "\n\n######## shp by asset ###############\n";
    my $cmd5="
#get_portfolioShp_byAsset_new.pl pls.txt
get_portfolioShp_byAsset_new_plot.pl pls.txt \"$substr\"
";
  # print "$cmd5\n";
   system("$cmd5");



print "\n\n######## corr by asset ###############\n";
    my $cmd6="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_asset4_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";
if($withInter==0)
{
   $cmd6="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_asset4_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat  /tmp/tmp_corr_by_key.txt
";   
}
system("$cmd6");


print "\n\n######## corr (w/o deman) by asset ###############\n";
    my $cmd62="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_asset4_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat /tmp/tmp_corr_by_key.txt
";
if($withInter==0)
{
   $cmd62="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_asset4_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";   
}
  # print "$cmd62\n";
   system("$cmd62");


print "\n\n######## shp by session ###############\n";
    my $cmd5="
#get_portfolioShp_bySession_new.pl pls.txt
get_portfolioShp_bySession_new_plot.pl pls.txt \"$substr\"
";
  # print "$cmd5\n";
   system("$cmd5");



print "\n\n######## corr by session ###############\n";
    my $cmd622="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_session_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";
if($withInter==0)
{
   $cmd622="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_session_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat  /tmp/tmp_corr_by_key.txt
";   
}

  # print "$cmd622\n";
   system("$cmd622");


print "\n\n######## corr (w/o demean) by session ###############\n";
    my $cmd60="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_session_R.pl tmp_y_x.txt 2 1 3 4
";
if($withInter==0)
{
   $cmd60="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_session_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";   
}

  # print "$cmd60\n";
   system("$cmd60");



print "\n\n######## corr by session_asset ###############\n";
    my $cmd68="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_session_asset_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";
if($withInter==0)
{
   $cmd68="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_session_asset_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat  /tmp/tmp_corr_by_key.txt
";   
}
  # print "$cmd68\n";
   system("$cmd68");


print "\n\n######## corr (w/o deman) by session_asset ###############\n";
    my $cmd62="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_session_asset_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat /tmp/tmp_corr_by_key.txt
";
if($withInter==0)
{
   $cmd62="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_session_asset_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";   
}
  # print "$cmd62\n";
   system("$cmd62");



print "\n\n######## shp by session_asset ###############\n";
    my $cmd5="
get_portfolioShp_bySessionAsset_new.pl pls.txt
";
  # print "$cmd5\n";
   system("$cmd5");




print "\n\n######## corr by eurIBC ###############\n";
    my $cmd6c="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_eurIBC_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";
if($withInter==0)
{
   $cmd6c="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_eurIBC_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat  /tmp/tmp_corr_by_key.txt
";   
}
  # print "$cmd6c\n";
system("$cmd6c");


print "\n\n######## corr (w/o deman) by eurIBC ###############\n";
    my $cmd6c1="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_eurIBC_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat /tmp/tmp_corr_by_key.txt
";
if($withInter==0)
{
   $cmd6c1="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_eurIBC_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";   
}
  # print "$cmd6c1\n";
   system("$cmd6c1");


print "\n\n######## corr by samAB ###############\n";
    my $cmd6c2="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_sampleAB_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";
if($withInter==0)
{
   $cmd6c2="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_sampleAB_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat  /tmp/tmp_corr_by_key.txt
";   
}
  # print "$cmd6c2\n";
   system("$cmd6c2");


print "\n\n######## corr (w/o deman) by samAB ###############\n";
    my $cmd6c22="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_sampleAB_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
cat /tmp/tmp_corr_by_key.txt
";
if($withInter==0)
{
   $cmd6c22="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_sampleAB_R.pl tmp_y_x.txt 2 1 3 4 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";   
}
  # print "$cmd6c22\n";
   system("$cmd6c22");



print "\n\n######## shp by year, fcst= $indName ###############\n";
    my $cmd2="
get_portfolioShp_byYear.pl pls.txt
";
# print "$cmd2\n";
   system("$cmd2");

print "\n\n######## shp by symbol, fcst= $indName ###############\n";
    my $cmd3="
get_portfolioShp_bySym.pl pls.txt
";
  # print "$cmd3\n";
   system("$cmd3");


print "\n\nind=$indName fcstMean |DOW \n";
## here we calc fcstMean by DOW
   my $cmd3="
#cat   /tmp/y_x.txt |mygetcols.pl 1 2 5 > pls.txt
cat   /tmp/y_x.txt |mygetcols.pl 1 2 4 |myDayOfWeek.pl 1 1 > /tmp/fcst_dow.txt
getMeanStdByDate.pl /tmp/fcst_dow.txt  1 4 3|myFloatRoundingInPlace.pl 0 4 5| myFloatRoundingInPlace.pl 0 5 5|myAddHeader.sh \"DOW min max mean std count\"|myFormatAuto.pl 1
";
system("$cmd3");


print "\n\nind=$indName yMean |DOW \n";
## here we calc yMean by DOW
   my $cmd3x="
#cat   /tmp/y_x.txt |mygetcols.pl 1 2 5 > pls.txt
cat   /tmp/y_x.txt |mygetcols.pl 1 2 3 |myDayOfWeek.pl 1 1 > /tmp/y_dow.txt
getMeanStdByDate.pl /tmp/y_dow.txt  1 4 3|myFloatRoundingInPlace.pl 0 4 5| myFloatRoundingInPlace.pl 0 5 5|myAddHeader.sh \"DOW min max mean std count\"|myFormatAuto.pl 1
";
system("$cmd3x");


print "\n\n######## corr by DOW, fcst= $indName ###############\n";
    my $cmd3="
get_corr_by_DOW_R.pl  tmp_y_x.txt 3 4 |myAddHeader.sh \"dateRange: none\" |myFormatAuto.pl 1 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";
if($withInter==0)
{
   $cmd3="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_by_DOW_R.pl tmp_y_x.txt 3 4 |myAddHeader.sh \"dateRange: none\" |myFormatAuto.pl 1 > /tmp/tmp_corr_by_key.txt
cat  /tmp/tmp_corr_by_key.txt
";   
}
  # print "$cmd3\n";
   system("$cmd3");



print "\n\n######## corr wo demean by DOW, fcst= $indName ###############\n";
    my $cmd3x="
get_corr_wo_demean_by_DOW_R.pl  tmp_y_x.txt 3 4  |myAddHeader.sh \"dateRange: none\" |myFormatAuto.pl 1 >/tmp/tmp_corr_by_key.txt
cat /tmp/tmp_corr_by_key.txt
";
if($withInter==0)
{
   $cmd3x="
cp /tmp/y_x.txt tmp_y_x.txt
get_corr_wo_demean_by_DOW_R.pl tmp_y_x.txt 3 4  |myAddHeader.sh \"dateRange: none\" |myFormatAuto.pl 1 > /tmp/tmp_corr_by_key.txt
compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt $NObs $betaFull $tSP
";   
}
  # print "$cmd3x\n";
   system("$cmd3x");


############### optZA method ##########
my $entry=0.04;
my $tcost=0.04;
print "\n\n######## netShp, optZA method, entry=$entry tcost=$tcost fcst= $indName ###############\n";
   my $cmd1bza="
get_portfolioShp_with_tcosts_optEntry_ZA_with_plots.pl  tmp_y_x.txt  2 1 3 4 $entry $tcost
";
 print "cmd= $cmd1bza\n";
   system("$cmd1bza");


print "\n\n######## max drawdown, daily ret, pplFile= ppls.txt.$indName.netZA ###############\n";
    my $cmd3="
get_max_drawdown.pl ppls.txt.$indName.netZA  1 1 2
";
  # print "$cmd3\n";
   system("$cmd3");





############### optZAY method ##########
my $entryX=0.04;
my $entryY=0.02;
print "\n\n######## netShp, optZAY method, entryX=$entryX entryY=$entryY tcost=$tcost fcst= $indName ###############\n";
   my $cmd1bza2="
get_portfolioShp_with_tcosts_optEntry_ZAY.pl  tmp_y_x.txt  2 1 3 4 $entryX $entryY $tcost
";
 print "cmd= $cmd1bza2\n";
   system("$cmd1bza2");


print "\n\n######## max drawdown, daily ret, pplFile= ppls.txt.$indName.netZAY ###############\n";
    my $cmd3y="
get_max_drawdown.pl ppls.txt.$indName.netZAY  1 1 2
";
  # print "$cmd3y\n";
   system("$cmd3y");



print "\n\n######## netShp by year, fcst= $indName file= pls.txt.$indName.netZA ###############\n";
    my $cmd2x="
get_portfolioShp_byYear.pl pls.txt.$indName.netZA
";
# print "$cmd2x\n";
   system("$cmd2x");


print "\n\n######## corr (pnl,y) beta exposure: symbol level and idx level ###############\n";
    my $cmd60x="
#--check pnl and y corr:
#sym level
get_corr_matrix_R.pl tmp_y_x.txt 2 >/tmp/tmpCorr.txt
cat _tmp_correlation.txt|gawk '{if(NR==1){print \"colName\",\$0}else{print \$0}}'|myFormatAuto.pl 1
#0.14822074
#long only shp and shp
echo \"\#\#LongOnlyShp and fcstShp (sym level):\"
getstats_fast.pl tmp_y_x.txt 1|myStatsToShp.sh
echo \"\#\#LongOnlyShp and fcstShp (sym level): yup\"
# when y is up
cat tmp_y_x.txt|myRmOutliersSimple.pl 1 3 0 1000000 1 >/tmp/tmp_y_x.txt.up
getstats_fast.pl /tmp/tmp_y_x.txt.up 1|myStatsToShp.sh
echo \"\#\#LongOnlyShp and fcstShp (sym level): ydown\"
# when y is down
cat tmp_y_x.txt|myRmOutliersSimple.pl 1 3 -1000000 0 1 >/tmp/tmp_y_x.txt.down
getstats_fast.pl /tmp/tmp_y_x.txt.down 1|myStatsToShp.sh
#
#
#
#idx level
getMeanStdByDate.pl tmp_y_x.txt 1 1 3|mygetcols.pl 1 4 6|myAddHeader.sh \"DATE ooF1DMean count\" >/tmp/ooF1DMean.txt
getMeanStdByDate.pl tmp_y_x.txt 1 1 5|mygetcols.pl 1 4 6|myAddHeader.sh \"DATE pnlMean count\" >/tmp/pnlMean.txt
combine_match1.pl /tmp/ooF1DMean.txt /tmp/pnlMean.txt|mygetcols.pl 1 2 5 6 >/tmp/ooF1DMean_pnlMean.txt
get_corr_matrix_R.pl /tmp/ooF1DMean_pnlMean.txt 1  >/tmp/tmpCorr.txt
cat _tmp_correlation.txt|gawk '{if(NR==1){print \"colName\",\$0}else{print \$0}}'|myFormatAuto.pl 1
#0.13004338
echo \"\#\#LongOnlyShp and fcstShp (idx level):\"
getstats_fast.pl /tmp/ooF1DMean_pnlMean.txt 1|myStatsToShp.sh
echo \"\#\#LongOnlyShp and fcstShp (idx level): yup\"
# when y is up
cat /tmp/ooF1DMean_pnlMean.txt|myRmOutliersSimple.pl 1 2 0 1000000 1 >/tmp/ooF1DMean_pnlMean.txt.up
getstats_fast.pl /tmp/ooF1DMean_pnlMean.txt.up 1|myStatsToShp.sh
echo \"\#\#LongOnlyShp and fcstShp (idx level): ydown\"
# when y is down
cat /tmp/ooF1DMean_pnlMean.txt|myRmOutliersSimple.pl 1 2 -1000000 0 1 >/tmp/ooF1DMean_pnlMean.txt.down
getstats_fast.pl /tmp/ooF1DMean_pnlMean.txt.down 1|myStatsToShp.sh
";
  # print "$cmd60x\n";
   system("$cmd60x");



print "\n\n######## corr (pnl,y) beta exposure: symbol level and idx level (netZA pnls) ###############\n";
    my $cmd60x2="
#--beta_exp for netZA pnls
cat pls.txt.$indName.netZA|mygetcols.pl 2 1 3 >/tmp/pls.txt.netZA
 combine_match2.pl tmp_y_x.txt.fcstNetZA /tmp/pls.txt.netZA| myrmcols.pl 5 6 > tmp_y_x.txt.$indName.fcstNetZA.pls
get_beta_exposure.pl tmp_y_x.txt.$indName.fcstNetZA.pls 2 3 5
";
   system("$cmd60x2");


__END__

# by asset
cat MADIFScls.txt|mygetcols.pl 1 2 3 4|myAssetSession_four_aseets.pl 1 1|egrep -E -e"DATE|Currency"|mygetcols.pl 1 2 3 4 >/tmp/subset.txt

#all
cat MADIFScls.txt|mygetcols.pl 1 2 3 4 >/tmp/subset.txt

#by syms
cat MADIFScls.txt|mygetcols.pl 1 2 3 4|egrep -w -E -e"DATE|ES|NQ" >/tmp/subset.txt
