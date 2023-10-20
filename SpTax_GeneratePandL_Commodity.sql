alter Procedure [dbo].[SpTax_GeneratePandL_Commodity]               
(                  
 @RefId int,                  
 @cln Int,                      
 @FromDate VarChar(12),                      
 @ToDate VarChar(12),                      
 @tnty Char(1)='A',              
 @CMDProfit Numeric(15,2) output                     
)                      
As                      
Begin                      
set nocount on                    
                
Create Table #PurchaseCOM                      
(                      
 Slno Int  Not Null Identity(1,1),                      
 Instrument Varchar(10),                      
 Symbol Varchar(10),                      
 Contract Varchar(10),                      
 Strikeprice Numeric(15,4) Not null default 0,                      
 OptionType  Varchar(10),                      
 Security Varchar(50),                      
 Units Int Not Null Default 0,                      
 Value Numeric(15,2) Not Null default 0,                      
 AllocatedSellQty Int Not Null Default 0,                      
 contValue Numeric(15,2) Not Null default 0,  
 Product varchar(250) null
)                      
                      
Create Table #SalesCOM                      
(                      
 Slno Int  Not Null Identity(1,1),                      
 Instrument Varchar(10),                      
 Symbol Varchar(10),                      
 Contract Varchar(10),                      
 Strikeprice Numeric(15,4) Not null default 0,                      
 OptionType  Varchar(10),                      
 Security Varchar(50),                      
 Units Int Not Null Default 0,                      
 Value Numeric(15,2) Not Null default 0,                      
 AllocatedPurchaseQty Int Not Null Default 0,                      
 contValue Numeric(15,2) Not Null default 0,
  Product varchar(250) null

)                      
Create Table #TrnDetailsCOM                              
(                      
 Instrument Varchar(10),                      
 Symbol Varchar(10),                      
 Contract Varchar(10),                      
 Strikeprice Numeric(15,4) Not null default 0,                      
 OptionType  Varchar(10),                      
 Trandate datetime Not Null,                      
 SaudaType Varchar(25) Not Null Default 'NORMAL',                      
 Bqty Numeric(15,2)  Not Null default 0,                      
 BValue Numeric(18,2) Not Null default 0,                      
 BRate Numeric(15,4) Not Null default 0,                      
 Sqty Numeric(15,2)  Not Null default 0,                      
 SValue Numeric(18,2) Not Null default 0,                      
 SRate Numeric(15,4) Not Null default 0,                      
 slno Int Not null default 0,  
  Product varchar(250) null

)                      
                      
Declare @Ecess Numeric(15,8)  --(6,2)                      
Declare @SPStampduty Numeric(15,8) --(6,4)                      
--Declare @cdsStampduty Numeric(15,8)    --(6,4)   Commented by Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                  
                      
                      
Set @Ecess=0.02                      
Set @SPStampduty=0.00002                  
--Commented by Anish on 05.12.2012 as per Jiji Sir's Advice to avoid open close mismatch               
--Set @cdsStampduty=0--.000020         Commented by Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                  
                
-- jiji 16.07.2007                                                 
Select *,'N' contract_Closed,cast('01/01/1900' as Datetime)                         
as EndDate,                 
--@cdsStampduty as CdsStampduty       Commented by Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                    
0 as CdsStampduty                      
into #CommoditySauda  From Commodity_Sauda (Nolock)                        
where                        
(clientid=@cln) And TranDate <= @ToDate --Between @FromDate And Commented by Govind on 28.09.2022               
            
--alter table #CommoditySauda add constraint df_ExchangeVolume_zero_cd default 0 for ExchangeVolume  -- Added By Samson on 06.06.2019                     
                      
--Jiji/Suresh 26.07.2011 to nullify Option open positions for closed contract                            
                      
