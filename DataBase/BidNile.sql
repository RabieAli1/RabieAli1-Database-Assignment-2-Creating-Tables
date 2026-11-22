
-- Task 2 
-- Creat DB & Schemas
CREATE DATABASE BidNile;
GO

USE BidNile;
GO

CREATE SCHEMA Users;
Go

CREATE SCHEMA Operations;
GO

CREATE SCHEMA Catalog;
GO

CREATE SCHEMA Sales;
GO
--1. TABLE 1 Users.Country

CREATE TABLE Users.Country
(
	CountryCode CHAR(2) NOT NULL,
	NameEn VARCHAR(60) NOT NULL,
	NameAr      NVARCHAR(60) NOT NULL,
    PhoneCode   VARCHAR(5)   NOT NULL,

	CONSTRAINT PK_Country PRIMARY KEY (CountryCode),
	CONSTRAINT UQ_Country_NameEn UNIQUE (NameEn),
	CONSTRAINT CK_Country_Code CHECK (CountryCode IN ('EG','SA','AE'))

);
GO

--2. TABLE 2 Users.City
CREATE TABLE Users.City
(
	CityId INT IDENTITY(1, 1) NOT NULL,
	Name   NVARCHAR(60) NOT NULL,
	CountryCode CHAR (2) NOT NULL,

	CONSTRAINT PK_City  PRIMARY KEY (CityId),
	CONSTRAINT UQ_City_Name_CountryCode UNIQUE (Name, CountryCode)

);
GO

--3.Users.Member
CREATE TABLE Users.Member
(
	MemberId           UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Member_MemberId DEFAULT NEWID(),
	FullName           NVARCHAR(100)    NOT NULL,
    Email              VARCHAR(254)     NOT NULL,
    Mobile             VARCHAR(16)      NOT NULL,
    NationalId         VARCHAR(20)      NOT NULL,
    BirthDate          DATE             NOT NULL,
    IsVerified         BIT              NOT NULL CONSTRAINT DF_Member_IsVerified   DEFAULT 0,
    RegisteredAt       DATETIME2(3)     NOT NULL CONSTRAINT DF_Member_RegisteredAt DEFAULT SYSDATETIME(),
    CityId             INT              NOT NULL,
    ReferredByMemberId UNIQUEIDENTIFIER NULL,

	CONSTRAINT PK_Member            PRIMARY KEY (MemberId),
    CONSTRAINT UQ_Member_Email      UNIQUE (Email),
    CONSTRAINT UQ_Member_NationalId UNIQUE (NationalId),
    CONSTRAINT CK_Member_BirthDate  CHECK (DATEADD(YEAR,18,BirthDate)<= CAST(GETDATE() AS DATE)),
	CONSTRAINT CK_Member_ReferredBy CHECK (ReferredByMemberId <> MemberId)
);
GO


-- 4. Users.Wallet
CREATE TABLE Users.Wallet
(
    WalletId   INT              IDENTITY(1, 1) NOT NULL,
    MemberId   UNIQUEIDENTIFIER NOT NULL,
    Balance    DECIMAL(12, 2)   NOT NULL CONSTRAINT DF_Wallet_Balance    DEFAULT 0.00,
    HoldAmount DECIMAL(12, 2)   NOT NULL CONSTRAINT DF_Wallet_HoldAmount DEFAULT 0.00,
    Currency   CHAR(3)          NOT NULL CONSTRAINT DF_Wallet_Currency   DEFAULT 'EGP',
    UpdatedAt  DATETIME2(3)     NOT NULL CONSTRAINT DF_Wallet_UpdatedAt  DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Wallet              PRIMARY KEY (WalletId),
    CONSTRAINT UQ_Wallet_MemberId     UNIQUE (MemberId),
    CONSTRAINT CK_Wallet_Balance      CHECK (Balance >= 0),
    CONSTRAINT CK_Wallet_HoldAmount   CHECK (HoldAmount >= 0),
    CONSTRAINT CK_Wallet_Hold_Balance CHECK (HoldAmount <= Balance),
    CONSTRAINT CK_Wallet_Currency     CHECK (Currency IN ('EGP', 'SAR', 'AED'))
);
GO

-- Schema 2: Operations

-- 5. Operations.Warehouse
CREATE TABLE Operations.Warehouse
(
    WarehouseId      INT              IDENTITY(1, 1) NOT NULL,
    Name             NVARCHAR(80)     NOT NULL,
    Capacity         INT              NOT NULL,
    Latitude         FLOAT            NOT NULL,
    Longitude        FLOAT            NOT NULL,
    CityId           INT              NOT NULL,
    ManagerId        UNIQUEIDENTIFIER NULL,
    ManagerStartDate DATE             NULL,

    CONSTRAINT PK_Warehouse           PRIMARY KEY (WarehouseId),
    CONSTRAINT UQ_Warehouse_Name      UNIQUE (Name),
    CONSTRAINT UQ_Warehouse_ManagerId UNIQUE (ManagerId),
    CONSTRAINT CK_Warehouse_Capacity  CHECK (Capacity > 0),
    CONSTRAINT CK_Warehouse_Latitude  CHECK (Latitude BETWEEN -90 AND 90),
    CONSTRAINT CK_Warehouse_Longitude CHECK (Longitude BETWEEN -180 AND 180)
);
GO

