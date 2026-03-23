#!/usr/bin/perl

use strict;


($#ARGV+2) ==3 || die 
"Usage: datesXmgr.pl file.txt colDate
       Convert regular date(e.g, 20150215) into xmgr format: 2015-02-15-00:00:00.000\n";



my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $colDate=$ARGV[1];

my @line; 
while(<INFILE>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;

    my $str=$_;

    my $date=$line[$colDate-1];

    my $year=get_year($date);
    my $month=get_month($date);
    my $day=get_day_of_month($date);

    #print $date, "Y=",get_year($date)," M=",get_month($date)," D=",get_day_of_month($date),"\n";

    #xmgr date str:  1999-12-31-23:59:59.5
    my $dateStr=sprintf( "%04d-%02d-%02d-00:00:00",$year,$month,$day);
    
    print "$dateStr $str\n";

}
close(INFILE);


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


