#!/usr/bin/perl

use strict;

($#ARGV+2)==8 || die 
"Usage: get_portfolioShp_with_tcosts_optEntry_ZA.pl file.txt colSym colDate colY colFcst entry tcost(0.02)
       Compute porfolio shp and per commodity shp assuming linear tcost: use optZA method\n";


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



#get first date
my $cmd2012x="
check_duplicate.pl $filename  $colDate |fgrep -v DATE|head -1|mygetcols.pl 1
#19871007
";
 my $res2012x=`$cmd2012x`;
 chomp($res2012x);
my $firstDate=$res2012x;




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
print "Portfolio shp(netZA): file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1="
cat $filename |myFcstSubtractTcostNew_optZA_general.pl 1 $colSym $colDate $colFcst $entry|mygetcols.pl $colSym $colDate $colY $colFcstNet > $filename.fcstNetZA
cat $filename.fcstNetZA | myAfterTcostPnl_naive.pl 1 1 2 3 4 $tcost |fgrep -v DATE|mygetcols.pl 2 1 $colNet | myAddHeader.sh \"DATE SYM PL\" >pls.txt.$indName.netZA
compute_fcst_turnover.pl $filename.fcstNetZA 4 |gawk '{print \"netZATover:\",\$0}'
compute_fcst_unit_turnover.pl $filename.fcstNetZA 4 |gawk '{print \"netZAUtover:\",\$0}'
get_avg_hold_easy.pl $filename.fcstNetZA 1 2 4 20 |gawk '{print \"netZAAvgHold:\",\$0}'
";
# print "$cmd1\n";
   system("$cmd1");
my $pplFile="ppls.txt.$indName.netZA";
my $nPcShp;
my $nPortShp;
compute_shps_return_pcShp("pls.txt.$indName.netZA", $pplFile,\$nPcShp,\$nPortShp);
#print "nPcShp=$nPcShp nPortShp=$nPortShp \n";


## gross shps
print " ### Gross shps(grossZA) ###: file= $filename, fcst= $indName tcost=$tcost:\n";
    my $cmd1="
cat $filename.fcstNetZA | myAfterTcostPnl_naive.pl 1 1 2 3 4 $tcost |fgrep -v DATE|mygetcols.pl 2 1 $colGross | myAddHeader.sh \"DATE SYM PL\" >pls.txt.$indName.grossZA
";
# print "$cmd1\n";
   system("$cmd1");
$pplFile="ppls.txt.$indName.grossZA";
my $gPcShp;
my $gPortShp;
compute_shps_return_pcShp("pls.txt.$indName.grossZA", $pplFile,\$gPcShp,\$gPortShp);
#print "gPcShp=$gPcShp\n";
#pcSlip
my $pcSlip=$nPcShp-$gPcShp;
print "pcSlip = $pcSlip nPcShp = $nPcShp gPcShp = $gPcShp\n";


##-- this part is for plot gross and net pnls
# ppls.txt.$indName.grossZA
# ppls.txt.$indName.netZA

$gPortShp=nearest_junf(-6,$gPortShp);
$nPortShp=nearest_junf(-6,$nPortShp);






my $xmgrCmdStr="xmgrByDateGrid";
if($firstDate < 20000101)
{
  $xmgrCmdStr="xmgrByDateGrid5Y";
}



# get the data
    my $cmd="
datesXmgr.pl  ppls.txt.$indName.grossZA 1|fgrep -v DATE|myCum.pl 3|mygetcols.pl 1 5 >/tmp/forplot_ppl.txt.1
datesXmgr.pl  ppls.txt.$indName.netZA 1|fgrep -v DATE|myCum.pl 3|mygetcols.pl 1 5 >/tmp/forplot_ppl.txt.2
cat /home/jgeng/bin/batch_ppls_gross_net_2lines.txt | sed s/SYM/$indName/  | sed s/GSHP/$gPcShp/g| sed s/NSHP/$nPcShp/g | sed s/PCSLIP/$pcSlip/g | sed s/GPORTSHP/$gPortShp/g| sed s/NPORTSHP/$nPortShp/g  | sed s/XXX:XXX/$entry:$tcost/g  > /tmp/batch_ppls_gross_net_2lines.txt
#xmgrByDate  -batch /tmp/batch_ppls_gross_net_2lines.txt &
$xmgrCmdStr  -batch /tmp/batch_ppls_gross_net_2lines.txt &
";

#    print "$cmd\n";
    system("$cmd");





print "\n\n######## max drawdown(netZA), daily ret, pplFile= ppls.txt.$indName.netZA sizeX/tcost=$entry/$tcost ###############\n";
    my $cmd3="get_max_drawdown.pl ppls.txt.$indName.netZA  1 1 2
";
   print "cmd= $cmd3\n";
   system("$cmd3");






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
