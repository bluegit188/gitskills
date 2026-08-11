#!/usr/bin/perl

use strict;
use Date::Calc qw(Add_Delta_Days);


($#ARGV+2)==4 || die 
"Usage: myDateDif.pl isHeader=0/1 colDate1 colDate2
        Find date difference for date1 and date2\n";


my $isHeader=$ARGV[0];
my $colDate1=$ARGV[1];
my $colDate2=$ARGV[2];


my $count=0;
my @line; 
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;
    my $date1 = $line[$colDate1-1];
    my $date2 = $line[$colDate2-1];

    if($isHeader==1 && $count==1 ) # print header
    {
      print "$str DIF\n";
      next;
    }

    my $dif=dateDif($date1,$date2);

    print "$_ $dif\n";
}
close(INFILE);


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
