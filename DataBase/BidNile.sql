
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


-- =============================================

-- Task 3: ALTER (Business Changes)

-- 3.1 Connect all tables with Foreign Keys
-- (Deleting an item deletes its photos; all other FKs: NO ACTION)

-- Schema: Users
ALTER TABLE Users.City
    ADD CONSTRAINT FK_City_Country
    FOREIGN KEY (CountryCode) REFERENCES Users.Country (CountryCode)
    ON DELETE NO ACTION;

ALTER TABLE Users.Member
    ADD CONSTRAINT FK_Member_City
    FOREIGN KEY (CityId) REFERENCES Users.City(CityId)
    ON DELETE NO ACTION,
    CONSTRAINT FK_Member
    FOREIGN KEY (ReferredByMemberId) REFERENCES Users.Member (MemberId)
    ON DELETE NO ACTION;

ALTER TABLE Users.Wallet
    ADD CONSTRAINT FK_Wallet_Member
    FOREIGN KEY (MemberId) REFERENCES Users.Member (MemberId)
    ON DELETE NO ACTION;

GO


-- Schema: Operations 
ALTER TABLE Operations.Warehouse
    ADD CONSTRAINT FK_Warehouse_City
    FOREIGN KEY (CityId) REFERENCES Users.City (CityId)
    ON DELETE NO ACTION,
    CONSTRAINT FK_Warehouse_Employee
    FOREIGN KEY (ManagerId) REFERENCES Operations.Employee (MemberId)
    ON DELETE NO ACTION;

ALTER TABLE Operations.Employee
    ADD CONSTRAINT FK_Employee_Member
    FOREIGN KEY (MemberId) REFERENCES Users.Member (MemberId)
    ON DELETE NO ACTION,
    CONSTRAINT FK_Employee_Warehouse
    FOREIGN KEY (WarehouseId) REFERENCES Operations.Warehouse (WarehouseId)
    ON DELETE NO ACTION;
GO

-- Schema: Catalog
ALTER TABLE Catalog.Category
    ADD CONSTRAINT FK_Category_Category
    FOREIGN KEY (ParentCategoryCode) REFERENCES Catalog.Category (CategoryCode)
    ON DELETE NO ACTION;

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Category
    FOREIGN KEY (CategoryCode) REFERENCES Catalog.Category (CategoryCode)
    ON DELETE NO ACTION,
    CONSTRAINT FK_Item_Member
    FOREIGN KEY (SellerId) REFERENCES Users.Member (MemberId)
    ON DELETE NO ACTION,
    CONSTRAINT FK_Item_Warehouse
    FOREIGN KEY (WarehouseId) REFERENCES Operations.Warehouse (WarehouseId)
    ON DELETE NO ACTION,
    CONSTRAINT FK_Item_Employee
    FOREIGN KEY (InspectorId) REFERENCES Operations.Employee (MemberId)
    ON DELETE NO ACTION;

ALTER TABLE Catalog.ItemPhoto
    ADD CONSTRAINT FK_ItemPhoto_Item
    FOREIGN KEY (ItemId) REFERENCES Catalog.Item (ItemId)
    ON DELETE CASCADE;
GO

-- Schema: Sales
ALTER TABLE Sales.Auction
    ADD CONSTRAINT FK_Auction_Item
    FOREIGN KEY (ItemId) REFERENCES Catalog.Item (ItemId)
    ON DELETE NO ACTION;

ALTER TABLE Sales.Bid
    ADD CONSTRAINT FK_Bid_Auction
    FOREIGN KEY (AuctionId) REFERENCES Sales.Auction (AuctionId)
    ON DELETE NO ACTION,
    CONSTRAINT FK_Bid_Member
    FOREIGN KEY (MemberId) REFERENCES Users.Member (MemberId)
    ON DELETE NO ACTION;

