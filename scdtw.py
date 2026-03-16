import numpy as np
import math
from tslearn.metrics import dtw
from numba import njit

class SCDTW:
    """Computes distances between query and reference series."""
    def __init__(self, dist_type="manhattan"):
        self.dist_type = dist_type

    def compute_euc_dist(self, query_vec, ref_vec):
        """Compute vector-to-matrix distances."""
        dists = np.sum((ref_vec - query_vec) ** 2)
        return dists

    def compute_euc_dist_wgt(self, query_vec:np.ndarray, ref_vec:np.ndarray, a=0.81):#9):
        query_vec = np.asarray(query_vec)
        ref_vec = np.asarray(ref_vec)
        n = len(query_vec)

        # generate weights: 1, a, a^2, ..., a^(n-1)
        wgts = np.power(a, np.arange(n))

        # weighted squared difference
        diffs = (query_vec - ref_vec)**2 * wgts
        dist = np.sum(diffs )

        return dist

    def compute_euc_dist_1_lag(self, query_vec:np.ndarray, ref_vec:np.ndarray):
        query_vec = np.asarray(query_vec)
        ref_vec = np.asarray(ref_vec)
        n = len(query_vec)

        # generate weights: 1, a, a^2, ..., a^(n-1)
        a=1
        wgts = np.power(a, np.arange(n))

        # weighted squared difference
        diffs = (query_vec - ref_vec)**2 * wgts
        dist=diffs[0]
        return dist


    def compute_euc_dist_2_lags(self, query_vec:np.ndarray, ref_vec:np.ndarray):
        query_vec = np.asarray(query_vec)
        ref_vec = np.asarray(ref_vec)
        n = len(query_vec)

        # generate weights: 1, a, a^2, ..., a^(n-1)
        a=1
        wgts = np.power(a, np.arange(n))

        # weighted squared difference
        diffs = (query_vec - ref_vec)**2 * wgts
        dist=diffs[0]+diffs[1]
        return dist


    def simple_dtw_dist(self, x: np.ndarray, y: np.ndarray) -> float:
        """
        Compute the simplest DTW distance between two equal-length sequences x and y.
        Assumptions:
          - x and y are 1D numpy arrays of the same length (n = m)
          - Standard DTW with min of three directions: (i-1, j), (i, j-1), (i-1, j-1)
        """
        n = len(x)
        dtw = np.full((n, n), np.inf)
        dtw[0, 0] = (x[0] - y[0])**2
        
        # Initialize first row and first column
        for i in range(1, n):
            dtw[i, 0] = (x[i] - y[0])**2 + dtw[i-1, 0]
            dtw[0, i] = (x[0] - y[i])**2 + dtw[0, i-1]

        # dynamic programming core
        for i in range(1, n):
            for j in range(1, n):
                cost = (x[i] - y[j])**2
                dtw[i, j] = cost + min(dtw[i-1, j], dtw[i, j-1], dtw[i-1, j-1])

        return dtw[-1, -1]

    def compute_dtw_dist(self, query_vec, ref_vec):
        """
        Compute the dtw distance 
        between two 1D vectors (query_vec and ref_vec).
        """
        query_vec = np.asarray(query_vec)
        ref_vec = np.asarray(ref_vec)
        n, m = len(query_vec), len(ref_vec) #assume n==m

        # Initialize cost matrix
        dtw = np.full((n, n), np.inf)
        dtw[0, 0] = (query_vec[0] - ref_vec[0]) ** 2

        # Initialize first row and first column
        for i in range(1, n):
            dtw[i, 0] = (query_vec[i] - ref_vec[0]) ** 2 + dtw[i - 1, 0]
            dtw[0, i] = (query_vec[0] - ref_vec[i]) ** 2 + dtw[0, i - 1]
        
        # Fill the DTW table
        for i in range(1, n):
            for j in range(1, n):
                cost = (query_vec[i] - ref_vec[j]) ** 2
                dtw[i, j] = cost + min(
                    dtw[i - 1, j],      # insertion
                    dtw[i, j - 1],      # deletion
                    dtw[i - 1, j - 1]   # match
                )

        # Diagonal (no warping) cost for comparison
        # diag_cost = np.sum((query_vec - ref_vec[:n]) ** 2) if n <= m else np.sum((query_vec[:m] - ref_vec) ** 2)

        return dtw[-1, -1]
    
    def compute_dtw_dist_wgt(self, query_vec: np.ndarray, ref_vec: np.ndarray, a: float = 0.81) -> float:
        """
        Compute weighted DTW distance 
        """
        query_vec = np.asarray(query_vec)
        ref_vec = np.asarray(ref_vec)
        n = len(query_vec)
      
        # precompute sqrt(a**i) for all i to spped up
        # wgt_ij = sqrt_w[i] * sqrt_w[j], where sqrt_w[i] = a**(i/2).
        sqrt_w = np.power(a, np.arange(n) / 2.0)

        # initialize DTW matrix
        dtw = np.full((n, n), np.inf)
        dtw[0, 0] = (query_vec[0] - ref_vec[0]) ** 2 * sqrt_w[0] * sqrt_w[0]

        # initialize first row and column
        for i in range(1, n):
            dtw[i, 0] = dtw[i - 1, 0] + (query_vec[i] - ref_vec[0]) ** 2 * sqrt_w[i] * sqrt_w[0]
            dtw[0, i] = dtw[0, i - 1] + (query_vec[0] - ref_vec[i]) ** 2 * sqrt_w[0] * sqrt_w[i]

        # fill rest of table
        for i in range(1, n):
            wi = sqrt_w[i]
            for j in range(1, n):
                wgt = wi * sqrt_w[j]  # multiply, not recompute powers
                cost = (query_vec[i] - ref_vec[j]) ** 2 * wgt
                dtw[i, j] = cost + min(dtw[i - 1, j], dtw[i, j - 1], dtw[i - 1, j - 1])

        return dtw[-1, -1]



    def compute_scd_dist_wgt(self,query_vec: np.ndarray, ref_vec: np.ndarray, a: float = 0.81, band: int = 5) -> float:
        """
        Compute weighted DTW distance using the Sakoe-Chiba band
        
        Parameters
        ----------
        query_vec : np.ndarray
            Query vector (1D)
        ref_vec : np.ndarray
            Reference vector (1D)
        a : float, optional
            Weight decay factor (default = 0.81)
        band : int, optional
            Sakoe-Chiba band width (default = 5)
        
        Returns
        -------
        float
            Weighted DTW distance with band constraint.
        """
        query_vec = np.asarray(query_vec)
        ref_vec = np.asarray(ref_vec)
        n = len(query_vec)

        # precompute sqrt(a**i) for all i to spped up
        # wgt_ij = sqrt_w[i] * sqrt_w[j], where sqrt_w[i] = a**(i/2).
        sqrt_w = np.power(a, np.arange(n) / 2.0)

        # initialize DTW matrix
        dtw = np.full((n, n), np.inf)
        dtw[0, 0] = (query_vec[0] - ref_vec[0]) ** 2 * sqrt_w[0] * sqrt_w[0]

          
        # initialize first row and first column within the band
        for i in range(1, min(band + 1, n)):
            dtw[i, 0] = dtw[i - 1, 0] + (query_vec[i] - ref_vec[0]) ** 2 * sqrt_w[i] * sqrt_w[0]
            dtw[0, i] = dtw[0, i - 1] + (query_vec[0] - ref_vec[i]) ** 2 * sqrt_w[0] * sqrt_w[i]

        # fill only the cells inside the Sakoe-Chiba band
        for i in range(1, n):
            wi = sqrt_w[i]
            j_start = max(1, i - band)
            j_end = min(n, i + band + 1)
            for j in range(j_start, j_end):
                wgt = wi * sqrt_w[j]  # multiply, not recompute powers
                cost = (query_vec[i] - ref_vec[j]) ** 2 * wgt
                dtw[i, j] = cost + min(dtw[i - 1, j], dtw[i, j - 1], dtw[i - 1, j - 1])

        return dtw[-1, -1]

    @staticmethod
    @njit
    def compute_scd_dist_wgt_njit(query_vec: np.ndarray, ref_vec: np.ndarray, a: float = 0.81, band: int = 5) -> float:
        """
        Compute weighted DTW distance using the Sakoe-Chiba band
        
        Parameters
        ----------
        query_vec : np.ndarray
            Query vector (1D)
        ref_vec : np.ndarray
            Reference vector (1D)
        a : float, optional
            Weight decay factor (default = 0.81)
        band : int, optional
            Sakoe-Chiba band width (default = 5)
        
        Returns
        -------
        float
            Weighted DTW distance with band constraint.
        """
        #njit doesn't support f string
        #print("a=",a)
                
        query_vec = np.asarray(query_vec)
        ref_vec = np.asarray(ref_vec)
        n = len(query_vec)

        # precompute sqrt(a**i) for all i to spped up
        # wgt_ij = sqrt_w[i] * sqrt_w[j], where sqrt_w[i] = a**(i/2).
        sqrt_w = np.power(a, np.arange(n) / 2.0)

        # initialize DTW matrix
        dtw = np.full((n, n), np.inf)
        dtw[0, 0] = (query_vec[0] - ref_vec[0]) ** 2 * sqrt_w[0] * sqrt_w[0]

          
        # initialize first row and first column within the band
        for i in range(1, min(band + 1, n)):
            dtw[i, 0] = dtw[i - 1, 0] + (query_vec[i] - ref_vec[0]) ** 2 * sqrt_w[i] * sqrt_w[0]
            dtw[0, i] = dtw[0, i - 1] + (query_vec[0] - ref_vec[i]) ** 2 * sqrt_w[0] * sqrt_w[i]

        # fill only the cells inside the Sakoe-Chiba band
        for i in range(1, n):
            wi = sqrt_w[i]
            j_start = max(1, i - band)
            j_end = min(n, i + band + 1)
            for j in range(j_start, j_end):
                wgt = wi * sqrt_w[j]  # multiply, not recompute powers
                cost = (query_vec[i] - ref_vec[j]) ** 2 * wgt
                dtw[i, j] = cost + min(dtw[i - 1, j], dtw[i, j - 1], dtw[i - 1, j - 1])

        return dtw[-1, -1]

    def compute_scdtw_tslearn(self, x: np.ndarray, y: np.ndarray, band=3) -> float:
        """
        Compute DTW distance using tslearn's optimized implementation
        with a Sakoe–Chiba constraint.

        Parameters
        ----------
        x, y : array-like, shape (n_timestamps,)
            Two 1D time series of equal length.
        band : int, default=3
            Sakoe–Chiba radius (band width). If band >= len(x),
            this effectively reverts to full DTW.
        """
        return dtw(x, y, global_constraint="sakoe_chiba", sakoe_chiba_radius=band)

