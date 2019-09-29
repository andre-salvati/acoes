
# Objetivos
 
 - Acompanhamento de cotações no Google Sheets (delay de 20 minutos)
 - Acompanhamento de resultados do seu portfólio de ações na Bovespa
 - Análises de desempenho por setor
 - Simulação de carteiras
 - Cálculo de IR

 
 (colocar gráficos)
 
 
 # Instruções

 - Habilitar a instalação das bibliotecas abaixo, caso não ainda estejam instaladas.
 
 ```r
   install.packages("tidyverse")
   install.packages("readxl")
   install.packages("lubridate")
   install.packages("googledrive")
   install.packages("BatchGetSymbols")
   install.packages("corrplot")
 ```

 - preencher a [planilha modelo](https://docs.google.com/spreadsheets/d/1H7APdQhZKSnUgFOefXTshJa1AwwW_H7eY3Tg4dgo-ts/edit?usp=sharing) de acordo com suas posições compradas e vendidas. A planilha utiliza recursos da API Google Finance e permite acompanhamento 
   das cotações com delay de 20 minutos. A planilha é somente um modelo e NÃO indica sugestões de compra / venda para sua carteira. Na planilha "vendidos" há fórmulas para cálculo de IR, 
   que deve ser recolhido a cada mês.
   
 - atualizar o código com id e nome da sua planilha. O código fará o download automático da sua planilha para pasta de trabalho. 
   A função drive_find() fornecerá a lista dos nomes e ids de arquivos em sua pasta do Google Drive.

 ```r 
   drive_find(n_max = 30)
   minha_planilha = "1H7APdQhZKSnUgFOefXTshJa1AwwW_H7eY3Tg4dgo-ts"
   arquivo = "Ações (modelo).xlsx"
 ```

 - Executar o script, que fará automaticamente:

   - a conexão com sua conta no Google Drive (Oauth) 
   - download da planilha para gerar os gráficos de resultados.
   - download das cotações diárias de cada ação (ticker).
   - geração dos gráficos de resultados.
 
 - Se comprar ou vender, basta atualizar a planilha e executar o script novamente para analisar a posição de sua carteira.
   

