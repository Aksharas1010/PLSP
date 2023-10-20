  
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
    
-- select * from foclient where clientid in (select clientid from client (Nolock) where Rtrim(curlocation)+Rtrim(tradecode) = 'iqm041' )                                  
                         
-- Exec SpTax_GeneratePandL_FO 1041,6764795,1290751074,'2012/04/01','2013/01/31','A',0                                
-- Exec SpTax_GeneratePandL_FO 30159,4393117,1290382433,'2015/01/01','2016/03/31','A',0                                
                              
-- Exec SpTax_GeneratePandL_FO 611404,4393117,1290382433,'2022/04/01','2023/03/31','A',0                                  
IF EXISTS (SELECT 1 FROM sys.procedures WHERE NAME = 'SpTax_GeneratePandL_FO_V1')
BEGIN
	DROP PROCEDURE [dbo].[SpTax_GeneratePandL_FO_V1] 
END
GO                     
CREATE Procedure [dbo].[SpTax_GeneratePandL_FO_V1]                
    (                                  
        @RefId int,                              
        @cln Int,                                  
        @cid int,                              
        @FromDate VarChar(12),                                              
        @ToDate VarChar(12),                                  
        @tnty Char(1)='A',                                 
        @FOProfit Numeric(15,2) output                              
    )                                              
As                                              
Begin        
    
 set nocount on                                              
  Create Table #PurchaseFO                                              
  (                                              
    Slno Int  Not Null Identity(1,1),                                              
    Instrument Varchar(10),                                              
    Symbol Varchar(10),                                              
    Contract Varchar(10),                                              
    Strikeprice Numeric(15,4) Not null default 0,                                               
    OptionType  Varchar(10),                                              
    Security Varchar(50),                                               
    Qty Int Not Null Default 0,                                              
    Value Numeric(15,2) Not Null default 0,                                              
    AllocatedSellQty Int Not Null Default 0,                                              
  )                                              
                                              
  Create Table #SalesFO                                              
  (                                              
    Slno Int  Not Null Identity(1,1),                                              
    Instrument Varchar(10),                                              
    Symbol Varchar(10),                                              
    Contract Varchar(10),                                              
    Strikeprice Numeric(15,4) Not null default 0,                                               
    OptionType  Varchar(10),                                              
    Security Varchar(50),                                              
    Qty Int Not Null Default 0,                                              
    Value Numeric(15,2) Not Null default 0,                                              
    AllocatedPurchaseQty Int Not Null Default 0,                                              
  )                                              
                                              
   Create Table #TrnDetailsFO                                             
    (                                              
        Instrument Varchar(10),                                              
        Symbol Varchar(10),                                              
        Contract Varchar(10),                                              
        Strikeprice Numeric(15,4) Not null default 0,                                          
        OptionType  Varchar(10),                                              
        Trandate datetime Not Null,                                              
        SaudaType Varchar(25) Not Null Default 'NORMAL',                                         
        Bqty Numeric(15,2)  Not Null default 0,       
        BValue Numeric(15,2) Not Null default 0,                  
        BRate Numeric(15,2) Not Null default 0,                                              
        Sqty Numeric(15,2)  Not Null default 0,                                              
        SValue Numeric(15,2) Not Null default 0,                                              
        SRate Numeric(15,2) Not Null default 0,                                              
     slno Int Not null default 0,                                              
      )                                              
                            
  Declare @Ecess Numeric(15,8)                                              
  Declare @FOStampduty Numeric(15,8)                               
                                             
  Set @Ecess=0.02                                              
  Set @FOStampduty=0.000020                              
                                
---Added for getting Old tardecode details on 21-04-2011                                  
                                  
 Declare @oldcln integer                                                  
 Declare @oldcln1 integer                                                  
                                  
 select @oldcln=Clientid from foclient  (Nolock) where FOClientid= @cln                                             
                                        
 Create Table #oldclnsdetFO ( clientid integer,Foclientid  integer)                                  
                                        
 --Create Index IdxClnId on  #oldclnsdetFO(clientid)                                                  
                                        
 Insert  into #oldclnsdetFO  ( clientid )  Values  ( @oldcln )                                                  
                                        
 While @oldcln > 0                                               
 Begin                                                  
  set @oldcln1 = 0                                   
                                        
  select  @oldcln1 = isnull(Clientid, 0)                                     
  from inacln (Nolock)                                              
  Where                                           
   Toclientid = @oldcln   and isnull(clientid,'') <> isnull(Toclientid,'')                                                 
                                        
  Set @oldcln = @oldcln1                                                  
                                        
  if @oldcln > 0                                               
   Insert  into #oldclnsdetFO (clientid ) Values  ( @oldcln )                                                  
 End                                    
                                  
  Update c set c.Foclientid = F.Foclientid                                   
  from #oldclnsdetFO c, Foclient F(nolock)                                  
  where                                   
    c.clientid=f.clientid                                  
