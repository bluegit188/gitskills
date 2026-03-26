#!/usr/bin/perl

use strict;
#use Statistics::R;


($#ARGV+2) ==6 || die 
"Usage:get_cor_by_session.pl file.txt(header) colSym colDate colY colX
       Compute corr and signedR2 for each year
       Output: year corr signedR2 NObs\n";

my $filename=$ARGV[0];

my $colSym=$ARGV[1];
my $colDate=$ARGV[2];

my $colY=$ARGV[3];
my $colX=$ARGV[4];


 my $cmdx="
cat $filename |myAssetSession_four_aseets.pl  1 $colSym >/tmp/$filename.asset4
";
system("$cmdx");


 my $cmd0="
head -1 $filename |mygetcols.pl $colX
";
 my $res0=`$cmd0`;
 chomp($res0);
my $xName=$res0;

 my $cmd01="
head -1 $filename |mygetcols.pl $colY
";
 my $res01=`$cmd01`;
 chomp($res01);
my $yName=$res01;

#date range
 my $cmd01x="    
getstat_fast.pl $filename 1 $colDate|fgrep -v min|mygetcols.pl 2 3|gawk '{print \"dateRange:\",\$0}'
";
system("$cmd01x");



my $pid=$$;

print "$yName~$xName by sym:\n";

# Here-doc with multiple R commands:
my $cmd1 = <<EOF;
regdata<-fread(file="/tmp/$filename.asset4",header=T)
#summary(regdata)

syms=sort(unique(regdata\$SESSION))


cors=rep(0,length(syms))
signR2s=rep(0,length(syms))
nobs=rep(0,length(syms))
betas=rep(0,length(syms))


# check corr for each year
count=0;

for ( i in syms)
{

  count=count+1;

  regdataNow<- regdata[regdata\$SESSION == i,]


  cor=round(cor(regdataNow\$$yName, regdataNow\$$xName),digits=7)
  R2=sign(cor)*round(cor^2,digits=7)
  nob=nrow(regdataNow)


  fit  = lm(as.formula($yName~$xName), data = regdataNow)
  beta = round(coef(fit)[2],7)        # slope of x
  #print( paste("YEAR",i,cor,beta,R2,nobs)); 

  cors[count]=cor
  signR2s[count]=R2
  nobs[count]=nob
  betas[count]=beta
  #print( paste(i,cor,R2,nobs,betas)); 

}

allResults=as.data.frame(cbind(as.character(syms),cors,betas,signR2s,nobs))
names(allResults)=c("SESSION", "cors","betas","signR2s", "nobs")
allResults


write.table(allResults, file = "_tmp_all_results.txt",  quote = FALSE, sep = " ", eol = "\n", na = "NA", dec = ".", row.names = FALSE, col.names = TRUE,  fileEncoding = "")



EOF

#print "cmd1=$cmd1\n";
#save cmd to a temp file
open(OUTFILE, ">tmp_R_file.R.$pid") || die "Couldn't open tmp_R_file.R.$pid\n";
print OUTFILE $cmd1,"\n";
close(OUTFILE);


# Create a communication bridge with R and start R
my $cmd="R < tmp_R_file.R.$pid  -q --no-save 2>/dev/null 1>/dev/null ";
#my $cmd="R < tmp_R_file.R.$pid  -q --no-save  ";
system("$cmd");


#my $R = Statistics::R->new();
#my $out2 = $R->run($cmd1);
#print "$out2\n";


my $cmd2="
\\rm tmp_R_file.R.$pid
cat _tmp_all_results.txt|myFormatAuto.pl 1 ";
system("$cmd2");



__END__





------------- get corr by year:



regdata<-fread(file="cvFcst.txt.block.17",header=T)
#summary(regdata)

## by year for this period
regdata$MMDD=regdata$DATE%%10000
regdata$YYYY=(regdata$DATE-regdata$MMDD) /10000
regdata$DD=regdata$DATE%%10000%%100
regdata$YYMM=(regdata$DATE-regdata$DD) /100
regdata$MM=(regdata$MMDD-regdata$DD)/100


syms=sort(unique(regdata$SYM))

cors=rep(0,length(syms))
signR2s=rep(0,length(syms))
nobs=rep(0,length(syms))



# check corr for each year
count=0;

for ( i in syms)
{

  count=count+1;
  regdataNow<- regdata[regdata$SYM == i,]


  cor=round(cor(regdataNow$ooF1D, regdataNow$cvFcst.2000),digits=7)
  R2=sign(cor)*round(cor^2,digits=7)
  nob=nrow(regdataNow)


  cors[count]=cor
  signR2s[count]=R2
  nobs[count]=nob
  #print( paste(i,cor,R2,nobs)); 

}



allResults=as.data.frame(cbind(as.character(syms),cors,signR2s,nobs))
names(allResults)=c("SYM", "cors","signR2s", "nobs")
allResults


write.table(round(allResults[,-1],digits=4), file = "_tmp_all_results.txt",  quote = FALSE, sep = " ",
            eol = "\n", na = "NA", dec = ".", row.names = FALSE,
            col.names = TRUE,  fileEncoding = "")

write.table(allResults, file = "_tmp_all_results.txt",  quote = FALSE, sep = " ",
            eol = "\n", na = "NA", dec = ".", row.names = FALSE,
            col.names = TRUE,  fileEncoding = "")


___

get_corr_by_session_R.pl tmp_y_x.txt 2 1 3 4 >/tmp/tmp_corr_by_key.txt


cat /tmp/tmp_corr_by_key.txt|head -2 >/tmp/tmp_h
cat /tmp/tmp_corr_by_key.txt|gawk '{if(NR>=3){print $0}}' >/tmp/tmp_b
cat /tmp/tmp_b|gawk '{if(NR==1){print $0,"N beta_full tSP betaStd betaStdSub tBetaDev"}else{print $0,"60000 0.9 3.4",$7/$8,$7/$8*sqrt($6/$5), ($3-$7)/$10}}'


compute_subset_tDev.pl /tmp/tmp_corr_by_key.txt 60000 0.9 3.5
