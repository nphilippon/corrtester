#REQUIED PACKAGES TO BE INSTALLEWD LATER (VECTORIZE WITH IF STATEMENT SO WE DONT HAVE IMAGE GENERATION ERROR)
dockerpackages <- c("shiny", "shinythemes" , "tidyverse", "tidyquant", "quantmod", "plotly", "corrplot", "lubridate")
for (pkg in dockerpackages) {
  if(!require(pkg, character.only = TRUE)) install.packages(pkg, dependencies = TRUE)
}
