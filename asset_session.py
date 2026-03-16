import pandas as pd

class AssetSession:
    # Mapping from ASSET4 string → integer category
    ASSET4_INT_MAP = {
        "Index": 0,
        "Financial": 1,
        "Currency": 2,
        "Physical": 3,
        "SIR": 4,
        "Other": 5,
    }
    
    SESSION_INT_MAP = {
        "Asia": 0,
        "Europe": 1,
        "America": 2,
        "Other": 3,
    }
    
    def __init__(self, filename: str):
        """
        Reads a symbol-to-asset/session mapping file and builds
        a DataFrame with columns: sym, asset, session, ASSET4.
        """     
        self.df = pd.read_csv(
            filename,
            sep=r"\s+",
            names=["sym", "asset", "session"]
        )
        self.df["ASSET4"] = self.df["asset"].apply(self._map_asset4)
        # Add integer representation
        self.df["ASSET4_INT"] = self.df["ASSET4"].map(self.ASSET4_INT_MAP)
        self.df["SESSION_INT"] = self.df["session"].map(self.SESSION_INT_MAP)     
        self.df.set_index("sym", inplace=True)

    @staticmethod
    def _map_asset4(asset: str) -> str:
        """Map detailed asset classes to one of 4 macro groups."""
        if asset in {"Energy", "Grain", "Meat", "Metal", "Soft"}:
            return "Physical"
        elif asset == "Index":
            return "Index"
        elif asset in {"Financial"}:
            return "Financial"
        elif asset in {"SIR"}:
            return "SIR"
        elif asset == "Currency":
            return "Currency"
        else:
            return "Other"

    def get_asset(self, sym: str) -> str:
        return self.df.loc[sym, "ASSET4"]

    def get_asset_int(self, sym: str) -> int:
        """Return integer representation of the ASSET4 category."""
        return int(self.df.loc[sym, "ASSET4_INT"])
    
    def get_session(self, sym: str) -> str:
        return self.df.loc[sym, "session"]

    def get_session_int(self, sym: str) -> int:
        return int(self.df.loc[sym, "SESSION_INT"])

    def is_physical(self, sym: str) -> int:
        return int(self.get_asset(sym) == "Physical")

    def is_currency(self, sym: str) -> int:
        return int(self.get_asset(sym) == "Currency")

    def is_financial(self, sym: str) -> int:
        return int(self.get_asset(sym) == "Financial")

    def is_index(self, sym: str) -> int:
        return int(self.get_asset(sym) == "Index")

    def is_america(self, sym: str) -> int:
        return int(self.get_session(sym) == "America")

    def is_europe(self, sym: str) -> int:
        return int(self.get_session(sym) == "Europe")

    def is_asia(self, sym: str) -> int:
        return int(self.get_session(sym) == "Asia")

    
    def isEurIBC(self, sym: str) -> int:
        return int(self.get_session(sym) == "Europe" and self.get_asset(sym) != "Physical" )

    
    def merge_with(self, df: pd.DataFrame, sym_col: str = "SYM") -> pd.DataFrame:
        """
        Merge asset/session mapping into another DataFrame.
        Example:
        merged_df = AS.merge_with(df)
        print(merged_df)

        Parameters
        ----------
        df : pd.DataFrame
            Target DataFrame containing a symbol column.
        sym_col : str
            Column name in df corresponding to symbol (default: "SYM")

        Returns
        -------
        pd.DataFrame
            Copy of df with added columns: asset, session, ASSET4.
        """
        merged = df.merge(
            self.df.reset_index(),
            left_on=sym_col,
            right_on="sym",
            how="left"
        )

        # If the incoming symbol column had a different name than 'sym', drop the right-side 'sym'
        # Otherwise (sym_col == 'sym') keep it.
        if sym_col != "sym" and "sym" in merged.columns:
            merged = merged.drop(columns=["sym"])
        
        return merged


    def add_column_is_bond(self, df: pd.DataFrame, sym_col: str = "SYM") -> pd.DataFrame:
        """
        Merge bond dummy (1=Financial asset, 0=otherwise) into a DataFrame.
        Example: df_with_bond = asession.add_column_is_bond(df)
        Parameters
        ----------
        df : pd.DataFrame
            DataFrame that has a symbol column.
        sym_col : str, optional
            Name of the symbol column in df (default='SYM').

        Returns
        -------
        pd.DataFrame
            Copy of df with 'is_bond' column added.
        """
        # Prepare mapping from internal asset DataFrame
        map_df = self.df.reset_index()[["sym", "ASSET4"]].copy()
        map_df["is_bond"] = (map_df["ASSET4"] == "Financial").astype(int)

        # Merge with input DataFrame
        merged = df.merge(
            map_df[["sym", "is_bond"]],
            left_on=sym_col,
            right_on="sym",
            how="left"
        )

        # If the incoming symbol column had a different name than 'sym', drop the right-side 'sym'
        # Otherwise (sym_col == 'sym') keep it.
        if sym_col != "sym" and "sym" in merged.columns:
            merged = merged.drop(columns=["sym"])
            
        return merged
    

    def print(self, n=10):
        """Print a preview of the internal mapping table."""
        print(self.df.head(n))
