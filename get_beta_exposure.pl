#!/usr/bin/perl

use strict;

($#ARGV+2)==5 || die 
"Usage: get_beta_exposure.pl file.txt colDate colY colPnl
       Compute beta exposure at sym and portfolio level
       corr(meanY, meanPnl)
       typical data format: DATE SYM ooF1D fcst pnl\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];


my $colDate=$ARGV[1];
my $colY=$ARGV[2];
my $colPnl=$ARGV[3];





 my $cmd0="
head -1 $filename |mygetcols.pl $colY
";
 my $res0=`$cmd0`;
 chomp($res0);
my $yName=$res0;


    my $cmd60x="
#--check pnl and y corr:
#sym level
get_corr_matrix_R.pl $filename 0 >/tmp/tmpCorr.txt
cat _tmp_correlation.txt|gawk '{if(NR==1){print \"colName\",\$0}else{print \$0}}'|myFormatAuto.pl 1
#0.14822074
#long only shp and shp
echo \"\#\#LongOnlyShp and fcstShp (sym level):\"
getstats_fast.pl $filename 1|myStatsToShp.sh
echo \"\#\#LongOnlyShp and fcstShp (sym level): yup\"
# when y is up
cat $filename|myRmOutliersSimple.pl 1 $colY 0 1000000 1 >/tmp/$filename.up
getstats_fast.pl /tmp/$filename.up 1|myStatsToShp.sh
echo \"\#\#LongOnlyShp and fcstShp (sym level): ydown\"
# when y is down
cat $filename|myRmOutliersSimple.pl 1 $colY -1000000 0 1 >/tmp/$filename.down
getstats_fast.pl /tmp/$filename.down 1|myStatsToShp.sh
#
#
#
#idx level
getMeanStdByDate.pl $filename 1 $colDate $colY|mygetcols.pl 1 4 6|myAddHeader.sh \"DATE ooF1DMean count\" >/tmp/ooF1DMean.txt
getMeanStdByDate.pl $filename 1 $colDate $colPnl|mygetcols.pl 1 4 6|myAddHeader.sh \"DATE pnlMean count\" >/tmp/pnlMean.txt
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
    my ($pnlFile, $pplFile, $refPcShp, $refPortShp) = @_;

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

$$refPortShp=$portShp*sqrt(252);# annualized

my $divNum=$portShp/$pcShp;
printf "divNum = portShp/pcShp= $portShp / $pcShp = %.7f\n",$divNum;

}

sub nearest_junf()
# emulate Math::Round's nearest function, but elimiate extra zeros from $.4f notation
# input: -4, 3.56789 (max to 4th decimal digits
# output: 3.568
#
#more examples: first argu=-4
#0         -> 0
#0.1       -> 0.1
#0.11      -> 0.11
#0.111     -> 0.111
#0.1111111 -> 0.1111
{
    my ($pow10, $x) = @_;
    my $a = 10 ** $pow10;

    return (int($x / $a + (($x < 0) ? -0.5 : 0.5)) * $a);
}

__END__
