alter Procedure [dbo].[SpGetOpenPositionDetails]                  
    (                                    

        @clntid int,    
		@FrmDate Varchar(12),
        @ToDate VarChar(12)                                                             
    )                                                
As                                                
Begin          
      
 set nocount on    
 declare @foclntid int;declare @prevfinyr varchar(12);
 select @foclntid=FOClientId from foclient where clientid=@clntid
 SET @prevfinyr = DATEFROMPARTS(YEAR(@FrmDate) - 1, 4, 1)
 print @prevfinyr
 CREATE TABLE #TempTable (  
    ClientId INT,  
    Instrument VARCHAR(50),  
    Contract VARCHAR(50),  
    Symbol VARCHAR(50),  
    OptionType VARCHAR(10),  
    StrikePrice DECIMAL(18, 2),  
    TradeDate DATE,  
    EndDate DATE,  
    ClosingRate DECIMAL(18, 2),  
    Buy INT,  
    Sell INT,  
    OpenQty Decimal,  
	Type varchar(10),
	AvgRate Decimal(18,3)
 );  
  
 insert into #TempTable  
    SELECT  F.FOCLIENTID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL,Isnull(F.OptionType,'') OptionType, F.StrikePrice,  
	max(F.Trandate) as TradeDate ,max(F1.ENDDATE) as EndDate,avg(F2.Dayclose)ClosingRate,   
    SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END) Buy,      
    SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) Sell,  
	SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END)-SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) as OpenQty,'EQ' ,Avg(Rate) AvgRate
    FROM FOSAUDA F(NOLOCK)
	INNER JOIN FOCONTRACT F1 (NOLOCK) ON F1.INSTRUMENT = F.INSTRUMENT AND F1.SYMBOL = F.SYMBOL AND F1.CONTRACT = F.CONTRACT 
	INNER JOIN fobhavcopy_Full F2  ON  F2.INSTRUMENT = F.INSTRUMENT AND F2.SYMBOL = F.SYMBOL AND F2.CONTRACT = F.CONTRACT 
	AND Isnull(F2.OptionType,'')=Isnull(F.OptionType,'')and F2.Trandate=F.TranDate and F2.StrikePrice=F.StrikePrice     
    WHERE  F.FOCLIENTID = @foclntid   
    --AND F1.CLOSED = 'N'       
    And FinalStlmnt = 'N'       
    And (F.SaudaFlag Not In ('D') )   
	And F.TranDate< @FrmDate  and F.TranDate >= @prevfinyr and F1.ENDDATE >=@FrmDate  
    GROUP BY F.LOCATION, F.FOCLIENTID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL,  Isnull(F.OptionType,''), F.StrikePrice      
    Having SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END)<>SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END)  
	


 insert into #TempTable  
   SELECT DISTINCT  F.CLIENTID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL,  Isnull(F.OptionType,'')OptionType, F.StrikePrice,      
   max(F.Trandate) as TradeDate ,max(F1.ENDDATE) as EndDate,avg(F2.Dayclose)ClosingRate,  
   SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END) Buy,      
   SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) Sell,  
   SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END)-SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) as OpenQty,'CUR',Avg(Rate) AvgRate  
   FROM CDSSAUDA F (NOLOCK)
   INNER JOIN CDSCONTRACT F1 (NOLOCK) ON F1.INSTRUMENT = F.INSTRUMENT AND F1.SYMBOL = F.SYMBOL AND F1.CONTRACT = F.CONTRACT         
   INNER JOIN cdsbhavcopy F2  ON F2.INSTRUMENT = F.INSTRUMENT AND F2.SYMBOL = F.SYMBOL AND F2.CONTRACT = F.CONTRACT AND 
   Isnull(F2.OptionType,'')=Isnull(F.OptionType,'')and F2.Trandate=F.TranDate and F2.StrikePrice=F.StrikePrice
   where f.CLIENTID = @clntid
   --AND F1.CLOSED = 'N'                
   AND f.SaudaFlag <> 'I'      
   AND F.TranDate< @FrmDate  and F.TranDate >= @prevfinyr and F1.ENDDATE >=@FrmDate  
   GROUP BY F.LOCATION, F.CLIENTID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL,  Isnull(F.OptionType,''), F.StrikePrice      
   Having SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END) <>SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END)     



 insert into #TempTable
   SELECT  F.CLIENTID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL,Isnull(F.OptionType,'') OptionType, F.StrikePrice,
   max(F.Trandate) as TradeDate ,max(F1.ENDDATE) as EndDate,avg(F2.ClosingPrice)ClosingRate, 
    SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END) Buy,    
    SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) Sell,
	SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END)-SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) as OpenQty,'CDS',Avg(Rate) AvgRate
    FROM Commodity_Sauda F(NOLOCK) 
	INNER JOIN Commodity_Contract F1 (NOLOCK) ON F1.INSTRUMENT = F.INSTRUMENT AND F1.SYMBOL = F.SYMBOL AND F1.CONTRACT = F.CONTRACT and F1.Product=F.Product
	INNER JOIN Commodity_ClosingPrices F2(NOLOCK) ON  F2.INSTRUMENT = F.INSTRUMENT AND F2.SYMBOL = F.SYMBOL 
	AND F2.CONTRACT = F.CONTRACT AND Isnull(F2.OptionType,'')=Isnull(F.OptionType,'')and F2.Trandate=F.TranDate AND F.StrikePrice=F2.StrikePrice
    WHERE    
	F.CLIENTID = @clntid
    --AND F1.ExpiredFlag = 'N'     
	And F.TranDate<@FrmDate and F.TranDate >= @prevfinyr and F1.ENDDATE >=@FrmDate
    GROUP BY F.LOCATION, F.CLIENTID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL,  Isnull(F.OptionType,''), F.StrikePrice,F.Product    
    Having SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END)<>SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END)


	insert into #TempTable 
	SELECT 0, 0, 0, 0, 0, 0, getdate(), getdate(), 0, 0, 0, 0, 'CDS', 0
	WHERE NOT EXISTS (SELECT 1 FROM #TempTable WHERE Type = 'CDS');  
	insert into #TempTable 
	SELECT 0, 0, 0, 0, 0, 0,getdate(), getdate(), 0, 0, 0, 0, 'EQ', 0
	WHERE NOT EXISTS (SELECT 1 FROM #TempTable WHERE Type = 'EQ'); 
	insert into #TempTable 
	SELECT 0, 0, 0, 0, 0, 0, getdate(), getdate(), 0, 0, 0, 0, 'CUR', 0
	WHERE NOT EXISTS (SELECT 1 FROM #TempTable WHERE Type = 'CUR'); 
	select * from #TempTable
	drop table #TempTable
 end