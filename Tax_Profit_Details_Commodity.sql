USE [GCC]
GO

/****** Object:  Table [dbo].[Tax_Profit_Details_Derivative]    Script Date: 10/19/2023 3:45:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Tax_Profit_Details_Commodity](
	[RefId] [int] NULL,
	[Clientid] [int] NULL,
	[Type] [varchar](32) NULL,
	[Instrument] [varchar](10) NULL,
	[Symbol] [varchar](10) NULL,
	[Contract] [varchar](10) NULL,
	[Strikeprice] [numeric](15, 4) NULL,
	[OptionType] [varchar](10) NULL,
	[Security] [varchar](50) NULL,
	[SQPurchaseQty] [int] NULL,
	[SQPurchaseValue] [numeric](15, 2) NULL,
	[SQSaleQty] [int] NULL,
	[SQSaleValue] [numeric](15, 2) NULL,
	[RealizedPanL] [numeric](15, 2) NULL,
	[Euser] [varchar](10) NULL,
	[LastuPdatedon] [datetime] NULL,
	[ActualPurchaseQty] [numeric](15, 4) NOT NULL,
	[ActualSalesQty] [numeric](15, 4) NOT NULL,
	[ContractClosingRate] [numeric](15, 4) NOT NULL,
	[TransID] [int] IDENTITY(1,1) NOT NULL,
	[Product][varchar](150) NULL
PRIMARY KEY CLUSTERED 
(
	[TransID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Tax_Profit_Details_Commodity] ADD  DEFAULT ((0)) FOR [ActualPurchaseQty]
GO

ALTER TABLE [dbo].[Tax_Profit_Details_Commodity] ADD  DEFAULT ((0)) FOR [ActualSalesQty]
GO

ALTER TABLE [dbo].[Tax_Profit_Details_Commodity] ADD  DEFAULT ((0)) FOR [ContractClosingRate]
GO

ALTER TABLE [dbo].[Tax_Profit_Details_Commodity]  WITH CHECK ADD FOREIGN KEY([RefId])
REFERENCES [dbo].[TaxComputationRefId] ([RefId])
GO


