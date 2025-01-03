
def htmlToCsv(htmlF): ##assume only one table
  import pandas as pd, os; from bs4 import BeautifulSoup as bs
  soup = bs(open(htmlF),'html.parser')
  table = soup.find_all('table')
  entries = table[0].find_all('tr')
  fullT = []
  for entry in entries: fullT.append(['\n'.join(cell.find_all(text=True)) for cell in entry])
  if len(fullT) <= 1: return  
  out = pd.DataFrame(fullT[1:],columns=fullT[0])
  out.to_csv(os.path.basename(os.path.splitext(htmlF)[0])+'.csv',index=False)

