#!/usr/bin/perl

use strict;
use POSIX;

($#ARGV+2)==4  || die 
"Usage: myQuantiles.pl isHeader=0/1 colX N=100(or 200)
       Output quantiles at specified probs: 0, 1/N, 2/N, .., N/N\n";

my $isHeader=$ARGV[0];
my $colX=$ARGV[1];
my $N=$ARGV[2];


my @Xs;
my @line;
my $count=0;
while(<STDIN>)
{
    #chomp the new line at the end
    chomp($_);
    @line =split;

    $count++;

    if($isHeader==1 && $count==1)
    {
      next;
    }

    my $x=$line[$colX-1];
    push(@Xs,$x);

}

print "count=",$#Xs+1,"\n";

# sort data first, so extracting quantile faster if we have to do more than once
@Xs=sort {$a <=> $b} @Xs;
foreach my $i(0..$N)
{
   my $p=$i/$N;
   print "$p = ",quantile_sorted(\@Xs,$p),"\n";
}



sub quantile_unsorted
#input: aref=ref to data array, p=[0,1]
#       Note data is not sorted
#output: quantile
# this sub is from Statistics::Descriptive
{
    my ( $aref, $QuantileNumber ) = @_;
    #sort data
    my @data=sort {$a <=> $b} @$aref;
    return quantile_sorted(\@data,  $QuantileNumber);
}



sub quantile_sorted
#input: aref=ref to data array, p=[0,1]
#       Note data is sorted
#output: quantile
# this sub is from Statistics::Descriptive
# If array is sorted already, one can call many times to extract quantile quickly
# if unosorted, need to sort everytime, which is slow.
{
    my ( $aref, $QuantileNumber ) = @_;
    $QuantileNumber*=4; # original code deals with [0,4]
    #unless ( defined $QuantileNumber and $QuantileNumber =~ m/^0|1|2|3|4$/ ) {
    #   carp("Bad quartile type, must be 0, 1, 2, 3 or 4\n");
    #   return;
    #}
 
    #  check data count after the args are checked - should help debugging
    return undef if !($#$aref+1);

    #data is already sorted
    #my @data=@$aref;

    return $$aref[0] if ( $QuantileNumber == 0 );

    my $count = $#$aref+1;

    return $$aref[ $count - 1 ] if ( $QuantileNumber == 4 );

    my $K_quantile = ( ( $QuantileNumber / 4 ) * ( $count - 1 ) + 1 );
    #print "K=",$K_quantile,"\n";
    my $F_quantile = $K_quantile - POSIX::floor($K_quantile);
    $K_quantile = POSIX::floor($K_quantile);

    # interpolation
    my $aK_quantile     = $$aref[ $K_quantile - 1 ];
    return $aK_quantile if ( $F_quantile == 0 );
    my $aKPlus_quantile = $$aref[$K_quantile];

    # Calcul quantile
    my $quantile = $aK_quantile
      + ( $F_quantile * ( $aKPlus_quantile - $aK_quantile ) );
    return $quantile;
}




__END__


0m1.202s

 $stat->quantile($p*4);







> quantile(regdata$ooP1D,probs=0.01)
       1% 
-3.014274 
> quantile(regdata$ooP1D,probs=0.99)
     99% 
2.990058 

 Statistics::Descriptive;

don't use percentiles.

Use its quantile function which has same definition as R


$x = $stat->quantile($Type);

    Sorts the data and returns estimates of underlying distribution quantiles based on one or two order statistics from the supplied elements.

    This method use the same algorithm as Excel and R language (quantile type 7).

    The generic function quantile produces sample quantiles corresponding to the given probabilities.

    $Type is an integer value between 0 to 4 :

      0 => zero quartile (Q0) : minimal value
      1 => first quartile (Q1) : lower quartile = lowest cut off (25%) of data = 25th percentile
      2 => second quartile (Q2) : median = it cuts data set in half = 50th percentile
      3 => third quartile (Q3) : upper quartile = highest cut off (25%) of data, or lowest 75% = 75th percentile
      4 => fourth quartile (Q4) : maximal value

    Exemple :$x = $stat->quantile($Type);

    Sorts the data and returns estimates of underlying distribution quantiles based on one or two order statistics from the supplied elements.

    This method use the same algorithm as Excel and R language (quantile type 7).

    The generic function quantile produces sample quantiles corresponding to the given probabilities.

    $Type is an integer value between 0 to 4 :

      0 => zero quartile (Q0) : minimal value
      1 => first quartile (Q1) : lower quartile = lowest cut off (25%) of data = 25th percentile
      2 => second quartile (Q2) : median = it cuts data set in half = 50th percentile
      3 => third quartile (Q3) : upper quartile = highest cut off (25%) of data, or lowest 75% = 75th percentile
      4 => fourth quartile (Q4) : maximal value

    Exemple :

      my @data = (1..10);
      my $stat = Statistics::Descriptive::Full->new();
      $stat->add_data(@data);
      print $stat->quantile(0); # => 1
      print $stat->quantile(1); # => 3.25
      print $stat->quantile(2); # => 5.5
      print $stat->quantile(3); # => 7.75
      print $stat->quantile(4); # => 10



      my @data = (1..10);
      my $stat = Statistics::Descriptive::Full->new();
      $stat->add_data(@data);
      print $stat->quantile(0); # => 1
      print $stat->quantile(1); # => 3.25
      print $stat->quantile(2); # => 5.5
      print $stat->quantile(3); # => 7.75
      print $stat->quantile(4); # => 10



> quantile(regdata$ooP1D,probs=0:200/200)
        0.0%         0.5%         1.0%         1.5%         2.0%         2.5% 
-10.35349700  -3.43550083  -3.01427395  -2.78046463  -2.60846340  -2.47283075 
        3.0%         3.5%         4.0%         4.5%         5.0%         5.5% 
 -2.36382340  -2.26978350  -2.18708580  -2.11175270  -2.04534200  -1.98405772 
        6.0%         6.5%         7.0%         7.5%         8.0%         8.5% 
 -1.92513450  -1.87358507  -1.82385330  -1.77809625  -1.73431620  -1.69150972 
        9.0%         9.5%        10.0%        10.5%        11.0%        11.5% 
 -1.65052945  -1.61120620  -1.57406250  -1.53821057  -1.50436445  -1.47018225 
       12.0%        12.5%        13.0%        13.5%        14.0%        14.5% 
 -1.43811040  -1.40602200  -1.37521105  -1.34474162  -1.31490650  -1.28757010 
       15.0%        15.5%        16.0%        16.5%        17.0%        17.5% 
 -1.26037125  -1.23430923  -1.20731260  -1.18206755  -1.15678470  -1.13294012 
       18.0%        18.5%        19.0%        19.5%        20.0%        20.5% 
 -1.10826060  -1.08367845  -1.05999790  -1.03562000  -1.01336800  -0.99164600 
       21.0%        21.5%        22.0%        22.5%        23.0%        23.5% 
 -0.96965740  -0.94861618  -0.92746490  -0.90605175  -0.88538240  -0.86539298 
       24.0%        24.5%        25.0%        25.5%        26.0%        26.5% 
 -0.84534900  -0.82578908  -0.80505750  -0.78528077  -0.76531680  -0.74515328 
       27.0%        27.5%        28.0%        28.5%        29.0%        29.5% 
 -0.72640325  -0.70701012  -0.68862300  -0.67067860  -0.65190430  -0.63314578 
       30.0%        30.5%        31.0%        31.5%        32.0%        32.5% 
 -0.61370700  -0.59572280  -0.57723570  -0.55942870  -0.54222400  -0.52458575 
       33.0%        33.5%        34.0%        34.5%        35.0%        35.5% 
 -0.50758325  -0.49067115  -0.47382750  -0.45693828  -0.43941200  -0.42264347 
       36.0%        36.5%        37.0%        37.5%        38.0%        38.5% 
 -0.40562500  -0.38800320  -0.37102760  -0.35460788  -0.33762410  -0.32061248 
       39.0%        39.5%        40.0%        40.5%        41.0%        41.5% 
 -0.30420600  -0.28771283  -0.27249700  -0.25586772  -0.24001170  -0.22420815 
       42.0%        42.5%        43.0%        43.5%        44.0%        44.5% 
 -0.20759240  -0.19072488  -0.17467145  -0.15902053  -0.14365620  -0.12853182 
       45.0%        45.5%        46.0%        46.5%        47.0%        47.5% 
 -0.11222125  -0.09579260  -0.07835270  -0.06026367  -0.03913135   0.00000000 
       48.0%        48.5%        49.0%        49.5%        50.0%        50.5% 
  0.00000000   0.00000000   0.00000000   0.00000000   0.02228250   0.04627287 
       51.0%        51.5%        52.0%        52.5%        53.0%        53.5% 
  0.06611985   0.08351528   0.10043140   0.11706387   0.13375305   0.14978955 
       54.0%        54.5%        55.0%        55.5%        56.0%        56.5% 
  0.16526740   0.18064573   0.19658575   0.21252525   0.22762220   0.24315627 
       57.0%        57.5%        58.0%        58.5%        59.0%        59.5% 
  0.25865980   0.27464412   0.29017090   0.30509905   0.32089025   0.33688845 
       60.0%        60.5%        61.0%        61.5%        62.0%        62.5% 
  0.35290700   0.36980457   0.38594520   0.40182385   0.41797500   0.43442437 
       63.0%        63.5%        64.0%        64.5%        65.0%        65.5% 
  0.45037105   0.46628225   0.48258060   0.49827043   0.51374475   0.53000500 
       66.0%        66.5%        67.0%        67.5%        68.0%        68.5% 
  0.54642780   0.56323273   0.58053240   0.59704913   0.61424740   0.63109303 
       69.0%        69.5%        70.0%        70.5%        71.0%        71.5% 
  0.64777695   0.66586192   0.68299000   0.70092965   0.71870505   0.73631250 
       72.0%        72.5%        73.0%        73.5%        74.0%        74.5% 
  0.75438920   0.77261150   0.79035090   0.80921365   0.82743270   0.84590358 
       75.0%        75.5%        76.0%        76.5%        77.0%        77.5% 
  0.86509125   0.88484762   0.90374020   0.92393930   0.94405270   0.96397563 
       78.0%        78.5%        79.0%        79.5%        80.0%        80.5% 
  0.98456240   1.00531105   1.02578990   1.04721845   1.06866200   1.09101565 
       81.0%        81.5%        82.0%        82.5%        83.0%        83.5% 
  1.11340985   1.13556895   1.15811240   1.18146387   1.20581485   1.23068535 
       84.0%        84.5%        85.0%        85.5%        86.0%        86.5% 
  1.25498980   1.27953032   1.30445100   1.33096022   1.35745680   1.38451623 
       87.0%        87.5%        88.0%        88.5%        89.0%        89.5% 
  1.41246010   1.44068425   1.47037940   1.50088470   1.53242850   1.56546745 
       90.0%        90.5%        91.0%        91.5%        92.0%        92.5% 
  1.60062600   1.63670318   1.67261630   1.71113115   1.75092000   1.79187188 
       93.0%        93.5%        94.0%        94.5%        95.0%        95.5% 
  1.83698505   1.88504743   1.93543500   1.99003212   2.04973150   2.11179567 
       96.0%        96.5%        97.0%        97.5%        98.0%        98.5% 
  2.18548760   2.26410743   2.35761385   2.46096637   2.59156280   2.75775535 
       99.0%        99.5%       100.0% 
  2.99005805   3.37725597  11.15387000 
