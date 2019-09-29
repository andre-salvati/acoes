
#install.packages("tidyverse")
#install.packages("readxl")
#install.packages("lubridate")
#install.packages("googledrive")
#install.packages("BatchGetSymbols")
#install.packages("corrplot")

library(tidyverse)
library(readxl)
library(lubridate)
library(googledrive)
library(BatchGetSymbols)
library(corrplot)

setwd("~/Desktop/acoes/")
options("scipen"=100, digits = 4)
texto45 = theme(axis.text.x=element_text(angle=45, hjust=1))
theme_set(theme_minimal())

# Empresas ------------------------

df.sp500 <- GetIbovStocks()

bancos = c("PINE4","IDVL3","IDVL4","RPAD6","RPAD3","RPAD5","BNBR3","BAZA3","BRGE12","BRGE3","BRGE8","BRGE11","BMEB4","BMEB3",
           "BRGE7","BEES4","BGIP3","BEES3","BRSR3","BGIP4","BRSR6","BRIV3","BRSR5","ABCB4","BRIV4","ITSA4","BBAS3","BSLI3","ITSA3","SANB4",
           "BRGE6","ITUB3","BBDC3","SANB11","SANB3","BBDC4","ITUB4","BSLI4","BPAC5","BMIN3","BPAN4","BMIN4","BPAC11","BPAC3","BIDI4")

small = c( "ABCB4", "ALPA4","ALSC3","ALUP11","AMAR3","ANIM3","ARZZ3","AZUL4","BEEF3","BIDI4","BKBR3","BRAP4","BRML3","BRPR3","BRSR6",
           "CAML3","CESP6","CPLE6","CSMG3","CVCB3","CYRE3","DIRR3","DTEX3","ECOR3","ENAT3","ENBR3","ENEV3","ESTC3","EVEN3","EZTC3","FESA4","FJTA4",
           "FLRY3","GFSA3","GOAU4","GOLL4","GRND3","GUAR3","HGTX3","IGTA3","LCAM3","LEVE3","LIGT3","LINX3","LOGG3","MEAL3","MOVI3","MRFG3","MRVE3",
           "MULT3","MYPK3","ODPV3","PARD3","POMO4","PRIO3","QUAL3","RAPT4","SAPR11","SAPR4","SEER3","SLCE3","SMLS3","SMTO3","STBP3","TAEE11","TEND3","TGMA3",
           "TIET11","TOTS3","TUPY3","UNIP6","VLID3","VULC3","VVAR3","WIZS3")

outros = c("AGRO3", "EKTR3", "OIBR4", "CNTO3", "PNVL4", "CGRA3", "CGRA4", "LLIS3", "LAME3", "SLED4", "PFRM3",
           "EALT4", "KEPL3", "ROMI3", "SLCE3", "BOVA11", "DASA3","SULA11", "MDIA3", "WEGE3", "MOVI3", "CRFB3", "TAMM4", "JHSF3",
           "JSLG3", "COCE3", "EEEL3", "CPFE3", "CEEB3", "CLSC3", "ELPL3", "CBEE3", "TIET11")

my.tickers <- sort(unique(paste0(c(bancos,df.sp500$tickers,small, outros), ".SA")))


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

vendido$ticker = paste0(vendido$Ticker,".SA")
vendido$data_entrada = as.Date(vendido$Data)
vendido$quantidade = vendido$Qtd
vendido$data_saida = as.Date(vendido$`Data Saída`)
vendido$valor_saida = vendido$`Valor saída`
vendido$valor_entrada = vendido$`Valor entrada`
vendido$preco_entrada = vendido$`Preço entrada`
str(vendido)


# Cotações ----------------

first.date =  '2018-01-01'
last.date <- Sys.Date()
ind_bov = "^BVSP"
df.stocks <- BatchGetSymbols(tickers = c(ind_bov, my.tickers),
                             first.date = first.date,
                             last.date = last.date, 
                             do.cache=FALSE,
                             thresh.bad.data = 0.50,
                             freq.data = "daily")[[2]]


unique(df.stocks$ref.date)
sort(unique(df.stocks$ticker))
df.stocks = as.data.frame(df.stocks)


# Preparação ----------------------

comprado = df.stocks %>% 
  right_join(comprado, by = "ticker") %>%
  filter(ref.date >= data_entrada) %>%
  arrange(ref.date) %>%
  mutate(valor_atual = quantidade * price.close,
         resultado_atual = valor_atual - valor_entrada) %>%
  select(ticker, ref.date, data_entrada, quantidade, valor_entrada, valor_atual, resultado_atual)

vendido = df.stocks %>% 
  left_join(vendido, by = "ticker") %>%
  filter(ref.date >= data_entrada & ref.date <= data_saida) %>%
  #select(ticker, ref.date, data_entrada, valor_entrada, data_saida, valor_saida, quantidade, price.close)
  #filter(ref.date >= data_entrada) %>%
  arrange(ref.date) %>%
  #filter(ticker == "AZUL4.SA") %>%
  mutate(#valor_atual = if_else(ref.date == data_saida, valor_saida, quantidade * price.close),
         valor_atual = quantidade * price.close,
         temp = if_else(ref.date == data_saida, valor_saida - valor_entrada, 0),
         resultado_fin = cumsum(temp),
         valor_entrada = Qtd * preco_entrada,
         resultado_antes_fin = if_else(ref.date == data_saida, 0, valor_atual - valor_entrada)) %>%
  select(ticker, ref.date, data_entrada, quantidade, valor_entrada, data_saida, valor_saida, valor_atual, resultado_antes_fin, temp, resultado_fin)

