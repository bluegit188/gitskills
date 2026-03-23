#!/usr/bin/perl

use strict;

($#ARGV+2) == 3|| die
"Usage: combine_match2.pl file1(long) file2(short)
       Intersect two files based on first 2 columns matching
       Output: matched rows side by side\n";



my $file2=$ARGV[1];
open(INFILE2, "$file2") || die "Couldn't open $file2: $!\n";
my %hash2; # key->str
my @line;
while(<INFILE2>)
{
    #chomp the new line at the end
    chomp($_);
    my $str=$_;
    #print "str=|$str|\n";
    @line =split;
    my $key=$line[0].":".$line[1];

    $hash2{$key}=$str;
}
close(INFILE2);




my $file1=$ARGV[0];
open(INFILE1, "$file1") || die "Couldn't open $file1: $!\n";
while(<INFILE1>)
{
    #chomp the new line at the end
    chomp($_);
    my $str1=$_;
    #print "str1=|$str1|\n";

    @line =split;
    my $key1=$line[0].":".$line[1];

    if(!exists $hash2{$key1})
    {
      next;
    }

    my $str2= $hash2{$key1};

    print "$str1 $str2\n";
}
close(INFILE1);
