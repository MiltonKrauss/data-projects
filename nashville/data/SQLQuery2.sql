SELECT *
FROM PortfolioProject.dbo.Nashville_Housing

-- Convert SaleDate from DateTime to just Date

UPDATE Nashville_Housing
SET SaleDate = CONVERT(Date, SaleDate)

-- Populate property address data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.Nashville_Housing a
JOIN PortfolioProject.dbo.Nashville_Housing b
  ON a.ParcelID = b.ParcelID
  AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = b.PropertyAddress
FROM PortfolioProject.dbo.Nashville_Housing a
JOIN PortfolioProject.dbo.Nashville_Housing b
  ON a.ParcelID = b.ParcelID
  AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

-- Break off city and state from address

SELECT PropertyAddress
FROM PortfolioProject.dbo.Nashville_Housing

SELECT 
  SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
  SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.Nashville_Housing

ALTER TABLE Nashville_Housing
ADD AddressStreet nvarchar(255)

UPDATE Nashville_Housing
SET AddressStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE Nashville_Housing
ADD AddressCity nvarchar(255)

UPDATE Nashville_Housing
SET AddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))