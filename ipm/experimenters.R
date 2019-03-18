addRowAdpater <- function(resultados, baseline, matriz, ...) {
  print(baseline)
  newRes <- data.frame(baseline, matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

generateHash <- function(n = 5000) {
  a <- do.call(paste0, replicate(5, sample(LETTERS, n, TRUE), FALSE))
  paste0(a, sprintf("%04d", sample(9999, n, TRUE)), sample(LETTERS, n, TRUE))
}