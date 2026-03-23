#!/usr/bin/perl

use strict;

($#ARGV+2) >= 3|| die
"Usage: combine_match2na_all.pl file1 file2 file3 ...
       Combine multiple files based on first two columns, fill NA\n";

my @files;
my %hashs; # filename=>  hash: key=row
my %NAStrs;    # filename=> NAStr

my %allKeys;
foreach my $i (0..$#ARGV)
{
  my $file=$ARGV[$i];
  #NAStr would be different for each file if numCols are different
  my ($NAStr,$refHash)=build_hash_by_key($file,\%allKeys);

  #print "file=$file\n";
  #print "   NAStr=$NAStr;\n";
  #print_hash($refHash);

  push(@files,$file);
  $hashs{$file}=$refHash;
  $NAStrs{$file}=$NAStr;


}

## now for each key, loop through each file
foreach my $key (sort keys %allKeys)
{

   #print "key=$key\n";
   my ($key1,$key2)=split(/\|/,$key);
   print "$key1 $key2";
   foreach my $file (@files)
   {
      my $hashRef=$hashs{$file};
      my $NAStr=$NAStrs{$file};

      my $outstr;

      if( exists $$hashRef{$key})
      {
	 $outstr=" ".$$hashRef{$key};
      }
      else
      {
         $outstr=$NAStr;
      }
      print "$outstr";
   }
   print "\n";

}


sub build_hash_by_key
# input: filename(first column is key)
# return: numCols and ref to hash
{
   my ($filename, $refAllKeys)=@_;

   open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";
 
   my %hash; # key->str
   my @line;
   my $NAStr;

   my $count=0;
   while(<INFILE>)
   {
     $count++;
     #chomp the new line at the end
     chomp($_);
     my $str=$_;
     @line =split;
     my $key1=$line[0];
     my $key2=$line[1];
     my $key="$key1|$key2";
     $hash{$key}=$str;

     $$refAllKeys{$key}=1; ## insert into the big hash of all keys

     if($count==1) # create NA Str
     {
       $NAStr="";
       foreach my $k (@line)
       {
	 $NAStr=$NAStr." NA";
       }
     }
   }

   return ($NAStr,\%hash);
}



sub print_hash
{
    my $href = shift;
    print "$_\t=> $href->{$_}\n" for keys %{$href};
}



__END__

