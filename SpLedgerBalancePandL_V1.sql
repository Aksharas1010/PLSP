--exec SpLedgerBalancePandL_V1 '290002','2022-2023'  
alter  Procedure [dbo].[SpLedgerBalancePandL_V1]    
(                    
 @Clientid Int,                    
 @FiscYear  Varchar(15)  
)                    
As         
begin               
 Set nocount on    
 Declare @ToDate varchar(12)                          
 Declare @finstart varchar(12)   
 set @ToDate=+right(@FiscYear,4)+'-03-31'                          
 set @finstart=left(@FiscYear,4)+'-04-01'   
  
Create Table #Accounts
(
Clientid int,
AccountCode Int
)

Create Table #Balance
(
Particulars varchar(max),
Clientid int,
Amount Numeric(15,3)
)

Insert into #Accounts(Clientid,AccountCode) 
Select Clientid,AccountCode 
From ClientBusinessMemberShip(Nolock) A
Inner join BusinessProducts(Nolock) B On A.Product = B.Product
Where Clientid = @Clientid and  B.MarginProduct <> 'Y'

Insert into #Balance(Particulars,Clientid,Amount) 
Select 'Opening Balance',B.Clientid,isnull(Sum(A.SignedAmount),0) from #Accounts(nolock)  B
left join ACOPBAL  A On A.ACCOUNTCODE = B.AccountCode
Group by B.Clientid

Insert into #Balance(Particulars,Clientid,Amount) 
Select 'Closing Balance',B.Clientid,isnull(Sum(A.SignedAmount),0) from #Accounts(nolock) B
left join Transact A On A.ACCOUNTCODE = B.AccountCode
Where A.VOUCHERDATE <= GETDATE()
Group by B.Clientid

Select *  From #Balance
  
drop table #Accounts  
drop table #Balance  
END  
  