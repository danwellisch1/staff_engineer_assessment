import pandas as pd
import glob
import pyodbc
from datetime import datetime



class ETL:


  def importToDfs(self):
    path = 'data_inputs'
    extension = 'xlsx'
    files = [i for i in glob.glob('*.{}'.format(extension))]
    self.fileDate = files[0].split('.xlsx')[0][-6:]

    self.fileDate = datetime.strptime(self.fileDate, '%m%d%y')

    self.providerGroup = files[0].split('.xlsx')[0][:-6]

    #print(self.fileDate)
    #print(self.providerGroup)

    # Create main df.

    # Drop first 3 rows.  In a production app, I would write code to determine what rows 
    # to drop and not just hard code it to 3 rows.  When you read a data file from a customer,
    # you want to break-proof it as much as possible from client changes...
    self.df = pd.read_excel(files[0], skiprows=3, names= ['Dummy','ID','FirstName','MiddleName', 'LastName','DOB','Sex','FavoriteColor','AttributedQ1','AttributedQ2','RiskQ1','RiskQ2','RiskIncreasedFlag']) 

    #print(self.df)

    # Don't need 1st column.
    self.df = self.df.drop(self.df.columns[0], axis=1)

    # Retrieve only data rows with a numeric data type in the ID column.
    self.df = self.df[pd.to_numeric(self.df.ID, errors='coerce').notnull()]

    self.df['Sex'] = self.df['Sex'].apply({0:'M', 1:'F'}.get)

    self.df['MiddleName'] = self.df['MiddleName'].str[:1].fillna('')

    self.df['FileDate'] = self.fileDate

    

    # Create pivoted df for RiskByQtr table.
    dfQtrAttr = self.df[['ID', 'AttributedQ1', 'AttributedQ2']].copy()
    dfQtrAttr.rename(columns={'AttributedQ1': 'Q1', 'AttributedQ2': 'Q2'}, inplace=True)
    meltedDfQtrAttr = pd.melt(dfQtrAttr, id_vars=["ID"], 
                 var_name="Qtr", value_name="AttributedFlag")

    # print(self.df['RiskQ2'])

    dfQtrRisk = self.df[['ID', 'RiskQ1', 'RiskQ2']].copy()
    dfQtrRisk.rename(columns={'RiskQ1': 'Q1', 'RiskQ2': 'Q2'}, inplace=True)
    meltedDfQtrRisk = pd.melt(dfQtrRisk, id_vars=["ID"], 
                 var_name="Qtr", value_name="Risk")

    dfFDIncrRisk = self.df[['ID', 'FileDate', 'RiskIncreasedFlag']].copy()

    dfMergeTwo = pd.merge(meltedDfQtrAttr, meltedDfQtrRisk, on=['ID','Qtr'])
    self.dfRiskByQtr = pd.merge(dfMergeTwo, dfFDIncrRisk, on=['ID'])

    self.dfRiskByQtr = self.dfRiskByQtr[self.dfRiskByQtr['RiskIncreasedFlag'] == 'Yes']
    #print(self.dfRiskByQtr)

  def exportToDemographicsTable(self):
    connStr = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server}; SERVER=DESKTOP-6DG59DJ; DATABASE=PersonDatabase;Trusted_Connection=yes')
    cursor = connStr.cursor()

    for index,row in self.df.iterrows():
        cursor.execute("INSERT INTO dbo.Demographics([ID], [ProviderGroup], [FileDate],[FirstName], [MiddleName], [LastName], [DOB], [Sex], [FavoriteColors]) values (?,?,?,?,?,?,?,?,?)", row['ID'], self.providerGroup, self.fileDate, row['FirstName'], row['MiddleName'], row['LastName'],  row['DOB'], row['Sex'], row['FavoriteColor']) 
    connStr.commit()
    cursor.close()
    connStr.close()

  def exportToRiskByQtrTable(self):

    connStr = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server}; SERVER=DESKTOP-6DG59DJ; DATABASE=PersonDatabase;Trusted_Connection=yes')
    cursor = connStr.cursor()

    for index,row in self.dfRiskByQtr.iterrows():
        cursor.execute("INSERT INTO dbo.RiskByQuarter([ID], [Qtr], [AttributedFlag],[Risk], [FileDate]) values (?,?,?,?,?)", row['ID'], row['Qtr'], row['AttributedFlag'], row['Risk'],  row['FileDate']) 
    
    connStr.commit()
    cursor.close()
    connStr.close()

  def printDf(self):
    print(self.df)


etl = ETL()
etl.importToDfs()
etl.exportToDemographicsTable()
etl.exportToRiskByQtrTable()
#etl.printDf()


    

