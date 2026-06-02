package JunfeiUtil;

use strict;
use Exporter qw(import);
use POSIX;
use Date::Calc qw(Add_Delta_Days);

our @EXPORT = qw(
                 add
                 multiply
	         get_std
	         get_mean
		 get_min_max_mean_std
		 nearest_junf
		 log10
		 get_month
		 get_year
		 get_day_of_month
		 get_hour_from_HHMMSS
		 get_min_from_HHMMSS
		 get_sec_from_HHMMSS
		 index_in_min_HHMMSS
		 get_HHMM_from_min_index
		 get_day_of_week_fast
		 min
		 max
		 quantile_unsorted
		 quantile_sorted
		 getWeekdaysVec
		 getDatesVec
                 get_today_date	
                 sign
                 TY_quote_to_decimal
                 read_file_by_key
		 get_secs_since_epoch
		 get_date_time_from_SSE
		 get_now_date
		 get_now_HHMMSS
		 dateDif
		 timeDifInSeconds
		 get_next_nth_date
		 convertTTYM2YYYYMM
		 convertRTHYM2YYYYMM
		 convertRTHYM2TTYM
		 read_file
		 read_file_windows
		 getNextYMFromRollDict
		 getPrevYMFromRollDict
	       );

sub add
{
   my ($x, $y) = @_;
   return $x + $y;
}

sub multiply 
{
   my ($x, $y) = @_;
   return $x * $y;
}

sub get_mean
{
   my ($refX ) = @_;
   my $count=$#$refX+1;
   if($count==0){return 0;}
   my $sum=0;
   foreach my $x (@$refX)
   {
     $sum+=$x;
   }
   return $sum/$count;
}

sub get_std
#one pass
{
   my ($refX ) = @_;
   my $count=$#$refX+1;
   if($count<1){return 0;}

   #print "count=$count\n";
   my $xsum=0;
   my $x2sum=0;
   foreach my $x (@$refX)
   {
     $xsum+=$x;
     $x2sum+=($x*$x);
   }
   my $var=0; # count=1
   if($count >1)
   {
     $var=($x2sum-$xsum*$xsum/$count)/($count-1);
   }
   return sqrt($var);
}


sub get_min_max_mean_std
#one pass:
# input a ref to an arry of Xs
# return: min max mean std count
{
   my ($refX ) = @_;
   my $count=$#$refX+1;


   my $inf = 9**9**9;
   my $neginf = -9**9**9;


   my $min=$inf;
   my $max=$neginf;
   my $mean;
   my $std;

   if($count<1) # empty
   {
     return (0,0,0,0,0);
   }

   #print "count=$count\n";
   my $xsum=0;
   my $x2sum=0;
   foreach my $x (@$refX)
   {
     $xsum+=$x;
     $x2sum+=($x*$x);

     if($x<$min){$min=$x;}

     if($x>$max){$max=$x;}

   }
   my $var=0; # if only one ob
   if($count >1)
   { 
     $var=($x2sum-$xsum*$xsum/$count)/($count-1);
   }
   $std=sqrt($var);
   $mean=$xsum/$count;

   return ($min,$max,$mean,$std,$count);
}



sub nearest_junf()
# emulate Math::Round's nearest function, but elimiate extra zeros from $.4f notation
# input: -4, 3.56789 (max to 4th decimal digits
# output: 3.568
#
#more examples: first argu=-4
#0         -> 0
#0.1       -> 0.1
#0.11      -> 0.11
#0.111     -> 0.111
#0.1111111 -> 0.1111
{
    my ($pow10, $x) = @_;
    my $a = 10 ** $pow10;

    return (int($x / $a + (($x < 0) ? -0.5 : 0.5)) * $a);
}

sub log10
{
  my $n = shift;
  return log($n)/log(10);
}

sub get_month
#20150213 
# return 2
{
   my ($date) = @_;
   #my $YYYY=int($date/10000);
   my $MMDD=$date%10000;
   my $MM=int($MMDD/100);
   return $MM;
}