resultado = comprado %>% full_join(vendido, by = c("ticker", "ref.date")) %>% arrange(ref.date) %>% 
      fill(resultado_fin) %>% 
      replace_na(list(valor_atual = 0, resultado_atual = 0, resultado_antes_fin = 0)) %>%
      group_by(ref.date) %>%
      summarise(resultado_atual = sum(resultado_atual),
                resultado_antes_fin = sum(resultado_antes_fin),
                resultado_fin = last(resultado_fin)) %>%
      mutate(total = resultado_atual + resultado_fin + resultado_antes_fin)


# Análises --------------------

View(resultado)

# resultado ...

resultado %>%  
  ggplot(aes(ref.date, total)) +
  geom_line() +
  geom_point()


# resultado diário ...

resultado %>% 
  ggplot(aes(ref.date, total-lag(total))) +
  #geom_line() +
  geom_bar(stat = "identity") +
  geom_smooth()

# resultado semanal / mensal ... 

resultado %>%
  mutate(data = floor_date(ref.date, unit = "week")) %>%
  group_by(data) %>%
  summarise(return = last(total) - first(total)) %>%
  ggplot(aes(data, return)) +
  geom_point() +
  geom_bar(stat = "identity") 


# comprados ...

comprado %>% 
  ggplot(aes(ref.date, valor_atual, color = ticker)) +
  geom_point() +
  #geom_line() +
  geom_smooth(se = FALSE) +
  geom_point(data = comprado, aes(data_entrada, valor_entrada), shape=3, size = 4) #+
  #scale_color_manual(values=distinctColorPalette(15))

vendido %>% 
  mutate(group_no = as.integer(factor(paste0(ticker, data_entrada)))) %>%
  ggplot(aes(ref.date, valor_atual, color = ticker)) +
  geom_point() +
  geom_line(aes(group = group_no)) +
  #geom_smooth(se = FALSE) +
  geom_point(data = vendido, aes(data_entrada, valor_entrada), shape=3, size = 4) +
  geom_point(data = vendido, aes(data_saida, valor_saida), shape=4, size = 4)
  #scale_color_manual(values=distinctColorPalette(15))


# Simulação ------------------

carteira <- function(carteira, comp_setor) {
  investimento_setor = investimento_ini/length(comp_setor)
  setor = df.stocks %>% 
    filter(ref.date >= data_ini) %>%
    filter(ticker %in% comp_setor) %>% 
    group_by(ticker) %>%
    mutate(quantidade = investimento_setor/first(price.adjusted),
           total = quantidade * price.adjusted) %>%
    select(ticker, ref.date, price.adjusted, quantidade, total) %>%
    #group_by(ticker) %>%
    #summarise(cont = n())
    group_by(ref.date) %>%
    summarise(total = sum(total)) %>%
    mutate(ticker = carteira)
}

tickers_meus = unique(comprado$ticker)

#tickers_avaliando = holder %>% filter(grepl("Comércio",`subsetor bovespa`)) %>% select(ticker) %>% unlist()
#tickers_avaliando = tickers_avaliando[-4]
#tickers_avaliando = c("BTOW3.SA", "CCRO3.SA", "ECOR3.SA", "NATU3.SA", "BRFS3.SA", "CSAN3.SA", "ABEV3.SA", "AZUL4.SA", "GOLL4.SA", 
#                      "SMTO3.SA", "EMBR3.SA", "AGRO3.SA", "UGPA3.SA", "BRDT3.SA", "STBP3.SA")

tickers_ferro = c("VALE3.SA" , "GGBR4.SA", "CSNA3.SA")
tickers_banco = c("ITUB4.SA", "SANB4.SA", "BBDC4.SA", "B3SA3.SA")
tickers_saude = c("DASA3.SA", "FLRY3.SA", "GNDI3.SA", "HYPE3.SA", "ODPV3.SA", "PARD3.SA", "QUAL3.SA")
tickers_energia = c("ENEV3.SA", "EGIE3.SA", "EQTL3.SA", "CESP6.SA", "CPLE6.SA", "ENBR3.SA", "ELPL3.SA", "CPFE3.SA")
tickers_construcao = c("CYRE3.SA", "EVEN3.SA", "MRVE3.SA", "TEND3.SA", "EZTC3.SA", "JHSF3.SA")
tickers_varejo = c("RADL3.SA", "PCAR4.SA", "CRFB3.SA", "MGLU3.SA", "LREN3.SA", "BTOW3.SA", "VVAR3.SA")
tickers_transp = c("RAIL3.SA", "STBP3.SA", "JSLG3.SA", "BRDT3.SA") 
tickers_rodovia = c("ECOR3.SA", "CCRO3.SA") 
tickers_carne = c("BRFS3.SA", "MRFG3.SA", "JBSS3.SA", "BEEF3.SA")
tickers_educ = c("KROT3.SA", "ANIM3.SA", "SEER3.SA")
tickers_telecom = c("TIMP3.SA", "OIBR4.SA", "VIVT4.SA")
tickers_calcados = c("VULC3.SA", "GRND3.SA", "ALPA4.SA", "ARZZ3.SA")
tickers_agro = c("SMTO3.SA", "AGRO3.SA", "CSAN3.SA")
tickers_agua = c("SAPR4.SA", "SBSP3.SA")
tickers_oleo = c("BRDT3.SA", "UGPA3.SA", "PETR3.SA", "PRIO3.SA", "CSAN3.SA")
tickers_maquina = c("EALT4.SA", "WEGE3.SA", "KEPL3.SA", "ROMI3.SA")

