#' mdd Function
#'
#' This function allows to get the maximum drawdown
#' @param x
#' @keywords Drawdown
#' @export

mdd <- function(x) {
tseries::maxdrawdown(cumsum(x))$maxdrawdown / sd( x) / sqrt(252)
}
