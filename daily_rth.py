import math
import os
import sys
import importlib
import pandas as pd
import polars as pl
import numpy as np

class DailyRTH:
    #def __init__(self, sym: str,base_path: str = r"C:\Users\admin\notebooks\portara_1min_to_daily_rth\CCFixRTH"):
    def __init__(self, sym: str,base_path: str = r"/home/jgeng/notebooks/portara_1min_to_daily_rth/CCFixRTH"):
        self.sym = sym
        self.base_path = base_path
        self.df = self.read_rth_file(sym)
        self.size =len(self.df)

        #compute fvoo
        self.compute_fvoo()
        
    def __len__(self):
        return self.size

    def __getitem__(self, loc: int):
        """
        Make DailyRTH behave like a vector<DailyRTHUnit>
        """
        return self.df.iloc[loc]        
       
    def print(self):
        if self.df.empty:
            print("Daily RTH is empty.")
        else:
            print(self.df.to_string(index=False))


    def read_rth_file(self, sym: str)->pd.DataFrame:
        filename = fr"{self.base_path}/{sym}.txt"
        if not os.path.exists(filename):
            raise FileNotFoundError(f"Can't open file: {filename}")

        # Define column names
        colnames = [
            "date", "open", "high", "low", "close",
            "tradeCount", "volume", "oi", "sym",
            "contractYM", "spd", "cumSpd", "ot", "ct"
        ]

        # # polars read_csv is much faster than pandas read_csv
        # dtype_dict={
        # "date": pl.Int32,
        # "open": pl.Float64,
        # "high": pl.Float64,
        # "low": pl.Float64,
        # "close": pl.Float64,
        # "tradeCount": pl.Int32,
        # "volume": pl.Int32,
        # "oi": pl.Int32,
        # "sym": pl.Utf8,
        # "contractYM": pl.Utf8,
        # "spd": pl.Float64,
        # "cumSpd": pl.Float64,
        # "ot": pl.Int32,
        # "ct": pl.Int32
        # }

        try:
            pl_df = pl.read_csv(
                filename,
                has_header=False,
                new_columns=colnames,
                separator=' ',
                #schema_overrides=dtype_dict,
                try_parse_dates=False
            )
            # Convert to pandas
            df = pl_df.to_pandas()
            return df
        except Exception as e:
            print(f"Error reading file {filename}: {e}")
            return pd.DataFrame()
            #sys.exit(1)


    def compute_fvoo(self):   
        #self.df = self.df.copy(deep=True)
        self.df['oo'] = (self.df['open'] - self.df['cumSpd']) - (self.df['open'].shift(1) - self.df['cumSpd'].shift(1))   ## Open-Open change
        self.df['hilo'] = self.df['high'].shift(1) - self.df['low'].shift(1)
        self.df['gap'] = (self.df['open'] - self.df['cumSpd']) - (self.df['close'].shift(1) - self.df['cumSpd'].shift(1))
        self.df['agap'] = abs(self.df['gap'])
        self.df['hilo_adj'] = 1.29 * (0.45*self.df['hilo'] + 0.55*self.df['agap'])  
        ema0 = np.std(self.df['oo'].iloc[1:],ddof=1)        # open-open std

        #a = 0.975
        a = 0.915
        
        # # np array is faster
        # data = np.array(self.df['hilo_adj'])
        # ema = np.empty(len(data))
        # ema[0] = ema0  # custom initial value
        # for i in range(1, len(data)):
        #     ema[i] = a * ema[i-1] + (1 - a) * data[i]       
        # self.df['fvoo'] = ema

        # np array is faster
        data = np.array(self.df['hilo_adj'])
        emas = np.empty(len(data))
        emas[0] =np.nan
        ema=ema0
        for i in range(1, len(data)):
            ema = a * ema + (1 - a) * data[i]                
            emas[i] = ema       
        self.df['fvoo'] = emas

        self.df.dropna(subset=['fvoo'], inplace=True)                       
        self.df.reset_index(drop=True,inplace=True)
    
    def get_df(self):
        return self.df

    def compute_yvars(self):
        self.df['ooF1D'] = (self.df['oo'].shift(-1)/self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['FOC'] = (( (self.df['close'] - self.df['cumSpd']) - (self.df['open'] - self.df['cumSpd']) ) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['FGAP'] = (( (self.df['open'].shift(-1) - self.df['cumSpd'].shift(-1)) - (self.df['close'] - self.df['cumSpd']) ) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['ooFD2'] = (( (self.df['open'].shift(-2) - self.df['cumSpd'].shift(-2)) - (self.df['open'].shift(-1) - self.df['cumSpd'].shift(-1) )) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['ooF2D'] = (( (self.df['open'].shift(-2) - self.df['cumSpd'].shift(-2)) - (self.df['open'] - self.df['cumSpd'] )) /self.df['fvoo']).clip(lower=-9, upper=9) 
        self.df['ooF3D'] = (( (self.df['open'].shift(-3) - self.df['cumSpd'].shift(-3)) - (self.df['open'] - self.df['cumSpd'])) /self.df['fvoo']).clip(lower=-12, upper=12) 

    def compute_yvars_long(self):
        self.df['ooF5D'] = (( (self.df['open'].shift(-5) - self.df['cumSpd'].shift(-5)) - (self.df['open'] - self.df['cumSpd'])) /self.df['fvoo']).clip(lower=-15, upper=15) 
        self.df['ooF10D'] = (( (self.df['open'].shift(-10) - self.df['cumSpd'].shift(-10)) - (self.df['open'] - self.df['cumSpd'])) /self.df['fvoo']).clip(lower=-20, upper=20) 
        self.df['ooF15D'] = (( (self.df['open'].shift(-15) - self.df['cumSpd'].shift(-15)) - (self.df['open'] - self.df['cumSpd'])) /self.df['fvoo']).clip(lower=-25, upper=25) 

    def compute_FOC(self):
        self.df['FOC'] = (( (self.df['close'] - self.df['cumSpd']) - (self.df['open'] - self.df['cumSpd']) ) /self.df['fvoo']).clip(lower=-6, upper=6) 


    def compute_yvars_at_close(self):
        self.df['ccF1D'] = (( (self.df['close'].shift(-1) - self.df['cumSpd'].shift(-1)) - (self.df['close'] - self.df['cumSpd'] )) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['FOC2'] = (( (self.df['close'].shift(-1) - self.df['cumSpd'].shift(-1)) - (self.df['open'].shift(-1) - self.df['cumSpd'].shift(-1)) ) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['FGAP2'] = (( (self.df['open'].shift(-2) - self.df['cumSpd'].shift(-2)) - (self.df['close'].shift(-1) - self.df['cumSpd'].shift(-1)) ) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['ccF2D'] = (( (self.df['close'].shift(-2) - self.df['cumSpd'].shift(-2)) - (self.df['close'] - self.df['cumSpd'] )) /self.df['fvoo']).clip(lower=-6, upper=6) 

    def compute_FOM_FMC(self):
        self.df['FOM'] = ( ( ((self.df['high'] - self.df['cumSpd']) + (self.df['low'] - self.df['cumSpd']))/2 - (self.df['open'] - self.df['cumSpd']) ) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['FMC'] = (( (self.df['close'] - self.df['cumSpd']) - ((self.df['high'] - self.df['cumSpd']) + (self.df['low'] - self.df['cumSpd']))/2 ) /self.df['fvoo']).clip(lower=-6, upper=6) 


    def compute_FOH_FOL_FOM_FMC(self):
        self.df['FOH'] = ( ((self.df['high'] - self.df['cumSpd']) - (self.df['open'] - self.df['cumSpd']) ) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['FOL'] = ( ((self.df['low'] - self.df['cumSpd']) - (self.df['open'] - self.df['cumSpd']) ) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['FOM'] = ( ( ((self.df['high'] - self.df['cumSpd']) + (self.df['low'] - self.df['cumSpd']))/2 - (self.df['open'] - self.df['cumSpd']) ) /self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df['FMC'] = (( (self.df['close'] - self.df['cumSpd']) - ((self.df['high'] - self.df['cumSpd']) + (self.df['low'] - self.df['cumSpd']))/2 ) /self.df['fvoo']).clip(lower=-6, upper=6) 
 
    def compute_ooP1D(self):
        self.df['ooP1D'] = (self.df['oo']/self.df['fvoo']).clip(lower=-6, upper=6) 
        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)

   
    def compute_GAP_OC(self):
        self.df['GAP'] = (( (self.df['open'] - self.df['cumSpd']) - (self.df['close'].shift(1) - self.df['cumSpd'].shift(1)) ) /self.df['fvoo']).clip(lower=-6, upper=6)
        self.df['OC'] = (( (self.df['close'].shift(1) - self.df['cumSpd'].shift(1)) - (self.df['open'].shift(1) - self.df['cumSpd'].shift(1)) ) /self.df['fvoo']).clip(lower=-6, upper=6)
        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)

    def compute_GAP_OC_GAP2_OC2(self):
        self.df['GAP'] = (( (self.df['open'] - self.df['cumSpd']) - (self.df['close'].shift(1) - self.df['cumSpd'].shift(1)) ) /self.df['fvoo']).clip(lower=-6, upper=6)
        self.df['OC'] = (( (self.df['close'].shift(1) - self.df['cumSpd'].shift(1)) - (self.df['open'].shift(1) - self.df['cumSpd'].shift(1)) ) /self.df['fvoo']).clip(lower=-6, upper=6)
        self.df['GAP2'] = (( (self.df['open'].shift(1) - self.df['cumSpd'].shift(1)) - (self.df['close'].shift(2) - self.df['cumSpd'].shift(2)) ) /self.df['fvoo']).clip(lower=-6, upper=6)
        self.df['OC2'] = (( (self.df['close'].shift(2) - self.df['cumSpd'].shift(2)) - (self.df['open'].shift(2) - self.df['cumSpd'].shift(2)) ) /self.df['fvoo']).clip(lower=-6, upper=6)
        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)
 
    def compute_OO1_N_GAP2(self):
        self.df['OO1_N_GAP2'] = (self.df['ooP1D']+self.df['GAP2']).clip(lower=-9, upper=9)
        
    def compute_O_H_L_C(self):
        #normalized O/H/L/Cs
        self.df['O'] = (( (self.df['open'].shift(1) - self.df['cumSpd'].shift(1)) - (self.df['close'].shift(2) - self.df['cumSpd'].shift(2)) ) /self.df['fvoo']).clip(lower=-6, upper=6)
        self.df['H'] = (( (self.df['high'].shift(1) - self.df['cumSpd'].shift(1)) - (self.df['close'].shift(2) - self.df['cumSpd'].shift(2)) ) /self.df['fvoo']).clip(lower=-3, upper=7)
        self.df['L'] = (( (self.df['low'].shift(1) - self.df['cumSpd'].shift(1)) - (self.df['close'].shift(2) - self.df['cumSpd'].shift(2)) ) /self.df['fvoo']).clip(lower=-7, upper=3)
        self.df['C'] = (( (self.df['close'].shift(1) - self.df['cumSpd'].shift(1)) - (self.df['close'].shift(2) - self.df['cumSpd'].shift(2)) ) /self.df['fvoo']).clip(lower=-6, upper=6)
        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)
    
    def compute_knngol_O_H_L_C(self):
        #normalized O/H/L/C for 2 days
        self.compute_O_H_L_C()
        self.df['O2'] = self.df['O'].shift(1)
        self.df['H2'] = self.df['H'].shift(1)
        self.df['L2'] = self.df['L'].shift(1)
        self.df['C2'] = self.df['C'].shift(1)
        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)

        # knn using levels
        #wrt today open
        self.df['LC1']=-self.df['GAP'];
        self.df['LO1']=self.df['O']-self.df['C']-self.df['GAP'];
        self.df['LH1']=self.df['H']-self.df['C']-self.df['GAP'];
        self.df['LL1']=self.df['L']-self.df['C']-self.df['GAP'];

        #correct
        self.df['LC2']=-self.df['O']+self.df['LO1']; # GAP2=O1
        self.df['LO2']=self.df['O2']-self.df['C2']+self.df['LC2'];
        self.df['LH2']=self.df['H2']-self.df['C2']+self.df['LC2'];
        self.df['LL2']=self.df['L2']-self.df['C2']+self.df['LC2'];

    def compute_knngol_O_H_L_C_at_close(self):
        #normalized O/H/L/C for 2 days
        self.compute_O_H_L_C()
        self.df['O2'] = self.df['O'].shift(1)
        self.df['H2'] = self.df['H'].shift(1)
        self.df['L2'] = self.df['L'].shift(1)
        self.df['C2'] = self.df['C'].shift(1)
        self.compute_FOH_FOL_FOM_FMC()
        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)

        # knn using levels
        #wrt today open
        self.df['LC1']=-self.df['GAP'];
        self.df['LO1']=self.df['O']-self.df['C']-self.df['GAP'];
        self.df['LH1']=self.df['H']-self.df['C']-self.df['GAP'];
        self.df['LL1']=self.df['L']-self.df['C']-self.df['GAP'];

        #correct
        self.df['LC2']=-self.df['O']+self.df['LO1']; # GAP2=O1
        self.df['LO2']=self.df['O2']-self.df['C2']+self.df['LC2'];
        self.df['LH2']=self.df['H2']-self.df['C2']+self.df['LC2'];
        self.df['LL2']=self.df['L2']-self.df['C2']+self.df['LC2'];


    def compute_AEMAOO2(self):
        """
        Compute AEMAOO — an exponentially weighted average of the last 21
        ooP1D values, excluding the most recent two days (i.e. start from lag 2).
        Uses decay factor a=0.75 and clips the absolute EMA to [0, 1.5].
        """
        if "ooP1D" not in self.df.columns:
            raise ValueError("ooP1D must be computed before calling compute_AEMAOO().")

        a = 0.75
        n_lags = 21
        EMAOO = np.full(len(self.df), np.nan)

        ooP1D = self.df["ooP1D"].to_numpy()

        for loc in range(len(ooP1D)):
            if loc < 42:
                continue  # not enough history

            # get last 42 values (most recent first)
            OOs = ooP1D[loc-41:loc+1][::-1]

            # compute weighted EMA over lags 2..20 (inclusive)
            ema_sum = 0.0
            for i in range(2, n_lags):
                ema_sum += OOs[i] * (a ** (i - 2.0))

            ema_sum *= (1 - a)
            EMAOO[loc] = np.clip(ema_sum,-1.5, 1.5)

        self.df["EMAOO"] = EMAOO
        self.df["AEMAOO"] = np.abs(EMAOO)
        
        self.df.dropna(inplace=True)
        self.df.reset_index(drop=True, inplace=True)
 
    def compute_oo_sum(self, t1: int, t2: int):
        """
        Compute the sum of lagged ooP1D values from t1 to t2 (inclusive).
        For example:
            t1=1, t2=2 → ooP1D(t) + ooP1D(t-1)
            t1=1, t2=3 → ooP1D(t) + ooP1D(t-1) + ooP1D(t-2)
            t1=2, t2=2 → ooP1D(t-1)    
        Adds a new column:
            - 'OO_t1' if t1 == t2
            - 'OO_t1t2' otherwise
        """
        if 'ooP1D' not in self.df.columns:
            raise ValueError("Column 'ooP1D' not found in DataFrame.")
   
        if t1 < 1 or t2 < t1:
            raise ValueError("Require t1 >= 1 and t2 >= t1.")
    
        col_name = f"OO_{t1}" if t1 == t2 else f"OO_{t1}t{t2}"

        # #alternative method, slower
        # n = len(self.df)
        # result = np.zeros(n)
        # for lag in range(t1, t2 + 1):
        #     #result += self.df['ooP1D'].shift(lag - 1).fillna(0).to_numpy()
        #     result += self.df['ooP1D'].shift(lag - 1).to_numpy()   
        # self.df[col_name] = result

        if t1 == 1:
            # Sum from current to t2-1 lags
            self.df[col_name] = self.df['ooP1D'].rolling(window=t2).sum()
        else:
            # rolling(t2) - rolling(t1-1) gives sum from t1 to t2
            roll_t2 = self.df['ooP1D'].rolling(window=t2).sum()
            roll_t1_minus1 = self.df['ooP1D'].rolling(window=t1-1).sum()
            self.df[col_name] = roll_t2 - roll_t1_minus1
            
    def compute_oo_sums(self, n: int):
        """
        Compute multiple lagged sums of ooP1D.
        For example, if n=5:
            - OO_1
            - OO_1t2
            - OO_1t3
            - OO_1t4
            - OO_1t5
        """
        if n < 1:
            raise ValueError("n must be at least 1")
    
        for t2 in range(1, n + 1):
            self.compute_oo_sum(t1=1, t2=t2)

    def find_loc_of_date(self, date: int) -> int:
        """
        Given a date (int), find its row index in self.df['date'].
        Returns row index if found, -1 otherwise
        """

        if self.df is None or self.df.empty:
            return -1  # no data
        self.size = len(self.df)

        df=self.df
        first_date = int(df.loc[0, "date"])
        last_date = int(df.loc[self.size - 1, "date"])

        # check bounds
        if date < first_date or date > last_date:
            return -1

        matches = df.index[df["date"] == date]
        if len(matches) == 0:
            return -1
        else:
            return int(matches[0])
        
    
    @staticmethod
    def test():
        """check daily_rth read and price."""
        try:
            rth = DailyRTH("ES")
            #print(rth.df.head())
            print(f"Loaded symbol: {rth.sym}, rows: {rth.size}")
            rth.print()
        except FileNotFoundError as e:
            print(f"Test failed: {e}")
        except Exception as e:
            print(f"Unexpected error during test: {e}")
            

if __name__ == "__main__":
    DailyRTH.test()
