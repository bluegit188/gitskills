
import numpy as np
import pandas as pd
from tabulate import tabulate
import math
from numba import jit

# TODO: change format of cdf

# TODO: make CSV files, 1 raw file, 1 given info + result

# jit makes a compiled version za_helper, which helps with speed when running
# loops


@jit()
def za_helper(fcst, position, x):
    """
    (float,float,float) -> float
    """
    p2 = fcst - np.sign(fcst - position) * x
    r = position
    if abs(fcst - position) >= x:
        r = p2
    if np.sign(r) != np.sign(fcst):
        r = 0
    return r


def opt_za(df,priority,weight_list,x_list,trade_num, sfcst_list):
    """
    (DataFrame,str,list of floats, list of floats, int, list of floats) ->
    list of floats

    """
    fcst_list = []
    position_list = []
    sym_list = df.SYM.tolist()

    # making forecast list

    if priority == 'weight':
        # if priority is weight, we apply weights to forecasts.
        # then we make weight list = 1 to to avoid double weighting.
        for i in range(trade_num):
            fcst_list.append(
                (weight_list[i] * (df[sfcst_list[i]])).tolist())
            position_list.append([])
        weight_list.fill(1)
    else:
        # priority = opt, we apply weights later.
        for i in range(trade_num):
            fcst_list.append((df[sfcst_list[i]]).tolist())
            position_list.append([])
    # first iteration of this function is manual.
    # uses za helper to determine each value.
    # first one
    position_list[0].append(
        weight_list[0] * za_helper(fcst_list[0][0], 0, x_list[0]))
    for i in range(1, trade_num):
        position_list[i].append(weight_list[i] * za_helper(fcst_list[i][0], position_list[i - 1][0], x_list[i]))
    # rest of it
    for i in range(1, len(fcst_list[0])):
        for j in range(trade_num):
            if j == 0 and sym_list[i] != sym_list[i - 1]:
                position_list[j].append(weight_list[j] * za_helper(fcst_list[j][i], 0, x_list[j]))
            else:
                position_list[j].append(weight_list[j] * za_helper(fcst_list[j][i], position_list[j - 1][-1], x_list[j]))
    return position_list


def safe_div(x, y):
    """
    faster than exceptions!!
    """
    if y == 0:
        return 0
    return x / y


def get_sharpe(n):
    """
    (list of floats) -> float
    returns the sharpe ratio of list n.
    """

    return safe_div(np.mean(n), np.std(n))


def opt_xt(fcst, x):
    """


    """
    df = pd.DataFrame({'LTF': fcst, 'Pos': fcst})
    df.Pos[abs(df.LTF) < x] = 0
    df.Pos[abs(df.LTF) >= x] = (abs(df.LTF)-x)*np.sign(df.LTF)
    return df.Pos


def opt_xt_pw(fcst, x, maxf, pw=1):
    """
    list of floats, float, float, float) -> list of floats
    this was an experimental function
    opt xt adjusting based on line fcst = position, using polynomial power pw
    """
    df = pd.DataFrame({'LTF': fcst, 'Pos': fcst})
    df.Pos[abs(df.LTF) < x] = 0
    #df.Pos[abs(df.LTF) >= x] = (1 * maxf/math.pow(1 * maxf - x, pw)) * np.sign(df.LTF) * ((abs(df.LTF)-x)).pow(pw)
    df.Pos[abs(df.LTF) >= x] = np.sign(df.LTF) * (abs(df.LTF)-x)
    return df.Pos

def apply_constraint(arr, rng, flag):
    rng = rng.split()
    if flag.lower() == 'false':
        arr = arr.clip(lower=float(rng[0]), upper=float(rng[1]))
    else:
        l = arr.quantile(float(rng[0]))
        u = arr.quantile(float(rng[1]))
        arr = arr.clip(lower=l, upper=u)
    return arr


