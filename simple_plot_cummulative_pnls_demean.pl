#!/usr/bin/perl

use strict;

($#ARGV+2) >=13 || die 
"Usage: simple_plot_cummulative_pnls_demean.pl file.txt startDate endDate colSym colDate colY colFcst  fmin:fmax mean=x/0.02 beta  A/B/AB [all/stock/bond/curr/phy/sir/smallu3/allexphy/allexstock/aisa/europe/america/Index_Asia/eurIBC/nonEurIBC  or symbols]
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
cat /tmp/subset.txt |myRmOutliersSimple.pl 1 2 $startDate $endDate 1 |fgrep -v DATE|gawk '{print \$2,\$1,\$3,\$4}'|myAddHeader.sh \"DATE SYM $yName $indName\"   |myConstraintSimple.pl 4 $xmin $xmax  |mySampleSelector.pl 1 1 $sampleTag >/tmp/raw_y_x.txt";

#print "$cmda0\n";
system("$cmda0");


#fcsts stats
my $cmd201="
echo \"\#\#Fcsts Stats (raw fcst before demean):\"
getstats_fast.pl /tmp/raw_y_x.txt 1|myFormatAuto.pl 1
";
system("$cmd201");



########################
#demean fcsts and check stats again
my $cmd2012="
cat  /tmp/raw_y_x.txt|myDemeanFcstInPlace.pl 1 4 $userMean |gawk '{ if( NR==1){print \$0,\"pnl\"}else{print \$0,\$3*\$4}}'  > /tmp/y_x.txt
echo \"\#\#Fcsts Stats (demean fcst):\"
getstats_fast.pl /tmp/y_x.txt 1|myFormatAuto.pl 1
";
system("$cmd2012");


#tover
my $cmd20="
compute_fcst_turnover.pl /tmp/y_x.txt 4
";
system("$cmd20");




#comb
my $cmd2="
get_corr_matrix_R.pl /tmp/y_x.txt 0 >/tmp/a0 2>/dev/null
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
 get_corr_matrix_R.pl /tmp/y_x.txt.gc 0 >/tmp/a 2>/dev/null
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




   my $cmd32="
datesXmgr.pl /tmp/ppls.txt 1 |fgrep -v DATE|gawk '{print \$1,\$3}'|myCum.pl 2 |mygetcols.pl 1 3 > /tmp/forplot &
echo \"title size 0.9\ntitle \\\"$filterStr (xmin:xmax=$xmin:$xmax userMean=$userMean beta=$beta sam=$sampleTag): \\n$yName~$indName corr=$corr corrZM=$corZM dates=$dateRange rshp=$rshp mdd=$mdd\\\"\ns0 symbol 2\ns0 symbol size 0.1\ns0 symbol fill 1\" > /tmp/title.txt
xmgrByDateGrid  -batch /tmp/title.txt /tmp/forplot  1>/dev/null 2>/dev/null &
echo \"\n\#\#PPLShp:\"
getstats_fast.pl /tmp/ppls.txt 1|myStatsToShp.sh
";

   #print "$cmd32\n";
   system("$cmd32");



__END__

# by asset
cat MADIFScls.txt|mygetcols.pl 1 2 3 4|myAssetSession_four_aseets.pl 1 1|egrep -E -e"DATE|Currency"|mygetcols.pl 1 2 3 4 >/tmp/subset.txt

#all
cat MADIFScls.txt|mygetcols.pl 1 2 3 4 >/tmp/subset.txt

#by syms
cat MADIFScls.txt|mygetcols.pl 1 2 3 4|egrep -w -E -e"DATE|ES|NQ" >/tmp/subset.txt
