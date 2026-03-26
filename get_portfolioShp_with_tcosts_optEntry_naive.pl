#!/usr/bin/perl

use strict;

($#ARGV+2)==8 || die 
"Usage: get_portfolioShp_with_tcosts_optEntry_naive.pl file.txt colSym colDate colY colFcst entry tcost(0.02)
       Compute porfolio shp and per commodity shp assuming linear tcost: use naive method\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];

my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colY=$ARGV[3];
my $colFcst=$ARGV[4];

my $entry=$ARGV[5];
my $tcost=$ARGV[6];


 my $cmd0="
head -1 $filename |mygetcols.pl $colFcst
";
 my $res0=`$cmd0`;
 chomp($res0);
my $indName=$res0;



 my $cmd0a="
head -1 $filename |wc|mygetcols.pl 2
";
 my $res0a=`$cmd0a`;
 chomp($res0a);
my $numCols=$res0a;

my $colFcstNet= $numCols+1;


my $colPL= $numCols+3;

my $colNet=7;
my $colGross=6;

### netShps
print "Portfolio shp(naive): file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1="
cat $filename |myFcstSubtractTcostNew_optZA_general.pl 1 $colSym $colDate $colFcst $entry|mygetcols.pl $colSym $colDate $colY $colFcstNet > $filename.fcstNetNaive
cat $filename.fcstNetNaive | myAfterTcostPnl_naive.pl 1 1 2 3 4 $tcost |fgrep -v DATE|mygetcols.pl 2 1 $colNet | myAddHeader.sh \"DATE SYM PL\" >pls.txt.$indName.netNaive
compute_fcst_turnover.pl $filename.fcstNetNaive 4 |gawk '{print \"netNaiveTover:\",\$0}'
";
# print "$cmd1\n";
   system("$cmd1");
my $pplFile="ppls.txt.$indName.netNaive";
compute_shps("pls.txt.$indName.netNaive", $pplFile);


## gross shps
print " ### Gross shps(grossNaive) ###: file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1="
cat $filename.fcstNetNaive | myAfterTcostPnl_naive.pl 1 1 2 3 4 $tcost |fgrep -v DATE|mygetcols.pl 2 1 $colGross | myAddHeader.sh \"DATE SYM PL\" >pls.txt.$indName.grossNaive
";
# print "$cmd1\n";
   system("$cmd1");
$pplFile="ppls.txt.$indName.grossNaive";
compute_shps("pls.txt.$indName.grossNaive", $pplFile);




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


__END__