--------------------------------------------                                   
                               
 Select distinct CONTRACT,INSTRUMENT,SYMBOL into #contract                               
 From Fosauda (Nolock)                                              
 Where (foclientid in (select Foclientid from #oldclnsdetFO))  And (TranDate <= @ToDate)     -- modified by Abdul Samad On 29.122016 for taking all transactions     And (TranDate >= @FromDate)                            
                              
 Alter table #contract add StDate datetime,EndDate Datetime                              
            
 Update A                              
 Set A.Enddate = fc.ENDDATE                               
 from #contract A                              
 Inner join FOContract fc on fc.CONTRACT =  A.CONTRACT and A.SYMBOL = fc.SYMBOL and a.INSTRUMENT = fc.INSTRUMENT                              
                              
 Update CA                              
 Set ca.StDate = cb.Trandate                              
 from #contract CA      
 Inner join                               
 (                              
  Select A.CONTRACT,A.INSTRUMENT,A.SYMBOL,MIn(A.Trandate) Trandate                              
  From Fosauda A(Nolock)                                              
  Inner join #contract fc on fc.CONTRACT =  A.CONTRACT and A.SYMBOL = fc.SYMBOL and a.INSTRUMENT = fc.INSTRUMENT                              
  Where (A.foclientid in (select Foclientid from #oldclnsdetFO))                                
  group by A.CONTRACT,A.INSTRUMENT,A.SYMBOL                              
 ) CB on CA.CONTRACT = cb.CONTRACT and ca.INSTRUMENT = cb.INSTRUMENT and ca.SYMBOL = cb.SYMBOL                              
       
	   
	   select * from #contract where Enddate  >= @ToDate
   --Added by Abdul Samad on 29.11.2016 to avoid contracts that ended in next Fin.Year                            
 -- delete from #contract where (Enddate <  @FromDate or Enddate  > @ToDate) or (Enddate >= getdate())   -- Modified by Abdul Samad On 29.08.2017 to avoid not expired contracts     
   delete from #contract where (Enddate <  @FromDate ) -- akshara to include next finyear items also

  Select A.*,10000000000.0000 Stmp into #fosauda                                
  From Fosauda A(Nolock)                                              
  Inner join #contract FC on fc.CONTRACT =  A.CONTRACT and A.SYMBOL = fc.SYMBOL and a.INSTRUMENT = fc.INSTRUMENT                              
  where (A.FOCLIENTID in (select Foclientid from #oldclnsdetFO))  And (A.TRANDATE <= @ToDate)      -- Modified by Abdul Samad avoid fromdate   --And (A.TRANDATE >= @FromDate)                            
                          
  Create index idxdtl on #fosauda(INSTRUMENT,SYMBOL,CONTRACT)                                        
                            
  alter table #fosauda alter column SAUDAFLAG char(2)                   
                
 -- alter table #fosauda add constraint df_ExchangeVolume_zero_fo default 0 for Exchangevolume  -- Added By Samson on 06.06.2019                       
                                   
  Update #fosauda set Stmp=0                        
                        
  Update #fosauda set SAUDAFLAG = 'N' Where SAUDAFLAG = 'A' and INSTRUMENT like 'OPT%' --Added by Abdul Samad On 05.05.2017 for taking assignment entries of Option Contract as normal transactions                                                     
                                               
--Jiji 14.07.2009 To find the profit/loss on closed contracts                                          
                                          
   SELECT f.location,f.FOCLIENTID, F.INSTRUMENT, F.CONTRACT, F.SYMBOL,  isnull(F.OptionType,'') OptionType,                     
    F.StrikePrice, f1.enddate,                                          
          SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END) Buy,                                          
          SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) Sell    into #Fopos                                          
   FROM #fosauda F (NoLock) , FOCONTRACT F1 (NoLock)                                           
   WHERE(F1.INSTRUMENT = F.INSTRUMENT) AND                     
        (F1.SYMBOL = F.SYMBOL) AND                     
        (F1.CONTRACT = F.CONTRACT) AND                     
        (F1.CLOSED = 'Y')                     
        --and (F.StrikePrice>0) Commented by Abdul Samad On 31.07.2017                                          
   GROUP BY  f.location,F.FOCLIENTID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL, isnull(F.OptionType,'') , F.StrikePrice,f1.enddate                                         
                                          
   --Added By Abdul Samad  on 31.07.2017 for taking expired quantity transaction                      
   Update F1 set F1.SAUDAFLAG='NC'                     
   From #fosauda F1 , #Fopos F2                      
   Where(F1.INSTRUMENT = F2.INSTRUMENT) AND                                                    
        (F1.SYMBOL = F2.SYMBOL) AND                           
        (F1.CONTRACT = F2.CONTRACT) AND                                                       
        (F1.Trandate = F2.ENDDATE) AND                      
        (F1.SAUDAFLAG='C')                       
                                                      
------------------------------------Added by Abdul Samad On 09.05.2018 to get last transaction of Reintroduced contract -------------------------------                
                  
  Select Max(Trandate) Trandate, F1.INSTRUMENT,F1.CONTRACT,F1.SYMBOL,F1.FOCLIENTID  into #NCPOS                
  From #fosauda F1 , #Fopos F2                
  Where (F1.INSTRUMENT = F2.INSTRUMENT) AND (F1.SYMBOL = F2.SYMBOL) AND (F1.CONTRACT = F2.CONTRACT) AND                 
  (F1.SAUDAFLAG<>'NC') And (F1.FinalStlmnt ='Y')                
  Group by F1.INSTRUMENT,F1.CONTRACT,F1.SYMBOL,F1.FOCLIENTID                
                
  Update F1 set F1.SAUDAFLAG='NC'                
  From #fosauda F1 , #NCPOS F2                
  Where (F1.INSTRUMENT = F2.INSTRUMENT) AND (F1.SYMBOL = F2.SYMBOL) AND (F1.CONTRACT = F2.CONTRACT) AND                
             (F1.Trandate = F2.Trandate) AND (F1.SAUDAFLAG='C')                    
                             
------------------------------------Added by Abdul Samad On 09.05.2018 to get last transaction of Reintroduced contract -------------------------------                
                   
 Delete from #Fopos where Buy=Sell                     
                                           
                                                    
   if @tnty='A'                                        
   Begin                                        
    Insert into #fosauda(LOCATION,TRANSACTIONNO,TRANDATE,FOCLIENTID,INSTRUMENT,CONTRACT,SYMBOL,QTY,BUYSELL,RATE,                                   
       SAUDAFLAG,OptionType, StrikePrice,Saudatype,TRADENO,BROKERAGE,SERVICETAX,SquaredQty,HedgedQty,OpenQty,                                          
       Lastupdatedon,StampDuty,STTSELL,STTbuy,TOLEVY,Stmp,ExchangeVolume)                                          
    Select LOCATION,1,enddate,FOCLIENTID,INSTRUMENT,CONTRACT,SYMBOL,Abs(Buy-Sell),'S',0,'NC',OptionType, StrikePrice,   --Sauda flag changed from 'C' to 'NC' by Samad On 15.03.2017                                       
      'C','1',0,0,0,0,0,getdate(),0,0,0,0,0,0 from #Fopos                                          
where                                           
    Buy-Sell>0                                          
                                          
    Insert into #fosauda(LOCATION,TRANSACTIONNO,TRANDATE,FOCLIENTID,INSTRUMENT,CONTRACT,SYMBOL,QTY,BUYSELL,RATE,                                       
       SAUDAFLAG,OptionType, StrikePrice,Saudatype,TRADENO,BROKERAGE,SERVICETAX,SquaredQty,HedgedQty,OpenQty,                                          
       Lastupdatedon,StampDuty,STTSELL,STTbuy,TOLEVY,Stmp,ExchangeVolume )                                          
    Select LOCATION,1,enddate,FOCLIENTID,INSTRUMENT,CONTRACT,SYMBOL,Abs(Buy-Sell),'B',0,'NC',OptionType, StrikePrice,   --Sauda flag changed from 'C' to 'NC' by Samad On 15.03.2017                                        
       'C','1',0 ,0,0 ,0,0 ,getdate(),0,0,0,0,0,0 from #Fopos                                          
    where                                      
    Buy-Sell<0                                          
 End                                        
                                    
                              
  SELECT f.location,f.FOCLIENTID, F.INSTRUMENT, F.CONTRACT, F.SYMBOL,                                           
  f1.enddate,                              
  SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END) Buy,                                                                  
  SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) Sell    into #FoposISSL                                           
  FROM #fosauda F , FOCONTRACT F1                                         
  WHERE                                                                  
  (F1.INSTRUMENT = F.INSTRUMENT) AND                                                   
  (F1.SYMBOL = F.SYMBOL) AND                                     
  (F1.CONTRACT = F.CONTRACT) AND                                           
  (F1.CLOSED = 'Y') and (F.StrikePrice=0)                                                              
  GROUP BY F.location,F.FOCLIENTID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL,f1.enddate                                                   
                                                       
  Delete from #Fopos where Buy=Sell                                               
                                
  Alter table #FoposISSL add Rate Numeric(15,3)  not null default 0                                        
                                        
  update t set t.rate=c.dayclose from #FoposISSL t,fobhavcopy_Full c (Nolock)                                        
  where                                        
  t.INSTRUMENT=c.Instrument and                                        
  t.SYMBOL=c.Symbol and                                        
