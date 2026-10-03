#!/usr/bin/perl

use strict;
#use PDL::LiteF;        # loads less modules
#use PDL::NiceSlice;    # preprocessor for easier pdl indexing syntax 
#use PDL::Stats;


($#ARGV+2) ==7 || die
"Usage: compute_ema_multi.pl file.txt(header) colSym colDate colX alpha ema0
       Compute emaStd as: ema(t)= a*ema(t-1) + (1-a)*(x_t)
       The ema0 is specified by the user.
       Output: SYM DATE X ema\n";

my $DEBUG=0;

my $filename=$ARGV[0];
open(INFILE, "$filename") || die "Couldn't open $filename: $!\n";

my $colSym=$ARGV[1];
my $colDate=$ARGV[2];
my $colX=$ARGV[3];

my $a=$ARGV[4];

my $ema0=$ARGV[5];

### loads in data


my @syms;
my @dates;
my @xs;

my %stdHash; # sym-> std

my @line;
my $header;
my $count=0;
my $prevSym="NA";
my $prevDate="NA";
my @tmpXs=();
while(<INFILE>)
{
    $count++;
    #chomp the new line at the end
    chomp($_);

    if($count==1)
    {
      $header=$_;
      next;
    }


    @line =split;

    my $sym=$line[$colSym-1];
    my $date=$line[$colDate-1];
    my $x=$line[$colX-1];


    # compute std for prev sym or if at last line
    my $std;
    if( $sym ne $prevSym)
    {

        if($prevSym eq "NA")
	{

	  push(@syms,$sym);
	  push(@dates,$date);
	  push(@xs,$x);
	  push(@tmpXs,$x);
	  $prevSym=$sym;
	  $prevDate=$date;
	  next;
	}
	else
	{
	  my $count2=$#tmpXs+1;
	  #print "XXX=",join(" ",@tmpXs),"\n";
	  # finish up last sym std calculations

	  #my $pdlRef = pdl @tmpXs;
	  # a simple function
	  #my $std = $pdlRef->stdv_unbiased ;
	  #print "$prevSym $prevDate $std $count2\n";

	  my $std=get_std(\@tmpXs);

	  $stdHash{$prevSym}=$std;

	  @tmpXs=();
	  push(@syms,$sym);
	  push(@dates,$date);
	  push(@xs,$x);
	  push(@tmpXs,$x);
	  $prevSym=$sym;
	  $prevDate=$date;
	  next;
	}

    }

    push(@syms,$sym);
    push(@dates,$date);
    push(@xs,$x);
    push(@tmpXs,$x);
    $prevSym=$sym;
    $prevDate=$date;

    if (eof)
    {

	  my $count2=$#tmpXs+1;
	  # finish up  std 
	  #my $pdlRef = pdl @tmpXs;
	  # a simple function
	  #my $std = $pdlRef->stdv_unbiased ;
	  #print "$sym $date $std $count2\n";

	  my $std=get_std(\@tmpXs);

	  $stdHash{$sym}=$std;
    }

}
close(INFILE);

if($DEBUG)
{
    foreach my $sym (sort keys %stdHash)
    {
      if(exists $stdHash{$sym})
      {
	my $std= $stdHash{$sym};
	print "sym=$sym std=$std\n";
      }
    }
}


#########################
# compute ema std
my $ema;

$prevSym="NA";
foreach my $i (0..$#xs)
{
    my $curSym=$syms[$i];
    my $curDate=$dates[$i];
    my $curX=$xs[$i];


    #print "$curSym $curDate $curX\n";
    if($prevSym eq $curSym )
    {
      $ema=$ema*$a+(1-$a)*($curX);
    }
    else
    {
      if( ! exists $stdHash{$curSym})
      {
	print "Error: $curSym has no std computed.\n";
	exit(0);
      }
      $ema=$ema0; # ema0
      #print "ema0=$ema\n";
      $ema=$ema*$a+(1-$a)*($curX);
    }

    printf "$curSym $curDate $curX %.7f\n",$ema;
    $prevSym=$curSym;

}


sub get_std
#one pass  
{          
   my ($refX ) = @_;
   my $count=$#$refX+1;
   if($count<1){return 0;}

   #print "count=$count\n";
   my $xsum=0;             
   my $x2sum=0;            
   foreach my $x (@$refX)  
   {                       
     $xsum+=$x;            
     $x2sum+=($x*$x);      
   }                       
   my $var=0; # count=1    
   if($count >1)
   {
     $var=($x2sum-$xsum*$xsum/$count)/($count-1);
   }
   return sqrt($var);
}


__END__



