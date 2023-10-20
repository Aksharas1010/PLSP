  
    
    
      
-- Exec SpTax_GeneratePandL_CDS 1290622757,'2010.04.01','2011.03.31',''                        
-- Exec SpTax_GeneratePandL_CDS 1290622757,'2010.04.01','2011.04.30',''                        
-- Exec SpTax_GeneratePandL_CDS 1290622087,'2010.04.01','2011.03.31',''                        
-- Exec SpTax_GeneratePandL_CDS 1041,'1290730500','2013.04.01','2014.03.31','A',0       
    
      
-- Exec SpTax_GeneratePandL_CDS 1290622757,'2010.04.01','2011.03.31',''                        
-- Exec SpTax_GeneratePandL_CDS 1290622757,'2010.04.01','2011.04.30',''                        
-- Exec SpTax_GeneratePandL_CDS 1290622087,'2010.04.01','2011.03.31',''                        
-- Exec SpTax_GeneratePandL_CDS 1041,'1290730500','2013.04.01','2014.03.31','A',0         
      
alter Procedure [dbo].[SpTax_GeneratePandL_CDS]               
(                  
 @RefId int,                  
 @cln Int,                      
 @FromDate VarChar(12),                      
 @ToDate VarChar(12),                      
 @tnty Char(1)='A',              
 @CDProfit Numeric(15,2) output                     
)                      
As                      
Begin                      
set nocount on                    
                
Create Table #PurchaseCDS                      
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
)                      
                      
Create Table #SalesCDS                      
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
)                      
Create Table #TrnDetailsCDS                              
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
into #cdssauda  From cdssauda (Nolock)                        
where                        
(clientid=@cln) And TranDate <= @ToDate --Between @FromDate And Commented by Govind on 28.09.2022               
            
--alter table #cdssauda add constraint df_ExchangeVolume_zero_cd default 0 for ExchangeVolume  -- Added By Samson on 06.06.2019                     
                      
--Jiji/Suresh 26.07.2011 to nullify Option open positions for closed contract                            
                      
Update S Set S.contract_Closed='Y',S.EndDate=C.EndDate from #cdssauda S,CdsContract  C (Nolock)                      
Where                      
(S.Instrument=C.Instrument) and                      
(S.Symbol=C.Symbol) and                      
(S.Contract=C.Contract) and                      
(C.Closed='Y') and       
(C.EndDate<= @ToDate or C.EndDate > @ToDate)  
--(C.EndDate<= @ToDate)    // Akshara  to include next finyear items also                
                   
Select Exchange,Location,Clientid,Instrument,Symbol,Contract,Strikeprice,OptionType,EndDate,Buysell,Units,Sum(qty)qty  into #optopen from #cdssauda                      
Where                      
isnull(strikeprice,0)>0 And (contract_Closed='Y')                      
Group by Exchange,Location,Clientid,Instrument,Symbol,Contract,Strikeprice,OptionType,Buysell,EndDate,Units                      
                      
Update #optopen set qty=qty*-1                      
where Buysell='S'                      
                      
Select Exchange,Location,Clientid,Instrument,Symbol,Contract,Strikeprice,OptionType,EndDate,Units,Sum(qty) qty into #optopen1 from #optopen                      
Group by Exchange,Location,Clientid,Instrument,Symbol,Contract,Strikeprice,OptionType,EndDate,Units                      
                      
Delete from #optopen1 where   qty = 0                      
                      
Alter table #optopen1                      
Add Transactionno integer not null identity(1,1)                      
                      
