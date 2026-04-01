import sys
import numpy as np
import pandas as pd
import importlib
import config
importlib.reload(config)
from config import Config


import scdtw
importlib.reload(scdtw)
from scdtw import SCDTW

import asset_session
importlib.reload(asset_session)
from asset_session import AssetSession

#sys.path.append(r"C:\Users\admin\notebooks\junfei_lib\base")
#linux
sys.path.append(r"/home/jgeng/notebooks/junfei_lib/base")
import daily_rth
importlib.reload(daily_rth)
from daily_rth import DailyRTH
import datetime as dt


class TW:
    def __init__(self, cfg: Config, df: pd.DataFrame,AS:AssetSession):
        self.cfg = cfg
        self.df = df #template_df
        self.AS = AS 

    
    def compute_fcst(self, rth:DailyRTH, today_date:int):
        """
        Compute forecast for each yvar based on top Ks nearest reference series.
        """
        df = self.df.copy()
        #df=dateint_to_dateiso(df,'date')
        
        #query for scd
        query_vec=self.get_x_vec_21(rth,today_date)
        #print(f"query= {query_vec}")


        leak_dist=self.cfg.leakDist
        wgts=self.cfg.wgts
        K=self.cfg.Ks
        WFD=self.cfg.WFD
        x_names=self.cfg.colXNames
        y_names=self.cfg.colYNames

        #print(f"x_names={x_names}")
        #print(f"y_names={y_names}")

        WFD=1

        dtw=SCDTW()
    
        # set up dates for valid template sereis
        today_date_iso = pd.to_datetime(str(today_date), format="%Y%m%d")
        cur_dow = today_date_iso.dayofweek+1  # Monday=1, Fri=5
        cur_is_bond = self.AS.is_financial(rth.sym)
         
        
        #today_date_iso=dt.date.strptime(str(today_date),'%Y%m%d')
        #today_date_iso = dt.datetime.strptime(str(today_date), "%Y%m%d").date()
        start_date = dt.date(1970, 1, 1)
        end_date = dt.date(2050, 1, 1)

        #forbidden_start=today_date_iso - dt.timedelta(days=leakDist)
        #forbidden_end=today_date_iso + dt.timedelta(days=leakDist)
        forbidden_start = today_date_iso - pd.Timedelta(days=leak_dist)
        forbidden_end = today_date_iso + pd.Timedelta(days=leak_dist)

        #print(f"start={start_date} end={end_date} forbid_start={forbidden_start} forbid_end={forbidden_end}")
        # filter template data
        if (WFD==1): # walk forward
            window=365*30 # 10-yr window
            start_date=today_date_iso - pd.Timedelta(days=window)
            #start_date = pd.to_datetime("2015-01-01") # post-2015 templates
            #forbidden_start = pd.to_datetime("2015-01-01") #pre-2015 templates
            df = df[ (df["date_iso"] > start_date) & (df["date_iso"] < forbidden_start)]
        else: # for CV method
            df = df[(df["date_iso"] < forbidden_start) | (df["date_iso"] > forbidden_end)]

        if df.empty:
            raise ValueError("No valid reference data after date filtering.")

        # Compute distances
        #ref_df = df[x_names]
        x_data = df[x_names].to_numpy(dtype=np.float64)
        #distances = np.array([dtw.compute_euc_dist(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_euc_dist_wgt(query_vec, x_data[i],a=0.81) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_dtw_dist(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_dtw_dist_wgt(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_scd_dist_wgt(query_vec, x_data[i],a=1.0,band=5) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_scdtw_tslearn(query_vec, x_data[i],band=21) for i in range(len(x_data))])
        distances = np.array([SCDTW.compute_scd_dist_wgt_njit(query_vec, x_data[i],a=0.81,band=5) for i in range(len(x_data))])
        #print("a={a}")
        
        # DOW adjustment
        distances[cur_dow != df["DOW"].values ] *= 1.5

        # Bond/non-bond adjustment
        #ref_is_bond = df["is_bond"].values
        #distances[cur_is_bond != ref_is_bond] *= 1.5

         
        df["distance"] = distances
        
        # top Ks matches
        df_top = df.nsmallest(K, "distance")
        # Debug: write df_top to file as space-separated
        #df_top.to_csv("test_matches.txt.scd", sep=" ", index=False)

        #print(df_top)
        # compute fcsts(mean and std)        
        forecast = {}
        for y in y_names:
            forecast[f"{y}_mean"] = df_top[y].mean()
            forecast[f"{y}_std"] = df_top[y].std()
            
        # Flip forecast means if current symbol is VX
        if rth.sym == "VX":
            for y in y_names:
                forecast[f"{y}_mean"] = -forecast[f"{y}_mean"]
                
        return forecast

    
    def compute_fcst_oogap(self, rth:DailyRTH, today_date:int):
        """
        Compute forecast for each yvar based on top Ks nearest reference series.
        """
        df = self.df.copy()
        #df=dateint_to_dateiso(df,'date')
        
        #query for scd
        query_vec=self.get_x_vec_21_oogap(rth,today_date)
        #print(f"query= {query_vec}")


        leak_dist=self.cfg.leakDist
        wgts=self.cfg.wgts;
        K=self.cfg.Ks
        WFD=self.cfg.WFD
        x_names=self.cfg.colXNames
        y_names=self.cfg.colYNames


        query_vec=query_vec*wgts
        
        #print(f"x_names={x_names}")
        #print(f"y_names={y_names}")

        WFD=1

        dtw=SCDTW()
    
        # set up dates for valid template sereis
        today_date_iso = pd.to_datetime(str(today_date), format="%Y%m%d")
        cur_dow = today_date_iso.dayofweek+1  # Monday=1, Fri=5
        cur_is_bond = self.AS.is_financial(rth.sym)
         
        
        #today_date_iso=dt.date.strptime(str(today_date),'%Y%m%d')
        #today_date_iso = dt.datetime.strptime(str(today_date), "%Y%m%d").date()
        start_date = dt.date(1970, 1, 1)
        end_date = dt.date(2050, 1, 1)

        #forbidden_start=today_date_iso - dt.timedelta(days=leakDist)
        #forbidden_end=today_date_iso + dt.timedelta(days=leakDist)
        forbidden_start = today_date_iso - pd.Timedelta(days=leak_dist)
        forbidden_end = today_date_iso + pd.Timedelta(days=leak_dist)

        #print(f"start={start_date} end={end_date} forbid_start={forbidden_start} forbid_end={forbidden_end}")
        # filter template data
        if (WFD==1): # walk forward
            window=365*30 # 10-yr window
            start_date=today_date_iso - pd.Timedelta(days=window)
            #start_date = pd.to_datetime("2015-01-01") # post-2015 templates
            #forbidden_start = pd.to_datetime("2015-01-01") #pre-2015 templates
            df = df[ (df["date_iso"] > start_date) & (df["date_iso"] < forbidden_start)]
        else: # for CV method
            df = df[(df["date_iso"] < forbidden_start) | (df["date_iso"] > forbidden_end)]

        if df.empty:
            raise ValueError("No valid reference data after date filtering.")

        # Compute distances
        #ref_df = df[x_names]
        x_data = df[x_names].to_numpy(dtype=np.float64)
        #distances = np.array([dtw.compute_euc_dist(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_euc_dist_wgt(query_vec, x_data[i],a=0.81) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_dtw_dist(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_dtw_dist_wgt(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_scd_dist_wgt(query_vec, x_data[i],a=1.0,band=5) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_scdtw_tslearn(query_vec, x_data[i],band=21) for i in range(len(x_data))])
        distances = np.array([SCDTW.compute_scd_dist_wgt_njit(query_vec, x_data[i],a=0.81,band=0) for i in range(len(x_data))])

        
        # DOW adjustment
        distances[cur_dow != df["DOW"].values ] *= 1.5

        # Bond/non-bond adjustment
        #ref_is_bond = df["is_bond"].values
        #distances[cur_is_bond != ref_is_bond] *= 1.5

         
        df["distance"] = distances
        
        # top Ks matches
        df_top = df.nsmallest(K, "distance")
        # Debug: write df_top to file as space-separated
        # df_top.to_csv("test_matches.txt.scd", sep=" ", index=False)

        #print(df_top)
        # compute fcsts(mean and std)        
        forecast = {}
        for y in y_names:
            forecast[f"{y}_mean"] = df_top[y].mean()
            forecast[f"{y}_std"] = df_top[y].std()
            
        # Flip forecast means if current symbol is VX
        if rth.sym == "VX":
            for y in y_names:
                forecast[f"{y}_mean"] = -forecast[f"{y}_mean"]
                
        return forecast

    def compute_fcst_oogapc(self, rth:DailyRTH, today_date:int):
        """
        Compute forecast for each yvar based on top Ks nearest reference series.
        """
        df = self.df.copy()
        #df=dateint_to_dateiso(df,'date')
        
        #query for scd
        query_vec=self.get_x_vec_21_oogapc(rth,today_date)
        #print(f"query= {query_vec}")


        leak_dist=self.cfg.leakDist
        wgts=self.cfg.wgts;
        K=self.cfg.Ks
        WFD=self.cfg.WFD
        x_names=self.cfg.colXNames
        y_names=self.cfg.colYNames


        query_vec=query_vec*wgts
        
        #print(f"x_names={x_names}")
        #print(f"y_names={y_names}")

        WFD=1

        dtw=SCDTW()
    
        # set up dates for valid template sereis
        today_date_iso = pd.to_datetime(str(today_date), format="%Y%m%d")
        cur_dow = today_date_iso.dayofweek+1  # Monday=1, Fri=5
        cur_is_bond = self.AS.is_financial(rth.sym)
        cur_AS =self.AS.get_asset_int(rth.sym)
        cur_SES =self.AS.get_session_int(rth.sym)      
        

        
        #today_date_iso=dt.date.strptime(str(today_date),'%Y%m%d')
        #today_date_iso = dt.datetime.strptime(str(today_date), "%Y%m%d").date()
        start_date = dt.date(1970, 1, 1)
        end_date = dt.date(2050, 1, 1)

        #forbidden_start=today_date_iso - dt.timedelta(days=leakDist)
        #forbidden_end=today_date_iso + dt.timedelta(days=leakDist)
        forbidden_start = today_date_iso - pd.Timedelta(days=leak_dist)
        forbidden_end = today_date_iso + pd.Timedelta(days=leak_dist)

        #print(f"start={start_date} end={end_date} forbid_start={forbidden_start} forbid_end={forbidden_end}")
        # filter template data
        if (WFD==1): # walk forward
            window=365*30 # 10-yr window
            start_date=today_date_iso - pd.Timedelta(days=window)
            #start_date = pd.to_datetime("2015-01-01") # post-2015 templates
            #forbidden_start = pd.to_datetime("2015-01-01") #pre-2015 templates
            df = df[ (df["date_iso"] > start_date) & (df["date_iso"] < forbidden_start)]
        else: # for CV method
            df = df[(df["date_iso"] < forbidden_start) | (df["date_iso"] > forbidden_end)]

        if df.empty:
            raise ValueError("No valid reference data after date filtering.")

        # Compute distances
        #ref_df = df[x_names]
        x_data = df[x_names].to_numpy(dtype=np.float64)
        #distances = np.array([dtw.compute_euc_dist(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_euc_dist_wgt(query_vec, x_data[i],a=0.81) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_dtw_dist(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_dtw_dist_wgt(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_scd_dist_wgt(query_vec, x_data[i],a=1.0,band=5) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_scdtw_tslearn(query_vec, x_data[i],band=21) for i in range(len(x_data))])
        distances = np.array([SCDTW.compute_scd_dist_wgt_njit(query_vec, x_data[i],a=0.81,band=10) for i in range(len(x_data))])

        
        # DOW adjustment
        distances[cur_dow != df["DOW"].values ] *= 1.5

        # Bond/non-bond adjustment
        #ref_is_bond = df["is_bond"].values
        #distances[cur_is_bond != ref_is_bond] *= 1.5

        #asset
        #ref_AS=df["ASSET4_INT"].values
        #distances[cur_AS != ref_AS] *= 1.25
        
        #session
        #ref_SES=df["SESSION_INT"].values
        #distances[cur_SES != ref_SES] *= 1.25
         
        df["distance"] = distances
        
        # top Ks matches
        df_top = df.nsmallest(K, "distance")
        # Debug: write df_top to file as space-separated
        # df_top.to_csv("test_matches.txt.scd", sep=" ", index=False)

        #print(df_top)
        # compute fcsts(mean and std)        
        forecast = {}
        for y in y_names:
            forecast[f"{y}_mean"] = df_top[y].mean()
            forecast[f"{y}_std"] = df_top[y].std()
            
        # Flip forecast means if current symbol is VX
        if rth.sym == "VX":
            for y in y_names:
                forecast[f"{y}_mean"] = -forecast[f"{y}_mean"]
                
        return forecast

    def compute_fcst_oogapc_v2(self, rth:DailyRTH, today_date:int):
        """
        Compute forecast for each yvar based on top Ks nearest reference series.
        """
        df = self.df.copy()
        #df=dateint_to_dateiso(df,'date')
        
        #query for scd
        query_vec=self.get_x_vec_21_oogapc_v2(rth,today_date)
        #print(f"query= {query_vec}")


        leak_dist=self.cfg.leakDist
        wgts=self.cfg.wgts;
        K=self.cfg.Ks
        WFD=self.cfg.WFD
        x_names=self.cfg.colXNames
        y_names=self.cfg.colYNames


        query_vec=query_vec*wgts
        
        #print(f"x_names={x_names}")
        #print(f"y_names={y_names}")

        WFD=1

        dtw=SCDTW()
    
        # set up dates for valid template sereis
        today_date_iso = pd.to_datetime(str(today_date), format="%Y%m%d")
        cur_dow = today_date_iso.dayofweek+1  # Monday=1, Fri=5
        cur_is_bond = self.AS.is_financial(rth.sym)
        cur_AS =self.AS.get_asset_int(rth.sym)
        cur_SES =self.AS.get_session_int(rth.sym)      
        cur_eurIBC =self.AS.isEurIBC(rth.sym)      
           

        
        #today_date_iso=dt.date.strptime(str(today_date),'%Y%m%d')
        #today_date_iso = dt.datetime.strptime(str(today_date), "%Y%m%d").date()
        start_date = dt.date(1970, 1, 1)
        end_date = dt.date(2050, 1, 1)

        #forbidden_start=today_date_iso - dt.timedelta(days=leakDist)
        #forbidden_end=today_date_iso + dt.timedelta(days=leakDist)
        forbidden_start = today_date_iso - pd.Timedelta(days=leak_dist)
        forbidden_end = today_date_iso + pd.Timedelta(days=leak_dist)

        #print(f"start={start_date} end={end_date} forbid_start={forbidden_start} forbid_end={forbidden_end}")
        # filter template data
        if (WFD==1): # walk forward
            window=365*30 # 10-yr window
            start_date=today_date_iso - pd.Timedelta(days=window)
            #start_date = pd.to_datetime("2015-01-01") # post-2015 templates
            #forbidden_start = pd.to_datetime("2015-01-01") #pre-2015 templates
            df = df[ (df["date_iso"] > start_date) & (df["date_iso"] < forbidden_start)]
        else: # for CV method
            df = df[(df["date_iso"] < forbidden_start) | (df["date_iso"] > forbidden_end)]

        if df.empty:
            raise ValueError("No valid reference data after date filtering.")

        # Compute distances
        #ref_df = df[x_names]
        x_data = df[x_names].to_numpy(dtype=np.float64)
        #distances = np.array([dtw.compute_euc_dist(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_euc_dist_wgt(query_vec, x_data[i],a=0.81) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_dtw_dist(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_dtw_dist_wgt(query_vec, x_data[i]) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_scd_dist_wgt(query_vec, x_data[i],a=1.0,band=5) for i in range(len(x_data))])
        #distances = np.array([dtw.compute_scdtw_tslearn(query_vec, x_data[i],band=21) for i in range(len(x_data))])
        distances = np.array([SCDTW.compute_scd_dist_wgt_njit(query_vec, x_data[i],a=0.81,band=0) for i in range(len(x_data))])

        
        # DOW adjustment
        distances[cur_dow != df["DOW"].values ] *= 1.5

        # Bond/non-bond adjustment
        #ref_is_bond = df["is_bond"].values
        #distances[cur_is_bond != ref_is_bond] *= 1.5

        #asset
        ref_AS=df["ASSET4_INT"].values
        distances[cur_AS != ref_AS] *= 2
        
        #session
        ref_SES=df["SESSION_INT"].values
        distances[cur_SES != ref_SES] *= 2

        #isEurIBC
        #ref_eurIBC=df["isEurIBC"].values
        #distances[cur_eurIBC != ref_eurIBC] *= 1.5
        
        df["distance"] = distances
        
        # top Ks matches
        df_top = df.nsmallest(K, "distance")
        # Debug: write df_top to file as space-separated
        #df_top.to_csv("best_matches.txt.scd", sep=" ", index=False)

        #print(df_top)
        # compute fcsts(mean and std)        
        forecast = {}
        for y in y_names:
            forecast[f"{y}_mean"] = df_top[y].mean()
            forecast[f"{y}_std"] = df_top[y].std()
            
        # Flip forecast means if current symbol is VX
        if rth.sym == "VX":
            for y in y_names:
                forecast[f"{y}_mean"] = -forecast[f"{y}_mean"]
                
        return forecast

               
    def get_x_vec_21(self, rth, today_date: int) -> np.ndarray:
        """
        get query vec for scd fcst

        Parameters
        ----------
        rth : DailyRTH
            Object containing self.df with 'date' and 'ooP1D'.
        today_date : pd.Timestamp
            The current date for which to compute the query vector.

        Returns
        -------
        np.ndarray
            Vector of 21 cumulative OO sums scaled by 100.
        """
        #df = rth.df.sort_values("date").reset_index(drop=True)
        df=rth.df
        if today_date not in set(df["date"]):
            raise ValueError(f"Date {today_date} not found in rth.df")

        loc = df.index[df["date"] == today_date][0]
        if loc < 42:
            raise ValueError("Error: less than 42 days OOs to compute knn15 fcst")

        # Take the past 42 ooP1D values (most recent first)
        oo_values = df.loc[loc - 41:loc, "ooP1D"].iloc[::-1].to_numpy()

        # Compute cumulative sums for 21 days
        cum_sums = np.cumsum(oo_values)[:21]

        # Optional sign flip logic (disabled by default)
        is_flip = 0
        # Example:
        if rth.sym in ["VX"]:  #, "JY", "JYA"]:
            is_flip = 1

        C = 1#100.0
        if is_flip:
            x_vec = -cum_sums * C
        else:
            x_vec = cum_sums * C

        return x_vec

    def get_x_vec_21_oogap(self, rth, today_date: int) -> np.ndarray:
        """
        get query vec for scd fcst

        Parameters
        ----------
        rth : DailyRTH
            Object containing self.df with 'date' and 'ooP1D'.
        today_date : pd.Timestamp
            The current date for which to compute the query vector.

        Returns
        -------
        np.ndarray
            Vector of 21 cumulative OO sums scaled by 100.
        """
        #df = rth.df.sort_values("date").reset_index(drop=True)
        df=rth.df
        if today_date not in set(df["date"]):
            raise ValueError(f"Date {today_date} not found in rth.df")

        loc = df.index[df["date"] == today_date][0]
        if loc < 42:
            raise ValueError("Error: less than 42 days OOs to compute knn15 fcst")

        # Take the past 42 ooP1D values (most recent first)
        oo_values = df.loc[loc - 41:loc, "ooP1D"].iloc[::-1].to_numpy()

        # Compute cumulative sums for GAP+OOs of 20 days
        cum_sums = np.cumsum(oo_values)[:20]
        GAP= df.loc[loc, "GAP"]
        x_vec=np.insert(cum_sums,0,GAP)
        
        # Optional sign flip logic (disabled by default)
        is_flip = 0
        # Example:
        if rth.sym in ["VX"]:  #, "JY", "JYA"]:
            is_flip = 1

        C = 1#100.0
        if is_flip:
            x_vec = -x_vec * C
        else:
            x_vec = x_vec * C

        return x_vec

    
    def get_x_vec_21_oogapc(self, rth, today_date: int) -> np.ndarray:
        """
        get query vec for scd fcst

        Parameters
        ----------
        rth : DailyRTH
            Object containing self.df with 'date' and 'ooP1D'.
        today_date : pd.Timestamp
            The current date for which to compute the query vector.

        Returns
        -------
        np.ndarray
            Vector of 21 cumulative OO sums scaled by 100.
        """
        #df = rth.df.sort_values("date").reset_index(drop=True)
        df=rth.df
        if today_date not in set(df["date"]):
            raise ValueError(f"Date {today_date} not found in rth.df")

        loc = df.index[df["date"] == today_date][0]
        if loc < 42:
            raise ValueError("Error: less than 42 days OOs to compute knn15 fcst")

        # Take the past 42 ooP1D values (most recent first)
        oo_values = df.loc[loc - 41:loc, "ooP1D"].iloc[::-1].to_numpy()

        # Compute cumulative sums for GAP+OOs of 20 days
        cum_sums = np.cumsum(oo_values)[:20]
        GAP= df.loc[loc, "GAP"]
        FOC= df.loc[loc, "FOC"]       
        x_vec=np.insert(cum_sums,0,GAP)
        x_vec=np.insert(x_vec,0,FOC)
          
        # Optional sign flip logic (disabled by default)
        is_flip = 0
        # Example:
        if rth.sym in ["VX"]:  #, "JY", "JYA"]:
            is_flip = 1

        C = 1#100.0
        if is_flip:
            x_vec = -x_vec * C
        else:
            x_vec = x_vec * C

        return x_vec

    
    def get_x_vec_21_oogapc_v2(self, rth, today_date: int) -> np.ndarray:
        """
        get query vec for scd fcst

        Parameters
        ----------
        rth : DailyRTH
            Object containing self.df with 'date' and 'ooP1D'.
        today_date : pd.Timestamp
            The current date for which to compute the query vector.

        Returns
        -------
        np.ndarray
            Vector of 21 cumulative OO sums scaled by 100.
        """
        #df = rth.df.sort_values("date").reset_index(drop=True)
        df=rth.df
        if today_date not in set(df["date"]):
            raise ValueError(f"Date {today_date} not found in rth.df")

        loc = df.index[df["date"] == today_date][0]
        if loc < 42:
            raise ValueError("Error: less than 42 days OOs to compute knn15 fcst")

        # Take the past 42 ooP1D values (most recent first)
        oo_values = df.loc[loc - 41:loc, "ooP1D"].iloc[::-1].to_numpy()

        # Compute cumulative sums for GAP+OOs of 20 days
        cum_sums = np.cumsum(oo_values)[:20]
        GAP= df.loc[loc, "GAP"]
        FOM= df.loc[loc, "FOM"]
        FMC= df.loc[loc, "FMC"]      
        x_vec=np.insert(cum_sums,0,GAP)
        x_vec=np.insert(x_vec,0,FOM)
        x_vec=np.insert(x_vec,0,FMC)
          
        # Optional sign flip logic (disabled by default)
        is_flip = 0
        # Example:
        if rth.sym in ["VX"]:  #, "JY", "JYA"]:
            is_flip = 1

        C = 1#100.0
        if is_flip:
            x_vec = -x_vec * C
        else:
            x_vec = x_vec * C

        return x_vec

    
