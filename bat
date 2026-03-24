for thsi dir, the daily RTH is from here:

cat config.txt 
RTH_DIR = /home/jgeng/notebooks/portara_1min_to_daily_rth/CCFixRTH


I just manually changed the portara_get_ooRets.pl's a from 0.975 to 0.915 temporarily for now:

#--create sector returns

1). FxDs
 cp ../list_sym_67 .


more ../list_sym_67 >list_sym_all
more ../list_sym_67 |myAssetSession_four_aseets.pl 0 1|egrep -E -e"Index"|mygetcols.pl 1 >list_sym_index
more ../list_sym_67 |myAssetSession_four_aseets.pl 0 1|egrep -E -e"Financial"|mygetcols.pl 1 >list_sym_bond
more ../list_sym_67 |myAssetSession_four_aseets.pl 0 1|egrep -E -e"Physical"|mygetcols.pl 1 >list_sym_phy
more ../list_sym_67 |myAssetSession_four_aseets.pl 0 1|egrep -E -e"Currency"|mygetcols.pl 1 >list_sym_curr


  #cmd: getF1D/F2D/F3D returns
  portara_get_ooRets_multi.pl list_sym_petro 14 1 >tmp_ooF1Ds
  portara_get_ooRets_multi.pl list_sym_petro 14 2 >tmp_ooF2Ds
  portara_get_ooRets_multi.pl list_sym_petro 14 3 >tmp_ooF3Ds
  combine_match2na_all.pl tmp_ooF1Ds tmp_ooF2Ds tmp_ooF3Ds|mygetcols.pl 2 1 5 9 13 |egrep -v -E -e" NA$" |myShiftDateRowToFirstRow.pl 1 DATE >yvar_FxDs.txt.agri


time  ./auto_batch_FxDs.pl list_asset


2). FOC/FGAP:

   portara_get_FOC_FGAPs_multi.pl list_sym_petro |mygetcols.pl 2 1 3 4 5  >yvar_FOC_FGAPs.txt.agri



time  ./auto_batch_FOCs.pl list_asset


3). F5Ds

more ../list_sym_67 >list_sym_all
more ../list_sym_67 |myAssetSession_four_aseets_cn.pl 0 1|egrep -E -e"Agri"|mygetcols.pl 1 >list_sym_agri
more ../list_sym_67 |myAssetSession_four_aseets_cn.pl 0 1|egrep -E -e"Coalsteel"|mygetcols.pl 1 >list_sym_coalsteel
more ../list_sym_67 |myAssetSession_four_aseets_cn.pl 0 1|egrep -E -e"Nfmetal"|mygetcols.pl 1 >list_sym_nfmetal
more ../list_sym_67 |myAssetSession_four_aseets_cn.pl 0 1|egrep -E -e"Petro"|mygetcols.pl 1 >list_sym_petro


  #cmd: getF1D/F2D/F3D returns
  portara_get_ooRets_multi.pl list_sym_petro 14 1 >tmp_ooF1Ds
  portara_get_ooRets_multi.pl list_sym_petro 14 2 >tmp_ooF2Ds
  portara_get_ooRets_multi.pl list_sym_petro 14 3 >tmp_ooF3Ds
  portara_get_ooRets_multi.pl list_sym_petro 14 4 >tmp_ooF4Ds
  portara_get_ooRets_multi.pl list_sym_petro 14 5 >tmp_ooF5Ds

  combine_match2na_all.pl tmp_ooF1Ds tmp_ooF2Ds tmp_ooF3Ds tmp_ooF4Ds tmp_ooF5Ds|mygetcols.pl 2 1 5 9 13 17 21|egrep -v -E -e" NA$" |myShiftDateRowToFirstRow.pl 1 DATE >yvar_F5Ds.txt.agri


time  ./auto_batch_F5Ds.pl list_asset


--combine
combine_match2.pl yvar_F5Ds.txt.all yvar_FOC_FGAPs.txt.all |myrmcols.pl 8 9 10 > yvar_F5Ds_FOC_FGAPs.txt.all




portara_get_ooRets_multi.pl list_sym_all 0|mygetcols.pl 2 1 3 >ooP1Ds.txt



-----add some yvars at close:

FGAP #already have it
FOC2
FGAP2
ccF1D
ccF2D


4). ccFxDs

  #cmd: ccFxD
  portara_get_ooRets_multi.pl list_sym_index 39 >tmp_FOC2s
  portara_get_ooRets_multi.pl list_sym_index 40 >tmp_FGAP2s
  portara_get_ooRets_multi.pl list_sym_index 41 >tmp_ccF1Ds
  portara_get_ooRets_multi.pl list_sym_index 42 >tmp_ccF2Ds

  combine_match2na_all.pl tmp_FOC2s tmp_FGAP2s tmp_ccF1Ds tmp_ccF2Ds|mygetcols.pl 2 1 5 9 13 17|egrep -v -E -e" NA$" |myShiftDateRowToFirstRow.pl 1 DATE >yvar_ccFxDs.txt.index


time  ./auto_batch_ccFxDs.pl list_asset



--combine
combine_match2.pl yvar_F5Ds_FOC_FGAPs.txt.all yvar_ccFxDs.txt.all |myrmcols.pl 10 11 > yvar_F5Ds_FOC_FGAPs_ccFxDs.txt.all