def maximum_drawdown(df):
    # TODO: Update documantation of maximum_drawdown on all files.
    """
    (DataFrame, str) -> float
    gets the maximum drawdown of given PnL(net or gross) in the DataFrame, calculates the maximum drawdown value.
    the maximum drawdown value is adjusted by std of Portfolio_PnL (gross or net), and sqrt(252)
    maximum draw down : https://en.wikipedia.org/wiki/Drawdown_%28economics%29
    """
    dff = pd.DataFrame({'PnL': df})
    portfolio = dff.reset_index()
    portfolio['cumulative_PnL'] = portfolio.PnL.cumsum()
    i = np.argmax(
        np.maximum.accumulate(portfolio['cumulative_PnL']) - portfolio[
            'cumulative_PnL'])  # end of the period
    j = np.argmax(portfolio['cumulative_PnL'][:i])  # start of period
    # to plot cumulative PnL and Maximum drawdown points,  use the two commented lines below
    '''
    plt.plot(portfolio['cumulative_PnL'])
    plt.plot([i, j], [portfolio['cumulative_PnL'][i], portfolio['cumulative_PnL'][j]], 'o', color='Red', markersize=10)
    '''
    return (portfolio['cumulative_PnL'][j] - portfolio['cumulative_PnL'][i]) / (
        np.std(portfolio.PnL) * math.sqrt(252))


def df_delta_stable(data):
    """
    (DataFrame) -> DataFrame
    return a DataFrame with each value being the difference between it self and
    the value before it. first values of a row gets compared two last value of
    last row. keeps column names. adds 'turnover' columns which is sum of all
    cells in each row.
    """

    a = data.values
    l = [abs(a[0][0])]
    for i in range(1, len(a)):
        l.append(abs(a[i][0] - a[i-1][-1]))
    df = abs(data.diff(axis=1))
    df[df.columns[0]] = l
    df['turnover'] = df.sum(axis=1)
    return df


def df_delta(data):
    """
    (DataFrame) -> DataFrame
    return a DataFrame with each value being the difference between it self and
    the value before it. first values of a row gets compared to last value of
    last row. keeps column names. adds 'turnover' column which is sum of all
    cells in each row.

    """
    df = data.diff(axis=1)
    
    #df.iloc[:, 0] = data.iloc[:, 0] - data.iloc[:, -1].shift(1)
    #df.iloc[:, 0][0] = data.iloc[:, 0][:1]
    #df = abs(df)
    #df['turnover'] = df.sum(axis=1)
    #return df

    # Fixed
    df.iloc[:, 0] = data.iloc[:, 0] - data.iloc[:, -1].shift(1)
    df.iloc[0, 0] = float(data.iloc[0, 0])
    df = df.abs()
    df["turnover"] = df.sum(axis=1)
    return df


def group_by(a, s):
    """
    (DataFrame,str) -> list of DataFrame
     separates the table to different groups in column s
    """
    l = []
    gp = a.groupby(s)
    for g in gp.groups.items():
        l.append(a.loc[g[1]])
    return l


class Set:
    # class set load raw file dataFrame and configuration variables.

    def __init__(self, config, df=None):
        self.trade_num = int(config.trade_num.iloc[0])
        self.config = config
        self.file = config.file.item()
        self.fcst_list = []
        self.y_list = []
        self.x_list = []
        self.w_list = []
        self.fc_list = []
        self.yc_list = []
        ###
        self.tcost_list = []
        ###
        for i in range(1, self.trade_num + 1):
            self.fcst_list.append(config['fcst%g' % i].item())
            self.y_list.append(config['open%g' % i].item())
            self.x_list.append(float(config['x%g' % i].iloc[0]))
            self.fc_list.append(config['fconst%g' % i][1])
            self.yc_list.append(config['yconst%g' % i][1])
            ###
            self.tcost_list.append(float(config['tcost%g' %i].iloc[0]))
            ###
        if self.trade_num > 1:
            for i in range(1, self.trade_num + 1):
                self.w_list.append(float(config['s%g' % i].iloc[0]))

        self.priority = config.priority.item()
        self.opt = config.opt.item()
        self.fcst_constraint_percent = config.fcst_constraint_by_percent.item()
        self.yvar_constraint_percent = config.yvar_constraint_by_percent.item()
        #self.tcost = float(config.tcost.iloc[0])
        self.minute = float(config.minute.iloc[0])
        if df is not None:
            self.df = df
        else:
            self.df = pd.read_csv(self.config.file.item(), sep=" ")
        # self.xpw = float(config.xpw)


