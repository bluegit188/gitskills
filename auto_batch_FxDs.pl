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
  #cmd: getF1D/F2D/F3D returns
  portara_get_ooRets_multi.pl list_sym_$sym 14 1 >tmp_ooF1Ds
  portara_get_ooRets_multi.pl list_sym_$sym 14 2 >tmp_ooF2Ds
  portara_get_ooRets_multi.pl list_sym_$sym 14 3 >tmp_ooF3Ds
  combine_match2na_all.pl tmp_ooF1Ds tmp_ooF2Ds tmp_ooF3Ds|mygetcols.pl 2 1 5 9 13|egrep -v -E -e\" NA\$\" |myShiftDateRowToFirstRow.pl 1 DATE >yvar_FxDs.txt.$sym
";
   # print "$cmd\n";
    system("$cmd");


}
close(INFILE);


__END__


 my $cmd="wc test.txt| head -1 |mygetcols.pl 1";
 my $res=`$cmd`;
 chomp($res);

