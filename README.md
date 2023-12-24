
## Stock portfolio analysis 

This mini project enables:

- track realtime results of your stock portfolio (20-minute delay on Google Sheets)
- track historic results of your stock portfolio (downladed quotes (tidyquant)

## Instructions

- Enable the installation of the libraries below if not already installed.

  ```
  install.packages("tidyverse")
  install.packages("readxl")
  install.packages("lubridate")
  install.packages("googledrive")
  install.packages("tidyquant")
  ```

- Fill in the model spreadsheet with your bought and sold positions. The spreadsheet uses Google Finance API features and allows tracking quotations with a 20-minute delay. The spreadsheet is just a template and DOES NOT provide buy/sell suggestions for your portfolio. In the "sold" sheet, there are formulas for calculating income tax, which should be paid each month.

- Update the code with the ID and name of your spreadsheet. The code will automatically download your spreadsheet to the working directory. The drive_find() function will provide a list of names and IDs of files in your Google Drive folder.

  ```
  drive_find(n_max = 30)
  my_spreadsheet = "1H7APdQhZKSnUgFOefXTshJa1AwwW_H7eY3Tg4dgo-ts"
  file_name = "Stocks (template).xlsx"
  ```
- Run script, which will automatically:
  
  - connect to your Google Drive account (OAuth).
  - download the spreadsheet to generate result charts.
  - download daily quotations for each stock (ticker).
  - generate result charts.
  
- If you buy or sell, simply update the spreadsheet and run the script again to analyze your portfolio position.

## Diagram


## Charts