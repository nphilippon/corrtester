#Cleanly install all the packages that were used in this shinyapp
dockerpackages <- c("shiny", "shinythemes" , "tidyverse", "tidyquant", "plotly", "corrplot", "moments", "gt")
install.packages(dockerpackages, dependencies = TRUE)