Update S Set S.contract_Closed='Y',S.EndDate=C.EndDate from #CommoditySauda S,Commodity_Contract  C (Nolock)                      
Where                      
(S.Instrument=C.Instrument) and                      
(S.Symbol=C.Symbol) and                      
(S.Contract=C.Contract) and                      
(C.ExpiredFlag='Y') and                      
(C.EndDate<= @ToDate) 
and S.Product=C.Product
                   
Select Product,Location,Clientid,Instrument,Symbol,Contract,Strikeprice,OptionType,EndDate,Buysell,Units,Sum(qty)qty  into #optopen from #CommoditySauda                      
Where                      
isnull(strikeprice,0)>0 And (contract_Closed='Y')                      
Group by Product,Location,Clientid,Instrument,Symbol,Contract,Strikeprice,OptionType,Buysell,EndDate,Units                      
                      
Update #optopen set qty=qty*-1                      
where Buysell='S'                      
                      
Select Product,Location,Clientid,Instrument,Symbol,Contract,Strikeprice,OptionType,EndDate,Units,Sum(qty) qty into #optopen1 from #optopen                      
Group by Product,Location,Clientid,Instrument,Symbol,Contract,Strikeprice,OptionType,EndDate,Units                      
                      
Delete from #optopen1 where   qty = 0                      
                      
Alter table #optopen1                      
Add Transactionno integer not null identity(1,1)                      
    
alter table #CommoditySauda add SaudaFlag varchar(10) null
alter table #CommoditySauda add SquaredQty decimal(18,3) null,HedgedQty decimal(18,3)  null,OpenQty decimal(18,3) null,
StampDutyPer decimal(18,3) null,StampDutyMin decimal(18,3) null,StampDutyMax decimal(18,3) null

Insert into #CommoditySauda(Transactionno,Product,Location,TranDate,ClientID,Instrument,Contract,Symbol,                      
Units,qty,BuySell,Rate,
SaudaFlag,
OptionType,StrikePrice,                      
SaudaType,TradeNo,Brokerage,ServiceTax,
SquaredQty,HedgedQty,OpenQty,
Lastupdatedon,
StampDutyPer,StampDutyMin,StampDutyMax,
IntraDaySquaredQty,contract_Closed,TOLEVY,Euser,CdsStampduty,ExchangeVolume)                      
Select Transactionno,Product,Location,EndDate,Clientid,Instrument,Contract,Symbol,Units,qty,'S',0,'X',                      
OptionType,StrikePrice,'C' ,'' ,0,0,0 ,0,0  ,getdate(),0,0,0 , 0 ,'Y',0 ,'Jiji',0,0 From #optopen1                      
Where                      
Qty>0                      
                      
                      
Insert into #CommoditySauda(Transactionno,Product,Location,TranDate,ClientID,Instrument,Contract,Symbol,                      
Units,qty,BuySell,Rate,
SaudaFlag,
OptionType,StrikePrice,                      
SaudaType,TradeNo,Brokerage,ServiceTax,
SquaredQty,HedgedQty,OpenQty,
Lastupdatedon,
StampDutyPer,StampDutyMin,StampDutyMax,
IntraDaySquaredQty,contract_Closed,TOLEVY,Euser,CdsStampduty,ExchangeVolume)                      
Select Transactionno,Product,Location,EndDate,Clientid,Instrument,Contract,Symbol,Units,abs(qty),'B',0,                      
'X',OptionType,StrikePrice,'C' ,'' ,0,0,0 ,0,0  ,getdate(),0,0,0 , 0 ,'Y' ,0 ,'Jiji',0,0 From #optopen1                      
Where                        
Qty<0        
select * from #CommoditySauda

update #CommoditySauda set SaudaFlag='N' where SaudaFlag is NULL

-----------------added by Govind on 29-09-2022    
Update S Set S.contract_Closed='Y',S.EndDate=C.EndDate from #CommoditySauda S,Commodity_Contract  C (Nolock)                      
Where                      
(S.Instrument=C.Instrument) and                      
(S.Symbol=C.Symbol) and                      
(S.Contract=C.Contract) and        
--(C.Closed='Y') and                      
(C.EndDate<= @ToDate)    
and (c.Product=S.Product)
-----------------end by     
                                                       