Insert into #cdssauda(Transactionno,Exchange,Location,TranDate,ClientID,Instrument,Contract,Symbol,                      
Units,qty,BuySell,Rate,SaudaFlag,OptionType,StrikePrice,                      
SaudaType,TradeNo,Brokerage,ServiceTax,SquaredQty,HedgedQty,OpenQty,Lastupdatedon,StampDutyPer,                      
StampDutyMin,StampDutyMax,IntraDaySquaredQty,contract_Closed,TOLEVY,Euser,CdsStampduty,ExchangeVolume)                      
Select Transactionno,Exchange,Location,EndDate,Clientid,Instrument,Contract,Symbol,Units,qty,'S',0,'X',                      
OptionType,StrikePrice,'C' ,'' ,0,0,0 ,0,0  ,getdate(),0,0,0 , 0 ,'Y',0 ,'Jiji',0,0 From #optopen1                      
Where                      
Qty>0                      
                      
                      
Insert into #cdssauda(Transactionno,Exchange,Location,TranDate,ClientID,Instrument,Contract,Symbol,                      
Units,qty,BuySell,Rate,SaudaFlag,OptionType,StrikePrice,                      
SaudaType,TradeNo,Brokerage,ServiceTax,SquaredQty,HedgedQty,OpenQty,Lastupdatedon,StampDutyPer,                      
StampDutyMin,StampDutyMax,IntraDaySquaredQty,contract_Closed,TOLEVY,Euser,CdsStampduty,ExchangeVolume)                      
Select Transactionno,Exchange,Location,EndDate,Clientid,Instrument,Contract,Symbol,Units,abs(qty),'B',0,                      
'X',OptionType,StrikePrice,'C' ,'' ,0,0,0 ,0,0  ,getdate(),0,0,0 , 0 ,'Y' ,0 ,'Jiji',0,0 From #optopen1                      
Where                        
Qty<0        
-----------------added by Govind on 29-09-2022    
Update S Set S.contract_Closed='Y',S.EndDate=C.EndDate from #cdssauda S,CdsContract  C (Nolock)                      
Where                      
(S.Instrument=C.Instrument) and                      
(S.Symbol=C.Symbol) and                      
(S.Contract=C.Contract) and        
(C.Closed='Y') and                      
--(C.EndDate<= @ToDate) //Akshara to include next finyear items also 
(C.EndDate<= @ToDate or C.EndDate > @ToDate)
-----------------end by     
                                                       
update #cdssauda set units=qty * units                 
              
------------------------------------Abdul Samad On 06.03.2017 for GBNPP_SUP-1485 (split stamp duty for each trade)-------------------------------------------------------------------------------------------------------              
select TranDate,Exchange,Location,ClientID,Instrument,Contract,Symbol,sum(Units * Rate)Volume,sum(isnull(StampDuty,0)) as StampDuty into #ConsolidatedStampDuty               
from #cdssauda              
group by TranDate,Exchange,Location,ClientID,Instrument,Contract,Symbol              
              
update A set StampDuty = (a.Units * a.Rate * B.StampDuty) / B.Volume              
from #cdssauda A , #ConsolidatedStampDuty B               
where A.TranDate = b.TranDate and a.Exchange = b.Exchange and a.Location = b.Location and a.Instrument = b.Instrument and a.Contract = b.Contract and a.Symbol = b.Symbol              
and B.Volume <> 0 --Abdul Samad On 20.12.2017              
              
select min(Transactionno) Transactionno,a.TranDate,a.Exchange,a.Location,a.ClientID,a.Instrument,a.Contract,a.Symbol,sum(a.StampDuty) -  b.StampDuty diff into #Diff_StampDuty              
 from #cdssauda a, #ConsolidatedStampDuty B               
where A.TranDate = b.TranDate and a.Exchange = b.Exchange and a.Location = b.Location and a.Instrument = b.Instrument and a.Contract = b.Contract and a.Symbol = b.Symbol              
group by a.TranDate,a.Exchange,a.Location,a.ClientID,a.Instrument,a.Contract,a.Symbol, b.StampDuty              
              
update A Set StampDuty = A.StampDuty - B.Diff              
from #cdssauda A , #Diff_StampDuty B Where A.TransactionNo = B.Transactionno     
    
    
---findout closed contracts----------------------Added by Govind on 29.09.2022    
    
    
 --delete from #cdssauda where (Enddate <  @FromDate or Enddate  > @ToDate) or (Enddate >= getdate())     //Akshara To include next fin year items   
    delete from #cdssauda where (Enddate <  @FromDate)  
 SELECT f.location,f.ClientID, F.INSTRUMENT, F.CONTRACT, F.SYMBOL,  isnull(F.OptionType,'') OptionType,                   
    F.StrikePrice, f1.enddate,                                        
          SUM(CASE F.BUYSELL  WHEN 'B' THEN F.QTY ELSE 0 END) Buy,                                        
          SUM(CASE F.BUYSELL  WHEN 'S' THEN F.QTY ELSE 0 END) Sell       
    into #CDSpos                                        
   FROM #cdssauda F (NoLock) , CdsContract F1 (NoLock)                                         
   WHERE(F1.INSTRUMENT = F.INSTRUMENT) AND                   
        (F1.SYMBOL = F.SYMBOL) AND                   
        (F1.CONTRACT = F.CONTRACT) AND                   
        (F1.CLOSED = 'Y')                   
        --and (F.StrikePrice>0) Commented by Abdul Samad On 31.07.2017                                        
   GROUP BY  f.location,F.ClientID, F.INSTRUMENT, F.CONTRACT,F.SYMBOL, isnull(F.OptionType,'') , F.StrikePrice,f1.enddate                                       
                                        
   --Added By Abdul Samad  on 31.07.2017 for taking expired quantity transaction                    
   Update F1 set F1.SAUDAFLAG='W'                   
   From #cdssauda F1 , #CDSpos F2                    
   Where(F1.INSTRUMENT = F2.INSTRUMENT) AND                                                     
        (F1.SYMBOL = F2.SYMBOL) AND                         
        (F1.CONTRACT = F2.CONTRACT) AND     
  (F1.Trandate = F2.ENDDATE) AND       
        (F1.SAUDAFLAG='C')     
              
