#!/usr/bin/perl

use strict;
#use Statistics::R;


($#ARGV+2) ==4 || die 
"Usage: compute_resid_shp_R.pl PPLs.txt(header) colPPL_Y colPPL_X
       Compute resid pnl of PPL_Y when controlling for PPL_X
       inputfile format: 
       DATE PPL.Y PPL.X\n";

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

my $colPPL_Y=$ARGV[1];
my $colPPL_X=$ARGV[2];

 my $cmd0="
head -1 $filename |mygetcols.pl $colPPL_X
";
 my $res0=`$cmd0`;
 chomp($res0);
my $indName=$res0;

 my $cmd01="
head -1 $filename |mygetcols.pl $colPPL_Y
";
 my $res01=`$cmd01`;
 chomp($res01);
my $yName=$res01;


# Here-doc with multiple R commands:
my $cmd1 = <<EOF;
regdata<-fread("$filename")
regdata\$PPL_Y=regdata\$$yName
regdata\$PPL_X=regdata\$$indName

shpY=mean(regdata\$PPL_Y)/sd(regdata\$PPL_Y)*sqrt(252)
#shpY
#2.086766
shpX=mean(regdata\$PPL_X)/sd(regdata\$PPL_X)*sqrt(252)
#shpX
#1.327187

corr=cor(regdata\$PPL_Y,regdata\$PPL_X)
#0.785132

# beta w/ intercept
beta=cov(regdata\$PPL_Y,regdata\$PPL_X)/var(regdata\$PPL_X)
#beta

# beta w/o intercept
#beta_ni=sum(regdata\$PPL_Y*regdata\$PPL_X)/sum(regdata\$PPL_X**2)
#beta_ni
#0.8782514

resid_Y=regdata\$PPL_Y-beta*regdata\$PPL_X
shpResid=mean(resid_Y)/sd(resid_Y)*sqrt(252)
#shpResid
#1.686906

shpOpt=sqrt(shpX**2+shpResid**2)
#shpOpt
#2.14641

shpImprov=shpOpt/shpX-1
#shpImprov
#0.6172627

dateRange=range(regdata\$DATE)
# 20140102 20231018

NumYears=length(regdata\$PPL_Y)/252
tResid=shpResid*sqrt(NumYears)

regdata\$SYM="AAA"
regdata\$Y=1
regdata\$res_$yName=resid_Y

## write resid pnls
attach(regdata)
df= cbind(data.frame(SYM),DATE,Y,res_$yName) 
write.table(df, file = "residPPL.txt.$yName",  quote = FALSE, sep = " ",
            eol = "\n", na = "NA", dec = ".", row.names = FALSE,
            col.names = TRUE,  fileEncoding = "")

## write results
df2= cbind(corr,shpY,shpX,beta,shpResid,shpOpt,shpImprov,tResid) 
df2=round(df2,7)
write.table(df2, file = "/tmp/resid_shps.txt",  quote = FALSE, sep = " ",
            eol = "\n", na = "NA", dec = ".", row.names = FALSE,
            col.names = TRUE,  fileEncoding = "")

EOF
#print "cmd1=$cmd1\n";
#save cmd to a temp file
open(OUTFILE, ">tmp_R_file.R") || die "Couldn't open tmp_R_file.R\n";
print OUTFILE $cmd1,"\n";
close(OUTFILE);


# Create a communication bridge with R and start R
my $cmd="R < tmp_R_file.R  --no-save  1>/dev/null 2>/dev/null";
system("$cmd");

my $cmd2="simple_plot_cummulative_pnls_demean.pl residPPL.txt.$yName 0 30000101 1 2 3 4 -100:100 0 1 AB all > /tmp/tmp_perf.txt";
system("$cmd2");

my $cmd3="
cat /tmp/resid_shps.txt|fgrep -v corr|myAddHeader.sh \"corrPPLs shp.$yName shp.$indName beta shpResid shpOpt shpImprov tResid\"|myFormatAuto.pl 1|myAddHeader.sh \"-----------------------\"|myAddHeader.sh \"Resid shp: Y=$yName X=$indName(control) (shpOpt=sqrt(shpX^2+shpRes^2), shpImprov=shpOpt/shpX-1, tRes=shpResid*sqrt(Yrs))\"";
system("$cmd3");






__END__



regdata<-read.table(file="compare",header=T)
#summary(regdata)

cor(regdata)

 cor(regdata[-1])

