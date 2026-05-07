#!/usr/bin/perl

use File::Basename;
use strict;


my $DEBUG=0;

 ($#ARGV+2)==4  || die
"Usage: plot_rolling_corrTimeSeries_bySyms.pl  sym1 sym2 type=60/100/400
       Plot rolling corr of past X-days\n";

my $sym1=$ARGV[0];
my $sym2=$ARGV[1];

my $X=$ARGV[2]; # window size


# get the data
    my $cmd="
portara_get_ooRets.pl $sym1 5 |mygetcols.pl 2 1 3 | myConstraintSimple.pl 3 -4 4 > /tmp/ccP1D.txt.$sym1
portara_get_ooRets.pl $sym2 5 |mygetcols.pl 2 1 3 | myConstraintSimple.pl 3 -4 4 > /tmp/ccP1D.txt.$sym2
combine_match1.pl /tmp/ccP1D.txt.$sym1 /tmp/ccP1D.txt.$sym2|mygetcols.pl 1 3 6|fgrep -v DATE|gawk '{print \"AAA\",\$0}'|myAddHeader.sh \"SYM DATE $sym1 $sym2\" > /tmp/ccP1D.txt.$sym1.$sym2
get_rolling_corr_fast.pl /tmp/ccP1D.txt.$sym1.$sym2 3 4 $X|mygetcols.pl 2 5 > /tmp/corP1D_100D.txt.$sym1.$sym2
datesXmgr.pl /tmp/corP1D_100D.txt.$sym1.$sym2 1|fgrep -v DATE|mygetcols.pl 1 3 > /tmp/forplot_corP1D_100D.txt.$sym1.$sym2
echo \"title \\\"Rolling corrP${X}D for $sym1 vs $sym2\\\"\" > /tmp/title.txt
xmgrByDate  -batch /tmp/title.txt /tmp/forplot_corP1D_100D.txt.$sym1.$sym2 &
";

#    print "$cmd\n";
    system("$cmd");




__END__


--cmd:

portara_get_ooRets.pl DX 5 |mygetcols.pl 2 1 3 | myConstraintSimple.pl 3 -4 4 > /tmp/ccP1D.txt.DX
portara_get_ooRets.pl CL 5 |mygetcols.pl 2 1 3 | myConstraintSimple.pl 3 -4 4 > /tmp/ccP1D.txt.CL
combine_match1.pl /tmp/ccP1D.txt.DX /tmp/ccP1D.txt.CL|mygetcols.pl 1 3 6|fgrep -v DATE|gawk '{print "AAA",$0}'|myAddHeader.sh "SYM DATE DX CL" > /tmp/ccP1D.txt.DX.CL
get_rolling_corr_fast.pl /tmp/ccP1D.txt.DX.CL 3 4 100|mygetcols.pl 2 5 > /tmp/corP1D_100D.txt.DX.CL
datesXmgr.pl /tmp/corP1D_100D.txt.DX.CL 1|fgrep -v DATE|mygetcols.pl 1 3 > /tmp/forplot_corP1D_100D.txt.DX.CL
echo "title \"Rolling corrP100D for DX vs CL\"" > /tmp/title.txt
xmgrByDate  -batch /tmp/title.txt /tmp/forplot_corP1D_100D.txt.DX.CL















xmgrByDate  -autoscale none -timestamp -param /home/jgeng/wli.par  -batch xmgr.batch -nosafe ^C

1037  datesXmgr.pl a 1|mygetcols.pl 1 8 >b
 1038  xmgrByDate b&
 1039  more b
 1040  xmgrByDate b
 1041  more b
 1042  more b|cat
 1043  extract_CorrTimeSeries_from_corrMatrix_bySyms.pl DX CL 19800101 20160202 100 >a
 1044  datesXmgr.pl a 1|mygetcols.pl 1 8 >b
 1045  xmgrByDate b
 1046  pico aaa
 1047  xmgrByDate  -batch aaa b
 1048  bg
 1049  history 
 1050  more ~/bin/extract_CorrTimeSeries_from_corrMatrix_bySyms.pl
