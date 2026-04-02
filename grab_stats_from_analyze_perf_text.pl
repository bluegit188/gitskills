#!/usr/bin/perl

use strict;

 ($#ARGV+2)==2 || die 
"Usage: grab_stats_from_analyze_perf_text.pl perf.txt
       Just grab some stats from perf.txt file
\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];


 my $cmd0="
#gshp.naive:
cat $filename|egrep -A 10 -E -e\"gross pcShp and portShp\"|fgrep \"PPL \"|mygetcols.pl 9
";
 my $res0=`$cmd0`;
 chomp($res0);
my $gshpNaive=$res0;


 my $cmd1="
#nshp.naive
cat $filename|egrep -A 10 -E -e\"naive tcost method\"|fgrep \"PPL \"|mygetcols.pl 9
";
 my $res1=`$cmd1`;
 chomp($res1);
my $nshpNaive=$res1;



# XT method:
$cmd1="
cat $filename|egrep -A 20 -E -e\"netShp, opt entry/XT\"|fgrep \"PPL \"|mygetcols.pl 9|myTranspose.pl
";
$res1=`$cmd1`;
 chomp($res1);
my ($nshpXT, $gshpXT)=split(' ',$res1);

# ZA method:
$cmd1="
cat $filename|egrep -A 20 -E -e\"netShp, optZA method\"|fgrep \"PPL \"|mygetcols.pl 9|myTranspose.pl
";
$res1=`$cmd1`;
 chomp($res1);
my ($nshpZA, $gshpZA)=split(' ',$res1);


# ZAY method:
$cmd1="
cat $filename|egrep -A 20 -E -e\"netShp, optZAY method\"|fgrep \"PPL \"|mygetcols.pl 9|myTranspose.pl
";
$res1=`$cmd1`;
 chomp($res1);
my ($nshpZAY, $gshpZAY)=split(' ',$res1);



# ZAMR method:
$cmd1="
cat $filename|egrep -A 20 -E -e\"netShp, optZAMR method\"|fgrep \"PPL \"|mygetcols.pl 9|myTranspose.pl
";
$res1=`$cmd1`;
 chomp($res1);
my ($nshpZAMR, $gshpZAMR)=split(' ',$res1);




print "TYPE $filename\n";
print "gshp.Naive $gshpNaive\n";
print "nshp.Naive $nshpNaive\n";
print "\n";
print "gshp.XT $gshpXT\n";
print "nshp.XT $nshpXT\n";
print "\n";
print "gshp.ZA $gshpZA\n";
print "nshp.ZA $nshpZA\n";
print "\n";
print "gshp.ZAY $gshpZAY\n";
print "nshp.ZAY $nshpZAY\n";
print "\n";
print "gshp.ZAMR $gshpZAMR\n";
print "nshp.ZAMR $nshpZAMR\n";





__END__


#gshp.naive and net shps:

 cat perf.txt.V95|egrep -A 10 -E -e"gross pcShp and portShp"|fgrep "PPL "|mygetcols.pl 9
3.67414


 cat perf.txt.V95|egrep -A 10 -E -e"naive tcost method"|fgrep "PPL "|mygetcols.pl 9

2.05962

# XT method:

 cat perf.txt.V95|egrep -A 20 -E -e"netShp, opt entry/XT" |fgrep "PPL "|mygetcols.pl 9 |myTranspose.pl
2.19224 3.69842


# ZA method:

 cat perf.txt.V95|egrep -A 20 -E -e"netShp, optZA method" |fgrep "PPL "|mygetcols.pl 9 |myTranspose.pl
1.97549 3.08884

# ZAY method:

 cat perf.txt.V95|egrep -A 20 -E -e"netShp, optZAY method" |fgrep "PPL "|mygetcols.pl 9 |myTranspose.pl
2.04506 3.14728



# ZAMR method:

 cat perf.txt.V95|egrep -A 20 -E -e"netShp, optZAMR method" |fgrep "PPL "|mygetcols.pl 9 |myTranspose.pl

1.81797 3.0735
