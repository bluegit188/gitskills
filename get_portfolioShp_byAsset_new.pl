#!/usr/bin/perl

use strict;

($#ARGV+2)==2 || die 
"Usage: get_portfolioShp_byAsset.pl pls.txt(header)
       Compute shp by symbol
       input: DATE SYM PL\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];

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
combine_match1na_all.pl /tmp/pcShp.txt /tmp/portShp.txt  /tmp/pplMinMax.txt|myrmcols.pl 1 8 14 |fgrep -v SYM|gawk '{print \$0, \$5==0?0:\$10/\$5}'|myAddHeader.sh \"SYM pl.mean pl.std pcShp pcShp.pa nobs pplM pplStd portShp portShp.pa nDays pplMinStd pplMaxStd divNum\"|myFormatAuto.pl 1


";

# print "$cmd1\n";
   system("$cmd1");

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