t.CONTRACT=c.Contract and                                        
  t.ENDDATE=c.Trandate                                        
                                
  --------------------------------------------------------------                              
 Insert into #fosauda(LOCATION,TRANSACTIONNO,TRANDATE,FOCLIENTID,INSTRUMENT,CONTRACT,                                                  
 SYMBOL,QTY,BUYSELL,RATE,SAUDAFLAG, OptionType, StrikePrice,Saudatype,TRADENO,BROKERAGE,                             
SERVICETAX,SquaredQty,HedgedQty,OpenQty,Lastupdatedon,StampDuty,STTSELL,STTbuy,TOLEVY,Stmp,ManualEntry,ExchangeVolume)                                                            
 Select LOCATION,1,enddate,FOCLIENTID,INSTRUMENT,CONTRACT,SYMBOL,Abs(Buy-Sell),'S',Rate,'C',                                                  
 '' as OptionType, 0 as StrikePrice,'C','1',0,0,0,0,0,getdate(),0,0,0,0,0,'Y',0 from #FoposISSL                                                  
 where Buy-Sell>0                                                       
                                                    
 Insert into #fosauda(LOCATION,TRANSACTIONNO,TRANDATE,FOCLIENTID,INSTRUMENT,CONTRACT,                                                  
 SYMBOL,QTY,BUYSELL,RATE,SAUDAFLAG,OptionType, StrikePrice,Saudatype,TRADENO,BROKERAGE,                                                  
 SERVICETAX,SquaredQty,HedgedQty,OpenQty,Lastupdatedon,StampDuty,STTSELL,STTbuy,TOLEVY,Stmp,ManualEntry,ExchangeVolume )                           
 Select LOCATION,1,enddate,FOCLIENTID,INSTRUMENT,CONTRACT,SYMBOL,Abs(Buy-Sell),'B',Rate,'C',                                                  
 '' as OptionType, 0 as StrikePrice,'C','1',0 ,0,0 ,0,0 ,getdate(),0,0,0,0,0,'Y',0 from #FoposISSL                                                                  
 where Buy-Sell<0                              
                            
 --Added by Abdul Samad to add closing date transaction--                            
 Insert into #fosauda(LOCATION,TRANSACTIONNO,TRANDATE,FOCLIENTID,INSTRUMENT,CONTRACT,                                                
SYMBOL,QTY,BUYSELL,RATE,SAUDAFLAG, OptionType, StrikePrice,Saudatype,TRADENO,BROKERAGE,                                                
SERVICETAX,SquaredQty,HedgedQty,OpenQty,Lastupdatedon,StampDuty,STTSELL,STTbuy,TOLEVY,Stmp,ManualEntry,ExchangeVolume)                               
 Select distinct lOCATION,TRANSACTIONNO,f.TRANDATE,FOCLIENTID,f.INSTRUMENT,f.CONTRACT,                          
 f.SYMBOL,QTY,BUYSELL,A.Dayclose,'NC' SAUDAFLAG, f.OptionType, f.StrikePrice,Saudatype,TRADENO,BROKERAGE,                                                
 SERVICETAX,SquaredQty,HedgedQty,OpenQty,f.Lastupdatedon,StampDuty,STTSELL,STTbuy,TOLEVY,0,ManualEntry,0                             
 From #Fosauda f (Nolock)                               
 inner join focontract fc(nolock) on fc.symbol = f.symbol and fc.instrument = f.instrument and fc.contract = f.contract and fc.endDate = F.Trandate                               
 inner join fobhavcopy_Full A (Nolock) On a.instrument=F.Instrument And a.Symbol=F.Symbol And a.contract=F.contract       
 and a.StrikePrice=F.StrikePrice And Isnull(a.Optiontype,'')=Isnull(F.Optiontype,'') and a.Trandate = F.trandate                                 
 where f.saudaflag ='C' and f.instrument like 'FUT%'                             
 order by trandate                            