sub get_year
#20150213 
# return 2
{
   my ($date) = @_;
   my $YYYY=int($date/10000);
   #my $MMDD=$date%10000;
   #my $MM=int($MMDD/100);
   return $YYYY;
}

sub get_day_of_month
#20150213 
# return 2
{
   my ($date) = @_;
   #my $YYYY=int($date/10000);
   my $MMDD=$date%10000;
   #my $MM=int($MMDD/100);
   my $DD=$MMDD%100;
   return $DD;
}



sub get_hour_from_HHMMSS
# 143005 ( 2:30PM, 5 sec)
# return 14
{
   my ($hhmmss) = @_;
   my $hh=int($hhmmss/10000);
   #my $mmss=$hhmmss%10000;
   #my $mm=int($mmss/100);
   #my $ss=$mmss%100;
   return $hh;
}



sub get_min_from_HHMMSS
# 143005 ( 2:30PM, 5 sec)
# return 30
{
   my ($hhmmss) = @_;
   #my $hh=int($hhmmss/10000);
   my $mmss=$hhmmss%10000;
   my $mm=int($mmss/100);
   #my $ss=$mmss%100;
   return $mm;
}


sub get_sec_from_HHMMSS
# 143005 ( 2:30PM, 5 sec)
# return 5
{
   my ($hhmmss) = @_;
   #my $hh=int($hhmmss/10000);
   my $mmss=$hhmmss%10000;
   #my $mm=int($mmss/100);
   my $ss=$mmss%100;
   return $ss;
}

sub index_in_min_HHMMSS
#input: 14:30:05
# output: 14*60+30
{
  my ($hhmmss) = @_;
  return get_hour_from_HHMMSS($hhmmss)*60+get_min_from_HHMMSS($hhmmss);
}


