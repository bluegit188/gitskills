#!/usr/bin/perl

use strict;
#use Statistics::R;


($#ARGV+2) ==3 || die 
"Usage: auto_corr.pl file.txt(header) colToRemove=0
       Compute corr matrix
       colToRemove: set to 0 if not needed; otherwise,eg, sym column is 1, set to 1
       Example cmd: auto_corr.pl AOOF1.txt 3 63 TRUE|mygetcols.pl 2 3 4|fgrep -v \"[\"|more
       Output: corr matrix
       Also, cor matrix is in file= tmp_correlation.txt\n";

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

my $colToGo=$ARGV[1];

my $corCmd="cor(Filter(is.numeric,regdata))";
if($colToGo!=0)
{
   #$corCmd="cor(regdata[-$colToGo])";
   $corCmd="cor(Filter(is.numeric,regdata[-$colToGo]))";
}

# Here-doc with multiple R commands:
my $cmd1 = <<EOF;
#for fread fast read
library(data.table)
#fast read
#regdata<-read.table(file="$filename",header=T)
regdata<-fread("$filename")
#summary(regdata)
cor=$corCmd
write.table(round(cor,digits=4), file = "_tmp_correlation.txt",  quote = FALSE, sep = " ",
            eol = "\n", na = "NA", dec = ".", row.names = TRUE,
            col.names = TRUE,  fileEncoding = "")
cor
EOF

#print "cmd1=$cmd1\n";
#save cmd to a temp file
open(OUTFILE, ">tmp_R_file.R") || die "Couldn't open tmp_R_file.R\n";
print OUTFILE $cmd1,"\n";
close(OUTFILE);


# Create a communication bridge with R and start R
my $cmd="R < tmp_R_file.R  --no-save";
system("$cmd");

my $cmd2="cat _tmp_correlation.txt |gawk '{if(NR==1){print \"colNames\", \$0}else{print \$0}}' >  tmp_correlation.txt";
system("$cmd2");


#my $R = Statistics::R->new();
#my $out2 = $R->run($cmd1);
#print "$out2\n";




__END__



regdata<-read.table(file="compare",header=T)
#summary(regdata)

cor(regdata)

 cor(regdata[-1])

