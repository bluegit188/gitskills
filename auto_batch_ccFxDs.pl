#!/usr/bin/perl

use strict;

($#ARGV+2)==2 || die 
"Usage: auto_batch.pl file.txt\n";


# open file an dput column specified into a hash
my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";



my @line; 
while(<INFILE>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;


    my $sym = $line[0];
    $sym=~s/^\s+//; # remove leading spaces
    $sym=~s/\s+$//; # remove trailing spaces


    my $cmd="
  #cmd: ccFxD
  portara_get_ooRets_multi.pl list_sym_$sym 39 >tmp_FOC2s
  portara_get_ooRets_multi.pl list_sym_$sym 40 >tmp_FGAP2s
  portara_get_ooRets_multi.pl list_sym_$sym 41 >tmp_ccF1Ds
  portara_get_ooRets_multi.pl list_sym_$sym 42 >tmp_ccF2Ds

  combine_match2na_all.pl tmp_FOC2s tmp_FGAP2s tmp_ccF1Ds tmp_ccF2Ds|mygetcols.pl 2 1 5 9 13 17 |egrep -v -E -e\" NA\$\" |myShiftDateRowToFirstRow.pl 1 DATE >yvar_ccFxDs.txt.$sym
";
   # print "$cmd\n";
    system("$cmd");


}
close(INFILE);


__END__


 my $cmd="wc test.txt| head -1 |mygetcols.pl 1";
 my $res=`$cmd`;
 chomp($res);