sub get_HHMM_from_min_index
#input: minute index
# output: time in HHMM format
{
  my ($minIndex) = @_;

  my $hour=int($minIndex/60);
  my $min=$minIndex-60*$hour;
  my $timeStr=sprintf( "%02d%02d",$hour,$min);
  return $timeStr;
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

sub min
#input: x1, x2
# output: smaller one
{
  my ($x1,$x2) = @_;

  if($x1<=$x2)
  {
    return $x1;
  }

  return $x2;
}

sub max
#input: x1, x2
# output: bigger one
{
  my ($x1,$x2) = @_;

  if($x1 >= $x2)
  {
    return $x1;
  }

  return $x2;
}


sub quantile_unsorted
#input: aref=ref to data array, p=[0,1]
#       Note data is not sorted
#output: quantile
# this sub is from Statistics::Descriptive
{
    my ( $aref, $QuantileNumber ) = @_;
    #sort data
    my @data=sort {$a <=> $b} @$aref;
    return quantile_sorted(\@data,  $QuantileNumber);
}



sub quantile_sorted
#input: aref=ref to data array, p=[0,1]
#       Note data is sorted
#output: quantile
# this sub is from Statistics::Descriptive
# If array is sorted already, one can call many times to extract quantile quickly
# if unosorted, need to sort everytime, which is slow.
{
    my ( $aref, $QuantileNumber ) = @_;
    $QuantileNumber*=4; # original code deals with [0,4]
    #unless ( defined $QuantileNumber and $QuantileNumber =~ m/^0|1|2|3|4$/ ) {
    #   carp("Bad quartile type, must be 0, 1, 2, 3 or 4\n");
    #   return;
    #}
 
    #  check data count after the args are checked - should help debugging
    return undef if !($#$aref+1);

    #data is already sorted
    #my @data=@$aref;

    return $$aref[0] if ( $QuantileNumber == 0 );

    my $count = $#$aref+1;

    return $$aref[ $count - 1 ] if ( $QuantileNumber == 4 );

    my $K_quantile = ( ( $QuantileNumber / 4 ) * ( $count - 1 ) + 1 );
    #print "K=",$K_quantile,"\n";
    my $F_quantile = $K_quantile - POSIX::floor($K_quantile);
    $K_quantile = POSIX::floor($K_quantile);

    # interpolation
    my $aK_quantile     = $$aref[ $K_quantile - 1 ];
    return $aK_quantile if ( $F_quantile == 0 );
    my $aKPlus_quantile = $$aref[$K_quantile];

    # Calcul quantile
    my $quantile = $aK_quantile
      + ( $F_quantile * ( $aKPlus_quantile - $aK_quantile ) );
    return $quantile;
}


sub getWeekdaysVec()
# return a vector of dates, excluding weekends, inclusive
{
    my ($refVec,$startDate, $endDate) = @_;

    my $date=$startDate;

    while($date<= $endDate)
    {
       #print "$date\n";
       my $dow=get_day_of_week_fast($date);
       if($dow != 0 && $dow!=6) # non-weekends
       {
          push(@$refVec,$date);
       }

       my $YYYY=int($date/10000);
       my $MMDD=$date%10000;
       my $MM=int($MMDD/100);
       my $DD=$MMDD%100;
       #-- add 60 days to November 4th, 1985
       my ($newY, $newM, $newD) = Add_Delta_Days($YYYY, $MM, $DD,1);

       $date=sprintf("%4d%02d%02d",$newY,$newM,$newD);

    }
}


sub getDatesVec()
# return a vector of dates, excluding weekends, inclusive
{
    my ($refVec,$startDate, $endDate) = @_;

    my $date=$startDate;

    while($date<= $endDate)
    {
       #print "$date\n";
       push(@$refVec,$date);
       
       my $YYYY=int($date/10000);
       my $MMDD=$date%10000;
       my $MM=int($MMDD/100);
       my $DD=$MMDD%100;
       #-- add 60 days to November 4th, 1985
       my ($newY, $newM, $newD) = Add_Delta_Days($YYYY, $MM, $DD,1);

       $date=sprintf("%4d%02d%02d",$newY,$newM,$newD);

    }
}



sub get_today_date
# get today date: 20151015
{
   #my ($x, $y) = @_;
   my $cmd="date \"+\%Y\%m\%d\"";
   my $res=`$cmd`;
   chomp($res);
   return $res;
}

sub sign()
{
    my ($x) = @_;

    if($x>0)
    {
      return 1;
    }
    elsif($x<0)
    {
      return -1;
    }
    else
    {
      return 0;
    }

}



sub TY_quote_to_decimal
# 112^297=112+29.75*1/32=112.9297
# from 112297 to 112.9297        
{                                
   my ($old)=@_;                 

   #print "old=$old\n";

   # 112^297: A=112, B=29, C=7
   my $A=int($old/1000);      
   my $BC=$old%1000;          
   my $B=int($BC/10);         
   my $C=$BC%10;              
   if($C eq "2")              
   {                          
     $C=0.25;                 
   }                          
   elsif($C eq "5")           
   {                          
     $C=0.5;                  
   }                          
   elsif($C eq "7")           
   {                          
     $C=0.75;                 
   }                          
   else                       
   {                          
     $C=0;
   }      

   #print "A/B/C= $A,$B,$C\n";
   return $A+($B+$C)*1/32;    

 }


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

   my $dif = Date::Calc::Delta_Days( @first, @second );
   return $dif;
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



sub get_next_nth_date
#20150213
#20150214
{
   my ($date,$N) = @_;

   my $YYYY=int($date/10000);
   my $MMDD=$date%10000;
   my $MM=int($MMDD/100);
   my $DD=$MMDD%100;
   my ($y,$m,$d)=Add_Delta_Days($YYYY,$MM,$DD,$N);
   my $newDate=sprintf("%4d%02d%02d",$y,$m,$d);
   return "$newDate";
}



sub convertRTHYM2TTYM
# input: YM in RTH format: 2015Z
# output: TT YM Dec2015
{

   my ($YM)=@_;

my %monHash =(
"F" => "Jan",
"G" => "Feb",
"H" => "Mar",
"J" => "Apr",
"K" => "May",
"M" => "Jun",
"N" => "Jul",
"Q" => "Aug",
"U" => "Sep",
"V" => "Oct",
"X" => "Nov",
"Z" => "Dec"
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

    my $mStr=$monHash{$mStr};

    my $yy2=$yyyy%100;
    my $newTTYM=sprintf( "%s%02d",$mStr,$yy2);
    #print "YM=|$YM|, aaa=",join("|",@aaa),"\n";
    #print "RTH: mStr=$mStr yyyy=$yyyy mNum=$mNum yyyymm=$yyyymm\n";

    return $newTTYM;
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


sub read_file
# input: filename
# return: ref to array of rows
{
   my ($filename)=@_;

   open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";
   my @allRows=(<INFILE>);
   chomp@allRows; # remove new lines at each row
   close(INFILE);
   return @allRows;
}



sub read_file_windows
# input: filename, read both unix and window files
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


sub getNextYMFromRollDict
#input: 2015Z and HMUZ
#output: 2016H
{
   my ($curYM,$rollDict)=@_;


   my $curY=substr($curYM,0,4);
   my $curM=substr($curYM,-1,1);


   #print "Y=$curY M=$curM\n";

   # split to letter
   my @letters = split(//, $rollDict);
   my $len=$#letters+1;


   # create a has of letter count as well for easy search
   #my %hash;
   #$hash{$_}++ for split(//, $rollDict);   # increase count for each field
                                            # in the loop

   my %hash; # letter-> loc
   for my $i (0..$#letters)
   {
      my $char=$letters[$i];
      $hash{$char}= $i;
   }
   #print join(" ",sort keys %hash),"\n";


   # get nextYM
   my $curMLoc; #e.g, Z=3
   my $nextMLoc; # then next must be 0
   if( !exists $hash{$curM})
   {
      print "Error: curM=$curM not in rollDict=$rollDict\n";
      return "NA";
   }

   $curMLoc=$hash{$curM};
   # add 1 if not the last in rollDict
   $nextMLoc=$curMLoc+1;
   my $nextY=$curY;
   if($curMLoc == $len-1) # if last in rollDict, add 1 to year as well
   {
     $nextMLoc=0;
     $nextY=$curY+1;
   }

   my $nextM=$letters[$nextMLoc];

   return "$nextY$nextM";

}



sub getPrevYMFromRollDict
#input: 2015H and HMUZ
#output: 2014Z
{
   my ($curYM,$rollDict)=@_;


   my $curY=substr($curYM,0,4);
   my $curM=substr($curYM,-1,1);


   #print "Y=$curY M=$curM\n";

   # split to letter
   my @letters = split(//, $rollDict);
   my $len=$#letters+1;


   # create a has of letter count as well for easy search
   #my %hash;
   #$hash{$_}++ for split(//, $rollDict);   # increase count for each field
                                            # in the loop

   my %hash; # letter-> loc
   for my $i (0..$#letters)
   {
      my $char=$letters[$i];
      $hash{$char}= $i;
   }
   #print join(" ",sort keys %hash),"\n";


   # get nextYM
   my $curMLoc; #e.g, Z=3
   my $prevMLoc; # then next must be 0
   if( !exists $hash{$curM})
   {
      print "Error: curM=$curM not in rollDict=$rollDict\n";
      return "NA";
   }

   $curMLoc=$hash{$curM};
   # add 1 if not the last in rollDict
   $prevMLoc=$curMLoc-1;
   my $prevY=$curY;
   if($curMLoc == 0) # if first in rollDict, subtract 1 to year as well
   {
     $prevMLoc=$len-1;
     $prevY=$curY-1;
   }

   my $prevM=$letters[$prevMLoc];

   return "$prevY$prevM";

}


1;

__END__
my $inf = 9**9**9;
my $neginf = -9**9**9;
my $nan = -sin(9**9**9);

sub isinf { $_[0]==9**9**9 || $_[0]==-9**9**9 }
sub isnan { ! defined( $_[0] <=> 9**9**9 ) }
# useful for detecting negative zero
sub signbit { substr( sprintf( '%g', $_[0] ), 0, 1 ) eq '-' }
