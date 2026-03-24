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
  #cmd: getF1D/FOC/FGAPs returns
portara_get_FOC_FGAPs_multi.pl list_sym_$sym |mygetcols.pl 2 1 3 4 5  >yvar_FOC_FGAPs.txt.$sym
";
   # print "$cmd\n";
    system("$cmd");


}
close(INFILE);


__END__


 my $cmd="wc test.txt| head -1 |mygetcols.pl 1";
 my $res=`$cmd`;
 chomp($res);

