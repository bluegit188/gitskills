cat $1|head -1 |myTranspose.pl|gawk '{print NR,$1}'

