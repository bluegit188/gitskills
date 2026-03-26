#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: myDayOfWeek.pl isHeader=0/1 colDate
        Find day of week:  Sun=0, Mon=1, Tue=2, .., Fri=5, Sun=6.\n";


my $isHeader=$ARGV[0];
my $colDate=$ARGV[1];

my $count=0;
my @line; 
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;
    my $date = $line[$colDate-1];

    if($isHeader==1 && $count==1 ) # print header
    {
      print "$str DOW\n";
      next;
    }

    my $dow=get_day_of_week_fast($date);

    print "$_ $dow\n";
}
close(INFILE);

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

   #print $k+int(2.6*$m-0.2)-2*$C+$Y+int($Y/4)+int($C/4),"\n";
   #print ((9)%7), "\n";
   return ( $k+int(2.6*$m-0.2)-2*$C+$Y+int($Y/4)+int($C/4) )%7;

}

__END__



 where denotes the integer floor function,
k is day (1 to 31)
m is month (1 = March, ..., 10 = December, 11 = Jan, 12 = Feb) Treat Jan & Feb as months of the preceding year
C is century (1987 has C = 19)
Y is year (1987 has Y = 87 except Y = 86 for Jan & Feb)
W is week day (0 = Sunday, ..., 6 = Saturday)

Here the century and 400 year corrections are built into the formula. The term relates to the repetitive pattern that the 30-day months show when March is taken as the first month. 


__END__
https://cs.uwaterloo.ca/~alopez-o/math-faq/node73.html

 The following formula, which is for the Gregorian calendar only, may be more convenient for computer programming. Note that in some programming languages the remainder operation can yield a negative result if given a negative operand, so mod 7 may not translate to a simple remainder.

where denotes the integer floor function,
k is day (1 to 31)
m is month (1 = March, ..., 10 = December, 11 = Jan, 12 = Feb) Treat Jan & Feb as months of the preceding year
C is century (1987 has C = 19)
Y is year (1987 has Y = 87 except Y = 86 for Jan & Feb)
W is week day (0 = Sunday, ..., 6 = Saturday)

Here the century and 400 year corrections are built into the formula. The term relates to the repetitive pattern that the 30-day months show when March is taken as the first month.

The following short C program works for a restricted range, it returns 0 for Monday, 1 for Tuesday, etc.

dow(m,d,y){y-=m<3;return(y+y/4-y/100+y/400+"-bed=pen+mad."[m]+d)%7;}

The program appeared was posted by sakamoto@sm.sony.co.jp (Tomohiko Sakamoto) on comp.lang.c on March 10th, 1993. 

