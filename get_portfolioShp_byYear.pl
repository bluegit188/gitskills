#!/usr/bin/perl

use strict;

($#ARGV+2)==2 || die 
"Usage: get_portfolioShp_byYear.pl pls.txt(header)
       Compute pcShp and portShp by year
       input: DATE SYM PL\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];

    my $cmd1="
 #pcShp by year
 cat $filename |fgrep -v DATE|myYear.pl 0 1 >tmp_pls_year.txt
 getMeanStdByDate.pl tmp_pls_year.txt 0 4 3|mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7 |gawk '{ if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4}else{print \$1,\$2,\$3,\"0\",0, \$4}}'  >tmp_pcShp_year.txt
 #port shp by year
 getMeanStdByDate.pl $filename 1 1 3|gawk '{print \$1,\$4*\$6,\$6}' |myYear.pl 0  1 >tmp_ppls_year.txt
getMeanStdByDate.pl tmp_ppls_year.txt 0 4 2 |mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7  |gawk '{ if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4 }else{print \$1,\$2,\$3,\"0\",0,\$4}}' >tmp_portShp_year.txt
 #combine
combine_match1.pl tmp_pcShp_year.txt tmp_portShp_year.txt|myrmcols.pl 7|gawk '{if(\$5!=0){print \$0, \$10/\$5}else{print \$0,0}}'|myAddHeader.sh \"YEAR pl.mean pl.std pcShp pcShp.pa nObs ppl.mean ppl.std portShp portShp.pa nDays divNum\"|myFormatAuto.pl 1
";

# print "$cmd1\n";
   system("$cmd1");

