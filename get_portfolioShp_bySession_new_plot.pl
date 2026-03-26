#!/usr/bin/perl

use strict;

( ($#ARGV+2)==2 || ($#ARGV+2)==3 )|| die
"Usage: get_portfolioShp_bySession.pl pls.txt(header) [opt: subtitle]
       Compute shp by symbol
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
cat $filename  |myAssetSession_four_aseets.pl 1 2|mygetcols.pl 1 5 3 2 |sed s/\\ /:/ >tmp_session_pl
cat tmp_session_pl| sed s/:/\\ / > tmp_session_pl.2
getMeanStdByDate.pl tmp_session_pl 1 1 2|gawk '{print \$1,\$4*\$6,\$6}'| sed s/:/\\ /|sort -k2,2 -k1,1g|myAddHeader.sh \"DATE SESSION PLPct\" >bySessionPl_$filename

#given pnls
getMeanStdByDate.pl bySessionPl_$filename 1 2 3 |mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7|gawk '{if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4}else{print \$1,\$2,\$3,0,0,\$4}}'|myAddHeader.sh \"SYM pplM pplStd portShp portShp.pa nDays\"  > /tmp/portShp.txt

#pctShp
getMeanStdByDate.pl tmp_session_pl.2 1 2 3|mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7|gawk '{if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4}else{print \$1,\$2,\$3,0,0,\$4}}'  |myAddHeader.sh \"SYM pl.mean pl.std pcShp pcShp.pa nobs\"|myFormatAuto.pl 1 >/tmp/pcShp.txt

#combine
 combine_match1.pl /tmp/pcShp.txt /tmp/portShp.txt|myrmcols.pl 7|fgrep -v SYM|gawk '{print \$0, \$5==0?0:\$10/\$5}'|myAddHeader.sh \"SYM pl.mean pl.std pcShp pcShp.pa nobs pplM pplStd portShp portShp.pa nDays divNum\"|myFormatAuto.pl 1  > /tmp/table_sessionShp.txt

cat  /tmp/table_sessionShp.txt
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
my $cmd2="cat /tmp/table_sessionShp.txt|mygetcols.pl 1 10|myTranspose.pl|mygetcols.pl 3 4 2|tail -1";
#0.890449 0.759419 0.408102 0.919837
 my $res2=`$cmd2`;
 chomp($res2);
my ($shp_asia,$shp_eur,$shp_america)=split(' ',$res2);

my $cmd3="
cat  bySessionPl_pls.txt |egrep -E -e\" Asia \"|myCum.pl 3 |mygetcols.pl 1 5 >/tmp/tmp_as_pl.txt.1
cat  bySessionPl_pls.txt |egrep -E -e\" Europe \"|myCum.pl 3 |mygetcols.pl 1 5 >/tmp/tmp_as_pl.txt.2
cat  bySessionPl_pls.txt |egrep -E -e\" America \"|myCum.pl 3 |mygetcols.pl 1 5 >/tmp/tmp_as_pl.txt.3
combine_match1na_all.pl /tmp/tmp_as_pl.txt.1 /tmp/tmp_as_pl.txt.2 /tmp/tmp_as_pl.txt.3 |mygetcols.pl 1 3 5 7  | egrep -v -E -e \" NA\" > tmp_bySessionPl_table.txt
datesXmgr.pl tmp_bySessionPl_table.txt 1 >/tmp/tmp_bySessionPl_table.txt.forplot
cat /home/jgeng/bin/batch_bySession_plot.txt    | sed s/SHP1/$shp_asia/ | sed s/SHP2/$shp_eur/ | sed s/SHP3/$shp_america/   | sed s/#subtitle/subtitle\\ \\\"$subtitle\\\"/ > /tmp/batch_bySession_plot.txt
$xmgrCmdStr -batch /tmp/batch_bySession_plot.txt &
";
#print("$cmd3");
system("$cmd3");
    


__END__


  cat plsPct.txt.fcstNet|myAssetSession_four_aseets.pl  1 2|mygetcols.pl 1 6 3|sed s/\ /:/ >a1
getMeanStdByDate.pl a1 1 1 2|gawk '{print $1,$4*$6,$6}'| sed s/:/\ /|sort -k2,2 -k1,1g|myAddHeader.sh "DATE ASSET PLPct" >a2