-- 6. Operations.Employee
CREATE TABLE Operations.Employee
(
    MemberId    UNIQUEIDENTIFIER NOT NULL,
    WarehouseId INT              NOT NULL,

    CONSTRAINT PK_Employee PRIMARY KEY (MemberId)
);
GO

-- Schema 3: Catalog

-- 7. Catalog.Category
CREATE TABLE Catalog.Category
(
    CategoryCode       INT           NOT NULL,
    NameEn             VARCHAR(50)   NOT NULL,
    NameAr             NVARCHAR(50)  NULL,
    CommissionPct      DECIMAL(4, 2) NOT NULL,
    ParentCategoryCode INT           NULL,

    CONSTRAINT PK_Category                PRIMARY KEY (CategoryCode),
    CONSTRAINT UQ_Category_NameEn         UNIQUE (NameEn),
    CONSTRAINT CK_Category_CommissionPct  CHECK (CommissionPct BETWEEN 0 AND 30),
    CONSTRAINT CK_Category_ParentCategory CHECK (ParentCategoryCode <> CategoryCode)
);
GO

-- 8. Catalog.Item
CREATE TABLE Catalog.Item
(
    ItemId         INT              IDENTITY(1, 1) NOT NULL,
    Title          NVARCHAR(150)    NOT NULL,
    Description    NVARCHAR(MAX)    NULL,
    ConditionScore TINYINT          NOT NULL,
    Specifications NVARCHAR(MAX)    NOT NULL,
    ListedAt       DATETIME2(3)     NOT NULL CONSTRAINT DF_Item_ListedAt DEFAULT SYSDATETIME(),
    CategoryCode   INT              NOT NULL,
    SellerId       UNIQUEIDENTIFIER NOT NULL,
    WarehouseId    INT              NULL,
    InspectorId    UNIQUEIDENTIFIER NULL,

    CONSTRAINT PK_Item                 PRIMARY KEY (ItemId),
    CONSTRAINT CK_Item_ConditionScore  CHECK (ConditionScore BETWEEN 1 AND 10),
    CONSTRAINT CK_Item_Specifications  CHECK (ISJSON(Specifications) = 1),
    CONSTRAINT CK_Item_SellerInspector CHECK (InspectorId <> SellerId)
);
GO

-- 9. Catalog.ItemPhoto (Weak Entity)
CREATE TABLE Catalog.ItemPhoto
(
    ItemId   INT          NOT NULL,
    Position TINYINT      NOT NULL,
    Url      VARCHAR(500) NOT NULL,
    IsMain   BIT          NOT NULL CONSTRAINT DF_ItemPhoto_IsMain DEFAULT 0,

    CONSTRAINT PK_ItemPhoto          PRIMARY KEY (ItemId, Position),
    CONSTRAINT CK_ItemPhoto_Position CHECK (Position BETWEEN 1 AND 20)
);
GO


-- Schema 4: Sales

-- 10. Sales.Auction
CREATE TABLE Sales.Auction
(
    AuctionId     INT            IDENTITY(1, 1) NOT NULL,
    ItemId        INT            NOT NULL,
    StartingPrice DECIMAL(12, 2) NOT NULL,
    ReservePrice  DECIMAL(12, 2) NULL,
    BidIncrement  DECIMAL(12, 2) NOT NULL CONSTRAINT DF_Auction_BidIncrement DEFAULT 50.00,
    StartsAt      DATETIMEOFFSET NOT NULL,
    EndsAt        DATETIMEOFFSET NOT NULL,
    Status        VARCHAR(20)    NOT NULL CONSTRAINT DF_Auction_Status       DEFAULT 'Draft',

    CONSTRAINT PK_Auction               PRIMARY KEY (AuctionId),
    CONSTRAINT CK_Auction_StartingPrice CHECK (StartingPrice > 0),
    CONSTRAINT CK_Auction_ReservePrice  CHECK (ReservePrice >= StartingPrice),
    CONSTRAINT CK_Auction_BidIncrement  CHECK (BidIncrement > 0),
    CONSTRAINT CK_Auction_EndAfterStart CHECK (EndsAt > StartsAt),
    CONSTRAINT CK_Auction_Status        CHECK (Status IN ('Draft', 'Live', 'Ended', 'Cancelled'))
);
GO

-- 11. Sales.Bid
CREATE TABLE Sales.Bid
(
    BidId     BIGINT           IDENTITY(1, 1) NOT NULL,
    AuctionId INT              NOT NULL,
    MemberId  UNIQUEIDENTIFIER NOT NULL,
    Amount    DECIMAL(12, 2)   NOT NULL,
    PlacedAt  DATETIME2(3)     NOT NULL CONSTRAINT DF_Bid_PlacedAt DEFAULT SYSDATETIME(),
    IpAddress VARCHAR(45)      NOT NULL,

    CONSTRAINT PK_Bid                  PRIMARY KEY (BidId),
    CONSTRAINT UQ_Bid_AuctionId_Amount UNIQUE (AuctionId, Amount),
    CONSTRAINT CK_Bid_Amount           CHECK (Amount > 0)
);
GO

-- 12. Sales.AuctionFollow
CREATE TABLE Sales.AuctionFollow
(
    MemberId   UNIQUEIDENTIFIER NOT NULL,
    AuctionId  INT              NOT NULL,
    FollowedAt DATETIME2(3)     NOT NULL CONSTRAINT DF_AuctionFollow_FollowedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_AuctionFollow PRIMARY KEY (MemberId, AuctionId)
);
GO