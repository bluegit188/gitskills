#!/usr/bin/perl

use strict;

($#ARGV+2) ==5 || die
"Usage: compute_subset_tDev.pl cor_by_key.txt N beta_full tSP
       Compute subset beta tDev for a given corr_by_key result file
cor_by_key.txt example
dateRange: 20140102 20231018
FGAP~FGAP_mean by sym:
 SESSION      cors     betas   signR2s  nobs
 America 0.0220737 0.5819293 0.0004872 65372
    Asia 0.0087862 0.2906529  7.72e-05 13808
  Europe 0.0317314 0.7273207 0.0010069 40077
       #def
       betaStd=beta/tSP
       betaStdSub=betaStd*sqrt(totalObs/nobsSub)
       BetaDev=(betaSub-beta)/betaStdSub
\n";

my $filename=$ARGV[0];
my $N=$ARGV[1];
my $beta_full=$ARGV[2];
my $tSP=$ARGV[3];

my $betaStd=$beta_full/$tSP;

    my $cmd="
cat $filename|head -2 
cat $filename|gawk '{if(NR>=3){print \$0}}' |gawk '{if(NR==1){print \$0,\"N betaFull tSP betaStd betaStdSub tBetaDev\"}else{print \$0,\"$N $beta_full $tSP\",$betaStd,$betaStd*sqrt($N/\$5), (\$3-$beta_full)/( $betaStd*sqrt($N/\$5))  }}' |myFormatAuto.pl 1
";
    #print "$cmd\n";
    system("$cmd");


__END__
get_corr_by_session_R.pl tmp_y_x.txt 2 1 3 4 >/tmp/tmp_corr_by_key.txt


cat /tmp/tmp_corr_by_key.txt|head -2 >/tmp/tmp_h
cat /tmp/tmp_corr_by_key.txt|gawk '{if(NR>=3){print $0}}' >/tmp/tmp_b
cat /tmp/tmp_b|gawk '{if(NR==1){print $0,"N beta_full tSP betaStd betaStdSub tBetaDev"}else{print $0,"60000 0.9 3.4",$7/$8,$7/$8*sqrt($6/$5), ($3-$7)/$10}}'

