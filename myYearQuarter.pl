#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: myYearQuarter.pl isHeader=0/1 colDate
        Find YYYYQQ of date\n";


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
      print "$str YYYYQQ\n";
      next;
    }

    my $YYYY=int($date/10000);
    my $MMDD=$date%10000;
    my $MM=int($MMDD/100);
    my $DD=$MMDD%100;
    my $QQ=int(($MM-1)/3)+1;

    my $yq=sprintf("%4d%02d",$YYYY,$QQ);
    print "$_ $yq\n";
}


__END__
#qtrs, YYYY01, YYYY04
regdata$QQ=(regdata$MM-1)%/%3+1 # interger division
regdata$YYQQ=regdata$YYYY*100+regdata$QQ