class Col(Set):
    # Col is a Set with position, gross, and net return added to it.

    def __init__(self, config, df=None):
        Set.__init__(self, config, df)
        cdf = pd.DataFrame()
        # pdf and gdf are dummy DataFrames to containing only position and gross
        # it is faster than separating them later .
        gdf = pd.DataFrame()
        pdf = pd.DataFrame()
        position = Col.opt(self)
        for i in range(self.trade_num):
            cdf[self.fcst_list[i]] = apply_constraint(self.df[self.fcst_list[i]], self.fc_list[i], self.fcst_constraint_percent)
            cdf[self.y_list[i]] = apply_constraint(self.df[self.y_list[i]], self.yc_list[i], self.yvar_constraint_percent)
            pdf['pos%g' % i] = cdf['pos%g' % i] = position[i]
            gdf['gross%g' % i] = cdf['gross%g' % i] = cdf['pos%g' % i] * cdf[self.y_list[i]]
        cdf['gross_return'] = gdf.sum(axis=1)
        cdf['DATE'] = self.df.DATE
        cdf['SYM'] = self.df.SYM
        self.delta_dataFrame = df_delta(pdf)
        turnover_num = self.delta_dataFrame.turnover
        # TODO: net return when sym changes is wrong.



        ###
        cdf['net_return'] = 0
        for i in range(self.trade_num):
            cdf['net%g' % i] = cdf['gross%g' % i] - self.delta_dataFrame['pos%g' % i] * self.tcost_list[i]
            cdf['net_return'] += cdf['net%g' %i]
            ### slight deviation from original code and this modified section for Net Sharpe
            ### is difference in Net Sharpe results due to change going to += cdf['net%g' %i] from turnover_num * self.tcost ???
            ### or could be due to rounding error
        ###
        # for i in range(self.trade_num):
        #     cdf['net%g' % i] = cdf['gross%g' % i] - self.delta_dataFrame['pos%g' % i] * self.tcost
        # cdf['net_return'] = cdf.gross_return - (turnover_num * self.tcost)



        turnover_dom = cdf['pos%g' % (self.trade_num - 1)]
        self.turnover = turnover_num.sum() / abs(turnover_dom).sum()
        self.cdf = cdf

    #(df, priority, weight_list, x_list, trade_num)
    def opt(self):
        x_list = self.x_list
        for i in range(self.trade_num):
            self.df[self.fcst_list[i]] = apply_constraint(self.df[self.fcst_list[i]], self.fc_list[i],self.fcst_constraint_percent)
        weight_list = np.array(self.w_list)
        if self.trade_num == 1:
            weight_list = np.array([1])

        if self.opt == 'xt':
            position_list = []
            fcst_list = []
            for i in range(self.trade_num):
                fcst_list.append(self.df[self.fcst_list[i]])
            if self.priority == 'weight':
                for i in range(self.trade_num):
                    fcst_list[i] = fcst_list[i] * weight_list[i]
                weight_list.fill(1)
            for i in range(self.trade_num):
                position_list.append(
                    weight_list[i] * opt_xt(fcst_list[i], x_list[i]))

        elif self.opt == 'za':
            # TODO: make Za a function.
            # position_list = opt_za(self.df,self.priority,weight_list,x_list,self.trade_num,self.fcst_list)

            fcst_list = []
            position_list = []
            sym_list = self.df.SYM.tolist()

            # making forecast list

            if self.priority == 'weight':
                # if priority is weight, we apply weights to forecasts.
                # then we make weight list = 1 to to avoid double weighting.
                for i in range(self.trade_num):
                    fcst_list.append((weight_list[i]*(self.df[self.fcst_list[i]])).tolist())
                    position_list.append([])
                weight_list.fill(1)
            else:
                for i in range(self.trade_num):
                    fcst_list.append((self.df[self.fcst_list[i]]).tolist())
                    position_list.append([])
            # first one
            position_list[0].append(weight_list[0] * za_helper(fcst_list[0][0], 0, x_list[0]))
            for i in range(1, self.trade_num):
                position_list[i].append(weight_list[i] * za_helper(fcst_list[i][0], position_list[i - 1][0], x_list[i]))
            # rest of it
            for i in range(1, len(fcst_list[0])):
                for j in range(self.trade_num):
                    if j == 0 and sym_list[i] != sym_list[i-1]:
                        position_list[j].append(weight_list[j] *
                            za_helper(fcst_list[j][i], 0, x_list[j]))
                    else:
                        position_list[j].append(weight_list[j] *
                                                za_helper(fcst_list[j][i], position_list[j - 1][-1],
                                                x_list[j]))


        return position_list

    def prin(self):
	# terminal visualization
        # Print out info for each period
        ret_msg = ['General:']
        #header = ['Period', 'Forecast','Forecast max','Forcast min', 'Y_value', 'X_Value', 'Constraint', 'Weight']
        header = ['Period', 'Fcst','FcstMax','FcstMin', 'Y_value', 'X_Value', 'Constraint', 'tcost','Weight']
        l = []
        for i in range(self.trade_num):
            l.append(['P%g' % i])
            l[i].append(self.fcst_list[i])
            l[i].append(self.df[self.fcst_list[i]].max())
            l[i].append(self.df[self.fcst_list[i]].min())
            l[i].append(self.y_list[i])
            l[i].append(self.x_list[i])
            l[i].append(self.fc_list[i])
            l[i].append(self.tcost_list[i])
            if self.trade_num > 1:
                l[i].append(self.w_list[i])
                
        ret_msg.append(tabulate(l, headers=header, tablefmt='orgtbl'))
        ret_msg.append(' ')
        ret_msg.append(' ')

        ### contract level results
        ret_msg.append('Contract LeveL:')
        #header =  ['Period', 'Gross Mean', 'Gross STD', 'Gross Sharpe', 'Net Mean', 'Net STD', 'Net Sharpe']
        header =  ['Period', 'GrossMean', 'GrossSTD', 'GrossShp_PA', 'NetMean', 'NetSTD', 'NetShp_PA']
        l = []
        for i in range(self.trade_num):
            l.append(['P%g' % i])
            l[i].append(np.mean(self.cdf['gross%g' % i]))
            l[i].append(np.std(self.cdf['gross%g' % i]))
            l[i].append(l[i][1] / l[i][2]*math.sqrt(252))
            l[i].append(np.mean(self.cdf['net%g' % i]))
            l[i].append(np.std(self.cdf['net%g' % i]))
            l[i].append(l[i][4] / l[i][5]*math.sqrt(252))

        ret_msg.append(tabulate(l, headers=header, tablefmt='orgtbl'))
        ret_msg.append(' ')
        ret_msg.append(' ')
        ret_msg.append('Portfolio Level:')
        #header = ['Period', 'Gross Mean', 'Gross STD', 'Gross Sharpe',
        #          'Net Mean', 'Net STD', 'Net Sharpe', 'DivNum','Net MDD']
        header = ['Period', 'GrossMean', 'GrossSTD', 'GrossShp_PA',
                  'NetMean', 'NetSTD', 'NetShp_PA', 'DivNum','NetMDD']
        k = []
        for i in range(self.trade_num):
            a = self.cdf.pivot(index='DATE', columns='SYM', values='gross%g' % i).sum(
                axis=1)
            k.append(['P%g' % i])
            k[i].append(np.mean(a))
            k[i].append(np.std(a))
            k[i].append(k[i][1] / k[i][2]*math.sqrt(252))
            b = self.cdf.pivot(index='DATE', columns='SYM', values='net%g' % i).sum(
                axis=1)
            k[i].append(np.mean(b))
            k[i].append(np.std(b))
            k[i].append(k[i][4] / k[i][5]*math.sqrt(252))
            k[i].append(k[i][-1] / l[i][-1])
            k[i].append(maximum_drawdown(b))
        ret_msg.append(tabulate(k, headers=header, tablefmt='orgtbl'))

        return ret_msg

    def lala(self):
	# terminal visualization
        l = []
        for i in range(self.trade_num):
            l.append(['P%g' % i])
            l[i].append(self.fcst_list[i])
            l[i].append(self.df[self.fcst_list[i]].max())
            l[i].append(self.df[self.fcst_list[i]].min())
            l[i].append(np.std(self.df[self.fcst_list[i]]))
            l[i].append(self.y_list[i])
            l[i].append(self.x_list[i])
            l[i].append(self.fc_list[i])
            if self.trade_num > 1:
                l[i].append(self.w_list[i])
            else:
                l[i].append('NA')
            l[i].append(np.mean(self.cdf['gross%g' % i]))
            l[i].append(np.std(self.cdf['gross%g' % i]))
            l[i].append(l[i][-2] / l[i][-1])
            l[i].append(np.mean(self.cdf['net%g' % i]))
            l[i].append(np.std(self.cdf['net%g' % i]))
            c_sh = (l[i][-2] / l[i][-1])
            l[i].append(c_sh)
            a = self.cdf.pivot(index='DATE', columns='SYM', values='gross%g' % i).sum(
                axis=1)
            l[i].append(np.mean(a))
            l[i].append(np.std(a))
            l[i].append(l[i][-2] / l[i][-1])
            l[i].append(maximum_drawdown(a))
            b = self.cdf.pivot(index='DATE', columns='SYM', values='net%g' % i).sum(
                axis=1)
            l[i].append(np.mean(b))
            l[i].append(np.std(b))
            l[i].append(l[i][-2] / l[i][-1])
            l[i].append(l[i][-1] / c_sh)
            l[i].append(maximum_drawdown(b))


       
        df = pd.DataFrame(l,columns=['Period', 'Fcst','FcstMax', 'FcstMin' ,'FcstSTD','Y_value', 'X_Value',
                                     'Constraint', 'Weight', 'ContractGrossMean',
                                     'ContractGrossSTD', 'ContractGrossSharpe',
                                     'ContractNetMean', 'ContractNetSTD',
                                     'ContractNetSharpe', 'PortfolioGrossMean',
                                     'PortfolioGrossSTD', 'PortfolioGrossSharpe', 'PortfolioGrossMDD',
                                     'PortfolioNetMean', 'PortfolioNetSTD',
                                     'PortfolioNetSharpe', 'DivNum'
                                     ,'Portfolio Net MDD'])
        
        return df


