# 
# install.packages("tidyverse")
# install.packages("readxl")
# install.packages("lubridate")
# install.packages("googledrive")
# install.packages("tidyquant")
# install.packages("janitor")

library(tidyverse)
library(readxl)
library(lubridate)
library(googledrive)
library(tidyquant)
library(janitor)

setwd("~/Desktop/workspace/git/stocks/")
options("scipen"=100, digits = 4)
texto45 = theme(axis.text.x=element_text(angle=45, hjust=1))
theme_set(theme_bw())

# download an prepare portfolio (Google Drive) -----------------

drive_find(n_max = 30)
my_spreadsheet = "1H7APdQhZKSnUgFOefXTshJa1AwwW_H7eY3Tg4dgo-ts"
file = "Stocks (template).xlsx"
drive_download(as_id(my_spreadsheet), overwrite = TRUE)
portfolio = read_excel(file, sheet = "bought", col_names = TRUE) %>% clean_names() %>%
                mutate(symbol = paste0(ticker,".SA"),
                      date = as.Date(date))


# download quotes ---------------------

prices <- c(portfolio$symbol) %>%
            tq_get(get  = "stock.prices",
                    from = "2023-01-01",
                    to   = "2023-12-31")

statement = prices %>%
              left_join(portfolio, by = c("symbol" = "symbol", "date" = "date")) %>%
              select(symbol, date, category, qty, purchase_price, open, close) %>%
              mutate(qty = replace_na(qty, 0)) %>%
              group_by(symbol) %>%
              mutate(qty = cumsum(qty)) %>%
              filter(qty > 0 ) %>%
              #filter(symbol == "ITSA4.SA")
              mutate(price = if_else(is.na(purchase_price), close, purchase_price),
                    current_value = price * qty,
                    category = first(category)) %>%
              select(symbol, category, date, qty, current_value)

total = statement %>% group_by(date) %>%
          summarise(total = sum(current_value)) %>%
          ggplot(aes(date, total)) +
          geom_point() +
          geom_line() +
          ggtitle("Total")

total_symbol = statement %>% rename(total = current_value) %>%
                ggplot(aes(date, total, color = symbol)) +
                geom_point() +
                geom_line() +
                ggtitle("Total per symbol")

total_category = statement %>% group_by(category, date) %>%
                  summarise(total = sum(current_value)) %>%
                  ggplot(aes(date, total, color = category)) +
                  geom_point() +
                  geom_line() +
                  ggtitle("Total per category")

prices_median = prices %>% group_by(symbol) %>% summarise(last_price = last(close),
                  median_price = median(close)) %>%
                  mutate(perc_change = ((last_price/median_price) -1) *100) %>%
                  select(symbol, perc_change, last_price)

prices %>% left_join(prices_median, by = "symbol") %>% 
            mutate(symbol = fct_reorder(symbol, desc(perc_change))) %>%
            ggplot(aes(symbol, close)) +
            geom_boxplot() +
            geom_point(data=portfolio, aes(symbol, purchase_price), color = "green") +
            #geom_point(, 
            #             aes(symbol, last_price), color = "blue") +
              texto45

w_ = 15
h_ = 10

ggsave(total, filename = "./img/total.png", width = w_, height = h_)
ggsave(total_symbol, filename = "./img/total_per_symbol.png", width = w_, height = h_)
ggsave(total_category, filename = "./img/total_per_category.png", width = w_, height = h_)