update #CommoditySauda set units=qty * units                 
              
------------------------------------Abdul Samad On 06.03.2017 for GBNPP_SUP-1485 (split stamp duty for each trade)-------------------------------------------------------------------------------------------------------              
select TranDate,Product,Location,ClientID,Instrument,Contract,Symbol,sum(Units * Rate)Volume,sum(isnull(StampDuty,0)) as StampDuty into #ConsolidatedStampDuty               
from #CommoditySauda              
group by TranDate,Product,Location,ClientID,Instrument,Contract,Symbol              
              
update A set StampDuty = (a.Units * a.Rate * B.StampDuty) / B.Volume              
from #CommoditySauda A , #ConsolidatedStampDuty B               
where A.TranDate = b.TranDate and  a.Product = b.Product and a.Location = b.Location and a.Instrument = b.Instrument and a.Contract = b.Contract and a.Symbol = b.Symbol           
and B.Volume <> 0 --Abdul Samad On 20.12.2017              
              
select min(Transactionno) Transactionno,a.TranDate,a.Product,a.Location,a.ClientID,a.Instrument,a.Contract,a.Symbol,sum(a.StampDuty) -  b.StampDuty diff into #Diff_StampDuty              
 from #CommoditySauda a, #ConsolidatedStampDuty B               
where A.TranDate = b.TranDate and a.product = b.Product and a.Location = b.Location and a.Instrument = b.Instrument and a.Contract = b.Contract and a.Symbol = b.Symbol                       
group by a.TranDate,a.Product,a.Location,a.ClientID,a.Instrument,a.Contract,a.Symbol, b.StampDuty              
              
update A Set StampDuty = A.StampDuty - B.Diff              
from #CommoditySauda A , #Diff_StampDuty B Where A.TransactionNo = B.Transactionno     
    
    
---findout closed contracts----------------------Added by Govind on 29.09.2022    
    
    
 delete from #CommoditySauda where (Enddate <  @FromDate or Enddate  > @ToDate) or (Enddate >= getdate())      
    
 SELECT f.location,f.ClientID, F.INSTRUMENT, F.CONTRACT, F.SYMBOL,  isnull(F.OptionType,'') OptionType,                   
    F.StrikePrice, f1.enddate,                                        
          SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END) Buy,                                        
          SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) Sell,
		  F.Product
    into #COMpos                                        
   FROM #CommoditySauda F (NoLock) , Commodity_Contract F1 (NoLock)                                         
   WHERE(F1.INSTRUMENT = F.INSTRUMENT) AND                   
        (F1.SYMBOL = F.SYMBOL) AND                   
        (F1.CONTRACT = F.CONTRACT) 
		AND                   
       (F1.EXPIREDFLAG = 'Y')
		and(F1.Product=F.Product)
        --and (F.StrikePrice>0) Commented by Abdul Samad On 31.07.2017                                        
   GROUP BY  f.location,F.ClientID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL, isnull(F.OptionType,'') , F.StrikePrice,f1.enddate,F.Product                                       
                                        
   --Added By Abdul Samad  on 31.07.2017 for taking expired quantity transaction                    
   Update F1 set F1.SAUDAFLAG='W'                   
   From #CommoditySauda F1 , #COMpos F2                    
   Where(F1.INSTRUMENT = F2.INSTRUMENT) AND                                                     
        (F1.SYMBOL = F2.SYMBOL) AND                         
        (F1.CONTRACT = F2.CONTRACT) AND     
  (F1.Trandate = F2.ENDDATE) AND       
        (F1.SAUDAFLAG='C')   
		and (F1.Product=F2.Product)
              
------------------------------------Abdul Samad On 06.03.2017 for GBNPP_SUP-1485 (split stamp duty for each trade)-------------------------------------------------------------------------------------------------------              
                
