#!/usr/bin/perl

use strict;

($#ARGV+2)==6 || die 
"Usage: get_avg_hold_easy.pl file.txt colSym colDate colFcst(pos) maxLen(20)
       Compute postion or fcst avgHold, note only count NEW positions
       Cap maxHold at, e.g, 20 days;
       Holding days distribution is here: /tmp/holdDaysDist.txt \n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];

my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colFcst=$ARGV[3];

my $maxN=$ARGV[4];


 my $cmd0="
head -1 $filename |mygetcols.pl $colFcst
";
 my $res0=`$cmd0`;
 chomp($res0);
my $indName=$res0;



 my $cmd0a="
#get pos only
cat $filename |mygetcols.pl $colSym $colDate $colFcst >/tmp/pos.txt
#get hold length
get_avg_hold.pl /tmp/pos.txt >/tmp/flags.txt
# extract independent trades, if the next is new
get_prev_row.pl /tmp/flags.txt 1 1|gawk '{if(\$5==\"NEW\"){print \$0}}'|mygetcols.pl 6 7 8 9 10 |myConstraintSimpleNew.pl 0 4 0 $maxN >/tmp/indepTrades.txt
# allow both new and old
#get_prev_row.pl /tmp/flags.txt 1 1|mygetcols.pl 6 7 8 9 10 |myConstraintSimpleNew.pl 0 4 0 $maxN >/tmp/indepTrades.txt
check_duplicate.pl /tmp/indepTrades.txt 4|sort -gk1,1|egrep -v -E -e\"\^0\" |fgrep -v \"length\">/tmp/posLen.txt
cat  /tmp/posLen.txt |mySum.pl 2|mygetcols.pl 2
#8880
";
 my $res0a=`$cmd0a`;
 chomp($res0a);
my $numObs=$res0a;


# get avgHold
    my $cmd1="
cat /tmp/posLen.txt |gawk '{print \$0,\$2/$numObs}'|myFormatAuto.pl 1 >/tmp/holdDaysDist.txt
cat /tmp/holdDaysDist.txt|gawk '{print \$0, \$1*\$3}'|mySum.pl 4|mygetcols.pl 2
";
# print "$cmd1\n";
 my $res1=`$cmd1`;
 chomp($res1);
my $avgHold=$res1;
printf "$filename $indName holdDays: avgHold= %.2f maxHold= %.0f\n",$avgHold, $maxN;

__END__


#get pos only
cat Y_X_simu_fcst.txt.fcstNetZA |mygetcols.pl 1 2 4 >/tmp/pos.txt
#get hold length
 get_avg_hold.pl /tmp/pos.txt >/tmp/flags.txt
# extract independent trades, if the next is new
get_prev_row.pl /tmp/flags.txt 1 1|gawk '{if($5=="NEW"){print $0}}'|mygetcols.pl 6 7 8 9 10 |myConstraintSimpleNew.pl 0 4 0 20 >/tmp/indepTrades.txt
check_duplicate.pl /tmp/indepTrades.txt 4|sort -gk1,1|egrep -v -E -e"^0" >/tmp/posLen.txt
cat  /tmp/posLen.txt |mySum.pl 2|mygetcols.pl 2
8880


 cat /tmp/posLen.txt |gawk '{print $0,$2/8880}'|myFormatAuto.pl 1 >/tmp/holdDaysDist.txt

  1 5024    0.483495 0.483495
  2 2249    0.216437 0.432874
  3 1271    0.122317 0.366951
  4  815   0.0784333 0.313733
  5  326   0.0313733 0.156866
  6  246   0.0236743 0.142046
  7  164   0.0157829 0.11048
  8   99  0.00952748 0.0762198
  9   70   0.0067366 0.0606294
 10   38  0.00365701 0.0365701
 11   34  0.00327206 0.0359927
 12   21  0.00202098 0.0242518
 13    9 0.000866134 0.0112597
 14   11  0.00105861 0.0148205
 15    4 0.000384949 0.00577423
 16    7  0.00067366 0.0107786
 17    3 0.000288711 0.00490809

cat /tmp/holdDaysDist.txt|gawk '{print $0, $1*$3}'|mySum.pl 4
sum= 2.40135237 count= 20




# extract independent trades, if the next is new
get_prev_row.pl /tmp/flags.txt 1 1|gawk '{if(($5=="NEW" && $10=="OLD")||($5=="NEW" && $10=="NEW")  ){print $0}}'|mygetcols.pl 6 7 8 9 10 |myConstraintSimpleNew.pl 0 4 0 20 >/tmp/indepTrades.txt

get_prev_row.pl /tmp/flags.txt 1 1|gawk '{if($5=="NEW" && $10=="OLD"  ){print $0}}'|mygetcols.pl 6 7 8 9 10 |myConstraintSimpleNew.pl 0 4 0 20 >/tmp/indepTrades.txt



check_duplicate.pl /tmp/indepTrades.txt 4|sort -gk1,1|egrep -v -E -e"^0" >/tmp/posLen.txt
cat  /tmp/posLen.txt |mySum.pl 2|mygetcols.pl 2
531


 cat /tmp/posLen.txt |gawk '{print $0,$2/17779}'|myFormatAuto.pl 1 >/tmp/holdDaysDist.txt

  1 5024    0.483495 0.483495
  2 2249    0.216437 0.432874
  3 1271    0.122317 0.366951
  4  815   0.0784333 0.313733
  5  326   0.0313733 0.156866
  6  246   0.0236743 0.142046
  7  164   0.0157829 0.11048
  8   99  0.00952748 0.0762198
  9   70   0.0067366 0.0606294
 10   38  0.00365701 0.0365701
 11   34  0.00327206 0.0359927
 12   21  0.00202098 0.0242518
 13    9 0.000866134 0.0112597
 14   11  0.00105861 0.0148205
 15    4 0.000384949 0.00577423
 16    7  0.00067366 0.0107786
 17    3 0.000288711 0.00490809

cat /tmp/holdDaysDist.txt|gawk '{print $0, $1*$3}'|mySum.pl 4
sum= 2.40135237 count= 20

