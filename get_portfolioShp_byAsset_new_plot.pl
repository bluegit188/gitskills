#!/usr/bin/perl

use strict;

( ($#ARGV+2)==2 || ($#ARGV+2)==3 )|| die 
"Usage: get_portfolioShp_byAsset.pl pls.txt(header) [opt: subtitle]
       Compute shp by asset
       Use double quotes for subtitle
       input: DATE SYM PL\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];

my $subtitle="";

if( $#ARGV+2==3)
{
    $subtitle=$ARGV[1];
}


    my $cmd1="
#port shp
cat $filename  |myAssetSession_four_aseets.pl 1 2|mygetcols.pl 1 6 3 2 |sed s/\\ /:/ >tmp_asset_pl
cat tmp_asset_pl| sed s/:/\\ / > tmp_asset_pl.2
getMeanStdByDate.pl tmp_asset_pl 1 1 2|gawk '{print \$1,\$4*\$6,\$6}'| sed s/:/\\ /|sort -k2,2 -k1,1g|myAddHeader.sh \"DATE ASSET PLPct\" >byAssetPl_$filename

#given pnls
getMeanStdByDate.pl byAssetPl_$filename 1 2 3 |mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7|gawk '{if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4}else{print \$1,\$2,\$3,0,0,\$4}}'|myAddHeader.sh \"SYM pplM pplStd portShp portShp.pa nDays\"  > /tmp/portShp.txt

#pcShp
getMeanStdByDate.pl tmp_asset_pl.2 1 2 3|mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7|gawk '{if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4}else{print \$1,\$2,\$3,0,0,\$4}}'  |myAddHeader.sh \"SYM pl.mean pl.std pcShp pcShp.pa nobs\"|myFormatAuto.pl 1 >/tmp/pcShp.txt

#ppl min/max in stds
getMeanStdByDate.pl byAssetPl_$filename 1 2 3 |gawk '{print \$1, \$2/\$5,\$3/\$5}'|myFloatRoundingInPlace.pl 0 2 4|myFloatRoundingInPlace.pl 0 3 4 |myAddHeader.sh \"SYM pplMinStd pplMaxStd\"  > /tmp/pplMinMax.txt


#combine
# combine_match1.pl /tmp/pcShp.txt /tmp/portShp.txt|myrmcols.pl 7|fgrep -v SYM|gawk '{print \$0, \$5==0?0:\$10/\$5}'|myAddHeader.sh \"SYM pl.mean pl.std pcShp pcShp.pa nobs pplM pplStd portShp portShp.pa nDays divNum\"|myFormatAuto.pl 1

#combine
combine_match1na_all.pl /tmp/pcShp.txt /tmp/portShp.txt  /tmp/pplMinMax.txt|myrmcols.pl 1 8 14 |fgrep -v SYM|gawk '{print \$0, \$5==0?0:\$10/\$5}'|myAddHeader.sh \"SYM pl.mean pl.std pcShp pcShp.pa nobs pplM pplStd portShp portShp.pa nDays pplMinStd pplMaxStd divNum\"|myFormatAuto.pl 1  > /tmp/table_assetShp.txt

cat  /tmp/table_assetShp.txt
";

# print "$cmd1\n";
   system("$cmd1");


#get first date
my $cmd2012x="
check_duplicate.pl  $filename 1|fgrep -v DATE|head -1|mygetcols.pl 1
#19871007
";
 my $res2012x=`$cmd2012x`;
 chomp($res2012x);
my $firstDate=$res2012x;

my $xmgrCmdStr="xmgrByDateGrid";
if($firstDate < 20000101)
{
  $xmgrCmdStr="xmgrByDateGrid5Y";
}


############
## for plot
my $cmd2="cat /tmp/table_assetShp.txt|mygetcols.pl 1 10|myTranspose.pl|mygetcols.pl 4 3 2 5|tail -1";
#0.890449 0.759419 0.408102 0.919837
 my $res2=`$cmd2`;
 chomp($res2);
my ($shp_stock,$shp_bond,$shp_curr,$shp_phy)=split(' ',$res2);

my $cmd3="
cat  byAssetPl_pls.txt |egrep -E -e\" Index \"|myCum.pl 3 |mygetcols.pl 1 5 >/tmp/tmp_as_pl.txt.1
cat  byAssetPl_pls.txt |egrep -E -e\" Financial \"|myCum.pl 3 |mygetcols.pl 1 5 >/tmp/tmp_as_pl.txt.2
cat  byAssetPl_pls.txt |egrep -E -e\" Currency \"|myCum.pl 3 |mygetcols.pl 1 5 >/tmp/tmp_as_pl.txt.3
cat  byAssetPl_pls.txt |egrep -E -e\" Physical \"|myCum.pl 3 |mygetcols.pl 1 5 >/tmp/tmp_as_pl.txt.4
combine_match1na_all.pl /tmp/tmp_as_pl.txt.1 /tmp/tmp_as_pl.txt.2 /tmp/tmp_as_pl.txt.3 /tmp/tmp_as_pl.txt.4|mygetcols.pl 1 3 5 7 9  | egrep -v -E -e \" NA\" > tmp_byAssetPl_table.txt
datesXmgr.pl tmp_byAssetPl_table.txt 1 >/tmp/tmp_byAssetPl_table.txt.forplot
cat /home/jgeng/bin/batch_byAsset_plot.txt    | sed s/SHP1/$shp_stock/ | sed s/SHP2/$shp_bond/ | sed s/SHP3/$shp_curr/ | sed s/SHP4/$shp_phy/  | sed s/#subtitle/subtitle\\ \\\"$subtitle\\\"/ > /tmp/batch_byAsset_plot.txt
$xmgrCmdStr -batch /tmp/batch_byAsset_plot.txt &
";
#print("$cmd3");
system("$cmd3");
    

__END__


  cat plsPct.txt.fcstNet|myAssetSession_four_aseets.pl  1 2|mygetcols.pl 1 6 3|sed s/\ /:/ >a1
getMeanStdByDate.pl a1 1 1 2|gawk '{print $1,$4*$6,$6}'| sed s/:/\ /|sort -k2,2 -k1,1g|myAddHeader.sh "DATE ASSET PLPct" >a2


#perCom shps
 more tmp_asset_pl| sed s/:/\ / > tmp_asset_pl.2

getMeanStdByDate.pl tmp_asset_pl.2 1 2 3|mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7|gawk '{if($3!=0){print $1,$2,$3,$2/$3,$2/$3*sqrt(252),$4}else{print $1,$2,$3,0,0,$4}}'|myAddHeader.sh "SYM pl.mean pl.std pcShp pcShp.pa nobs"|myFormatAuto.pl 1 >/tmp/pcShp.txt

get_portfolioShp_byAsset.pl pls.txt.bt1Fcst.dm > /tmp/portShp.txt 


 combine_match1.pl /tmp/pcShp.txt /tmp/portShp.txt|myrmcols.pl 7|fgrep -v SYM|gawk '{print $0, $5==0?0:$10/$5}'|myAddHeader.sh "SYM    pl.mean    pl.std      pcShp  pcShp.pa nobs       pplM    pplStd    portShp portShp.pa nDays divNum"|myFormatAuto.pl 1



Currency -0.015764 0.0138264 0.000111322725071059 0.00193271416692757 1548
Financial -0.0283673 0.0495859 0.000269453914757909 0.00387207422535384 1549
Index -0.0168214 0.0459466 0.000205318755320513 0.00282542585219997 1560
Physical -0.0113427 0.0245883 0.000406012973109244 0.00311314678196674 1547
