#!/usr/bin/perl

use strict;
use POSIX;
#use Date::Calc qw/Delta_Days/;
use Date::Calc;
use threads;


my $TEST_MODE=0;
my $DEBUG=0;

( ($#ARGV+2)==2 || ($#ARGV+2)==3 ) || die
"Usage: bt1_fcst_launcher_mt_v96.pl tradeDate=20151022 [opt: isRestart=0/1]
       Reads in open times, offset, open prices, and spread to compute fcst at the specified times.
       opt: isRestart=0 by default, which mv all by-symbol fcst and trades for current tradeDate to .old file
                     fcstFileBySym=Logs/bySym/fcst_log.txt.tradeDate.curSym
                     tradeFileBySym=Logs/bySym/trade_log.txt.tradeDate.curSym
            isRestart=1 will leave these fcst/trades file as is.
            !!! For example, if restart the launcher in the middle of day(before last open), set isRestart to 1
                will retain the fcsts computed earlier.
       Input files: 4 files
         /roottransfer/jgeng/Prod/opentimes/opentimes_byAlphabet.txt
         /roottransfer/jgeng/Prod/opentimes/offsetTimes.txt
         /roottransfer/jgeng/Prod/rollLogs/rollLog.txt
         /roottransfer/jgeng/Prod/ttPrices/patrick_prices.txt (sym bid ask netPos)
         ## own rollLog file
         /roottransfer/jgeng/Prod/rollLogs/spdNorgate_ADLRolls_combo.txt
       output trades.txt format: SYM trades fcst netPosAtT targetPos date:time
\n";

# this will flush print buffer
$|++;


my $tradeDate=$ARGV[0];

my $isRestart=0;
if( ($#ARGV+2)==3 )
{
  $isRestart=$ARGV[1];
}



my $fileOpenTimes="/roottransfer/jgeng/Prod/opentimes/opentimes_byAlphabet.txt";
#my $fileOpenTimes="/roottransfer/jgeng/Prod/opentimes/opentimes_byAlphabet.txt.test";

if($TEST_MODE == 1)
{
   $fileOpenTimes="/roottransfer/jgeng/Prod/opentimes/opentimes_byAlphabet.txt.test";
}


#offset new with slow fcst calculations
my $fileOffsetTimes="/roottransfer/jgeng/Prod/opentimes/offsetTimes_new_v96.txt";
my $fileRolls="/roottransfer/jgeng/Prod/rollLogs/rollLog.txt";
my $filePrices="/roottransfer/jgeng/Prod/ttPrices/patrick_prices.txt";

my $fileOwnRolls="/roottransfer/jgeng/Prod/rollLogs/spdNorgate_ADLRolls_combo.txt";


# get unsorted syms
my @allUnsortedSyms=read_file_by_colNum($fileOpenTimes,1);


my %hashOTs=read_file_by_key($fileOpenTimes);
my %hashOffsets=read_file_by_key($fileOffsetTimes);

# read these two files on demend
my %hashRolls;
my %hashPrices;
my %hashOwnRolls;


############################
###
### format of files
###
############################
#1) opentimes_byAlphabet.txt
# STW 20151023 084500 135000 20151022 204500 20151023 015000
# TY  20151023 072000 140000 20151023 082000 20151023 150000
# W   20151023 083000 131500 20151023 093000 20151023 141500
#
#2). offsetTimes.txt
# BC 080000 5
# C 083000 5
# CD 072000 5
#
#3). rollLog.txt
# W 2015Z 20151021 20151223 20151214 494.75 2016H 20151021 20160323 20160314 501.25 6.50 Dec15 Mar16
# LSS 2016H 20151021 20160314 20160316 99.360 2016M 20151021 20160613 20160615 99.300 -0.060 Mar16 Jun16
#
#4). patrick_prices.txt
# STW 20151022 125728 0 322.45
# TY 20151022 125728 0 128.914
# W 20151022 125728 0 491.125

#5). own rolls
# more spdNorgate_ADLRolls_combo.txt
# SYM YM1Yest DATE1 priceF YM2Yest DATE2 priceS Spd tradeDate prevYM frontYM secondYM rollDate expiry RDays
# BC 2016G 20151217 37.06 2016H 20151217 37.62 0.56 20151217 Jan16 Feb16 Mar16 20160107 20160114 7
# C 2016H 20151217 374.25 2016K 20151217 380.25 6 20151217 Dec15 Mar16 May16 20160223 20160314 20
#

# file1,2,3,4's relevant column numbers
my $F1ColDateLoc=2;
my $F1ColDateOpenET=5;
my $F1ColOTET=6;

my $F2ColOffset=3;


my $F3ColLastDate=3;
my $F3ColRollDate=4;
my $F3ColSpread=12;

#columns in price file
my $F4ColDate=2;
my $F4ColTime=3;
#my $F4ColNetPos=4;
#my $F4ColNetPos=6; # this column is now actually from EODPos, which is more accurate
my $F4ColNetPos=4; # go back to use NPosAdj column
                   # if we do trades before open(e.g, cut TY pos before 8:20, EODPos is incorrect
                   # as prePos, we need to use NPosAdj at 8:20
my $F4ColPrice=5;
my $F4ColYM=7;


#ownRolls
my $F5ColLastDate=3;
my $F5ColRollDate=13;
my $F5ColSpread=8;



### for now, timing:
# open=9:30:00
# priceTime= 9:30:02
# fcstTime= 9:30:07, 5 seconds after priceTime
# tradeTime=9:30:12, 5 seconds after fcstTime

#my $OFFSET_LAG=5; # I will read 5 seconds after patrick's write

my $OFFSET_LAG=10; # change from 5 to 10 temporiaily due to lbox2 slowness, need to change back once HD is fixed, 2022/11/07

#my $CUTOFF_WINDOW=30; # allow some delays due to computation time, if more than 30 seconds, ignore it
#20200424, chg to 90 secs
my $CUTOFF_WINDOW=90; # allow some delays due to computation time, if more than 30 seconds, ignore it


if($TEST_MODE)
{
   print "#####  TEST_MODE = ",$TEST_MODE,"  ##############\n";
}

print "-------------------------------------------\n";
print "TradeDate= $tradeDate\n";
print "The bt1_fcst_launcher.pl is starting, preparing ...\n";


print "\n--- check the opentimes file\n";
my @tmpVecs=keys %hashOTs;
my $symAny=$tmpVecs[0]; #
#print "symAny=$symAny\n";
my $localDate=$hashOTs{$symAny}[$F1ColDateLoc-1];
if($tradeDate != $localDate)
{
   print "Error: The input trade date($tradeDate) != local date($localDate) from the opentimes file, check.\n";
   exit(0);
}
else
{
   print "opentimes file OK: The input trade date($tradeDate) == local date($localDate).\n";

}

print "\n--- check how many batches are needed, and symbols in each batch...\n";
###########################################
### sort symbols by dist(in secs) to open
###########################################

my $timeNow=time(); # in secs from epoch
my $nowDateET=get_now_date();
my $nowHHMMSSET=get_now_HHMMSS();
my %hashDists; # distToOpen -> array of symbols
my %hashOTAdjs; # distToOpen -> open times(adjusted for offset/lag)

# use a better struct:
# record=
# %record = ( "Name"    => "Jane Hathaway",
#             "Address" => "123 Anylane Rd.",
#             "Zip"     => "12345-1234");
#database=
#%database = (
#    "MRD-100" => { "Name"    => "Jane Hathaway",
#                   "Address" => "123 Anylane Rd.",
#                   "Zip"     => "12345-1234"
#                 },
#    "MRD-250" => { "Name"    => "Kevin Hughes",
#                   "Address" => "123 Allways Dr.",
#                   "Zip"     => "12345-1234"
#                 }
#	    );

my %otDB; #open time database
foreach my $sym (keys %hashOTs)
{

   my $dateOpenET=$hashOTs{$sym}[$F1ColDateOpenET-1];
   my $timeOpenET=$hashOTs{$sym}[$F1ColOTET-1];
   my $offset=$hashOffsets{$sym}[ $F2ColOffset-1];

   my $offset2=$offset+ $OFFSET_LAG;
   my ($dateOpenETAdj,$timeOpenETAdj)=get_date_time_by_offset($dateOpenET,$timeOpenET,$offset2);

   my $secsToOpen=timeDifInSeconds($nowDateET,$nowHHMMSSET,$dateOpenETAdj,$timeOpenETAdj);
   my $minsToOpen=$secsToOpen/60;
   my $secsToOpenHr=$secsToOpen/3600;

   if($DEBUG==1)
   {
     print "### sym=$sym\n";
     print "timeNow=$nowDateET $nowHHMMSSET\n";
     print "timeOpen=$dateOpenETAdj,$timeOpenETAdj\n";
     printf "$sym timeNow=$nowDateET $nowHHMMSSET openET= $dateOpenETAdj,$timeOpenETAdj  secsToOpen= $secsToOpen mins=%.2f hours= %.2f\n",$minsToOpen, $secsToOpenHr;
   }

   # hash: dist -> symbols
   my $key=$secsToOpen;
   my $value=$sym;
   #$hashDists{$key} .= exists $hash{$key} ? ",$value" : $value;

   if( ! exists $hashDists{$key} ) # not in hash1
   {
      my @syms=();
      push(@syms, $sym);
      $hashDists{$key}=\@syms;
    }
    else                               # date already in hash1
    {
       my $ref=$hashDists{$key};
       push(@$ref,$sym);
    }

   # dist -> date:time (adjusted OT)
   my $value2="$dateOpenETAdj:$timeOpenETAdj";
   if( ! exists $hashOTAdjs{$key} ) # not in hash1
   {
      $hashOTAdjs{$key}=$value2;
    }
    else                               # date already in hash1
    {
       # nothing
    }
}



print "\n--- symbols for each batch (wakeup times)...\n";
my @dists=();
# unique dists
my @sortedUniqueDists= (sort  {$a <=> $b}  keys %hashDists);
# This is the one I use for symbols in each batch
my %hashDists2; # batchNo -> array of (sorted) syms
my @sortedUniqueOTAdjs; # sorted open times, unique

print "BatchNo dateOTAdj timeOTAdj sec2Open mins2Open hrs2Open symbols\n";
for my $i (0..$#sortedUniqueDists)
{
   my $dist=$sortedUniqueDists[$i];
   my $refSyms=$hashDists{$dist};

   my $batchNo=$i+1;

   my @syms2= sort( @$refSyms);
   $refSyms=\@syms2;
   $hashDists2{$batchNo}=$refSyms; # syms are sorted

   push(@dists,$dist);

   # all symbols for this batch:
   my $datetime=$hashOTAdjs{$dist};
   my ($oTDate,$otTime)=split(':',$datetime);
   my $batchNo=$i+1;

   my $minsToOpen=$dist/60;
   my $secsToOpenHr=$dist/3600;

   #printf "batchNo=$batchNo dateOpenAdj=$oTDate timeOpenAdj=$otTime secToOpen= $dist minsToOpen=%.2f hrsToOpen=%.2f ", $minsToOpen,$secsToOpenHr;
   printf "$batchNo $oTDate $otTime $dist %.2f %.2f ", $minsToOpen,$secsToOpenHr;

   foreach my $sym (@$refSyms)
   {
     print " $sym";
   }
   print "\n";

   # sorted OTs
   my $oT= $hashOTAdjs{$dist};
   push(@sortedUniqueOTAdjs,$oT);

}

#print "dists= ",join(" ",@dists),"\n";
#print "sortedUniqueOTAdjs= ",join(" ",@sortedUniqueOTAdjs),"\n";




print "\n--- Starting the main control loop...\n";
###########################################################
###########################################################
##
## This is main control loop
##
###########################################################
############################################################
# note dists are unique values already(ie, grouped by same open times)
my @allSortedSyms= sort keys %hashOTs;
#print "All syms: ",join(" ",@allSortedSyms),"\n";

############################################################
### Before the start of the new tradeDay, clean up trades or
### fcst file from possible test runs
### Instead removal, just rename it
#############################################################

foreach my $curSym (@allSortedSyms)
{
   # at this step, will compute fcst and trades for syms in the batch
   my $fcstFileBySym="Logs/bySym/fcst_log.txt.$tradeDate.$curSym";
   my $tradeFileBySym="Logs/bySym/trade_log.txt.$tradeDate.$curSym";

   #since we have these 2 files only once per day, rename  old copy if any(due to test run etc)
   # and re-compute with correct prices
   if( -e $fcstFileBySym  )
   {
       if($isRestart==0) # don't mv file if it's a restart
       {
	 my $cmdx="mv $fcstFileBySym $fcstFileBySym.old";
	 system($cmdx);
       }

   }
   if( -e $tradeFileBySym  )
   {
       if($isRestart==0)
       {
	 my $cmdx="mv $tradeFileBySym $tradeFileBySym.old";
	 system($cmdx);
       }
   }
 }



#################################
#################################
##
## loop each batch now
##
#################################
for my $i (0..$#sortedUniqueDists)
{
   my $batchNo=$i+1;
   #my $interval=$sortedUniqueDists[$i];



   ## a more accuarte dist is to update each time since calculation itself might take time
   my $nowDateET=get_now_date();
   my $nowHHMMSSET=get_now_HHMMSS();

   my ($openDateETAdj,$openTimeETAdj)=split(':',$sortedUniqueOTAdjs[$i]);
   #print "openDateETAdj/openTimeETAdj= $openDateETAdj $openTimeETAdj\n";
   # this is always dist to next open
   my $dist=timeDifInSeconds($nowDateET,$nowHHMMSSET,$openDateETAdj,$openTimeETAdj);
   my $minsToOpen=$dist/60; # minutes to open
   my $hoursToOpen=$dist/3600; # hours to open


   ###########################################
   ###
   ###  work on the current batch
   ###
   ###########################################
   print "\n\n---###############   Batch No.: ",$i+1,"    ##################\n\n";


   my $refSyms0=$hashDists2{$batchNo};
   print "SymsInBatch: ",join(" ",sort @$refSyms0),"\n";
   printf "NextOpen: $openDateETAdj $openTimeETAdj TimeNow: $nowDateET $nowHHMMSSET secToOpen= $dist mins= %.2f hours= %.2f\n",$minsToOpen,$hoursToOpen ;


   if($TEST_MODE==1)
   {
       if($dist < 0) # if open already passed, ignore it. or not, maybe?
       {
	   print "Warning: This batch (batch $batchNo) calculation time has already passed\n";
       }
   }
   else
   {
       if($dist < 0) # if open already passed, ignore it. or not, maybe?
       {
	   print "Warning: This batch (batch $batchNo) calculation time has already passed\n";
	   next;
       }
   }

   ###########################
   ##### prepare to sleep #####
   ###########################
   print "\n--- Ready to sleep: will sleep for $dist seconds, and wake up at: $openDateETAdj,$openTimeETAdj ...\n";
   print "Sleeping ... \n";
   if($TEST_MODE==1)
   {
     sleep 2;
   }
   else
   {
     sleep $dist;  # sleep for a fixed number of seconds to next open
   }


   ###########################
   #####  after wake up ######
   ###########################

   ## after wakeup, compute fcsts for this batch of symbols
   my $nowDateETAW=get_now_date(); # after wakeup
   my $nowHHMMSSETAW=get_now_HHMMSS();
   print "\n--- Wake up now: timeNowET= $nowDateETAW $nowHHMMSSETAW\n";

   ### read roll and price files on demand
   %hashRolls=();
   %hashPrices=();
   %hashOwnRolls=();
   update_patrick_price_file(); # update price file first

   if( ! -e $fileRolls || -z $fileRolls ) # if roll file is corrupt, use backup one
   {
      my $fileRollsBak="/roottransfer/jgeng/Prod/rollLogs/rollLog_bak.txt";
      %hashRolls=read_file_by_key($fileRollsBak);
   }
   else
   {
     %hashRolls=read_file_by_key($fileRolls);
   }


   if( ! -e $fileOwnRolls || -z $fileOwnRolls ) # if roll file is corrupt, use backup one
   {
      my $fileOwnRollsBak="/roottransfer/jgeng/Prod/rollLogs/spdNorgate_ADLRolls_combo.txt";
      %hashOwnRolls=read_file_by_key($fileOwnRollsBak);
   }
   else
   {
     %hashOwnRolls=read_file_by_key($fileOwnRolls);
   }





   %hashPrices=read_file_by_key($filePrices);



   my $refSyms=$hashDists2{$batchNo};
   print "The symbols at this batch: ",join(" ",sort @$refSyms),"\n";





   ##################################
   ## loop each symbol at the current batch //begin of thread
   ##################################

   print "\n### Launch one thread per symbol for computing fcsts and trades.\n";



   my  @threads=();
   # init threads
   for my $j (0..$#$refSyms)
   {
      push(@threads,$j);
   }


   ## launch all threads
   for my $j (0..$#$refSyms)
   {
       my $n=$j+1;
       my $curSym=$$refSyms[$j];

       my @ParaList = ($curSym, $j,$nowDateETAW,$nowHHMMSSETAW);
       my ($thr) = threads->create(\&compute_fcst_for_sym, @ParaList); #create is same as new

       $threads[$j]=$thr;
       #my @ReturnData = $thr->join(); # uncommenting this will make it a sequential code

   }### end of sym loop for this batch //end of thread

   my $threadVecSize=$#threads+1;
   printf "threadVecSize=$threadVecSize\n";

   # This tells the main program to keep running until all threads have finished.
   foreach my $id (@threads)
   {
      #print "thread=$id\n";
      my @ReturnData=$id->join(); # wait for thread to exit, and receive results if any
   }
   print "\nall threads of fcst calculations done.\n";


   print "\n--- Collecting all fcst lines(on all 26 symbols) after the current  batch is ready...\n";
   #print "The trades log is in Logs/byDate/fcsts.txt.$tradeDate.$nowDateETAW.$nowHHMMSSETAW\n";
   print "The trades log is in Logs/byDate/fcsts.txt.$tradeDate.$nowDateETAW.$nowHHMMSSETAW\n";
   ########################################
   ### after this batch, collect all fcsts, and write to the composite file
   #my $nowDateETAW=get_now_date();
   #my $nowHHMMSSETAW=get_now_HHMMSS();
   my $outFile2="Logs/byDate/fcsts.txt.$tradeDate.$nowDateETAW.$nowHHMMSSETAW";
   open(OUTFILE2, ">$outFile2") || die "Couldn't open $outFile2\n";

   my $count=0;
   foreach my $curSym (@allUnsortedSyms)
   {

      $count++;
      #print "$count) $curSym:\n";
      my $curFcstFileBySym="Logs/bySym/fcst_log.txt.$tradeDate.$curSym";
      if( !(-e $curFcstFileBySym) ||  (-z $curFcstFileBySym) )
      {
	 printf OUTFILE2 "$curSym NA\n"; # no fcst computed, set timestamp=NA
      }
      else
      {

	  my $cmd4="cat $curFcstFileBySym|egrep -E -e\"\^Timestamp:\"|mygetcols.pl 4 5 1:3 6:200";
	  #print "$count) $curSym:\n";
	  #print "cmd4= $cmd4\n";
	  my $res4=`$cmd4`;
	  chomp($res4);
	  #20151105 ES Timestamp: 20151104 164228 open= 2102.12 spd= 0 cumSpd= 198.5 bt1Fcst.dm= 0.0457398 bt1Fcst= 0.0557398 svmFcst= 0.0525698 nnFcst= 0.0735661 FVOO= 20.8167 DateDif= 2 preDate= 20151103 today= 20151105 preOpen= 2093.5 GAP= -0.0422738 OO1= 0.414091 OO2= 0.784203 OO3= -0.330576 OO4= 0.327353 OO5= 0.620689
	  my $fcstLine=$res4;
	  #print "fcstLineLine= $tradesLine\n";

	  printf OUTFILE2 "$curSym $fcstLine\n";
      }

    }
    close(OUTFILE2);
   print "Done\n";


   print "\n--- Collecting all trades(on all 26 symbols) after the current  batch is ready...\n";
   print "The trades log is in Logs/byDate/trades.txt.$tradeDate.$nowDateETAW.$nowHHMMSSETAW\n";
   ########################################
   ### after this batch, collect all fcsts, and write to the composite file
   #my $nowDateETAW=get_now_date();
   #my $nowHHMMSSETAW=get_now_HHMMSS();
   my $outFile="Logs/byDate/trades.txt.$tradeDate.$nowDateETAW.$nowHHMMSSETAW";
   open(OUTFILE, ">$outFile") || die "Couldn't open $outFile\n";

   my $count=0;
   foreach my $curSym (@allUnsortedSyms)
   {


       # to get openTimeETAdj
       my $dateOpenET=$hashOTs{$curSym}[$F1ColDateOpenET-1];
       my $timeOpenET=$hashOTs{$curSym}[$F1ColOTET-1];
       my $offset=$hashOffsets{$curSym}[ $F2ColOffset-1];
       my $timeOpen=get_secs_since_epoch($dateOpenET,$timeOpenET); # oT in seconds from epoch
       # open date/time adjusting for offset:
       my ($dateOpenETAdj,$timeOpenETAdj)=get_date_time_from_SSE($timeOpen+$offset+$OFFSET_LAG);
       #print "datex, timex= $datex  $timex;  otAdj: $dateOpenETAdj $timeOpenETAdj\n";


       my $NAStr="NA";
       my $targetPosStr="NA";

       # this is seconds to next open (AW=after wakeup)
       my $dist=timeDifInSeconds($nowDateETAW,$nowHHMMSSETAW,$dateOpenETAdj,$timeOpenETAdj);
       if($dist > 0) # this sym is upcoming, ie, not open yet
       {
	  $NAStr="NAU";
	  $targetPosStr="NAU";
       }

       $count++;
       #print "$count) $curSym:\n";
       my $curTradeFileBySym="Logs/bySym/trade_log.txt.$tradeDate.$curSym";
       if( !(-e $curTradeFileBySym) ||  (-z $curTradeFileBySym) )
       {
	 printf OUTFILE "$curSym,0,0,0,$targetPosStr,$nowDateETAW:$nowHHMMSSETAW:$NAStr\n"; # no trades computed, set timestamp=NA
	                                  # format: SYM trades fcst prePos targetPos date:time
       }
       else
       {
          print "$count) $curSym:\n";
	  my $cmd4="cat $curTradeFileBySym|egrep Timestamp";
	  print "cmd4= $cmd4\n";
	  my $res4=`$cmd4`;
	  chomp($res4);
	  #Timestamp: 20151027 154126 20151027 TY prePos= 0 targetPos= 0 trades= 0 absTrades= 0 signTrades= 0 fcst= 0.01543 fcstNet= 0 tcost= 0.02 FVOO= 0.402458 FVOOD= 402.458 pointValue= 1000 denom= USD fxRate= 1 fxDate= -1 RPF= 11000 RPFAdj= 11000
	  my $tradesLine=$res4;
	  print "tradesLine= $tradesLine\n";

	  my @vec2=split(' ',$tradesLine);
	  #if($#vec2 != 37-1)
	  if($#vec2 < 37-1)
	  {
	      print "Error: trades calculations error for $tradeDate $curSym, see $curTradeFileBySym\n";
	      printf OUTFILE "$curSym,0,0,0,$targetPosStr,$nowDateETAW:$nowHHMMSSETAW:$NAStr\n"; # no trades computed, set timestamp=NA
	      next;
	  }

	  my $trades=$vec2[11-1];
	  my $absTrades=$vec2[13-1];
	  my $signTrades=$vec2[15-1];
	  my $fcstDM=$vec2[17-1]; # raw fcst(demeaned), not fcstNet
	  my $prevPos=$vec2[7-1]; 
	  my $targetPos=$vec2[9-1];
	  my $tsDate=$vec2[2-1]; # fcst calculation time
	  my $tsTime=$vec2[3-1];
	  printf OUTFILE "$curSym,$trades,%.6f,$prevPos,$targetPos,$tsDate:$tsTime:OK\n",$fcstDM;
       }

    }
    close(OUTFILE);


    # make a copy in main dir
    my $cmd5="cp $outFile trades.txt
              cat trades.txt |myAddWindowEOL.sh >trades_patrick.txt";
   system("$cmd5");
   print "The full trades file: trades.txt and logFile: $outFile\n";




   # added 20180621, collect openPrices
   print "\n--- Collecting all openPrices(on all 26 symbols) after the current  batch is ready...\n";
   print "The openPrices log is in Logs/byDate/openPrices.txt.$tradeDate.$nowDateETAW.$nowHHMMSSETAW\n";
   ########################################
   ### after this batch, collect all fcsts, and write to the composite file
   #my $nowDateETAW=get_now_date();
   #my $nowHHMMSSETAW=get_now_HHMMSS();
   my $outFile3="Logs/byDate/openPrices.txt.$tradeDate.$nowDateETAW.$nowHHMMSSETAW";
   open(OUTFILE3, ">$outFile3") || die "Couldn't open $outFile3\n";

   my $count=0;
   foreach my $curSym (@allUnsortedSyms)
   {


       # to get openTimeETAdj
       my $dateOpenET=$hashOTs{$curSym}[$F1ColDateOpenET-1];
       my $timeOpenET=$hashOTs{$curSym}[$F1ColOTET-1];
       my $offset=$hashOffsets{$curSym}[ $F2ColOffset-1];
       my $timeOpen=get_secs_since_epoch($dateOpenET,$timeOpenET); # oT in seconds from epoch
       # open date/time adjusting for offset:
       my ($dateOpenETAdj,$timeOpenETAdj)=get_date_time_from_SSE($timeOpen+$offset+$OFFSET_LAG);
       #print "datex, timex= $datex  $timex;  otAdj: $dateOpenETAdj $timeOpenETAdj\n";


       my $NAStr="NA";
       my $openPriceStr="NA";
       my $openCymStr="NA";
       my $openSpdStr="NA";

       # this is seconds to next open (AW=after wakeup)
       my $dist=timeDifInSeconds($nowDateETAW,$nowHHMMSSETAW,$dateOpenETAdj,$timeOpenETAdj);
       if($dist > 0) # this sym is upcoming, ie, not open yet
       {
	  $NAStr="NAU";
	  $openPriceStr="NAU";
	  $openCymStr="NAU";
	  $openSpdStr="NAU";
       }

       $count++;
       print "$count) $curSym:\n";
       my $curOpenFileBySym="Logs/bySym/open_log.txt.$tradeDate.$curSym";
       if( !(-e $curOpenFileBySym) ||  (-z $curOpenFileBySym) )
       {
	 printf OUTFILE3 "$curSym,$tradeDate,0,0,0,$nowDateETAW:$nowHHMMSSETAW:$NAStr\n"; # no trades computed, set timestamp=NA
	                                  # format: SYM trades fcst prePos targetPos date:time
       }
       else
       {
	  my $cmd4="cat $curOpenFileBySym";
	  print "cmd4= $cmd4\n";
	  my $res4=`$cmd4`;
	  chomp($res4);
	  #ES 20180621 Sep18 20180621 092955 open= 2770.125 0
	  my $openPricesLine=$res4;
	  print "openPricesLine= $openPricesLine\n";

	  my @vec2=split(' ',$openPricesLine);
	  #if($#vec2 != 37-1)
	  if($#vec2 < 8-1)
	  {
	      print "Error: openPrices calculations error for $tradeDate $curSym, see $curOpenFileBySym\n";
	      printf OUTFILE3 "$curSym,$tradeDate,0,0,0,$nowDateETAW:$nowHHMMSSETAW:$NAStr\n"; # no openPrices computed, set timestamp=NA
	      next;
	  }

	  my $openPrices=$vec2[7-1];
	  my $openSpd=$vec2[8-1];
	  my $openCym=$vec2[3-1];

	  my $tsDate=$vec2[4-1]; # fcst calculation time
	  my $tsTime=$vec2[5-1];
	  printf OUTFILE3 "$curSym,$tradeDate,$openCym,$openPrices,$openSpd,$tsDate:$tsTime:OK\n";
       }

    }
    close(OUTFILE3);


    # make a copy in main dir
    my $cmd6="cp $outFile3 openPrices.txt
              cat openPrices.txt |myAddWindowEOL.sh >openPrices_patrick.txt";
   system("$cmd6");
   print "The full openPrices file: openPrices.txt and logFile: $outFile\n";
   print "--- This batch is done\n";





} ## end of loop batches








##############################################################
###
###   below are subroutines
###
##############################################################



sub compute_fcst_for_sym
# input: filename,  
# file format:  ID x1 x1 x2
# return: ref to hash: ID->ref to array
### usage:
# my %hash=read_file_by_key($decimalFile);
# my $pMult=$hash{"ES"}[1];
{
       my ($curSym,$j,$nowDateETAW,$nowHHMMSSETAW)=@_;
       my $n=$j+1;

       # Thread 'cancellation' signal handler
       $SIG{'KILL'} = sub { threads->exit(); };



       #if($curSym eq "LEU" || $curSym eq "S"|| $curSym eq "HS")
       if($curSym eq "LEU" || $curSym eq "HS")
       {
	     print "TH:$curSym: not trading this symbol, skip it ...\n";
	     threads->exit();
       }



       # at this step, will compute fcst and trades for syms in the batch
       my $fcstFileBySym="Logs/bySym/fcst_log.txt.$tradeDate.$curSym";
       my $tradeFileBySym="Logs/bySym/trade_log.txt.$tradeDate.$curSym";


      # this is to record open prices
      my $openFileBySym="Logs/bySym/open_log.txt.$tradeDate.$curSym";


       ######################################
       ## for this sym, get all the necessary input values
       ######################################

       my $rollLastDate=$hashOwnRolls{$curSym}[$F5ColLastDate-1];
       my $rollDate=$hashOwnRolls{$curSym}[$F5ColRollDate-1];
       my $spread=$hashOwnRolls{$curSym}[$F5ColSpread-1];


       my $price="NA";
       my $priceDate="NA";
       my $priceTime="NA";
       my $prevPos="NA";
       my $YM="NA"; #Feb16

       if(exists $hashPrices{$curSym})
       {
	  $price=$hashPrices{$curSym}[$F4ColPrice-1];
	  $priceDate=$hashPrices{$curSym}[$F4ColDate-1];
	  $priceTime=$hashPrices{$curSym}[$F4ColTime-1];
	  $prevPos=$hashPrices{$curSym}[$F4ColNetPos-1];
	  $YM=$hashPrices{$curSym}[$F4ColYM-1];
       }

       # to get openTimeETAdj
       my $dateOpenET=$hashOTs{$curSym}[$F1ColDateOpenET-1];
       my $timeOpenET=$hashOTs{$curSym}[$F1ColOTET-1];
       my $offset=$hashOffsets{$curSym}[ $F2ColOffset-1];
       my $timeOpen=get_secs_since_epoch($dateOpenET,$timeOpenET); # oT in seconds from epoch
       # open date/time adjusting for offset:
       my ($dateOpenETAdj,$timeOpenETAdj)=get_date_time_from_SSE($timeOpen+$offset+$OFFSET_LAG);
       #print "datex, timex= $datex  $timex;  otAdj: $dateOpenETAdj $timeOpenETAdj\n";



       print "\nTH:$curSym: SYM $n= $curSym : rollLastDate= $rollLastDate rollDate= $rollDate spread= $spread p= $price pDate= $priceDate pTime= $priceTime prevPos=$prevPos YM=$YM\n";

       print "TH:$curSym:     now(ET): $nowDateETAW $nowHHMMSSETAW openTimeET: $dateOpenET $timeOpenET offset= $offset openTimeETAdj: $dateOpenETAdj $timeOpenETAdj\n";



       print "\nTH:$curSym: --- verifying rolls (roll date, spread etc)\n";
       ## if tradeDate==rollDate, we need to adjust spread, also check whether sprd is stale
       ## Arthur: spd=next price - this price
       ## need to get preSprd, then add this new spd
       my $spdInput=0;
       my $dateDif=dateDif($rollLastDate,$tradeDate);
       my $isRollDate=0;
       if($tradeDate >= $rollDate)
       {
	   $isRollDate=1;
	   $spdInput=$spread;
	   print "TH:$curSym: $curSym tradeDate=$tradeDate rollDate=$rollDate: today IS a roll date.\n";
	
	   my $dow=get_day_of_week_fast($tradeDate);
	   print "TH:$curSym: rollDate=$rollDate dow=$dow\n";
	   if( ($dow==1 && $dateDif >=4) || ($dow!=1 && $dateDif >=2 ) )
	   {
	       print "TH:$curSym: Warning/Check: dateDif=$dateDif, spd might be stale for $curSym tradeDate=$tradeDate rollLastDate=$rollLastDate dif >=4(Monday) or dif >==2 (non-Monday).\n";



	       if($dateDif > 100)
	       {
                  print "TH:$curSym: Error: dateDif=$dateDif, greater than 100, must be wrong, check!\n";
		  my $subject="bt1_fcst_missed_trades.pl dateDif=$dateDif incorrect";
		  my $content="bt1_fcst_missed_trades.pl dateDif=$dateDif incorrect\n
                               curSym=$curSym incorrect rollDate between rollLastDate=$rollLastDate,tradeDate=$tradeDate\n";
		  sendEmail($subject,$content);
                  threads->exit();

	       }

	   }
	   else
	   {
	       print "TH:$curSym: The spd appears to be timely for $curSym tradeDate=$tradeDate rollLastDate=$rollLastDate.\n";
	   }
	
       }
       else
       {
	 print "TH:$curSym: $curSym tradeDate=$tradeDate rollDate=$rollDate lastSpdDate=$rollLastDate : today is NOT a roll date.\n";
       }
       print "TH:$curSym: The spread for input: $spdInput\n";

       print "\nTH:$curSym: --- verifying price file timing...\n";
       ################################
       ### further check timing issue before computing fcsts:
       ### a). priceDate and priceTime matches current date/time
       ### b). current date/time matches openDate/Time+offset
       ################################

       print "TH:$curSym: --- check whether price is NA or zero:\n";
       if($TEST_MODE==1)
       {
	  if($price eq "NA" || $price == 0)
	  {
	     print "TH:$curSym: TestMode: price is NA or zero, skip this symbol ...\n";
	     threads->exit();
	  }
	  else
	  {
	     print "TH:$curSym: OK: price is not NA.\n";
	  }
       }
       else
       {
	  if($price eq "NA")
	  {
	     print "TH:$curSym: Error: price is NA, skip this symbol ...\n";
	     threads->exit();
	  }
	  else
	  {
	     print "TH:$curSym: OK: price is not NA.\n";
	  }
       }



       my $timeDif1=timeDifInSeconds($priceDate,$priceTime,$nowDateETAW,$nowHHMMSSETAW);
       my $timeDif2=timeDifInSeconds($dateOpenETAdj,$timeOpenETAdj,$nowDateETAW,$nowHHMMSSETAW);
       if($timeDif1 < 0 || $timeDif1 > $CUTOFF_WINDOW)
       {
	  print "TH:$curSym: Error: priceDate/Time might be off (more than  $CUTOFF_WINDOW seconds): priceDate/time= $priceDate $priceTime and nowDate/TimeET= $nowDateETAW $nowHHMMSSETAW  !\n";
	  if($TEST_MODE==1)
	  {
	     print "TH:$curSym: TestMode: pretend the price time and now timing are correct ...\n";
	     #threads->exit();
	  }
	  else
	  {
	     print "TH:$curSym: Skip this symbol ...\n";
	     threads->exit();
	  }
       }
       else
       {
	  print "TH:$curSym: The priceDate/Time OK: priceDate/time= $priceDate $priceTime and nowDate/TimeET= $nowDateETAW $nowHHMMSSETAW .\n";
       }


       if($timeDif2 < 0 || $timeDif2 >  $CUTOFF_WINDOW)
       {
	  print "TH:$curSym: Error: (now)fcstDate/Time  $CUTOFF_WINDOW secs away from openDate/TimeETAdj, date/timeOpenETAdj= $dateOpenETAdj $timeOpenETAdj and nowDate/TimeET= $nowDateETAW $nowHHMMSSETAW  !\n";
	  if($TEST_MODE==1)
	  {
	    print "TH:$curSym: TestMode: pretend the time now and the open timing are correct ...\n";
	    #threads->exit();
	  }
	  else
	  {
	     print "TH:$curSym: Skip this symbol ...\n";
	     threads->exit();
	  }

       }
       else
       {
	  print "TH:$curSym: OK: The fcstDate/Time is within  $CUTOFF_WINDOW secs of openDate/TimeETAdj, date/timeOpenETAdj= $dateOpenETAdj $timeOpenETAdj and nowDate/TimeET= $nowDateETAW $nowHHMMSSETAW .\n";

       }


       print "\nTH:$curSym: --- verifying price level...\n";
       ################################
       ### further check whether price is too off from last close, I set at 50% change
       ################################
       my $THRESHOLD_P=50;
       ### grab close from RTH file
       my $cmd20="portara_get_RTH_lastline.pl $curSym |mygetcols.pl 1 5 10";
       #print "cmd20= $cmd20\n";
       my $res20=`$cmd20`;
       chomp($res20);

       #20151030 2073.75 2016G
       my ($priceRTHDate,$priceRTH, $ymRTH)=split(' ',$res20);


       if($priceRTH == 0)
       {
	    print "TH:$curSym: Error: priceRTH is zero priceRTH=$priceRTH\n";
	    print "TH:$curSym: Skip this symbol ...\n";
	    threads->exit();
       }


       # compare patrick price vs RTH last close
       print "TH:$curSym: price=$price, priceRTHDate=$priceRTHDate,priceRTH=$priceRTH\n";
       my $chgPct=($price/$priceRTH-1)*100;
       #print "chgPct=$chgPct\n";
       if(abs($chgPct) >= $THRESHOLD_P)
       {
	  printf "TH:$curSym: Error(potential): price level is too off from last close: chgPct=%.4f p=$price lastClose=$priceRTH (\@ $priceRTHDate)!\n",$chgPct;
	  if($TEST_MODE==1)
	  {
	    print "TH:$curSym: TestMode: pretend the price level is correct ...\n";
	    #threads->exit();
	  }
	  else
	  {
	     print "TH:$curSym: Skip this symbol ...\n";
	     threads->exit();
	  }

       }
       else
       {
	  printf "TH:$curSym: OK: price level is within 50Pct of last close: chgPct=%.4f p=$price lastClose=$priceRTH (\@ $priceRTHDate).\n",$chgPct;
       }



       print "\nTH:$curSym: --- verifying contract YM ...\n";
       #20151030 2073.75 2016G
       # $ymRTH is already extracted in above step
       # compare patrick price(Feb16) vs RTH ym (2016G)
       print "TH:$curSym: Contract YM from RTH file: $ymRTH, and from ttPrice file: $YM\n";

       my $YYYYMM1=convertRTHYM2YYYYMM($ymRTH);
       my $YYYYMM2=convertTTYM2YYYYMM($YM);

       print "TH:$curSym: Standard contractYM format: RTH=$YYYYMM1 TT=$YYYYMM2\n";
       my $isCYMOK=0;
       if($YYYYMM1 ne "NA" && $YYYYMM2 ne "NA" && $YYYYMM2 >= $YYYYMM1)
       {
	 $isCYMOK=1; # TT YM must be >= RTH YM
       }

       #print "chgPct=$chgPct\n";
       if( $isCYMOK != 1)
       {
	  print "TH:$curSym: Error(potential): isCYMOK=$isCYMOK, tt YM must be >= RTH YM: YM(tt)= $YYYYMM2 YM(RTH)=$YYYYMM1\n";
	  if($TEST_MODE==1)
	  {
	    print "TH:$curSym: TestMode: pretend the contract YM is ok ...\n";
	    #threads->exit();
	  }
	  else
	  {
	     print "TH:$curSym: Skip this symbol ...\n";
	     threads->exit();
	  }

       }
       else
       {
	  print "TH:$curSym: OK: contractYM OK flag=$isCYMOK (tt >= RTH ), YM(tt)= $YYYYMM2 YM(RTH)=$YYYYMM1\n";
       }


       my $eps=0.000000001;
       # if roll date spd is not zero(from RollLog), but price has same cym as RTH
       # must be rollLog spd not correct, set to 0
       if(  $isRollDate==1 && abs($spdInput) > $eps && $YYYYMM2 == $YYYYMM1 )
       {

	 print "TH:$curSym: Warning: today is roll date but tt YM same as RTH YM, so spdInput is reset to 0\n";
	 print "TH:$curSym:          JunfeiSpread: sprd=$spdInput lastSpdDate=$rollLastDate (Stale)\n";
	 print "TH:$curSym:          YM(tt)= $YYYYMM2 YM(RTH)=$YYYYMM1\n";
	 $spdInput=0;
       }

       ## in some case,(e.g, monday is both roll and holiday, when rolling on Tue, it started to use next 
       ## rollDate already, this would cause the system to not recognize Tue as a roll date
       print "\nTH:$curSym: --- Verifying whether isRollDate is consistent with tt_YM/RTH_YM ...\n";
       if(  $isRollDate!=1 && $YYYYMM2 > $YYYYMM1 )
       {
	 print "TH:$curSym: Warning: today is NOT a roll date but tt YM > RTH YM, so it has to be a rollDate\n";
	 print "TH:$curSym:          I reset isRollDate to 1, and spdInput to spread=$spread\n";
	 $isRollDate=1;
	 $spdInput=$spread;
       }


       print "\nTH:$curSym: --- If everything goes well, compute fcst...\n";
       #####################
       ### if everything goes well(rollDate, spreadDate, priceDate/time, currentDateTime), compute fcst
       #####################
 
       # save open price
       my $cmd_o="echo \"$curSym $tradeDate $YM $priceDate $priceTime open= $price $spdInput\" > $openFileBySym 2>&1";
       print "TH:$curSym: cmd= $cmd_o\n";
       system("$cmd_o");



       # 2>&1: redirect cerr to file as well
       my $cmd="bt1_fcst_prod_v96 $tradeDate $curSym $price $spdInput > $fcstFileBySym 2>&1";
       print "TH:$curSym: cmd= $cmd\n";
       system("$cmd");


       ### grab fcst/FVOO from fcst file
       my $cmd2="cat $fcstFileBySym |fgrep bt1Fcst.dm|mygetcols.pl 4 5 12 13 20 21 22 23 24 25 174 175";
       print "TH:$curSym: cmd2= $cmd2\n";
       my $res=`$cmd2`;
       chomp($res);
       #20151027 TY bt1Fcst.dm= 0.0154397 FVOO= 0.402458 DateDif= 3 preDate= 20160722 FVOO2= 1.34811
       my $fcstLine=$res;
       my @vec=split(' ',$fcstLine);
       if($#vec != 12-1)
       {
	  print "TH:$curSym: Error: fcst error for $tradeDate $curSym, see $fcstFileBySym\n";
       }
       my $fcst=$vec[4-1];
       my $FVOO=$vec[6-1];
       my $FVOO2=$vec[12-1];

       my $dateDifRTH=$vec[8-1];
       my $preDateRTH=$vec[10-1];

       print "TH:$curSym: fcst=$fcst FVOO=$FVOO dateDifRTH=$dateDifRTH preDateRTH=$preDateRTH\n";



       ### if dateDifRTH is > 1 on nonMonday or > 3 on Mon, issue an email alert, could be an error
       my $dow=get_day_of_week_fast($tradeDate);
       print "TH:$curSym: Checking dateDifRTH: tradeDate=$tradeDate, preDateRTH=$preDateRTH, dateDifRTH=$dateDifRTH, dow=$dow\n";
        if( ($dow==1 && $dateDifRTH >=4) || ($dow!=1 && $dateDifRTH >=2 ) )
	{
	     print "TH:$curSym: Warning/Check: dateDifRTH=$dateDifRTH,dow=$dow, might be stale RTH data for $curSym tradeDate=$tradeDate preDateRTH=$preDateRTH, dateDifRTH=$dateDifRTH, dow=$dow\n";

	     my $subject="Fcst_launcher potential stale RTH data dateDifRTH=$dateDifRTH";
	     my $content="bt1_fcst_launcher dateDifRTH=$dateDifRTH potential stale RTH\n\ncurSym=$curSym tradeDate=$tradeDate preDateRTH=$preDateRTH, dateDifRTH=$dateDifRTH, dow=$dow\n";
	     sendEmail($subject,$content);
	     #threads->exit();

       }



       ## new addtions: 2016/01/13
       ## on roll date, new execution program liquidates pos on old, and start from 0 pos on new contract
       if( $isRollDate==1 )
       {
 	  $prevPos=0;
	  print "TH:$curSym: prevPos: isRollDate==1, set prevPos=0\n";
       }


       print "\nTH:$curSym: --- Fcst is ready, compute trades...\n";
       ### now, compute trade size, and extract it
       my $cmd3="pos_sizing_block2 $tradeDate $curSym $prevPos $fcst $FVOO $FVOO2 > $tradeFileBySym 2>&1";
       print "TH:$curSym: cmd= $cmd3\n";
       system($cmd3);


} # end of thread sub






sub read_file_by_key
# input: filename,  
# file format:  ID x1 x1 x2
# return: ref to hash: ID->ref to array
### usage:
# my %hash=read_file_by_key($decimalFile);
# my $pMult=$hash{"ES"}[1];
{
   my ($filename)=@_;
   open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";
   my %hash;
   while (<INFILE>)
   {
       chomp;
       my $str=$_;

       #ignore comment line
       if(substr($str,0,1) eq "#")
       {
	  next;
       }

       my @line= split;
       my $key=$line[0];
       my $value=$str;
       #$hash{$key} .= exists $hash{$key} ? ",$value" : $value;
       $hash{$key} =\@line;

    }
   close(INFILE);
   return %hash;
}




sub get_secs_since_epoch
# input: date, hhmmss= 20151023 93003
# return elpased second from epoch
{
   my ($date,$hhmmss)=@_;

   my ($sec,$min,$hour,$mday,$mon,$year,$isdst);

   my $YYYY=int($date/10000);
   my $MMDD=$date%10000;
   my $MM=int($MMDD/100);
   my $DD=$MMDD%100;

   my $hh=int($hhmmss/10000);
   my $mmss=$hhmmss%10000;
   my $mm=int($mmss/100);
   my $ss=$mmss%100;

   $MM -=1;
   $YYYY-=1900;

   #mktime(sec, min, hour, mday, mon, year, wday = 0,yday = 0, isdst = -1)
   my $secsSinceEpoch=POSIX::mktime($ss,$mm,$hh,$DD,$MM,$YYYY,0,0,-1);

   return  $secsSinceEpoch;
}

sub get_now_date
{
  my $str=strftime("%Y%m%d",localtime());
  return $str;
}

sub get_now_HHMMSS
{
  my $str=strftime("%H%M%S",localtime());
  return $str;
}

sub dateDif
#input; 20050102, 20050107
#output: the number of days in difference
#use Date::Calc qw/Delta_Days/;
{
   my ($date1,$date2)=@_;


   my $YYYY1=int($date1/10000);
   my $MMDD1=$date1%10000;
   my $MM1=int($MMDD1/100);
   my $DD1=$MMDD1%100;



   my $YYYY2=int($date2/10000);
   my $MMDD2=$date2%10000;
   my $MM2=int($MMDD2/100);
   my $DD2=$MMDD2%100;

   my @first = ($YYYY1, $MM1,$DD1);
   my @second = ($YYYY2,$MM2,$DD2);


   my $dif =999;
   # Make sure the dates are valid, otherwise, it will exit/crash
   if(Date::Calc::check_date($YYYY1, $MM1,$DD1) ==1 && Date::Calc::check_date($YYYY2, $MM2,$DD2) ==1)
   {
      $dif = Date::Calc::Delta_Days( @first, @second );
   }
   return $dif;
}

sub get_day_of_week_fast
#20150213
# return DOW: Sun=0, Mon=1, Tue=2, ...
{
   my ($date) = @_;

   my $YYYY=int($date/10000);
   my $MMDD=$date%10000;
   my $MM=int($MMDD/100);
   my $DD=$MMDD%100;

   my $k=$DD;
   my $m=$MM-2;
   if($m<=0){$m+=12;}

   # order of below 2 steps are important, otherwise, 2000 won't work.
   if($MM==1 || $MM==2)
   {
     $YYYY-=1;
   }
   my $Y=$YYYY%100; #

   my $C=int($YYYY/100);

   return ( $k+int(2.6*$m-0.2)-2*$C+$Y+int($Y/4)+int($C/4) )%7;

}

sub timeDifInSeconds
#input; 20050102, 203010, 20050102, 203020
#output: the number of seconds in time difference
{
   my ($date1,$hhmmss1,$date2,$hhmmss2)=@_;

   return get_secs_since_epoch($date2,$hhmmss2)- get_secs_since_epoch($date1,$hhmmss1),

}


sub get_date_time_from_SSE
# SSE=seconds since epoch
# input: # of seconds since epoch
# output: date and time
# localtime: Converts a time as returned by the time function to a 9-element list with the time analyzed for the
#            local time zone.
{

   my ($SSE)=@_; # SSE= seconds since epoch

   #    0    1    2     3     4    5     6     7     8
   #my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($SSE);

   my $date=strftime("%Y%m%d",localtime($SSE));
   my $time=strftime("%H%M%S",localtime($SSE));
   my @a;
   push(@a,$date);
   push(@a,$time);
   return @a;
}


sub get_date_time_by_offset
# input: date time(HHMMSS) and offset(in seconds)
# output: new date and time
{

   my ($date,$time,$offset)=@_;

   my $sse=get_secs_since_epoch($date,$time);
   my ($newDate,$newTime)=get_date_time_from_SSE($sse+$offset);

   my @a;
   push(@a,$newDate);
   push(@a,$newTime);
   return @a;
 }


sub update_patrick_price_file
# input: date time(HHMMSS) and offset(in seconds)
# output: new date and time
# process_patrick_prices.pl: will write 2 log files, one is raw file, the other is after processing
#                            both files are time-stamped with Patrick date/time
{
  # final
  my $cmd="process_patrick_prices.pl 1 > /roottransfer/jgeng/Prod/ttPrices/patrick_prices.txt";
  system($cmd);
  return; # return nothing
}


sub convertTTYM2YYYYMM
# input: YM in ttFormat: Feb16
# output: change to 201602; return NA if input is NA
{

   my ($YM)=@_;

my %monHash =(
"Jan" => "1",
"Feb" => "2",
"Mar" => "3",
"Apr" => "4",
"May" => "5",
"Jun" => "6",
"Jul" => "7",
"Aug" => "8",
"Sep" => "9",
"Oct" => "10",
"Nov" => "11",
"Dec" => "12"
);


   if($YM eq "NA" || $YM eq "")
   {
     return "NA";
   }

    # Feb16 is split into Feb and 16, convert to 201612
    # split on number, but also return the separator  
    my @aaa=split(/([A-Z|a-z]+)/,$YM);

    # first is empty
    my $m=$aaa[1];
    my $y=$aaa[2];

    my $mNum=$monHash{$m};

    my $yyyymm=sprintf( "%04d%02d",2000+$y,$mNum);
    #print "YM=|$YM|, aaa=",join("|",@aaa),"\n";
    #print "TT: m=$m y=$y mNum=$mNum yyyymm=$yyyymm\n";
    return $yyyymm;
}

sub convertRTHYM2YYYYMM
# input: YM in RTH format: 2015Z
# output: change to 201512; return NA if input is NA
{

   my ($YM)=@_;


my %monHash =(
"F" => "1",
"G" => "2",
"H" => "3",
"J" => "4",
"K" => "5",
"M" => "6",
"N" => "7",
"Q" => "8",
"U" => "9",
"V" => "10",
"X" => "11",
"Z" => "12"
);

   if($YM eq "NA" || $YM eq "")
   {
     return "NA";
   }

    # 2015Z  convert to 201612
    # split on number, but also return the separator
    my @aaa=split(/([0-9]+)/,$YM);

    # first is empty
    my $yyyy=$aaa[1];
    my $mStr=$aaa[2];

    my $mNum=$monHash{$mStr};

    my $yyyymm=sprintf( "%04d%02d",$yyyy,$mNum);
    #print "YM=|$YM|, aaa=",join("|",@aaa),"\n";
    #print "RTH: mStr=$mStr yyyy=$yyyy mNum=$mNum yyyymm=$yyyymm\n";

    return $yyyymm;
}



sub sendEmail
# input: YM in RTH format: 2015Z
# output: change to 201512; return NA if input is NA
{

   my ($subject,$content)=@_;

   my $outfile2="/tmp/tmpEmail.txt";

   open(OUTFILE2, '>', "$outfile2") || die "Couldn't open $outfile2: $!\n";

   printf OUTFILE2 "$content\n";
   close(OUTFILE2);
   #my $cmd0="cat  $outFile2";
   #system("$cmd0");          



   my $emailStr=create_email_str();
   #print "emaStr=$emailStr\n";


    my $cmd="
cat $outfile2 |myAddHeader.sh \"Subject: $subject\"  > /tmp/tmpEmailTxt.txt
# -v will save a copy in inbox
###################################
$emailStr
";

    #print "$cmd\n";
    system("$cmd");

}


sub create_email_str
# script specific string for email lists
# return: strings to insert into the send mail cmd
{
    ## reads in the current schedule pointer
    my $emailFile="/roottransfer/jgeng/Prod/schedules/list_emails.txt";
    my @emails=read_file($emailFile);
    #print join("\n",@emails),"\n";

    my $emailStr="";
    my @line;
    foreach my $email (@emails)
    {
      if(substr($email,0,1) eq "#") # skip # lines
      {
	next;
      }

      @line =split('@',$email);
      my $name=$line[0];
      my $domain=$line[1];

      $emailStr.="
       sendmail $name\\\@$domain  <  /tmp/tmpEmailTxt.txt";
    }

    return $emailStr;
# this is the raw cmds in the perl code
#sendmail junfei.geng\@gmail.com  < /roottransfer/jgeng/Prod/schedules/warn_schedule.txt
}



sub read_file
# input: filename
# return: ref to array of rows
{
   my ($filename)=@_;

   open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";
   my @allRows=(<INFILE>);
   #chomp@allRows; # remove new lines at each row
   for (my $i=0;$i<=$#allRows;$i++)
   {
     my $line=$allRows[$i];
     $line =~ s/[\r\n]+//g; # remove either windows or unix new lines
     $allRows[$i]=$line;
   }

   close(INFILE);
   return @allRows;
}


sub read_file_by_colNum
# input: filename, colNum
# return: ref to array of rows
{
   my ($filename,$colNum)=@_;

   open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";
   my @Xs;

   my @line; 
   while(<INFILE>)
  {

    #chomp the new line at the end
    chomp($_);
    @line =split;

    my $sym = $line[$colNum-1];
    $sym=~s/^\s+//; # remove leading spaces
    $sym=~s/\s+$//; # remove trailing spaces
    push (@Xs, $sym);
  }
   close(INFILE);
   return @Xs;
}



__END__


 my $cmd="wc test.txt| head -1 |mygetcols.pl 1";
 my $res=`$cmd`;
 chomp($res);




