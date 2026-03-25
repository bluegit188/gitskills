#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: check_duplicate.pl file.txt colNo\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";


my $n=$ARGV[1];
my %dicts=();

my @line; 
while(<INFILE>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str = $line[$n-1];
    $str=~s/^\s+//; # remove leading spaces
    $str=~s/\s+$//; # remove trailing spaces
    $dicts{$str}++;
}
close(INFILE);

foreach my $key (sort keys %dicts)
{
    my $count=$dicts{$key};
    #print $key,"=", $count,"\n" if $count>1;
    print $key,"\t", $count,"\n";

}
