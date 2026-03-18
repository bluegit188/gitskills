r'''
#example usage:
import sys
sys.path.append(r"C:\Users\admin\code")  # Add your directory to the module search path
import importlib
import utils as utils
importlib.reload(utils)
utils.nearest_jf(-4,0.111111)
'''


def nearest_jf(pow10:int, x: float) -> float:
    """
    Emulate Math::Round's nearest function, but elimiate extra zeros from $.4f notation
    Round x to nearest multiple of 10**pow10, 
    and remove unnecessary trailing zeros if pow10 < 0.
    Usage: nearest_jf(-4, 3.56789)=3.5679
    
    Examples:
    nearest_jf(-4, 3.56789) -> 3.568
    nearest_jf(-2, 12.00000) -> 12
    nearest_jf(2, 1234.567) -> 1200
    
    Args:
        x (float): The input number to round (e.g., 3.56789).
        pow10 (int): Power of 10 to round to.
                     - If pow10 = -4, rounds to 4 decimal places (0.0001).
                     - If pow10 = 2, rounds to the nearest 100.

    Returns:
        float: The rounded number with trailing zeros removed (up to the precision implied by pow10).
    """
    a = 10 ** pow10
    # round to nearest multiple of a
    y = int(x / a + (-0.5 if x < 0 else 0.5)) * a

    # remove unnecessary trailing zeros if rounding after decimal
    if pow10 < 0:
        # format with enough decimals and convert to float to strip zeros
        y = float(f"{y:.{-pow10}f}")
    return y

import matplotlib.pyplot as plt
import pandas as pd

def plot_one(df: pd.DataFrame, y_col: str, x_col: str = None,title_str: str = None) -> None:
    """
    Plot a column from a Pandas DataFrame using matplotlib.
    Usage:
        plot_one(df, y_col="Spread", x_col="datetime")
	plot_one(df, y_col="Spread")  # uses index for x-axis
    Parameters:
    - df (pl.DataFrame): Input Polars DataFrame.
    - y_col (str): The column to plot on the y-axis.
    - x_col (str, optional): The column to plot on the x-axis. If None, uses the DataFrame index.
                             If 'datetime', x-axis will use the 'datetime' column in the DataFrame.

    Returns:
    - None: Displays the plot.
    """
    # Check that y_col exists
    if y_col not in df.columns:
        raise ValueError(f"Column '{y_col}' not found in DataFrame.")

    # Determine x values
    x_vals = df[x_col] if x_col and x_col in df.columns else df.index
    y_vals = df[y_col]


    # Plot
    plt.figure(figsize=(8, 6))
    plt.plot(x_vals, y_vals)
    plt.xlabel(x_col if x_col else "Index")
    plt.ylabel(y_col)
    #plt.title(f"{y_col} over {x_col if x_col else 'Index'}")
    plt.title(title_str if title_str else f"{y_col} vs. {x_col if x_col else 'Index'}")
    plt.grid(True)
    plt.tight_layout()
    plt.show()


def plot_two(df: pd.DataFrame, y1_col: str, y2_col: str, x_col: str = None, title_str: str = None) -> None:
    """
    Plot two columns from a Pandas DataFrame using matplotlib.

    Usage:
        plot_two(df, y1_col="Spread", y2_col="Volume", x_col="datetime")
        plot_two(df, y1_col="Spread", y2_col="Volume")  # uses index for x-axis

    Parameters:
    - df (pd.DataFrame): Input Pandas DataFrame.
    - y1_col (str): First y-axis column to plot.
    - y2_col (str): Second y-axis column to plot.
    - x_col (str, optional): The column to plot on the x-axis. If None, uses the DataFrame index.
    - title_str (str, optional): Title of the plot.

    Returns:
    - None: Displays the plot.
    """
    # Validate input columns
    for col in [y1_col, y2_col]:
        if col not in df.columns:
            raise ValueError(f"Column '{col}' not found in DataFrame.")

    # Determine x values
    x_vals = df[x_col] if x_col and x_col in df.columns else df.index
    y1_vals = df[y1_col]
    y2_vals = df[y2_col]

    # Plot
    plt.figure(figsize=(8, 6))
    plt.plot(x_vals, y1_vals, label=y1_col)
    plt.plot(x_vals, y2_vals, label=y2_col)
    plt.xlabel(x_col if x_col else "Index")
    plt.ylabel("Values")
    plt.title(title_str if title_str else f"{y1_col} and {y2_col} vs. {x_col if x_col else 'Index'}")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()


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