class Port:
    def __init__(self, col):
        result = col.cdf
        self.col = col
        portfolio_net = result.pivot(index='DATE', columns='SYM',
                                     values='net_return')
        portfolio_gross = result.pivot(index='DATE', columns='SYM',
                                       values='gross_return')
        portfolio_net = portfolio_net.fillna(0)

        portfolio_gross = portfolio_gross.fillna(0)
        portfolio_net['net_return'] = portfolio_net.sum(axis=1)
        self.portfolio_net = portfolio_net.net_return
        portfolio_gross['gross_return'] = portfolio_gross.sum(axis=1)
        self.NMDD = maximum_drawdown(portfolio_net.net_return)
        self.GMDD = maximum_drawdown(portfolio_gross.gross_return)
        self.p_net_sharpe = get_sharpe(portfolio_net.net_return)
        self.p_gross_sharpe = get_sharpe(portfolio_gross.gross_return)
        self.c_net_sharpe = get_sharpe(result.net_return)
        self.c_gross_sharpe = get_sharpe(result.gross_return)
        self.p_divNum = self.p_net_sharpe / self.c_net_sharpe

        self.plNetStd = np.std(result.net_return)
        self.pplNetStd = np.std(portfolio_net.net_return)
        
        self.turnover = col.turnover

    def ret(self):
	# terminal visualization

        l = [[]]

        header = ['pcShpGross', 'pcShpNet',
                  'portShpGross',
                  'portShpNet', 'netMdd', 'grossMdd', 'Turnover',
                  'DivNum','plNetStd','pplNetStd']
        
        l[0].append(self.c_gross_sharpe*math.sqrt(252))
        l[0].append(self.c_net_sharpe*math.sqrt(252))
        l[0].append(self.p_gross_sharpe*math.sqrt(252))
        l[0].append(self.p_net_sharpe*math.sqrt(252))
        l[0].append(self.NMDD)
        l[0].append(self.GMDD)
        l[0].append(self.turnover)
        l[0].append(self.p_divNum)
        l[0].append(self.plNetStd)  
        l[0].append(self.pplNetStd)
        ret_val = (tabulate(l, headers=header, tablefmt='orgtbl'))
        return ret_val

    def ovr(self):
        k = pd.DataFrame()
        for i in range(self.col.trade_num):
            k['Forecast %g' % (i+1)] = [self.col.fcst_list[i]]
        for i in range(self.col.trade_num):
            k['Y_value %g' % (i+1)] = self.col.y_list[i]

        #k['Priority'] = self.col.priority
        #k['Opt'] = self.col.opt
        #k['Tcost'] = self.col.tcost
        #k['Minute'] = self.col.minute
        for i in range(self.col.trade_num):
            k['X_value %g' % (i+1)] = self.col.x_list[i]
        if self.col.trade_num > 1:
            for i in range(self.col.trade_num):
                k['Weight %g' % (i+1)] = self.col.w_list[i]
        #for i in range(self.col.trade_num):
            #k['Constraint %g' % (i+1)] = self.col.c_list[i]
        k['Contract_Gross_Sharpe'] = self.c_gross_sharpe
        k['Contract_Net_Sharpe'] = self.c_net_sharpe
        k['Portfolio_Gross_Sharpe'] = self.p_gross_sharpe
        k['Portfolio_Net_Sharpe'] = self.p_net_sharpe
        k['Gross_MDD'] = self.GMDD
        k['Net_MDD'] = self.NMDD
        k['Turnover'] = self.turnover
        k['DivNum'] = self.p_divNum
        return k
