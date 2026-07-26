# version 1: 2017/06 computer pnls at specified interval time during the day

# version 2: added some extra variables at given intervals: 
CHGSO
HSO
LSO

#derived:(OC=C-O; OH=H-O,OL=L-O)
CHGSH=C-H=C-H-O+O=OC-(H-O)=OC-OH
CHGSL=C-L=C-L-O+O=OC-(L-O)=OC-OL
OM=M-O=(H+L)/2-O=(H-O+L=O)/2=(OH+OL)/2

(see over here for these variables
/home/jgeng/junfei_lib/OneMinCodes/OneMin20MinInterval
)

time  ./onemin_24hr_ooF1D_ex5_2hr_v2 ES |head -2|myTranspose.pl|myFormatAuto.pl 1

       DATE   19970911
        SYM         ES
       TIME     083000
        ivl          1
  isOpenMin          1
         oT      83000
         cT     151500
       open     925.25
      close     918.25
  lastPrice     925.25
     cumAdj       9.75
       FVOO    14.7533
   nextOpen      925.5
        GAP  0.0169453
        YOC   -1.01672
      ooP1D  -0.999773
        YHC   -1.22006
        YLC    0.54225
        YMC  -0.338906
        YHL    1.76231
       PL2C  -0.474469
      PL2NO  0.0169453
      PL2NC    0.57614
       PLCO   0.491414
   PL2NOEx1   0.101672
   PL2NOEx2  0.0847265
   PL2NOEx5   0.101672
  PL2NOEx10   0.135562
  PL2NOEx15   0.118617
  PL2NOEx30  0.0508359
  PL2NOEx45   0.203344
  PL2NOEx60  0.0677812
  PL2NOEx90   0.152508
 PL2NOEx120   0.440578
        F1M -0.0847265
        F2M -0.0677812
        F5M -0.0847265
       F10M  -0.118617
       F15M  -0.101672
       F30M -0.0338906
       F45M  -0.186398
       F60M -0.0508359
       F90M  -0.135562
      F120M  -0.423633


-- compare to daily data, ES only: as of 2017/11

time  ./onemin_24hr_ooF1D_ex5_2hr_v2  ES  >raw_ES.txt

# FxM vs CHGSOxM
time  ./onemin_24hr_ooF1D_ex5_2hr_v2  ES  >raw_ES.txt
cat raw_ES.txt |mygetcols.pl 35:44 45:54 >aaa
get_corr_matrix_R.pl aaa 0 >b
more tmp_correlation.txt |myFormatAuto.pl 1

==> F120M and CHGSO120M are 99.9% correlated

# for GBL
time  ./onemin_24hr_ooF1D_ex5_2hr_v2  GBL |egrep -v -E -e"NA" >raw_GBL.txt
cat raw_GBL.txt |mygetcols.pl 35:44 45:54 >aaa
get_corr_matrix_R.pl aaa 0 >b
more tmp_correlation.txt |myFormatAuto.pl 1

==> good corr

# FxM vs HSOxM
cat raw_ES.txt |mygetcols.pl 35:44 55:64 >aaa
get_corr_matrix_R.pl aaa 0 >b
more tmp_correlation.txt |myFormatAuto.pl 1

==> F120M and HSO120M corr is 75%.

#FxM vs LSOxM
cat raw_ES.txt |mygetcols.pl 35:44 65:74>aaa
get_corr_matrix_R.pl aaa 0 >b
more tmp_correlation.txt |myFormatAuto.pl 1

==>  F120M and HSO120M corr is 78%.

#THC/TLC/TOC matches yesterday's values

 cat raw_ES.txt |mygetcols.pl 1 2 75:77 17 18 15|more
DATE SYM THC TLC TOC YHC YLC YOC
19970911 ES -0.508359 0.54225 -0.474469 -1.22006 0.54225 -1.01672
19970912 ES -0.186592 1.1874 0.559775 -0.508887 0.542812 -0.474961
19970915 ES -0.562452 0.17044 -0.17044 -0.187484 1.19308 0.562452
19970916 ES -0.274573 1.28706 1.25274 -0.566306 0.171608 -0.171608
19970917 ES -0.342141 0.307927 -0.307927 -0.273713 1.28303 1.24881
19970918 ES -0.884891 0.138806 0.0347016 -0.347016 0.312314 -0.312314


