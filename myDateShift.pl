#!/usr/bin/perl

use strict;
use Date::Calc qw(Add_Delta_Days);


($#ARGV+2)==4 || die 
"Usage: myDateShift.pl isHeader=0/1 colDate offset
        Find the new date by offset, can be -ive offset.
        For example, if date=20151202, n=2, return 20151204.\n";


my $isHeader=$ARGV[0];
my $colDate=$ARGV[1];
my $N=$ARGV[2];


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
      print "$str NEWDATE\n";
      next;
    }

    my $dateNew= get_next_nth_date($date,$N);

    print "$_ $dateNew\n";
}
close(INFILE);



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