Insert Into #PurchaseCOM (Instrument,Symbol,Contract,Strikeprice,OptionType,Units,Value,contValue,Product)                      
Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),                      
Sum(Units),Sum(Units*(rate))+(Sum(Brokerage)+Sum(Servicetax)+Sum(Servicetax)*@Ecess+                      
--Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+              
--Sum(TOLEVY)+Sum(Units*(rate+Strikeprice))* @CdsStampduty )  ,  -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                      
Sum(TOLEVY)+sum(isnull(StampDuty,0)))  ,        -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485               
Sum(Units*rate),Product                      
from #CommoditySauda                       
where buysell='B'  and saudaflag in ('N','X','A','E','W')  -- Added to include the Expiry contracts  - Added on 12-01-2010                      
group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Product                      
               
                      
Insert Into #TrnDetailsCOM (Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,BQty,BValue,Product)                      
Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag,                      
Sum(Units) ,Sum(Units*(rate))+(Sum(Brokerage)+Sum(Servicetax)+Sum(Servicetax)*@Ecess+                      
--Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                      
--Sum(TOLEVY)+Sum(Units*(rate+Strikeprice))*@cdsStampduty)     -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485               
Sum(TOLEVY)+ sum(isnull(StampDuty,0)))  -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485 
,Product
from #CommoditySauda                      
where    buysell='B'                      
group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag ,Product                     
                        
                      
Insert Into #SalesCOM (Instrument,Symbol,Contract,Strikeprice,OptionType,Units,Value,contValue,Product)                      
Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),                      
Sum(Units),Sum(Units*(rate))-(Sum(Brokerage)+Sum(Servicetax)+Sum(Servicetax)*@Ecess+                      
--Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                      
--Sum(TOLEVY)+Sum(Units*(rate+Strikeprice))*  @CdsStampduty )  ,      -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                  
Sum(TOLEVY)+  sum(isnull(StampDuty,0)))  ,         -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485               
Sum(Units*rate)  ,Product                    
from #CommoditySauda                       
where                        
buysell='S'   and saudaflag in ('N','X','A','E','W')  -- Added to include the Expiry contracts  - Added on 12-01-2010                      
group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,'') ,Product                   
                      
              
              
Update #PurchaseCOM set  Value=0 where ContValue=0                      
Update #SalesCOM set  Value=0 where ContValue=0                      
                      
Insert Into #TrnDetailsCOM (Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,SQty,SValue,Product)                      
Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag,                      
Sum(Units),Sum(Units*(rate))-(Sum(Brokerage)+Sum(Servicetax)+Sum(Servicetax)*@Ecess+                      
--Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                      
--Sum(TOLEVY)+Sum(Units*(rate+Strikeprice))*@cdsStampduty)        -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                
Sum(TOLEVY)+ sum(isnull(StampDuty,0))) -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485 
,Product
from #CommoditySauda                      
where                      
buysell='S'                      
group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag ,Product                   
                      
Update #PurchaseCOM Set Security=Ltrim(rtrim(Instrument))+Ltrim(rtrim(Symbol))+                      
Ltrim(rtrim(Contract))+Ltrim(rtrim(Isnull(Strikeprice,0)))+Ltrim(rtrim(Isnull(OptionType,'')))                      
                      
Update #SalesCOM Set Security=Ltrim(rtrim(Instrument))+Ltrim(rtrim(Symbol))+                      
Ltrim(rtrim(Contract))+Ltrim(rtrim(Isnull(Strikeprice,0)))+Ltrim(rtrim(Isnull(OptionType,'')))                      
                      
                      
-- Allocation Starts                                                          
Declare @Pqty Numeric(15,2)                      
Declare @Pslno Numeric(15,2)                      
Declare @Sqty Numeric(15,2)                                                          
Declare @Sslno Numeric(15,2)                      
Declare @sec Varchar(50)                      
                      