# for HG
time  ./onemin_24hr_ooF1D_ex5_2hr_v2  HG |egrep -v -E -e"NA" >raw_HG.txt
cat raw_HG.txt |mygetcols.pl 35:44 45:54 >aaa
get_corr_matrix_R.pl aaa 0 >b
more tmp_correlation.txt |myFormatAuto.pl 1

/home/jgeng/junfei_lib/OneMinCodes/OneMinOOF1Dx5Min2Hr/Ver2_201711


 more raw_HG.txt |mygetcols.pl 1:9|myFormatAuto.pl 1|egrep -E -e"DATE|2007"|more
     DATE SYM   TIME ivl isOpenMin    oT     cT   open  close
 20070102  HG 030000   1         1 30000 130000 285.95  278.1 # correct from 3AM
 20070103  HG 030000   1         1 30000 130000    276  264.9
 20070104  HG 030000   1         1 30000 130000  259.3  260.2
 20070105  HG 030000   1         1 30000 130000  261.5  253.5
 20070108  HG 030000   1         1 30000 130000  248.1  252.8
 20070109  HG 030000   1         1 30000 130000 254.85  255.6
 20070110  HG 030000   1         1 30000 130000  259.7  266.4
 20070111  HG 030000   1         1 30000 130000  268.3  265.9
 20070112  HG 030000   1         1 30000 130000  263.9  260.3
 20070115  HG 030000   1         1 30000 130000  260.5  256.5

 more raw_HG.txt |mygetcols.pl 1:9|myFormatAuto.pl 1|egrep -E -e"DATE|2007"|more
     DATE SYM   TIME ivl isOpenMin    oT     cT   open  close
 20070102  HG 030000   1         1 30000 130000 281.05  278.1 # wrong one from 8:10AM
 20070103  HG 030000   1         1 30000 130000 269.85  264.9
 20070104  HG 030000   1         1 30000 130000  258.5  260.2
 20070105  HG 030000   1         1 30000 130000  260.5  253.5
 20070108  HG 030000   1         1 30000 130000  254.1  252.8
 20070109  HG 030000   1         1 30000 130000  252.5  255.6


==> good corr




-- compare to daily data, ES only: as of 2017/06

time  ./onemin_24hr_ooF1D_ex5 ES  >raw_ES.txt

portara_get_ooRets.pl ES 1|mygetcols.pl 2 3 4 >ooF1D.txt.ES
 combine_match1.pl ooF1D.txt.ES raw_ES.txt |myrmcols.pl  4 5 >compare.txt.ES

A few discrepancy:

a). DATE ooF1D PL2NO PL2NOEx1 PL2NOEx2 0
20010911 -4.112831 -3.17031 -3.17031 -3.17031 -0.942521

==> I think my version is correct vs daily RTH. We can see that I use close of 0829 as the price for open which is more accuarate than using 0915 open.
20010911 0829 1080 1087.75 1080 1087.75 0 0 2477 ES 2001Z 0 236.75
20010911 0915 1101.5 1101.5 1101.5 1101.5 0 0 2477 ES 2001Z 0 236.75
20010917 0816 1041.5 1041.5 1041.5 1041.5 0 10564 6907 ES 2001Z 0 236.75


b).
20020911 -1.204677 -1.06621 -1.06621 -1.06621 -0.138467

Same issue here, when there's no price at open, the RTH used the price after open, while I used the price before open.


19990531 -0.088346 -0.0294488 -0.0294488 -0.0294488 -0.0588972
20011122 -0.252756 -0.205364 -0.205364 -0.205364 -0.047392
19980216 0.797005 0.819144 0.819144 0.819144 -0.022139
20000529 0.369339 0.391064 0.391064 0.391064 -0.021725
20020218 -0.531045 -0.51062 -0.531045 -0.531045 -0.020425
20010903 0.475565 0.493178 0.493178 0.475565 -0.017613
19991125 0.000000 0.0154274 0.0154274 0.0154274 -0.0154274
20000117 -0.798073 -0.783015 -0.783015 -0.783015 -0.015058
19981203 -0.269716 -0.254732 -0.254732 -0.254732 -0.014984
19980731 -2.252595 -2.25259 -2.18293 -2.09004 -5e-06

