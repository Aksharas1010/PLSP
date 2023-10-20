--exec SpOtherChargePandL_V1 '290002','2022-2023'  
alter  Procedure [dbo].[SpOtherChargePandL_V1]    
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
CREATE TABLE #TempResults  
(  
    Particulars VARCHAR(255),  
    Clientid INT,  
    Amount DECIMAL(18, 2)  
);  
Insert into #Accounts(Clientid,AccountCode)   
Select Clientid,AccountCode   
From ClientBusinessMemberShip(Nolock) A  
left join BusinessProducts(Nolock) B On A.Product = B.Product  
Where Clientid = @Clientid   
   
insert into #TempResults
Select 'DIS Charges' As Particulars, B.Clientid, ISNULL(Sum(A.SignedAmount)*-1, 0)  Amount 
from #Accounts B 
left join Transact(nolock) A On A.ACCOUNTCODE = B.AccountCode and A.VOUCHERDATE >= @finstart and A.VOUCHERDATE <= @ToDate and A.REFNO = 'TRDIS'
Group by B.Clientid

insert into #TempResults
Select 'Pledge Charges' As Particulars, B.Clientid, ISNULL(Sum(A.SignedAmount)*-1, 0)  Amount 
from #Accounts B 
left join Transact(nolock) A On A.ACCOUNTCODE = B.AccountCode and A.VOUCHERDATE >= @finstart and A.VOUCHERDATE <= @ToDate and A.REFNO = 'MARGIN_PLEDGE'
Group by B.Clientid

insert into #TempResults
Select 'MTF Interest' As Particulars, B.Clientid, ISNULL(Sum(A.SignedAmount)*-1, 0) Amount 
from #Accounts B 
left join Transact(nolock) A On A.ACCOUNTCODE = B.AccountCode and A.VOUCHERDATE >= @finstart and A.VOUCHERDATE <= @ToDate and A.REFNO = 'MTINTEREST'
Group by B.Clientid

insert into #TempResults
Select 'Interest on Delayed Payment' As Particulars, B.Clientid, ISNULL(Sum(A.SignedAmount)*-1, 0)  Amount 
from #Accounts B 
left join Transact(nolock) A On A.ACCOUNTCODE = B.AccountCode and A.VOUCHERDATE >= @finstart and A.VOUCHERDATE <= @ToDate and A.REFNO = 'DEBITCHARGES'
Group by B.Clientid
  
insert into #TempResults  
Select 'AMC' As Particulars,@Clientid,isnull(Sum(A.AmtRecived),0) Amount  
from GFSL2023.dbo.AMCCharge(Nolock) A  
left Join GFSL2023.dbo.ClientDPAccountCodes(Nolock) B On A.dpid = B.DPID and A.dPClientid = B.DPACNO  
Where B.Clientid = @Clientid And left(A.Financialyear,4)=DATEPART(Year,GETDATE())  
  
select * from #TempResults  
drop table #Accounts  
drop table #TempResults  
END  
  