--Added by Abdul Samad to add closing date transaction--                            
                            
 --------------------------------------------------------------                                  
                            
                                      
--Jiji 14.07.2009 To find the profit/loss on closed contracts                                                  
                                          
  Update #fosauda set Stmp=Qty*(rate+Strikeprice) *@FOStampduty where Saudaflag='N'                             
                              
                              
    ----------------------------------------  for findout rate updated by sudheer as on 20072016                            
-- Update Tab                            
-- Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)                             
--      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN 0 END                            
-- From #fosauda Tab                            
-- Inner join                            
-- (                            
--  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
--  from GFSL2017.dbo.Security Se                            
--  inner join GFSL2017.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
--  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
--  Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
--    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
-- Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'PE' and tab.INSTRUMENT = 'OPTSTK'                            
                             
-- Update Tab                            
-- Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN 0                             
--      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)  END                            
-- From #fosauda Tab                            
-- Inner join                            
-- (                            
--  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
--  from GFSL2017.dbo.Security Se                            
--  inner join GFSL2017.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
--  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
--  Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                            
--    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
-- Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'CE' and tab.INSTRUMENT = 'OPTSTK'                            
                            
-- Update Tab                            
-- Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)                             
--      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN 0 END                            
-- From #fosauda Tab                            
-- Inner join                         
-- (                            
--  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
--  from GFSL2018.dbo.Security Se                            
--  inner join GFSL2018.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY               
--  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
--Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
--    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
-- Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'PE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                            
                          
-- Update Tab                            
-- Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN 0                             
--      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)  END                            
-- From #fosauda Tab                            
-- Inner join                            
-- (                            
--  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
--  from GFSL2018.dbo.Security Se                            
--  inner join GFSL2018.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
--  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
--  Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
--    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
-- Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'CE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                            
                  
------------------ FY 2018 ------------------------------------------                  
-- Update Tab                            
-- Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)                             
--      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN 0 END                            
-- From #fosauda Tab                            
-- Inner join                            
-- (                            
--  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
--  from GFSL2019.dbo.Security Se                            
--  inner join GFSL2019.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
--  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
--Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
--    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
-- Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'PE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                            
     
 --Update Tab                            
 --Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN 0                             
 --     WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)  END                            
 --From #fosauda Tab                            
 --Inner join                            
 --(                            
 -- Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
 -- from GFSL2019.dbo.Security Se                            
 -- inner join GFSL2019.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
 -- inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
 -- Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
 --   ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
 --Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'CE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                  
 -------------------- FY 2018 ------------------------------------------                  
                 
 ------------------ FY 2019 ------------------------------------------                  
-- Update Tab                            
-- Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)                             
--  WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN 0 END                            
-- From #fosauda Tab                            
-- Inner join                            
-- (                            
--  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
--  from GFSL2020.dbo.Security Se                            
--  inner join GFSL2020.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
--  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
--Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
--    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
-- Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'PE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                            
                             
-- Update Tab                            
-- Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN 0                             
--      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)  END                            
-- From #fosauda Tab                            
-- Inner join                            
-- (                            
--  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
--  from GFSL2020.dbo.Security Se                            
--  inner join GFSL2020.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
--  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
--  Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
--    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
-- Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'CE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                  
 ------------------ FY 2019 ------------------------------------------                 
             
 ------------------ FY 2020 ------------------------------------------                  
 Update Tab                            
 Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)                             
      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN 0 END                            
 From #fosauda Tab                            
 Inner join                            
 (                            
  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
  from GFSL2021.dbo.Security Se                            
  inner join GFSL2021.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
 Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'PE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                            
                             
 Update Tab                            
 Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN 0                             
      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)  END                            
 From #fosauda Tab                            
 Inner join                            
 (                            
  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                    
  from GFSL2021.dbo.Security Se                            
  inner join GFSL2021.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
  Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
 Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'CE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                  
 ------------------ FY 2020 ------------------------------------------          
           
 ------------------ FY 2021 ------------------------------------------                  
 Update Tab                            
 Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)                             
      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN 0 END                            
 From #fosauda Tab                            
 Inner join                            
 (                            
  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
  from GFSL2022.dbo.Security Se                            
  inner join GFSL2022.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
 Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'PE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                            
                             
 Update Tab                            
 Set tab.RATE = CASE WHEN Tab.StrikePrice >= TABB.CLOSINGRATE THEN 0                             
      WHEN Tab.StrikePrice < TABB.CLOSINGRATE THEN ABS(Tab.StrikePrice - TABB.CLOSINGRATE)  END                            
 From #fosauda Tab                            
 Inner join           
 (                            
  Select distinct bc.CLOSINGRATE,bc.TRANDATE,fs.INSTRUMENT,fs.SYMBOL,fs.CONTRACT,fs.OptionType,fs.StrikePrice                            
  from GFSL2022.dbo.Security Se                            
  inner join GFSL2022.dbo.bhavcopy bc on se.SECURITY = bc.SECURITY                             
  inner join #fosauda fs on fs.TRANDATE = bc.TRANDATE and fs.SYMBOL = se.NSECODE                            
  Where bc.PRODUCT = 'NSE' and bc.GROUPCODE = 'EQ' and fs.SAUDAFLAG = 'NC'                             
    ) Tabb on Tab.INSTRUMENT = tabb.INSTRUMENT and tab.SYMBOL = tabb.SYMBOL and tab.CONTRACT = Tabb.CONTRACT and tab.StrikePrice = tabb.StrikePrice and tab.OptionType = Tabb.OptionType                            
 Where tab.SAUDAFLAG = 'NC' and tab.OptionType = 'CE' and tab.INSTRUMENT = 'OPTSTK' AND TAB.RATE = 0                  
 ------------------ FY 2021 ------------------------------------------                 
                
 Update #fosauda Set SAUDAFLAG = case when Rate > 0 then 'EX' Else 'NC' End Where BUYSELL = 'S' and SAUDAFLAG = 'NC'                            
 Update #fosauda Set SAUDAFLAG = case when Rate > 0 then 'AS' Else 'NC' End Where BUYSELL = 'B' and SAUDAFLAG = 'NC'                            
                            
 ----------------------------------------  for findout rate updated by sudheer as on 20072016                                   
                                                         
  Insert Into #PurchaseFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Qty,Value)                                              
  Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),                         
  Sum(Qty),Sum(Qty*(rate))+(Sum(isnull(Brokerage,0))+Sum(isnull(Servicetax,0))+                                    
  Sum(isnull(EducationalCessSTax,0))+                
  Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                  --Uncommented by Abdul Samad                 
  Sum(isnull(TOLEVY,0))+sum(isnull(StampDuty,0)))                                              
  from #fosauda                                              
  where buysell='B'                                     
   and SaudaFlag in ('N','I','NC','AS','EX')                     --Samad                                     
  group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,'')                                              
                                       
  -----------------Client Addition Portfolio Purchase---------------------------------                                       
  Insert Into #PurchaseFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Qty,Value)                                              
  Select Instrument,Symbol,Contract,0,'',Sum(Qty),Sum(Qty*NetRate)                                              
  from ClientAdditionalPortFolioFo (Nolock)                          Where                               
    BuySell='B' And FoClientId in (select Foclientid from #oldclnsdetFO)                                              
  group by Instrument,Symbol,Contract                                              
  ---------------------------------------------------------------------------------                                        
                                            
  Insert Into #TrnDetailsFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,BQty,BValue)                                              
  Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag,                                              
  Sum(Qty),Sum(Qty*(rate))+(Sum(isnull(Brokerage,0))+Sum(isnull(Servicetax,0))+                                    
  Sum(isnull(EducationalCessSTax,0))+               
  Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                   --Uncommented by Abdul Samad                            
  Sum(isnull(TOLEVY,0))+sum(isnull(StampDuty,0)))             
  from #fosauda                                              
  where    buysell='B'                                 
  and SaudaFlag in ('N','I','A','NC','AS','EX')              --Samad                                
 group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag                                              
                                        
  -----------------Client Addition Portfolio Pruchase Details-----------------------                                              
  Insert Into #TrnDetailsFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,BQty,BValue)                                              
  Select Instrument,Symbol,Contract,0,'',TranDate,SaudaType,Sum(Qty),Sum(Qty*NetRate)                                              
  from ClientAdditionalPortFolioFo  (Nolock)                                  
  Where                                   
    BuySell='B' And FoClientId in (select Foclientid from #oldclnsdetFO)                                  
  group by Instrument,Symbol,Contract,TranDate,SaudaType                                              
  ---------------------------------------------------------------------------------                                              
                                           
  Insert Into #SalesFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Qty,Value)                         
  Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),                                              
  Sum(Qty),Sum(Qty*(rate))-(Sum(isnull(Brokerage,0))+Sum(isnull(Servicetax,0))+                                    
  Sum(isnull(EducationalCessSTax,0))+                                              
  Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                   --Uncommented by Abdul Samad                       
  sum(isnull(TOLEVY,0))+sum(isnull(StampDuty,0)))                                              
  from #fosauda                                              
  where                                               
  buysell='S'                                     
  and SaudaFlag in ('N','I','NC','AS','EX', 'E')    --Samad                                              
  group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,'')                                     
                                        
   -----------------Client Addition Portfolio Sales---------------------------------                                              
  Insert Into #SalesFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Qty,Value)                                              
  Select Instrument,Symbol,Contract,0,'',Sum(Qty),Sum(Qty*NetRate)                                              
  from ClientAdditionalPortFolioFo  (Nolock)                                   
  Where                                   
    BuySell='S' And FoClientId in (select Foclientid from #oldclnsdetFO)                                  
  group by Instrument,Symbol,Contract                                              
  ---------------------------------------------------------------------------------                                              
                                              
  Insert Into #TrnDetailsFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,SQty,SValue)                                            
  Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag,                                              
  Sum(Qty),Sum(Qty*(rate))-(Sum(isnull(Brokerage,0))+Sum(isnull(Servicetax,0))+                                    
  Sum(isnull(EducationalCessSTax,0))+                               
  Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                   --Uncommented by Abdul Samad                            
  Sum(isnull(TOLEVY,0))+sum(isnull(StampDuty,0)))                                              
  from #fosauda      
  where                                         
  buysell='S'                                 
    and SaudaFlag in ('N','I','A','NC','AS','EX', 'E')   --Samad                                                     
  group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag                                              
                                        
  -----------------Client Addition Portfolio Sales Details-------------------------                                              
  Insert Into #TrnDetailsFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,BQty,BValue)                                              
  Select Instrument,Symbol,Contract,0,'',TranDate,SaudaType,Sum(Qty),Sum(Qty*NetRate)                                              
  from ClientAdditionalPortFolioFo  (Nolock)                                  
  Where                                   
    BuySell='S' And FoClientId in (select Foclientid from #oldclnsdetFO)                                  
  group by Instrument,Symbol,Contract,TranDate,SaudaType                                              
  ---------------------------------------------------------------------------------                                              
                                        
  Update #PurchaseFO Set Security=Ltrim(rtrim(Instrument))+Ltrim(rtrim(Symbol))+                                              
         Ltrim(rtrim(Contract))+Ltrim(rtrim(Isnull(Strikeprice,0)))+Ltrim(rtrim(Isnull(OptionType,'')))                                              
                                              
  Update #SalesFO Set Security=Ltrim(rtrim(Instrument))+Ltrim(rtrim(Symbol))+                                              
Ltrim(rtrim(Contract))+Ltrim(rtrim(Isnull(Strikeprice,0)))+Ltrim(rtrim(Isnull(OptionType,'')))                                              
                                                    
-- Allocation Starts                                              
  Declare @Pqty Numeric(15,2)                                              
    Declare @Pslno Numeric(15,2)                                              
    Declare @Sqty Numeric(15,2)                                              
    Declare @Sslno Numeric(15,2)                                              
    Declare @sec Varchar(50)                                           
                                                 
    Declare Pur Cursor for                                              
    Select Security,Slno,Qty-AllocatedSellQty from #PurchaseFO Where (Qty-AllocatedSellQty)>0                                              
    Open Pur                 
    Fetch Next From Pur into @sec,@Pslno,@Pqty                                              
    WHILE @@FETCH_STATUS = 0                                               
    Begin                                              
       Declare Sl Cursor for                                              
       Select Slno,Qty-AllocatedPurchaseQty from #SalesFO Where Security=@sec  and (Qty-AllocatedPurchaseQty)>0                               
       Open Sl                                              
       Fetch Next From Sl into @Sslno,@Sqty                                              
       WHILE @@FETCH_STATUS = 0                                          
       Begin                                              
           If @Pqty>0                                              
           Begin                                              
             If @Sqty>=@Pqty                                               
             Begin                                              
                Update #SalesFO Set AllocatedPurchaseQty=AllocatedPurchaseQty+@Pqty Where Security=@sec And Slno=@Sslno                                              
               Update #PurchaseFO Set AllocatedSellQty=AllocatedSellQty+@Pqty Where Security=@sec And Slno=@Pslno                                              
      Set @Pqty=0                                              
          End                                              
             Else                                              
             Begin                                               
                Update #SalesFO Set AllocatedPurchaseQty=AllocatedPurchaseQty+@Sqty Where Security=@sec And Slno=@Sslno                                              
                Update #PurchaseFO Set AllocatedSellQty=AllocatedSellQty+@Sqty Where Security=@sec And Slno=@Pslno                                              
                Set @Pqty=@Pqty-@Sqty                                       
             End                                              
           End                                              
           Fetch Next From Sl into @Sslno,@Sqty                                              
       End                                              
       Close Sl                                              
       Deallocate Sl                                              
       Fetch Next From Pur into @sec,@Pslno,@Pqty                                              
    End                                   
    Close Pur                                              
    Deallocate Pur                                              
-- Allocation Ends                                              
                                              
      ---@@--                            
  --select * from #SalesFO where  SYMBOL = 'ASHOKLEY' --order by TRANDATE                             
  --select * from #PurchaseFO where  SYMBOL = 'ASHOKLEY'                            
  --return                              
                            
                               
    Create Table #SumTempFO                                              
    (                                              
      Instrument Varchar(10),                                              
      Symbol Varchar(10),                                              
      Contract Varchar(10),                                              
      Strikeprice Numeric(15,4) Not null default 0,                                               
      OptionType  Varchar(10),                      
      Security Varchar(50),                                              
      SQPurchaseQty Numeric(15,2)  Not Null default 0,                                              
      SQPurchaseValue Numeric(15,2) Not Null default 0,                                              
      SQSaleQty Numeric(15,2)  Not Null default 0,                                              
      SQSaleValue Numeric(15,2) Not Null default 0,                                              
      BalPurchaseQty Numeric(15,2)  Not Null default 0,                                              
      BalPurchaseValue Numeric(15,2) Not Null default 0,                         
      BalSaleQty Numeric(15,2)  Not Null default 0,                                              
      BalSaleValue Numeric(15,2) Not Null default 0,            
     )                                              
                                                  
    Insert Into #SumTempFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,                                              
             SQPurchaseQty,SQPurchaseValue,BalPurchaseQty,BalPurchaseValue)                                              
    Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,AllocatedSellQty,(AllocatedSellQty*Round(Value/Qty,2)),                                              
 (Qty-AllocatedSellQty),(Qty-AllocatedSellQty)*(Value/Qty)                                              
    From #PurchaseFO                                               
                                              
    Insert Into #SumTempFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,                                              
             SQSaleQty,SQSaleValue,BalSaleQty,BalSaleValue)                               
    Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,AllocatedPurchaseQty,(AllocatedPurchaseQty*Round(Value/Qty,2)),                                              
    (Qty-AllocatedPurchaseQty),(Qty-AllocatedPurchaseQty)*(Value/Qty)                                  
    From #SalesFO                                               
                                                               
    Create Table #SumTblFO                                              
    (                                              
      Instrument Varchar(10),                                              
      Symbol Varchar(10),                                              
Contract Varchar(10),                                              
      Strikeprice Numeric(15,4) Not null default 0,                                               
      OptionType  Varchar(10),                            
  Security Varchar(50),                                              
      SQPurchaseQty Numeric(15,2)  Not Null default 0,                                     
      SQPurchaseValue Numeric(15,2) Not Null default 0,                                              
      SQSaleQty Numeric(15,2)  Not Null default 0,                                   
      SQSaleValue Numeric(15,2) Not Null default 0,                                              
      BalPurchaseQty Numeric(15,2)  Not Null default 0,                                              
      BalPurchaseValue Numeric(15,2) Not Null default 0,                                              
      BalSaleQty Numeric(15,2)  Not Null default 0,                                              
      BalSaleValue Numeric(15,2) Not Null default 0,                                                
   RealizedPanL Numeric(15,2) Not Null Default 0,                                              
      ClosingRate Numeric(15,2) Not Null Default 0,                                              
      UnRealizedPanL Numeric(15,2) Not Null Default 0,                                              
      Avg_price Numeric(15,2)  Not Null default 0,                                              
      Closed Varchar(1) not null default 'N'                                          
    )                                              
                                              
     Insert #SumTblFO (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,SQPurchaseQty,SQPurchaseValue,SQSaleQty,                                              
            SQSaleValue,BalPurchaseQty,BalPurchaseValue,BalSaleQty,BalSaleValue)                                              
     Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,Sum(SQPurchaseQty),Sum(SQPurchaseValue),Sum(SQSaleQty),                                              
            Sum(SQSaleValue),Sum(BalPurchaseQty),Sum(BalPurchaseValue),Sum(BalSaleQty),Sum(BalSaleValue)                                              
     From #SumTempFO                                   
     Group By Instrument,Symbol,Contract,Strikeprice,OptionType,Security                                              
                                              
