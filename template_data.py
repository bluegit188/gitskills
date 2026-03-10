import re
import sys
import importlib
import polars as pl
import pandas as pd


sys.path.append(r"C:\Users\admin\notebooks\junfei_lib\base")
import daily_rth
importlib.reload(daily_rth)
from daily_rth import DailyRTH


def load_universe_scd_v1(file_path: str = r"C:\Users\admin\notebooks\template_data\list_scd_v1") -> tuple:
    """
    scd_v1 univ    
    Returns:
    - tuple: Tuple of symbols read from the file. Empty tuple if file not found.
    """
    univ = ()
    try:
        with open(file_path, "r") as f:
            univ = tuple(line.strip() for line in f if line.strip())
    except FileNotFoundError:
        print(f"File not found: {file_path}")
    return univ

class TemplateData:
    def __init__(self, sym_univ:tuple):
        self.sym_univ=sym_univ
        self.df=pd.DataFrame()
        self.my_size=0

    def size(self) -> int:
        return self.my_size

    def print(self):
        if self.df.empty:
            print("Template DataFrame is empty.")
        else:
            print(self.df.to_string(index=False))
      
    def compute_template_data_scd(self):
        dfs = []
        for cur_sym in self.sym_univ:
            rth = DailyRTH(cur_sym)
            # some processing
            rth.compute_yvars()
            rth.compute_ooP1D()
            rth.compute_oo_sums(21)
            dfs.append(rth.get_df())
        if dfs:
            self.df = pd.concat(dfs, ignore_index=True)
        else:
            self.df = pd.DataFrame()  # empty if no symbols

        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)

    def compute_template_data_oogap(self):
        dfs = []
        for cur_sym in self.sym_univ:
            rth = DailyRTH(cur_sym)
            # some processing
            rth.compute_yvars()
            rth.compute_ooP1D()
            rth.compute_oo_sums(21)
            rth.compute_GAP_OC_GAP2_OC2()
            dfs.append(rth.get_df())
        if dfs:
            self.df = pd.concat(dfs, ignore_index=True)
        else:
            self.df = pd.DataFrame()  # empty if no symbols

        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)
        
    def get_df(self):
        return self.df.copy()

    def get_df_for_scd(self):
        # list of desired columns
        cols = [
            'date', 'sym', 'ooF1D', 'FOC', 'FGAP', 'ooFD2', 'ooF2D',
            'ooF3D', 'OO_1', 'OO_1t2', 'OO_1t3', 'OO_1t4', 'OO_1t5',
            'OO_1t6', 'OO_1t7', 'OO_1t8', 'OO_1t9', 'OO_1t10', 'OO_1t11', 'OO_1t12',
            'OO_1t13', 'OO_1t14', 'OO_1t15', 'OO_1t16', 'OO_1t17', 'OO_1t18',
            'OO_1t19', 'OO_1t20', 'OO_1t21'
        ]
        return self.df[cols].copy()


    def get_df_for_oogap(self):
        # list of desired columns
        cols = [
            'date', 'sym', 'ooF1D', 'FOC', 'FGAP', 'ooFD2', 'ooF2D',
            'ooF3D', 'OO_1', 'OO_1t2', 'OO_1t3', 'OO_1t4', 'OO_1t5',
            'OO_1t6', 'OO_1t7', 'OO_1t8', 'OO_1t9', 'OO_1t10', 'OO_1t11', 'OO_1t12',
            'OO_1t13', 'OO_1t14', 'OO_1t15', 'OO_1t16', 'OO_1t17', 'OO_1t18',
            'OO_1t19', 'OO_1t20', 'OO_1t21','GAP','OC','GAP2','OC2'
        ]
        return self.df[cols].copy()
    

if __name__=="__main__":
    univ_scd_v1 = load_universe_scd_v1()
    #print(univ_scd_v1)

    # for oogap fcst templates
    td = TemplateData(univ_scd_v1)
    td.compute_template_data_oogap()
    df=td.get_df_for_oogap()
    pl.from_pandas(df).write_csv(f"template_data_scd_20251031.txt.fastfvoo", separator=" ",float_precision=7)
    #pl.from_pandas(df).write_csv(f"template_data_oogap_20251031.txt", separator=" ",float_precision=7)

    # for scd templates
    #td = TemplateData(univ_scd_v1)
    #td.compute_template_data_scd()
    #df=td.get_df_for_scd()
    #pl.from_pandas(df).write_csv(f"template_data_scd_20251009.txt.fastfvoo", separator=" ",float_precision=7)
    #pl.from_pandas(df).write_csv(f"template_data_scd_20251009.txt", separator=" ",float_precision=7)

