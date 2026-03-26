#use double quotes on header str
fgrep -v max|fgrep -v SYM|gawk '{if($5==0){print $0,"0","0"}else{print $0,$4/$5,$4/$5*sqrt(252)}}'|myAddHeader.sh "colName min max mean std count shp shp.pa"|myFormatAuto.pl 1
