#!/usr/bin/perl

use strict;

($#ARGV+2)==2 || die 
"Usage: get_portfolioShp_bySym.pl pls.txt(header)
       Compute shp by symbol
       input: DATE SYM PL\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];

    my $cmd1=" 
 #given pnls
getMeanStdByDate.pl $filename 1 2 3 |mygetcols.pl 1 4 5 6|myFloatRoundingInPlace.pl 0 2 7|myFloatRoundingInPlace.pl 0 3 7|gawk '{if(\$3!=0){print \$1,\$2,\$3,\$2/\$3,\$2/\$3*sqrt(252),\$4}else{print \$1,\$2,\$3,0,0,\$4}}'|myAddHeader.sh \"SYM pl.mean pl.std shp shp.pa nDays\"|myFormatAuto.pl 1
";

# print "$cmd1\n";
   system("$cmd1");


