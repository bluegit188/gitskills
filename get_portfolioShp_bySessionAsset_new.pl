#!/usr/bin/perl

use strict;

($#ARGV+2)==2 || die 
"Usage: get_portfolioShp_bySessionAsset.pl pls.txt(header)
       Compute shp by symbol
       input: DATE SYM PL\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];



    my $cmd1="
#port shp
cat $filename  |myAssetSession_four_aseets.pl 1 2|mygetcols.pl 1 5 6 3 2 |sed s/\\ /:/ |sed s/\\ /_/|sed s/ASSET4/ASSET/ >tmp_session_pl
cat tmp_session_pl| sed s/:/\\ / > tmp_session_pl.2
getMeanStdByDate.pl tmp_session_pl 1 1 2|gawk '{print \$1,\$4*\$6,\$6}'| sed s/:/\\ /|sort -k2,2 -k1,1g|myAddHeader.sh \"DATE SESSION PLPct\" >bySessionPl_$filename

#given pnls
getMeanStdByDate.pl bySessionPl_$filename 1 2 3 |mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7|gawk '{if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4}else{print \$1,\$2,\$3,0,0,\$4}}'|myAddHeader.sh \"SYM pplM pplStd portShp portShp.pa nDays\"  > /tmp/portShp.txt

#pctShp
getMeanStdByDate.pl tmp_session_pl.2 1 2 3|mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7|gawk '{if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4}else{print \$1,\$2,\$3,0,0,\$4}}'  |myAddHeader.sh \"SYM pl.mean pl.std pcShp pcShp.pa nobs\"|myFormatAuto.pl 1 >/tmp/pcShp.txt

#combine
 combine_match1.pl /tmp/pcShp.txt /tmp/portShp.txt|myrmcols.pl 7|fgrep -v SYM|gawk '{print \$0, \$5==0?0:\$10/\$5}'|myAddHeader.sh \"SYM pl.mean pl.std pcShp pcShp.pa nobs pplM pplStd portShp portShp.pa nDays divNum\"|myFormatAuto.pl 1
";

# print "$cmd1\n";
   system("$cmd1");


__END__


  cat plsPct.txt.fcstNet|myAssetSession_four_aseets.pl  1 2|mygetcols.pl 1 6 3|sed s/\ /:/ >a1
getMeanStdByDate.pl a1 1 1 2|gawk '{print $1,$4*$6,$6}'| sed s/:/\ /|sort -k2,2 -k1,1g|myAddHeader.sh "DATE ASSET PLPct" >a2
