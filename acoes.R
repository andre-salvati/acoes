
#install.packages("tidyverse")
#install.packages("readxl")
#install.packages("lubridate")
#install.packages("googledrive")
#install.packages("tidyquant")

library(tidyverse)
library(readxl)
library(lubridate)
library(googledrive)
library(tidyquant)

setwd("~/Desktop/acoes/")
options("scipen"=100, digits = 4)
texto45 = theme(axis.text.x=element_text(angle=45, hjust=1))
theme_set(theme_minimal())

# Portfólio (Google Drive) -----------------

drive_find(n_max = 30)
minha_planilha = "1H7APdQhZKSnUgFOefXTshJa1AwwW_H7eY3Tg4dgo-ts"
arquivo = "Ações (modelo).xlsx"

drive_download(as_id(minha_planilha), overwrite = TRUE)
comprado = read_excel(arquivo, sheet = "Comprado", col_names = TRUE)
vendido = read_excel(arquivo, sheet = "Vendido", col_names = TRUE)

comprado$ticker = paste0(comprado$Ticker,".SA")
comprado$data_entrada = as.Date(comprado$Data)
comprado$quantidade = comprado$Qtd
comprado$valor_entrada = comprado$`Valor entrada`

# Cotações ----------------

stock_prices <- comprado$ticker %>%
                tq_get(get  = "stock.prices",
                       from = "2021-01-01",
                       to   = "2023-12-31") %>%
                mutate(symbol = str_replace(symbol, "\\.SA", ""))  

unique(stock_prices$symbol)