def plot_rolling_corr(
    df: pd.DataFrame,
    y1_col: str,
    y2_col: str,
    x_col: str = None,
    window: int = 252,
    title_str: str = None
) -> None:
    """
    Compute and plot rolling correlation between two columns of a DataFrame.

    Parameters:
    - df: pd.DataFrame
    - y1_col: str, first column for correlation
    - y2_col: str, second column for correlation
    - x_col: str, optional column for x-axis. Defaults to DataFrame index if not provided.
    - title_str: str, optional title for the plot
    - window: int, rolling window size (default 252)

    Returns:
    - pd.Series: the rolling correlation series
    """

    df = df.copy()

    # compute rolling correlation
    rolling_corr = df[y1_col].rolling(window=window,min_periods=window).corr(df[y2_col])

    corr=df[y1_col].corr(df[y2_col])

    # Determine x-axis values
    x_vals = df[x_col] if x_col and x_col in df.columns else df.index

    # Plot
    plt.figure(figsize=(10, 5))
    plt.plot(x_vals, rolling_corr, label=f'{window}-day rolling corr ({y1_col} vs {y2_col})')
    plt.axhline(0, color='gray', linestyle='--', linewidth=1)
    plt.title(title_str if title_str else f'{window}-Day Rolling Correlation: {y1_col} vs {y2_col}, corr={corr:.6f}')
    plt.xlabel(x_col if x_col else "Index")
    plt.ylabel('Correlation')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

def coplot(df: pd.DataFrame, y_col: str, x_col: str, cond_col: str, 
           num_bins: int = 4, col_wrap: int = 2, figsize=(4,4), 
           line_kwargs=None, ymin: float = -0.15, ymax: float = 0.15,plot_scatter=False):
    """
    Conditional plot similar to R's coplot(y ~ x | z), showing only the fit line and correlation.
    coplot(df, y_col="FGAP", x_col="FOC", cond_col="roll_corr", num_bins=4, col_wrap=2,figsize=(4,3))
    
    Parameters:
    - df: pd.DataFrame
    - y_col: str, column for y-axis
    - x_col: str, column for x-axis
    - cond_col: str, conditioning variable (z)
    - num_bins: int, number of bins for conditioning variable
    - col_wrap: int, number of panels per row
    - figsize: tuple, size of each subplot
    - line_kwargs: dict, keyword arguments for regression line
    - ymin, ymax: float, limits for y-axis

    Returns:
    - None, displays the plot
    """
    line_kwargs = line_kwargs or {"color": "red", "ci": None}

    corr_total=df[x_col].corr(df[y_col])
    
    # Create bins for the conditioning variable
    df['cond_bin'] = pd.qcut(df[cond_col], num_bins)
    
    # Create facet grid
    g = sns.FacetGrid(df, col="cond_bin", col_wrap=col_wrap, height=figsize[1], aspect=figsize[0]/figsize[1])
    
    # Only plot regression line
    g.map_dataframe(sns.regplot, x=x_col, y=y_col, scatter=plot_scatter, **line_kwargs)
    
    g.set_axis_labels(x_col, y_col)
    
    # Add correlation coefficient for each subplot
    for ax, (bin_name, bin_data) in zip(g.axes.flat, df.groupby('cond_bin', observed=True)):
        if len(bin_data) > 1:
            corr_val = bin_data[[x_col, y_col]].corr().iloc[0,1]
            # Alternative: Pearson correlation: corr_val, _ = pearsonr(bin_data[x_col], bin_data[y_col])
            ax.text(0.05, 0.9, f"r={corr_val:.4f}", transform=ax.transAxes, fontsize=10, color='blue')
        ax.set_ylim(ymin, ymax)
    
    g.set_titles(f"{cond_col} in {{col_name}}")

    # Overall title
    plt.subplots_adjust(top=0.85)
    g.fig.suptitle(f"{y_col} ~ {x_col} | {cond_col} (corr={corr_total:.5f})", fontsize=14)
    
    plt.tight_layout()
    plt.show()


from collections import Counter
import pandas as pd

def check_duplicate(sym_list, descending=True):
    """
    Count occurrences of each symbol in a list and return a DataFrame sorted by count.

    Parameters:
    - sym_list (list or tuple of str): List or tuple of symbols
    - descending (bool): If True, sort counts in descending order. Default is True.

    Returns:
    - pd.DataFrame: Two columns: 'sym' and 'count', sorted by count
    """
    counts = Counter(sym_list)
    df = pd.DataFrame(counts.items(), columns=['sym', 'count'])
    df = df.sort_values('count', ascending=not descending).reset_index(drop=True)
    return df

import numpy as np
def get_rolling_corr_by_sym(df:pd.DataFrame, y1_col, y2_col, sym_col='sym', date_col='date', window=21):
    """
    compute rolling corr by symbols
    Usage:
    df["roll_corr_intra_XX"] = get_rolling_corr_by_sym(df, 'FOC', 'FGAP', sym_col='sym', date_col='date', window=10)
    # Ensure data is sorted properly
      Parameters:
    - df: pd.DataFrame
    - y1_col, y2_col: str, column names for correlation
    - sym_col: str, symbol grouping column
    - date_col: str, column for sorting
    - window: int, rolling window size

    Returns:
    - pd.Series: rolling correlation aligned with df.index
    """
    
    df = df.sort_values([sym_col, date_col]).reset_index(drop=True)

    # Grouped rolling correlation (vectorized)
    rolling_corr = (
        df.groupby(sym_col, group_keys=False)
          .apply(lambda g: g[y1_col].shift(1)
                 .rolling(window=window, min_periods=window)
                 .corr(g[y2_col].shift(1))
           )
    )
    return rolling_corr.values

