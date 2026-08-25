#!/usr/bin/perl

use strict;

(($#ARGV+2) ==1 || ($#ARGV+2) ==2) || die
"Usage: mycat.pl opt:header=0/1
 header: 1=default, print file name, 0=no header\n";

my $isHeader=1;
if(($#ARGV+2) ==2)
{
  $isHeader=$ARGV[0];
}

while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    my $file=$_;

    if($isHeader)
    {
       print "###################\n";
       print "$file\n";
       print "###################\n";
    }

    my $cmd="cat $file";
    system("$cmd");


}


