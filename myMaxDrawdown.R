#' myMaxDrawdown Function
#'
#' This function allows to get the maximum drawdown
#' @param x
#' @keywords Drawdown
#' @export

myMaxDrawdown <- function(x) {
    Return.cumulative = 1+cumsum(x)
    maxCumulativeReturn = cummax(c(1,Return.cumulative))[-1]
    column.drawdown = Return.cumulative/maxCumulativeReturn - 1
    result <- min(column.drawdown)
    return(-result)
}