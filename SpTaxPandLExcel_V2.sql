
alter Procedure [dbo].[SpTaxPandLExcel_V2]  
(                  
 @Refid    Int,                  
 @Clientid Int,                  
 @FinYear  Varchar(15),  
 @reportType Varchar(15)  
)                  
As       
begin             
 Set nocount on                  
                
 --Added by Abdul Samad On 15.02.2017               
 Declare @Sql Varchar(8000);               
 Declare @StrServer Varchar(25);              
 Declare @Counter Int              
 Set @Counter =0              
 set @StrServer = '';              
      
 create table #TempCounter              
 (              
  Counter1 int              
 )  
  
 --If ((select Count(*) from GFSLIDB2021.dbo.Tax_Profit_Details_Cash (nolock)           
 --Where Refid = @Refid ) > 0  or  (select Count(*) from           
 --GFSLIDB2021.dbo.Tax_Profit_Details_Derivative (nolock) Where Refid = @Refid ) > 0)          
 --begin          
 -- Set @StrServer = 'GFSLIDB2021.dbo.'            
 --End       
 --Else  If ((select Count(*) from GFSLIDB2022.dbo.Tax_Profit_Details_Cash (nolock)           
 --Where Refid = @Refid ) > 0  or  (select Count(*) from           
 --GFSLIDB2022.dbo.Tax_Profit_Details_Derivative (nolock) Where Refid = @Refid ) > 0)          
 --begin          
 -- Set @StrServer = 'GFSLIDB2022.dbo.'            
 --End  
 Truncate table #TempCounter              
 Set @Counter=0  
  
 --F&O  
 if(@reportType = 'FO')  
 begin  
   set @Sql = 'select Count(*) from ' +@StrServer +  'Tax_Profit_Details_Derivative (nolock)               
   Where Refid = ' + Cast(@Refid  as varchar) +  ' And Clientid =  ' + Cast(@Clientid as varchar) +  ' And Type = ''F&O'''              
                         
   insert into #TempCounter              
   exec (@Sql)              
              
   select @Counter = counter1 from #TempCounter              
              
   If @Counter > 0              
   begin  
     set @sql ='Select T.Instrument,T.Symbol,T.Contract,T.Strikeprice,T.OptionType,T.Security,T.SQPurchaseQty,T.SQPurchaseValue,T.SQSaleQty,              
     T.SQSaleValue,T.RealizedPanL,ActualPurchaseQty,ActualSalesQty,ContractClosingRate              
     from ' +@StrServer +  'Tax_Profit_Details_Derivative T(nolock)                 
     Where T.Refid = ' + Cast(@Refid  as varchar) +  ' And Clientid =  ' + Cast(@Clientid as varchar) +  ' And T.Type = ''F&O'''  
     Exec(@sql)                                              
    end  
 end  
  
 --CDS  
  if(@reportType = 'CDS')  
 begin  
   Truncate table #TempCounter              
   Set @Counter=0              
              
   set @Sql = 'select Count(*) from ' +@StrServer +  'Tax_Profit_Details_Derivative (nolock)               
   Where Refid = ' + Cast(@Refid  as varchar) +  ' And Clientid =  ' + Cast(@Clientid as varchar) +  ' And Type = ''CDS'''              
                         
   insert into #TempCounter              
   exec (@Sql)              
              
  select @Counter = counter1 from #TempCounter              
              
   If @Counter > 0              
   begin  
     set @sql = 'Select T.Instrument,T.Symbol,T.Contract,T.Strikeprice,T.OptionType,T.SQPurchaseQty,T.SQPurchaseValue,T.SQSaleQty,T.SQSaleValue,T.RealizedPanL                
    from ' +@StrServer +  'Tax_Profit_Details_Derivative T(nolock)               
    Where T.Refid = ' + Cast(@Refid  as varchar) +  ' And Clientid =  ' + Cast(@Clientid as varchar) +  ' And T.Type = ''CDS'''   
    Exec(@sql)  
   end  
 end  
    
 if(@reportType='Equity')  
  begin  
  --Convert(varchar(10),T.TranDateBuy,104) TranDateBuy,T.SECURITY,T.DESCRIPTION,T.ISIN,T.BuyQty,T.BuyValue,T.PurchaseBrokerage,T.PurchaseServiceTax,                
    --T.PurchaseExchangeLevy,T.PurchaseStampDuty,Convert(varchar(10),T.TranDateSale,104)TranDateSale,T.SaleQty,T.SaleValue,T.SaleBrokerage,                
    --T.SaleServiceTax,T.SaleExchangeLevy,T.SaleStampDuty,T.DayToSell,BuyExpense,SellExpense,T.Profit  
    set @Sql = 'Select * from ' +@StrServer +  'Tax_Profit_Details_Cash T(nolock)               
    Where T.Refid = ' + Cast(@Refid  as varchar) +  '  And T.Clientid = ' + Cast(@Clientid as varchar) + ' order by Type desc, TranDateSale, SECURITY, TranDateBuy'  
    Exec(@sql)  
  end  

IF (@reportType = 'Bond')
BEGIN
    SET @Sql = 'SELECT * FROM Tax_Profit_Details_Cash T
                inner JOIN ' + @StrServer + 'ImageDB.dbo.FLIP_ISIN_Master m (NOLOCK)
                ON T.isin =m.Isin  AND (categ_desc = ''Bond'' OR categ_desc = ''Sovereign Gold Bonds'')
                WHERE T.Refid = ' + CAST(@Refid AS VARCHAR) + '
                AND T.Clientid = ' + CAST(@Clientid AS VARCHAR) + '                
                ORDER BY Type DESC, TranDateSale, SECURITY, TranDateBuy';
				print @Sql
    EXEC(@Sql);
END
print @reportType
if(@reportType = 'Commodity')  
 begin  
   Truncate table #TempCounter              
   Set @Counter=0              
              
   set @Sql = 'select Count(*) from ' +@StrServer +  'Tax_Profit_Details_Commodity (nolock)               
   Where Refid = ' + Cast(@Refid  as varchar) +  ' And Clientid =  ' + Cast(@Clientid as varchar) +  ' And Type = ''CMD'''              
                         
   insert into #TempCounter              
   exec (@Sql)              
              
  select @Counter = counter1 from #TempCounter              
              
   If @Counter > 0              
   begin  
     set @sql = 'Select T.Instrument,T.Symbol,T.Contract,T.Strikeprice,T.OptionType,T.SQPurchaseQty,T.SQPurchaseValue,T.SQSaleQty,T.SQSaleValue,T.RealizedPanL                
    from ' +@StrServer +  'Tax_Profit_Details_Commodity T(nolock)               
    Where T.Refid = ' + Cast(@Refid  as varchar) +  ' And Clientid =  ' + Cast(@Clientid as varchar) +  ' And T.Type = ''CMD'''   
    Exec(@sql)  
   end  
 end

   -- exec SpTaxPandLExcel_V2 614715,1290789020,'2022-2023','Bond'
END