match(tickers_maquina, unique(df.stocks$ticker))
#tickers_avaliando[c(4:7, 10:11, 19, 17)]

data_ini = as.Date("2019-08-02")
investimento_ini = 5000

carteiras = rbind(carteira("energia", tickers_energia),
                  carteira("varejo", tickers_varejo),
                  carteira("agro", tickers_agro),
                  carteira("rodovia", tickers_rodovia),
                  carteira("transporte", tickers_transp),
                  carteira("ferro", tickers_ferro),
                  carteira("antiga", c("VALE3.SA", "PETR3.SA")),
                  carteira("carne", tickers_carne),
                  carteira("calcados", tickers_calcados),
                  carteira("construcao", tickers_construcao),
                  carteira("educ", tickers_educ),
                  carteira("bancos", tickers_banco),
                  carteira("agua", tickers_agua),
                  carteira("telecom", tickers_telecom),
                  carteira("oleo", tickers_oleo),
                  carteira("maquina", tickers_maquina),
                  carteira("saude", tickers_saude),
                  #carteira("avaliando", tickers_avaliando),
                  carteira("meus", c(tickers_meus)))

df.stocks %>%
  #filter(ref.date >= data_ini & ticker %in% c("BOVA11.SA")) %>% 
  filter(ref.date >= data_ini & ticker %in% c("BOVA11.SA", tickers_saude)) %>% 
  #filter(ref.date >= data_ini & ticker %in% c("BOVA11.SA", tickers_carne, tickers_maquina, tickers_educ, tickers_agro, tickers_calcados, tickers_saude)) %>% 
  group_by(ticker) %>%
  mutate(quantidade = investimento_ini/first(price.adjusted),
         total = quantidade * price.adjusted) %>%
  select(ticker, ref.date, price.adjusted, quantidade, total) %>%
  #bind_rows(carteiras) %>% 
  bind_rows(carteiras %>% filter(ticker %in% c("saude"))) %>% 
  #bind_rows(carteiras %>% filter(ticker %in% c("agro", "maquina", "saude", "energia"))) %>%
  mutate(rand = sample(0:3, n(), replace = TRUE),
         label_x = case_when(
           rand == 0 ~ as.Date(now()) + 4,
           rand == 1 ~ as.Date(now()) + 6,
           rand == 2 ~ as.Date(now()) + 8, 
           rand == 3 ~ as.Date(now()) + 10
         )) %>%
  #filter(ref.date == as.Date(now()) - 1) 
  ggplot(aes(ref.date, total, color = ticker)) +
  geom_point() +
  geom_smooth(se = FALSE, span = 0.8) +
  #scale_color_manual(values=distinctColorPalette(42)) +
  geom_text(data=.%>%filter(ref.date == as.Date(now()) - 2), aes(label_x, total, label=ticker), size = 3)


# variação semanal / mensal por ação...

df.stocks %>% 
  filter(ticker %in% tickers_saude) %>%
  filter(ref.date >= as.Date("2019-06-01")) %>%
  group_by(ticker, ref.date) %>%
  mutate(data = floor_date(ref.date, unit = "month")) %>%
  #mutate(data = floor_date(ref.date, unit = "week")) %>%
  select(ticker, data, price.adjusted) %>%
  group_by(ticker, data) %>%
  summarise(return = round(last(price.adjusted)/first(price.adjusted) - 1, digits = 3)) %>%
  ggplot(aes(data, return)) +
  geom_point() +
  geom_bar(stat = "identity") +
  geom_smooth(se = FALSE) + 
  facet_wrap( ~ ticker, ncol=2)

# correlação ...

emp_cor = df.stocks %>% 
  filter(ref.date >= as.Date("2019-07-01")) %>%
  #filter(ticker == "CSNA3.SA") %>%
  #filter(ticker %in% c(tickers_meus, ind_bov, tickers_avaliando)) %>%
  filter(ticker %in% c(tickers_carne, ind_bov)) %>%
  #select(ticker, ref.date, ret.adjusted.prices, price.adjusted) %>%
  select(ticker, ref.date, ret.adjusted.prices) %>%
  spread(ticker, ret.adjusted.prices)

corrplot(cor(emp_cor[2:ncol(emp_cor)]), order = "hclust")