Declare Pur Cursor for                      
Select Security,Slno,Units-AllocatedSellQty from #PurchaseCOM Where (Units-AllocatedSellQty)>0                      
                      
Open Pur                      
Fetch Next From Pur into @sec,@Pslno,@Pqty                      
WHILE @@FETCH_STATUS = 0                      
Begin                      
Declare Sl Cursor for                      
Select Slno,Units-AllocatedPurchaseQty from #SalesCOM Where Security=@sec  and (Units-AllocatedPurchaseQty)>0                      
Open Sl                      
                      
Fetch Next From Sl into @Sslno,@Sqty                      
WHILE @@FETCH_STATUS = 0                      
Begin                      
If @Pqty>0                      
Begin                      
 If @Sqty>=@Pqty                      
 Begin                      
 Update #SalesCOM Set AllocatedPurchaseQty=AllocatedPurchaseQty+@Pqty Where Security=@sec And Slno=@Sslno                      
 Update #PurchaseCOM Set AllocatedSellQty=AllocatedSellQty+@Pqty Where Security=@sec And Slno=@Pslno                      
 Set @Pqty=0                      
 End                      
 Else                      
 Begin                      
 Update #SalesCOM Set AllocatedPurchaseQty=AllocatedPurchaseQty+@Sqty                       
 Where Security=@sec And Slno=@Sslno                         
 Update #PurchaseCOM Set AllocatedSellQty=AllocatedSellQty+@Sqty                       
 Where Security=@sec And Slno=@Pslno                      
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
Create                      
Table #SumTempCDS                      
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
 Product VARCHAR(100)
)                      
                      
Insert Into #SumTempCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,                      
SQPurchaseQty,SQPurchaseValue,BalPurchaseQty,BalPurchaseValue,Product)                      
Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,AllocatedSellQty,                      
(AllocatedSellQty*(Value/Units)),                      
(Units-AllocatedSellQty),(Units-AllocatedSellQty)*(Value/Units),Product From #PurchaseCOM                      
                      
                      
                      
Insert Into #SumTempCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,                      
SQSaleQty,SQSaleValue,BalSaleQty,BalSaleValue,Product)                      
Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,AllocatedPurchaseQty,               
(AllocatedPurchaseQty*(Value/Units)),                      
(Units-AllocatedPurchaseQty),(Units-AllocatedPurchaseQty)*(Value/Units),Product From #SalesCOM                      
                      
Create Table #SumTblCOM                      
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
 ClosingRate Numeric(15,4) Not Null Default 0,                      
 UnRealizedPanL Numeric(15,2) Not Null Default 0,                      
 Avg_price Numeric(15,4)  Not Null default 0,
 Product VARCHAR(MAX)
)                      
                      
Insert #SumTblCOM (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,                      
SQPurchaseQty,SQPurchaseValue,SQSaleQty,                      
SQSaleValue,BalPurchaseQty,BalPurchaseValue,BalSaleQty,BalSaleValue,Product)                      
Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,Sum(SQPurchaseQty),                      
Sum(SQPurchaseValue),Sum(SQSaleQty),                      
Sum(SQSaleValue),Sum(BalPurchaseQty),Sum(BalPurchaseValue),Sum(BalSaleQty),                      
Sum(BalSaleValue),Product From #SumTempCDS Group By Instrument,Symbol,Contract,Strikeprice,OptionType,Security,Product                      
                      
select TranDate,Instrument,Symbol,Contract,OptionType,StrikePrice,ClosingPrice ClosingRate,                        
Euser,LastUpdatedOn,Product    into #CDSClosingRate                      
from Commodity_ClosingPrices  (Nolock)                  
                      
