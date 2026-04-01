import polars as pl
import pandas as pd
import sys



import importlib
import config
importlib.reload(config)
from config import Config

import asset_session
importlib.reload(asset_session)
from asset_session import AssetSession


#sys.path.append(r"C:\Users\admin\notebooks\junfei_lib\base")
#linux
sys.path.append(r"/home/jgeng/notebooks/junfei_lib/base")
import daily_rth
importlib.reload(daily_rth)
from daily_rth import DailyRTH

import tw
importlib.reload(tw)
from tw import TW


AS = AssetSession("final_sym_asset_session.txt")
#AS.print()

def dateint_to_dateiso(df: pd.DataFrame, date_col: str, new_col: str = "date_iso") -> pd.DataFrame:
    """
    Convert an integer date column (e.g., 20250108) in a Pandas DataFrame
    into a datetime column (ISO format), and store it in `new_col`.


    Returns:
    - pd.DataFrame: The same DataFrame with an added datetime column.
    """
    if date_col not in df.columns:
        raise ValueError(f"Column '{date_col}' not found in DataFrame.")

    df[new_col] = pd.to_datetime(df[date_col].astype(str), format="%Y%m%d", errors="coerce")
    return df

def load_cfile_and_DF_scd(): #(ssetSession as)
    #load config file
    #config_file=rf"C:\Users\admin\notebooks\scdtw_fcsts\config_scdtw.yaml";
    config_file=rf"/home/jgeng/notebooks/scdtw_fcsts/config_scdtw.yaml";
    cfg=Config(config_file)

    #load template datafile
    data_file = cfg.dfile
    #print(data_file)
    pl_df = pl.read_csv(data_file, has_header=True,separator=' ',try_parse_dates=False)
    df = pl_df.to_pandas()
    df = df[df["sym"] != "VX"].copy()  #remove VX

    ### for scdFcst, need to add DOW and is_bond
    df=dateint_to_dateiso(df,'date')
    df = AS.merge_with(df,sym_col="sym") # add asset/session
    df["is_bond"] = (df["ASSET4"] == "Financial").astype(int)
    df["DOW"]= df["date_iso"].dt.dayofweek+1

    return cfg,df

def load_cfile_and_DF_oogap():
    #load config file
    config_file=rf"/home/jgeng/notebooks/oogap_fcsts/config_oogap.yaml";
    cfg=Config(config_file)

    #load template datafile
    data_file = cfg.dfile
    #print(data_file)
    pl_df = pl.read_csv(data_file, has_header=True,separator=' ',try_parse_dates=False)
    df = pl_df.to_pandas()
    df = df[df["sym"] != "VX"].copy()  #remove VX

    ### for scdFcst, need to add DOW and is_bond
    df=dateint_to_dateiso(df,'date')
    df = AS.merge_with(df,sym_col="sym") # add asset/session
    df["is_bond"] = (df["ASSET4"] == "Financial").astype(int)
    df["DOW"]= df["date_iso"].dt.dayofweek+1

    # adjust wgts for xvars in template DB
    x_names=cfg.colXNames
    wgts=cfg.wgts
    df[x_names] = df[x_names].mul(wgts)
    
    return cfg,df

def load_cfile_and_DF_oogapc():
    #load config file
    config_file=rf"/home/jgeng/notebooks/oogapc_fcsts/config_oogapc.yaml";
    cfg=Config(config_file)

    #load template datafile
    data_file = cfg.dfile
    #print(data_file)
    pl_df = pl.read_csv(data_file, has_header=True,separator=' ',try_parse_dates=False)
    df = pl_df.to_pandas()
    df = df[df["sym"] != "VX"].copy()  #remove VX

    ### for scdFcst, need to add DOW and is_bond
    df=dateint_to_dateiso(df,'date')
    df = AS.merge_with(df,sym_col="sym") # add asset/session
    df["is_bond"] = (df["ASSET4"] == "Financial").astype(int)
    df["DOW"]= df["date_iso"].dt.dayofweek+1

    # adjust wgts for xvars in template DB
    x_names=cfg.colXNames
    wgts=cfg.wgts
    df[x_names] = df[x_names].mul(wgts)
    
    return cfg,df

def load_cfile_and_DF_oogapc_v2():
    #load config file
    config_file=rf"/home/jgeng/notebooks/oogapc_v2_fcsts/config_oogapc_v2.yaml";
    cfg=Config(config_file)

    #load template datafile
    data_file = cfg.dfile
    #print(data_file)
    pl_df = pl.read_csv(data_file, has_header=True,separator=' ',try_parse_dates=False)
    df = pl_df.to_pandas()
    df = df[df["sym"] != "VX"].copy()  #remove VX

    ### for scdFcst, need to add DOW and is_bond
    df=dateint_to_dateiso(df,'date')
    df = AS.merge_with(df,sym_col="sym") # add asset/session
    df["is_bond"] = (df["ASSET4"] == "Financial").astype(int)
    df["DOW"]= df["date_iso"].dt.dayofweek+1
    df["isEurIBC"] = ( (df["session"] == "Europe") & (df["ASSET4"] != "Physical") ).astype(int)
    
    # adjust wgts for xvars in template DB
    x_names=cfg.colXNames
    wgts=cfg.wgts
    df[x_names] = df[x_names].mul(wgts)
    
    return cfg,df

def main(sym, start_date, end_date):
    start_date = int(start_date)
    end_date = int(end_date)
    #print(f"Running fcst for {sym} from {start_date} to {end_date}")

    (cfg,df)=load_cfile_and_DF_oogapc_v2()
    #cfg.print()

    # RTH
    rth = DailyRTH(sym)#,base_path="/home/jgeng/notebooks/portara_1min_to_daily_rth/CCFixRTH/")
    rth.compute_ooP1D()
    rth.compute_FOC()
    rth.compute_FOM_FMC()  
    rth.compute_GAP_OC()  

    # Initialize TW model 
    tw_model = TW(cfg, df, AS)  # assumes cfg, df, AS are loaded globally

    # filter dates in range -
    all_dates = rth.df['date'].unique()
    selected_dates = [d for d in all_dates if start_date <= d <= end_date]

    header_printed = False

    # Iterate dates and compute fcst 
    for date in sorted(selected_dates):
        try:
            fcst = tw_model.compute_fcst_oogapc_v2(rth, date)
            if not fcst or not isinstance(fcst, dict):
                continue

            # Use cfg.colYNames order for keys
            # Expect fcst keys like "<yname>_mean" and "<yname>_std"
            mean_keys = [f"{y}_mean" for y in cfg.colYNames]
            std_keys  = [f"{y}_std"  for y in cfg.colYNames]

            # Print header once, in desired order: date, sym, (means...), (stds...)
            if not header_printed:
                header = ["DATE","SYM"] + mean_keys + std_keys
                print(" ".join(header), flush=True)
                header_printed = True

            # Format row values with 7 decimal places
            row_values = [f"{date}", sym]
            for k in mean_keys + std_keys:
                val = fcst.get(k, float("nan"))
                # if val is not numeric (None or NaN), format to NaN-like string
                try:
                    row_values.append(f"{float(val):.7f}")
                except Exception:
                    row_values.append("nan")

            print(" ".join(row_values), flush=True)
            
           
        except Exception as e:
            print(f"Error computing fcst for {date}: {e}", flush=True)


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python compute_oogapc_fcsts.py sym start_date end_date")
        print("Example: python run_fcst.py ES 20220901 20220905")
        sys.exit(1)

    sym, start_date, end_date = sys.argv[1:4]
    main(sym, start_date, end_date)

    
