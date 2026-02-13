#Cleanly install all the packages that were used in this shinyapp
dockerpackages <- c("shiny", "shinythemes" , "tidyverse", "tidyquant", "plotly", "corrplot")
install.packages(dockerpackages, dependencies = TRUE)