-- Update Closing rate                                                          
Update #SumTblCOM  set #SumTblCOM.ClosingRate=#CDSClosingRate.ClosingRate                       
from #SumTblCOM, #CDSClosingRate (Nolock)                      
Where  #SumTblCOM.instrument=#CDSClosingRate.Instrument And                       
#SumTblCOM.Symbol=#CDSClosingRate.Symbol And                      
#SumTblCOM.contract=#CDSClosingRate.contract and                      
isnull(#SumTblCOM.OptionType,'')=isnull(#CDSClosingRate.OptionType,'') and                      
isnull(#SumTblCOM.StrikePrice,0)=isnull(#CDSClosingRate.StrikePrice,0) and   
isnull(#SumTblCOM.Product,'')=isnull(#CDSClosingRate.Product,'') and
(#SumTblCOM.BalSaleQty+#SumTblCOM.BalPurchaseQty)>0                      
                      
Update #SumTblCOM set RealizedPanL=SQSaleValue-SQPurchaseValue                      
                      
Update #SumTblCOM set UnRealizedPanL=(BalSaleValue)-((BalSaleQty)*(ClosingRate))                      
Where BalSaleQty>0                      
                      
Update #SumTblCOM set UnRealizedPanL=((BalPurchaseQty)*(ClosingRate))-(BalPurchaseValue)                      
Where BalPurchaseQty>0                      
                      
Update #SumTblCOM Set Avg_price=Round(BalPurchaseValue/BalPurchaseQty,4) where BalPurchaseQty>0 and BalPurchaseValue>0                      
                      
Update #SumTblCOM Set Avg_price=Round(BalSaleValue/BalSaleQty,4) where BalSaleQty>0 and BalSaleValue>0                      
                      
Update #SumTblCOM set SQSaleQty=SQSaleQty+BalSaleQty,                      
SQSaleValue=SQSaleValue+BalSaleValue from #SumTblCOM Where BalSaleQty>0                      
                      
Update #SumTblCOM set SQPurchaseQty=SQPurchaseQty+BalPurchaseQty,                      
SQPurchaseValue=SQPurchaseValue+BalPurchaseValue from #SumTblCOM Where BalPurchaseQty>0                      
                      
Update #TrnDetailsCOM set BRate=BValue/Bqty where Bqty>0 and BValue>0                      
Update #TrnDetailsCOM set SRate=SValue/Sqty where Sqty>0 and SValue>0               
              
--Truncate table Tax_Profit_CDS_Details              
              
--Insert into Tax_Profit_CDS_Details              
Insert into Tax_Profit_Details_Commodity              
(Refid,clientid,type,Instrument,Symbol,Contract,Strikeprice,OptionType,SQPurchaseQty,SQPurchaseValue,SQSaleQty,SQSaleValue,              
RealizedPanL,Euser,LastUpdatedOn,Product)              
select @RefId,@cln,'CMD',Instrument,Symbol,Contract,Strikeprice,OptionType,SQPurchaseQty,SQPurchaseValue,SQSaleQty,SQSaleValue,              
RealizedPanL,'System',getdate(),Product from #SumTblCOM Order By Instrument,Symbol,Contract,Strikeprice,OptionType               
               
              
              
                      
If @tnty='N'                      
Delete from #TrnDetailsCOM where SaudaType in ('O','C')                      
                      
                      
Update #TrnDetailsCOM set SaudaType='OPEN',slno=1 where SaudaType='O'                      
Update #TrnDetailsCOM set SaudaType='NORMAL',slno=2 where SaudaType='N'                      
Update #TrnDetailsCOM set SaudaType='CLOSE',slno=4 where SaudaType='C'                      
                      
Update #TrnDetailsCOM set SaudaType='EXPIRY',slno=8,BRate=0,SRate=0 where SaudaType='X'                      
Update #TrnDetailsCOM set SaudaType='ASSIGN',slno=8,BRate=0,SRate=0 where SaudaType='A'                      
Update #TrnDetailsCOM set SaudaType='EXERCISE',slno=8,BRate=0,SRate=0 where SaudaType='E'                 
                      
                    
Select @CMDProfit=sum(RealizedPanL) from #SumTblCOM                  
              
Select @CMDProfit                  
end 