-- Update Closing rate                                              
     Update #SumTblFO  set #SumTblFO.ClosingRate=FoBhavCopy.Dayclose from #SumTblFO, FoBhavCopy (Nolock)                           
     Where  #SumTblFO.instrument=FoBhavCopy.Instrument And                                  
     #SumTblFO.Symbol=FoBhavCopy.Symbol And                                              
     #SumTblFO.contract=FoBhavCopy.contract and                                     
     #SumTblFO.StrikePrice=FoBhavCopy.StrikePrice And                                              
     Isnull(#SumTblFO.Optiontype,'')=Isnull(FoBhavCopy.Optiontype,'') And (#SumTblFO.BalSaleQty+#SumTblFO.BalPurchaseQty)>0                                       
                                          
                                          
-- 08.07.2009 Jiji                                           
                                                          
     Select F.* into #fobhavcopy_Full From fobhavcopy_Full F (Nolock), #SumTblFO s                                          
     Where  s.instrument=f.Instrument And                                               
     s.Symbol=f.Symbol And                                   
s.contract=f.contract  and                                          
     Isnull(s.Optiontype,'')=Isnull(f.Optiontype,'') And                                           
     s.StrikePrice=f.StrikePrice And                                          
     s.ClosingRate=0                                          
                                          
    Select Instrument, Symbol,     Contract ,  Isnull(Optiontype,'') Optiontype ,StrikePrice ,max(Trandate) Trandate                                   
    into #finaldateRate from #fobhavcopy_Full                                          
    Group by Instrument, Symbol,  Contract ,  Isnull(Optiontype,'')  ,StrikePrice                                          
                                          
     Select F.* into #fobhavcopy_Fullrate From #fobhavcopy_Full F, #finaldateRate s                                          
     Where  s.instrument=f.Instrument And                       
     s.Symbol=f.Symbol And                                              
     s.contract=f.contract  and                                          
     Isnull(s.Optiontype,'')=Isnull(f.Optiontype,'') And                                           
     s.StrikePrice=f.StrikePrice And                                           
     s.trandate=f.trandate                                         
                                          
     Update #SumTblFO  set #SumTblFO.ClosingRate=#fobhavcopy_Fullrate.DayClose from #SumTblFO, #fobhavcopy_Fullrate (Nolock)                                              
     Where  #SumTblFO.instrument=#fobhavcopy_Fullrate.Instrument And                                     
     #SumTblFO.Symbol=#fobhavcopy_Fullrate.Symbol And                                              
     #SumTblFO.contract=#fobhavcopy_Fullrate.contract  and                                          
     Isnull(#SumTblFO.Optiontype,'')=Isnull(#fobhavcopy_Fullrate.Optiontype,'') And                                           
     #SumTblFO.StrikePrice=#fobhavcopy_Fullrate.StrikePrice and                                          
     #SumTblFO.ClosingRate=0                                          
                          
                                           
  ---Jiji 8.5.2009 to update closing rate for non update rows from foclosing rate                                          
                                          
     Select * into #FOclosingrate from FOclosingrate (Nolock)                                          
     Where                                          
     Trandate = (Select max(Trandate) from FOclosingrate (Nolock))                                          
                                          
     Update #SumTblFO  set #SumTblFO.ClosingRate=#FOclosingrate.CLOSINGRATE from #SumTblFO, #FOclosingrate (Nolock)                                              
     Where  #SumTblFO.instrument=#FOclosingrate.Instrument And                                               
     #SumTblFO.Symbol=#FOclosingrate.Symbol And                                              
     #SumTblFO.contract=#FOclosingrate.contract  and                                          
     #SumTblFO.ClosingRate=0                                          
                                          
   /*         Samad                              
  ---Jiji 8.5.2009 to update closing rate for non update rows from foclosing rate                                          
                                              
     Update #SumTblFO set RealizedPanL=SQSaleValue-SQPurchaseValue                                              
                    
     Update #SumTblFO set UnRealizedPanL=(BalSaleValue)-((BalSaleQty)*(ClosingRate))                                     
     Where BalSaleQty>0                                     
                                              
     Update #SumTblFO set UnRealizedPanL=((BalPurchaseQty)*(ClosingRate))-(BalPurchaseValue)                                              
     Where BalPurchaseQty>0                                              
                         
     Update #SumTblFO Set Avg_price=Round(BalPurchaseValue/BalPurchaseQty,2) where BalPurchaseQty>0 and BalPurchaseValue>0                                              
                                              
     Update #SumTblFO Set Avg_price=Round(BalSaleValue/BalSaleQty,2) where BalSaleQty>0 and BalSaleValue>0                                              
                                   
    */                                       
                                              
     Update #SumTblFO set SQSaleQty=SQSaleQty+BalSaleQty,                                              
                        SQSaleValue=SQSaleValue+BalSaleValue from #SumTblFO Where BalSaleQty>0                                              
                                            
     Update #SumTblFO set SQPurchaseQty=SQPurchaseQty+BalPurchaseQty,                                              
                     SQPurchaseValue=SQPurchaseValue+BalPurchaseValue from #SumTblFO Where BalPurchaseQty>0                                              
                                              
     Update #TrnDetailsFO set BRate=BValue/Bqty where Bqty>0 and BValue>0                                       
     Update #TrnDetailsFO set SRate=SValue/Sqty where Sqty>0 and SValue>0                                   
                            
  -----Samad----------------------                            
  Update S set S.UnRealizedPanL = 0 ,BalPurchaseQty = 0 ,BalSaleqty = 0,Avg_Price=0 ,Closed='Y'                                         
     from #SumTblFO S , FOContract F                                          
     where S.Instrument = F.Instrument  and S.Symbol=F.Symbol and S.Contract = F.Contract and F.Closed='Y'                                               
                                                    
      Update #SumTblFO set RealizedPanL=SQSaleValue-SQPurchaseValue  where Closed='Y'                             
   -----Samad----------------------                            
                                  
     /*--Added by naufal on 27.08.2012,Rqstd by ranjith (CC)  --*/                                 
     Declare @NetPandL numeric(15,2),@NetpurchaseValue numeric(15,2),@NetSalesValue Numeric(15,2)       
                                     
     Select @NetpurchaseValue = Sum(SQPurchaseValue),                                
            @NetSalesValue    = Sum(SQSaleValue),                                
            @NetPandL         = Sum(RealizedPanL+UnRealizedPanL)                                
            from #SumTblFO                                
     /*--Added by naufal on 27.08.2012,Rqstd by ranjith (CC) ! --*/                                                      
                                              
     --Select Instrument,Symbol,Contract,Strikeprice,OptionType,SQPurchaseQty,SQPurchaseValue,SQSaleQty,SQSaleValue,                                              
     --RealizedPanL,(BalPurchaseQty-BalSaleqty) OpenPos,Avg_price,                                              
     --ClosingRate,(BalPurchaseQty+BalSaleqty)*Avg_price OpenPosValue,                                              
     --(BalPurchaseQty+BalSaleqty)*Closingrate Market_value,                                              
     --UnRealizedPanL,RealizedPanL+UnRealizedPanL Total_PandL,                                
     --@NetpurchaseValue NetpurchaseValue,@NetSalesValue NetSalesValue,@NetPandL NetPandL                                              
     --from #SumTblFO Order By Instrument,Symbol,Contract,Strikeprice,OptionType               
                                              
     If @tnty='N'                                               
       Delete from #TrnDetailsFO where SaudaType in ('O','C')                                              
                                                  
                                  
     Update #TrnDetailsFO set SaudaType='OPEN',slno=1 where SaudaType='O'                                              
     Update #TrnDetailsFO set SaudaType='NORMAL',slno=2 where SaudaType in ('N','I')                              
     Update #TrnDetailsFO set SaudaType='CLOSE',slno=4 where SaudaType='C'                                              
     Update #TrnDetailsFO set SaudaType='ADJUSTMENT',slno=5 where SaudaType='J'                     
     Update #TrnDetailsFO set SaudaType='EXERCISE',slno=6 where SaudaType='E'                                              
     Update #TrnDetailsFO set SaudaType='ASSIGNMENT',slno=7 where SaudaType='A'                                              
     Update #TrnDetailsFO set SaudaType='EXPIRY',slno=8,BRate=0,SRate=0 where SaudaType='X'                               
                             
  ----                            
                                  
  --     --##--                           
  --select * from #SumTblFO where Contract = '28APR2016' and Symbol = 'DLF'                             
  -- return                            
     --Truncate table Tax_Profit_FO_Details                              
                              
     --insert into Tax_Profit_FO_Details                              
     Insert into Tax_Profit_Details_Derivative                              
     (Refid,clientid,type,Instrument,Symbol,Contract,Strikeprice,OptionType,Security,SQPurchaseQty,SQPurchaseValue,SQSaleQty,SQSaleValue,                              
     RealizedPanL,Euser,LastUpdatedOn)                              
     select @RefId,@cid,'F&O',Instrument,Symbol,Contract,Strikeprice,OptionType,Security,SQPurchaseQty,SQPurchaseValue,SQSaleQty,SQSaleValue,                              
     RealizedPanL,'System',getdate() from #SumTblFO                              
                                    
                            
                              
     --Select Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,Bqty,BRate,Sqty,SRate                                              
     --from #TrnDetailsFO                                   
     --Order By Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,slno                                              
                                  
                                  
  /*For Displaying Total*/                                  
                              
                              
  -- jiji 04.07.2016 For Barjeel Clients With Vipin                              
  Select Instrument,Symbol,Contract,Strikeprice,OptionType,Sum(BQty) BQty,Sum(SQty) SQty into #NormalQty from  #TrnDetailsFO                              
  where SaudaType not in ('OPEN','CLOSE')                              
  Group by Instrument,Symbol,Contract,Strikeprice,OptionType                              
                              
  update t set t.ActualPurchaseQty=s.BQty,                              
     t.ActualSalesQty=s.SQty  from Tax_Profit_Details_Derivative t,#NormalQty s                              
  where t.clientid = @cid and                              
   t.Refid= @RefId and                              
   t.Instrument=s.instrument and                              
   t.Symbol=s.Symbol and                            
   t.Contract=s.Contract and                              
   t.Strikeprice=s.Strikeprice and                              
   t.OptionType=s.OptionType                              
                              
                              
     Update S  set S.ContractClosingRate=F.DayClose from Tax_Profit_Details_Derivative s, #fobhavcopy_Fullrate F                              
     Where                                
  S.clientid = @cid and                              
  s.Refid= @RefId and                                
  S.instrument=F.Instrument And                                     
     S.Symbol=F.Symbol And                                              
     S.contract=F.contract  and                                          
     Isnull(S.Optiontype,'')=Isnull(F.Optiontype,'') And                                           
     S.StrikePrice=F.StrikePrice               
                              
  -- jiji 04.07.2016 For Barjeel Clients With Vipin                              
                              
  Select @FOProfit=sum(RealizedPanL) from #SumTblFO                    
                                
  Select @FOProfit                               
                                  
End   