------------------------------------Abdul Samad On 06.03.2017 for GBNPP_SUP-1485 (split stamp duty for each trade)-------------------------------------------------------------------------------------------------------              
                
Insert Into #PurchaseCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Units,Value,contValue)                      
Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),                      
Sum(Units),Sum(Units*(rate))+(Sum(Brokerage)+Sum(Servicetax)+Sum(Servicetax)*@Ecess+                      
--Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+              
--Sum(TOLEVY)+Sum(Units*(rate+Strikeprice))* @CdsStampduty )  ,  -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                      
Sum(TOLEVY)+sum(isnull(StampDuty,0)))  ,        -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485               
Sum(Units*rate)                      
from #cdssauda                       
where buysell='B'  and saudaflag in ('N','X','A','E','W')  -- Added to include the Expiry contracts  - Added on 12-01-2010                      
group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,'')                      
               
                      
Insert Into #TrnDetailsCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,BQty,BValue)                      
Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag,                      
Sum(Units) ,Sum(Units*(rate))+(Sum(Brokerage)+Sum(Servicetax)+Sum(Servicetax)*@Ecess+                      
--Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                      
--Sum(TOLEVY)+Sum(Units*(rate+Strikeprice))*@cdsStampduty)     -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485               
Sum(TOLEVY)+ sum(isnull(StampDuty,0)))  -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485               
from #cdssauda                      
where    buysell='B'                      
group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag                      
                        
                      
Insert Into #SalesCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Units,Value,contValue)                      
Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),                      
Sum(Units),Sum(Units*(rate))-(Sum(Brokerage)+Sum(Servicetax)+Sum(Servicetax)*@Ecess+                      
--Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                      
--Sum(TOLEVY)+Sum(Units*(rate+Strikeprice))*  @CdsStampduty )  ,      -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                  
Sum(TOLEVY)+  sum(isnull(StampDuty,0)))  ,         -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485               
Sum(Units*rate)                      
from #cdssauda                       
where                        
buysell='S'   and saudaflag in ('N','X','A','E','W')  -- Added to include the Expiry contracts  - Added on 12-01-2010                      
group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,'')                    
                      
              
              
Update #PurchaseCDS set  Value=0 where ContValue=0                      
Update #SalesCDS set  Value=0 where ContValue=0                      
                      
Insert Into #TrnDetailsCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,SaudaType,SQty,SValue)                      
Select INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag,                      
Sum(Units),Sum(Units*(rate))-(Sum(Brokerage)+Sum(Servicetax)+Sum(Servicetax)*@Ecess+                      
--Sum(isnull(STTSELL,0)+Isnull(STTbuy,0))+                      
--Sum(TOLEVY)+Sum(Units*(rate+Strikeprice))*@cdsStampduty)        -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                
Sum(TOLEVY)+ sum(isnull(StampDuty,0))) -- Abdul Samad On 06.03.2017 for GBNPP_SUP-1485                
from #cdssauda                      
where                      
buysell='S'                      
group by INSTRUMENT,SYMBOL,CONTRACT,isnull(strikeprice,0),Isnull(OptionType,''),Trandate,SaudaFlag                      
                      
Update #PurchaseCDS Set Security=Ltrim(rtrim(Instrument))+Ltrim(rtrim(Symbol))+                      
Ltrim(rtrim(Contract))+Ltrim(rtrim(Isnull(Strikeprice,0)))+Ltrim(rtrim(Isnull(OptionType,'')))                      
                      
Update #SalesCDS Set Security=Ltrim(rtrim(Instrument))+Ltrim(rtrim(Symbol))+                      
Ltrim(rtrim(Contract))+Ltrim(rtrim(Isnull(Strikeprice,0)))+Ltrim(rtrim(Isnull(OptionType,'')))                      
                      
                      
-- Allocation Starts                                                          
Declare @Pqty Numeric(15,2)                      
Declare @Pslno Numeric(15,2)                      
Declare @Sqty Numeric(15,2)                                                          
Declare @Sslno Numeric(15,2)                      
Declare @sec Varchar(50)                      
                      