..
20170228 1.547455 1.54745 1.45643 1.47918 5e-06
20010115 -0.059876 -0.0718512 -0.0718512 -0.059876 0.0119752
20001123 0.507688 0.494671 0.494671 0.494671 0.013017
20020902 -0.417624 -0.431096 -0.431096 -0.417624 0.013472
20010528 -0.095221 -0.108824 -0.108824 -0.108824 0.013603
20021128 0.190045 0.175427 0.175427 0.175427 0.014618
20010704 -0.458950 -0.474776 -0.45895 -0.45895 0.015826
20010219 0.171404 0.142837 0.142837 0.171404 0.028567
19990215 0.457225 0.412977 0.412977 0.412977 0.044248
19980608 -0.118719 -0.213695 -0.213695 -0.213695 0.094976





2).  for multiple symbols:

onemin_24hr_ooF1D_ex5_multi.pl
 

-- check GBL

 ./onemin_24hr_ooF1D_ex5_2hr GBL |egrep -E -e"DATE|20170504 GBL"|myTranspose.pl|myFormatAuto.pl 1

      DATE     20170504
        SYM          GBL
       TIME       080000
        ivl            1
  isOpenMin            1
         oT        80000
         cT       171500
       open       161.53
      close        160.9
  lastPrice            0
     cumAdj       -58.43
       FVOO     0.505001
   nextOpen          161
        GAP    -0.316831
        YOC    -0.158415
      ooP1D    -0.475246
        YHC    -0.495048
        YLC    0.0990096
        YMC    -0.198019
        YHL     0.594058
       PL2C 1.79769e+308
      PL2NO 1.79769e+308
      PL2NC 1.79769e+308
       PLCO     0.198019
   PL2NOEx1      -1.0495
   PL2NOEx2     -0.93069
   PL2NOEx5    -0.970294
  PL2NOEx10    -0.831681
  PL2NOEx15    -0.831681
  PL2NOEx30    -0.811879
  PL2NOEx45    -0.871285
  PL2NOEx60    -0.792077
  PL2NOEx90    -0.495048
 PL2NOEx120    -0.475246
        F1M           NA
        F2M           NA
        F5M           NA
       F10M           NA
       F15M           NA
       F30M           NA
       F45M           NA
       F60M           NA
       F90M           NA
      F120M           NA

==> note that GBL open at 8 local time, but on most days, it actually opens at 8:01.
(portara data of 0802 means 8:01 minute)

I changed this file to 801 open for GBL
/home/jgeng/transfer/final_sessionTimes.txt

20170504 0802 161.53 161.53 161.47 161.47 2323 791024 1758817 GBL 2017M 0 -58.43
20170504 0803 161.47 161.48 161.46 161.47 413 791024 1758817 GBL 2017M 0 -58.43
20170504 0804 161.48 161.49 161.47 161.49 378 791024 1758817 GBL 2017M 0 -58.43
20170504 0805 161.5 161.5 161.48 161.48 108 791024 1758817 GBL 2017M 0 -58.43
20170504 0806 161.49 161.49 161.48 161.49 115 791024 1758817 GBL 2017M 0 -58.43
20170504 0807 161.48 161.49 161.41 161.41 1290 791024 1758817 GBL 2017M 0 -58.43
20170504 0808 161.41 161.42 161.4 161.4 501 791024 1758817 GBL 2017M 0 -58.43
20170504 0809 161.4 161.42 161.39 161.42 793 791024 1758817 GBL 2017M 0 -58.43
20170504 0810 161.43 161.44 161.42 161.42 514 791024 1758817 GBL 2017M 0 -58.43
20170504 0811 161.42 161.42 161.39 161.4 881 791024 1758817 GBL 2017M 0 -58.43