ALTER TABLE Sales.AuctionFollow
    ADD CONSTRAINT FK_AuctionFollow_Member
    FOREIGN KEY (MemberId) REFERENCES Users.Member (MemberId)
    ON DELETE NO ACTION,
    CONSTRAINT FK_AuctionFollow_Auction
    FOREIGN KEY (AuctionId) REFERENCES Sales.Auction (AuctionId)
    ON DELETE NO ACTION;
GO



-- 3.2 Members choose an app language (ar or en), existing rows get 'ar' in one statement
ALTER TABLE Users.Member
    ADD AppLanguage CHAR(2) NOT NULL
        CONSTRAINT DF_Member_AppLanguage DEFAULT 'ar'
        CONSTRAINT CK_Member_AppLanguage CHECK (AppLanguage IN ('ar', 'en'));
GO

-- 3.3 Items can be featured (Yes/No, default No)
ALTER TABLE Catalog.Item
    ADD IsFeatured BIT NOT NULL
        CONSTRAINT DF_Item_IsFeatured DEFAULT 0;
GO

-- 3.4 Naming review (SQL Server uses sp_rename, not ALTER TABLE)
-- Drop CK_Warehouse_Capacity first because sp_rename fails on columns with dependencies
EXEC sp_rename 'Sales.Bid.IpAddress', 'DeviceIp', 'COLUMN';
GO

ALTER TABLE Operations.Warehouse
    DROP CONSTRAINT CK_Warehouse_Capacity;
GO

EXEC sp_rename 'Operations.Warehouse.Capacity', 'MaxItems', 'COLUMN';
GO

ALTER TABLE Operations.Warehouse
    ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO

-- 3.5 Extend FullName length to 150 while keeping NOT NULL
ALTER TABLE Users.Member
    ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
GO

-- 3.6 Change MaxItems to SMALLINT (fits up to 32,767)
-- Drop the dependent CHECK constraint first, alter the type, then re-add it
ALTER TABLE Operations.Warehouse
    DROP CONSTRAINT CK_Warehouse_MaxItems;
GO

ALTER TABLE Operations.Warehouse
    ALTER COLUMN MaxItems SMALLINT NOT NULL;
GO

ALTER TABLE Operations.Warehouse
    ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO

-- 3.7 Lower maximum category commission from 30% to 25%
ALTER TABLE Catalog.Category
    DROP CONSTRAINT CK_Category_CommissionPct;
GO

ALTER TABLE Catalog.Category
    ADD CONSTRAINT CK_Category_CommissionPct CHECK (CommissionPct BETWEEN 0 AND 25);
GO

-- 3.8 Add 'PendingReview' status and make it the new default for Auction.Status
ALTER TABLE Sales.Auction
    DROP CONSTRAINT CK_Auction_Status, DF_Auction_Status;
GO

ALTER TABLE Sales.Auction
    ADD CONSTRAINT CK_Auction_Status CHECK (Status IN ('Draft', 'PendingReview', 'Live', 'Ended', 'Cancelled')),
        CONSTRAINT DF_Auction_Status DEFAULT 'PendingReview' FOR Status;
GO

-- 3.9 Add optional BuyNowPrice (must be greater than StartingPrice)
ALTER TABLE Sales.Auction
    ADD BuyNowPrice DECIMAL(12, 2) NULL;
GO

ALTER TABLE Sales.Auction
    ADD CONSTRAINT CK_Auction_BuyNowPrice CHECK (BuyNowPrice > StartingPrice);
GO

-- 3.10 Make Member.Mobile unique
ALTER TABLE Users.Member
    ADD CONSTRAINT UQ_Member_Mobile UNIQUE (Mobile);
GO

-- 3.11 Remove Member.IsVerified (must drop its DEFAULT constraint first)
ALTER TABLE Users.Member
    DROP CONSTRAINT DF_Member_IsVerified;
GO

ALTER TABLE Users.Member
    DROP COLUMN IsVerified;
GO

-- 3.12 Create Marketing schema and move AuctionFollow into it
CREATE SCHEMA Marketing;
GO

ALTER SCHEMA Marketing TRANSFER Sales.AuctionFollow;
GO