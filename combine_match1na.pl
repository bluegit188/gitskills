#!/usr/bin/perl

use strict;

($#ARGV+2) == 3|| die
"Usage: combine_match1.pl file1(long) file2(short)
       Intersect two files based on first column matching
       Output: matched rows side by side\n";



my $file2=$ARGV[1];
open(INFILE2, "$file2") || die "Couldn't open $file2: $!\n";
my %hash2; # key->str
my @line;


my $NAStr;
my $count=0;
while(<INFILE2>)
{

    $count++;
    #chomp the new line at the end
    chomp($_);
    my $str=$_;
    @line =split;
    my $key=$line[0];
    $hash2{$key}=$str;


    if($count==1) # create NA Str
    {
       $NAStr="";
       foreach my $k (@line)
       {
	 $NAStr=$NAStr." NA";
       }
    }

}
close(INFILE2);



my $file1=$ARGV[0];
open(INFILE1, "$file1") || die "Couldn't open $file1: $!\n";

while(<INFILE1>)
{


    #chomp the new line at the end
    chomp($_);
    my $str1=$_;
    @line =split;
    my $key1=$line[0];

    if(!exists $hash2{$key1})
    {
      print "$str1 $NAStr\n";
      next;
    }

    my $str2= $hash2{$key1};

    print "$str1 $str2\n";
}
close(INFILE1);