Declare Pur Cursor for                      
Select Security,Slno,Units-AllocatedSellQty from #PurchaseCDS Where (Units-AllocatedSellQty)>0                      
                      
Open Pur                      
Fetch Next From Pur into @sec,@Pslno,@Pqty                      
WHILE @@FETCH_STATUS = 0                      
Begin                      
Declare Sl Cursor for                      
Select Slno,Units-AllocatedPurchaseQty from #SalesCDS Where Security=@sec  and (Units-AllocatedPurchaseQty)>0                      
Open Sl                      
                      
Fetch Next From Sl into @Sslno,@Sqty                      
WHILE @@FETCH_STATUS = 0                      
Begin                      
If @Pqty>0                      
Begin                      
 If @Sqty>=@Pqty                      
 Begin                      
 Update #SalesCDS Set AllocatedPurchaseQty=AllocatedPurchaseQty+@Pqty Where Security=@sec And Slno=@Sslno                      
 Update #PurchaseCDS Set AllocatedSellQty=AllocatedSellQty+@Pqty Where Security=@sec And Slno=@Pslno                      
 Set @Pqty=0                      
 End                      
 Else                      
 Begin                      
 Update #SalesCDS Set AllocatedPurchaseQty=AllocatedPurchaseQty+@Sqty                       
 Where Security=@sec And Slno=@Sslno                         
 Update #PurchaseCDS Set AllocatedSellQty=AllocatedSellQty+@Sqty                       
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
)                      
                      
Insert Into #SumTempCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,                      
SQPurchaseQty,SQPurchaseValue,BalPurchaseQty,BalPurchaseValue)                      
Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,AllocatedSellQty,                      
(AllocatedSellQty*(Value/Units)),                      
(Units-AllocatedSellQty),(Units-AllocatedSellQty)*(Value/Units) From #PurchaseCDS                      
                      
                      
                      
Insert Into #SumTempCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,                      
SQSaleQty,SQSaleValue,BalSaleQty,BalSaleValue)                      
Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,AllocatedPurchaseQty,               
(AllocatedPurchaseQty*(Value/Units)),                      
(Units-AllocatedPurchaseQty),(Units-AllocatedPurchaseQty)*(Value/Units) From #SalesCDS                      
                      
Create Table #SumTblCDS                      
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
)                      
                      
Insert #SumTblCDS (Instrument,Symbol,Contract,Strikeprice,OptionType,Security,                      
SQPurchaseQty,SQPurchaseValue,SQSaleQty,                      
SQSaleValue,BalPurchaseQty,BalPurchaseValue,BalSaleQty,BalSaleValue)                      
Select Instrument,Symbol,Contract,Strikeprice,OptionType,Security,Sum(SQPurchaseQty),                      
Sum(SQPurchaseValue),Sum(SQSaleQty),                      
Sum(SQSaleValue),Sum(BalPurchaseQty),Sum(BalPurchaseValue),Sum(BalSaleQty),                      
Sum(BalSaleValue) From #SumTempCDS Group By Instrument,Symbol,Contract,Strikeprice,OptionType,Security                      
                      
select TranDate,Instrument,Symbol,Contract,OptionType,StrikePrice,Dayclose ClosingRate,                        
Euser,LastUpdatedOn    into #CDSClosingRate                      
from cdsbhavcopy  (Nolock)                  
                      
