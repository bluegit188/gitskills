#!/usr/bin/perl

use strict;
#use Statistics::R;


($#ARGV+2) ==5 || die 
"Usage:reg_by_key_R.pl file.txt(header) colY colX colKey
       Compute simple (no-intercept) OLS reg of y~x|key
       Output:  KEY  b0 b1 t0 t1 nobs R2\n";

my $filename=$ARGV[0];

my $colY=$ARGV[1];
my $colX=$ARGV[2];

my $colKey=$ARGV[3];



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


 my $cmd02="
head -1 $filename |mygetcols.pl $colKey
";
 my $res02=`$cmd02`;
 chomp($res02);
my $keyName=$res02;




#date range
my $pid=$$;

print "$yName~$xName by $keyName:\n";

# Here-doc with multiple R commands:
my $cmd1 = <<EOF;
regdata<-fread(file="$filename",header=T)
#summary(regdata)

syms=sort(unique(regdata\$$keyName))


b0s=rep(0,length(syms))
b1s=rep(0,length(syms))
t0s=rep(0,length(syms))
t1s=rep(0,length(syms))
R2s=rep(0,length(syms))
nobs=rep(0,length(syms))



# check corr for each year
count=0;

for ( i in syms)
{

  count=count+1;

  regdataNow<- regdata[regdata\$$keyName == i,]


  fit1<-lm( $yName ~ $xName-1,data=regdataNow)
  summary(fit1)


  b0=0;
  b1=summary(fit1)\$coefficients[,1][1]

  t0=0;
  t1=summary(fit1)\$coefficients[,3][1]


  #df=summary(fit1)\$df[2]
  R2=summary(fit1)\$r.squared


  nob=nrow(regdataNow)

  b0s[count]=b0
  b1s[count]=b1
  t0s[count]=t0
  t1s[count]=t1

  nobs[count]=nob
  R2s[count]=R2

  #print( paste(i,cor,R2,nobs)); 

  print( paste("YEAR",i,b0,b1,t0,t1,R2)); 

}

allResults=as.data.frame(cbind(as.character(syms),b0s,b1s,t0s,t1s,nobs,R2s))
names(allResults)=c("$keyName", "b0","b1","t0","t1", "nobs","R2")
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



regdata<-fread(file="data_LTInds_CN.txt.year",header=T)
summary(regdata)

## by year for this period
regdata$MMDD=regdata$DATE%%10000
regdata$YYYY=(regdata$DATE-regdata$MMDD) /10000
regdata$DD=regdata$DATE%%10000%%100
regdata$YYMM=(regdata$DATE-regdata$DD) /100
regdata$MM=(regdata$MMDD-regdata$DD)/100


syms=sort(unique(regdata$YEAR))

b0s=rep(0,length(syms))
b1s=rep(0,length(syms))
t0s=rep(0,length(syms))
t1s=rep(0,length(syms))
R2s=rep(0,length(syms))
nobs=rep(0,length(syms))



# check corr for each year
count=0;

for ( i in syms)
{

  count=count+1;
  regdataNow<- regdata[regdata$YEAR == 2014,]

  fit1<-lm( ooF3D ~ OO.22t62,data=regdataNow)
  summary(fit1)

  b0=0;
  b1=summary(fit1)$coefficients[,1][1]

  t0=0;
  t1=summary(fit1)$coefficients[,3][1]
  #df=summary(fit1)$df[2]
  R2=summary(fit1)$r.squared

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



# Now, if you only want the t-values
summary(fit1)[["coefficients"]][, "t value"]
# Or (better practice as explained in comments by Axeman)
coef(summary(fit1))[, "t value"]
# (Intercept)           x           z 
#   23.216317    1.882841  786.035718 




summary(fit1)$coefficients[,4] for p-values
summary(fit1)$coefficients[,3] for t-values
summary(fit1)$coefficients[,1] for estimate


summary(fit1)$r.squared
[1] 0.001167099

#deg of freedom
summary(fit1)$df[2]
[1] 6036


> coef(summary(fit1))[, "t value"]
(Intercept)    OO.22t62 
  -6.516896    2.655719 


--OLS w/o intercept


  fit1<-lm( ooF3D ~ OO.22t62-1,data=regdataNow)
  summary(fit1)

 tvalue:
summary(fit1)$coefficients[,3]
[1] 5.159208
