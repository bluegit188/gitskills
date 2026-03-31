#!/usr/bin/perl

use strict;

($#ARGV+2)==3 || die 
"Usage: myIsEurIBC.pl isHeader=0/1 colSym
       Find if it's eurIBC\n";


my $isHeader=$ARGV[0];
my $colSym=$ARGV[1];



#Step 1: reads asset/session file: SYM asset session
my $fileAS="/home/jgeng/bin/final_sym_asset_session.txt";
my $colAsset=2;
my $colSession=3;
my %hashASs=read_file_by_key($fileAS);



my $count=0;
my @line; 
while(<STDIN>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);
    @line =split;
    my $str=$_;
    my $sym = $line[$colSym-1];

    if($isHeader==1 && $count==1 ) # print header
    {
      print "$str isEurIBC\n";
      next;
    }

    my $asset="NA";
    my $session="NA";

    if(exists $hashASs{$sym})
    {
       $asset=$hashASs{$sym}[$colAsset-1];
       $session=$hashASs{$sym}[$colSession-1];

    }
    my $newAsset=$asset;
    if($asset eq "Energy" || $asset eq "Grain" ||$asset eq "Meat" || $asset eq "Metal" || $asset eq "Soft"  )
    {
      $newAsset="Physical";
    }

    my $eurIBC=0;
    if( ($newAsset ne "Physical") &&  ($session eq "Europe"))
    {
      $eurIBC=1;
    }
    print "$_ $eurIBC\n";
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

       #ignore comment line
       if(substr($str,0,1) eq "#")
       {
          next;
       }
       my @line= split;
       my $key=$line[0];
       my $value=$str;
       #$hash{$key} .= exists $hash{$key} ? ",$value" : $value;
       $hash{$key} =\@line;

    }
   close(INFILE);
   return %hash;
}