-- Update Closing rate                                                          
Update #SumTblCDS  set #SumTblCDS.ClosingRate=#CDSClosingRate.ClosingRate                       
from #SumTblCDS, #CDSClosingRate (Nolock)                      
Where  #SumTblCDS.instrument=#CDSClosingRate.Instrument And                       
#SumTblCDS.Symbol=#CDSClosingRate.Symbol And                      
#SumTblCDS.contract=#CDSClosingRate.contract and                      
isnull(#SumTblCDS.OptionType,'')=isnull(#CDSClosingRate.OptionType,'') and                      
isnull(#SumTblCDS.StrikePrice,0)=isnull(#CDSClosingRate.StrikePrice,0) and                      
(#SumTblCDS.BalSaleQty+#SumTblCDS.BalPurchaseQty)>0                      
                      
Update #SumTblCDS set RealizedPanL=SQSaleValue-SQPurchaseValue                      
                      
Update #SumTblCDS set UnRealizedPanL=(BalSaleValue)-((BalSaleQty)*(ClosingRate))                      
Where BalSaleQty>0                      
                      
Update #SumTblCDS set UnRealizedPanL=((BalPurchaseQty)*(ClosingRate))-(BalPurchaseValue)                      
Where BalPurchaseQty>0                      
                      
Update #SumTblCDS Set Avg_price=Round(BalPurchaseValue/BalPurchaseQty,4) where BalPurchaseQty>0 and BalPurchaseValue>0                      
                      
Update #SumTblCDS Set Avg_price=Round(BalSaleValue/BalSaleQty,4) where BalSaleQty>0 and BalSaleValue>0                      
                      
Update #SumTblCDS set SQSaleQty=SQSaleQty+BalSaleQty,                      
SQSaleValue=SQSaleValue+BalSaleValue from #SumTblCDS Where BalSaleQty>0                      
                      
Update #SumTblCDS set SQPurchaseQty=SQPurchaseQty+BalPurchaseQty,                      
SQPurchaseValue=SQPurchaseValue+BalPurchaseValue from #SumTblCDS Where BalPurchaseQty>0                      
                      
Update #TrnDetailsCDS set BRate=BValue/Bqty where Bqty>0 and BValue>0                      
Update #TrnDetailsCDS set SRate=SValue/Sqty where Sqty>0 and SValue>0               
              
--Truncate table Tax_Profit_CDS_Details              
              
--Insert into Tax_Profit_CDS_Details              
Insert into Tax_Profit_Details_Derivative              
(Refid,clientid,type,Instrument,Symbol,Contract,Strikeprice,OptionType,SQPurchaseQty,SQPurchaseValue,SQSaleQty,SQSaleValue,              
RealizedPanL,Euser,LastUpdatedOn)              
select @RefId,@cln,'CDS',Instrument,Symbol,Contract,Strikeprice,OptionType,SQPurchaseQty,SQPurchaseValue,SQSaleQty,SQSaleValue,              
RealizedPanL,'System',getdate() from #SumTblCDS Order By Instrument,Symbol,Contract,Strikeprice,OptionType               
               
                      
--Select Instrument,Symbol,Contract,Strikeprice,OptionType,                      
--SQPurchaseQty,SQPurchaseValue,SQSaleQty,SQSaleValue,                      
--RealizedPanL,(BalPurchaseQty-BalSaleqty) OpenPos,Avg_price,                      
--ClosingRate,(BalPurchaseQty+BalSaleqty)*Avg_price OpenPosValue,                      
--(BalPurchaseQty+BalSaleqty)*Closingrate Market_value,                      
--UnRealizedPanL,RealizedPanL+UnRealizedPanL Total_PandL,                      
--Ltrim(Rtrim(Contract))+Ltrim(Rtrim(Symbol))+ltrim(rtrim(Instrument))+Ltrim(Rtrim(Strikeprice))+ Ltrim(Rtrim(OptionType)) Relation                      
--from #SumTblCDS Order By Instrument,Symbol,Contract,Strikeprice,OptionType               
              
                      
If @tnty='N'                      
Delete from #TrnDetailsCDS where SaudaType in ('O','C')                      
                      
                      
Update #TrnDetailsCDS set SaudaType='OPEN',slno=1 where SaudaType='O'                      
Update #TrnDetailsCDS set SaudaType='NORMAL',slno=2 where SaudaType='N'                      
Update #TrnDetailsCDS set SaudaType='CLOSE',slno=4 where SaudaType='C'                      
                      
Update #TrnDetailsCDS set SaudaType='EXPIRY',slno=8,BRate=0,SRate=0 where SaudaType='X'                      
Update #TrnDetailsCDS set SaudaType='ASSIGN',slno=8,BRate=0,SRate=0 where SaudaType='A'                      
Update #TrnDetailsCDS set SaudaType='EXERCISE',slno=8,BRate=0,SRate=0 where SaudaType='E'                 
                      
--Select T.Instrument,T.Symbol,T.Contract,T.Strikeprice,T.OptionType,                      
--T.Trandate,T.SaudaType,T.Bqty,T.BRate,T.Sqty,T.SRate,                   
--Ltrim(Rtrim(T.Contract))+Ltrim(Rtrim(T.Symbol))+ltrim(rtrim(T.Instrument))+                      
--Ltrim(Rtrim(T.Strikeprice)) + Ltrim(Rtrim(T.OptionType))  Relation                      
--from #TrnDetailsCDS T,#SumTblCDS S                      
--where T.Instrument=S.Instrument and T.Symbol=S.Symbol                      
--and T.Contract=S.Contract and T.Strikeprice=S.Strikeprice                      
--And isnull(T.OptionType,'')=isnull(S.OptionType,'')                      
--Order By Instrument,Symbol,Contract,Strikeprice,OptionType,Trandate,slno                      
                      
                      
/*For displaying Total value*/                      
Select @CDProfit=sum(RealizedPanL) from #SumTblCDS                  
              
Select @CDProfit                  
end 