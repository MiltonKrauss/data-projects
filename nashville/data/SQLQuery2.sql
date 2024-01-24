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


-- Using PARSENAME instead of SUBSTRING to divide OwnerAddress by delimiter

SELECT OwnerAddress
FROM PortfolioProject.dbo.Nashville_Housing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.Nashville_Housing

ALTER TABLE PortfolioProject.dbo.Nashville_Housing
ADD ParseStreet nvarchar(255)

ALTER TABLE PortfolioProject.dbo.Nashville_Housing
ADD ParseCity nvarchar(255)

-- In the query directly below, nvarchar was initially designed with a char limit of 2,
-- but this didn't allow sufficient space for NULL values, so it was modified to a limit of 4.

ALTER TABLE PortfolioProject.dbo.Nashville_Housing
ALTER COLUMN ParseState nvarchar(4)

UPDATE PortfolioProject.dbo.Nashville_Housing
SET ParseStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE PortfolioProject.dbo.Nashville_Housing
SET ParseCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE PortfolioProject.dbo.Nashville_Housing
SET ParseState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Change '1' and '0' to 'Yes' and 'No' in 'SoldAsVacant' column
-- SoldAsVacant data type had to be changed in order to update it

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.Nashville_Housing
GROUP BY SoldAsVacant

ALTER TABLE PortfolioProject.dbo.Nashville_Housing
ALTER COLUMN SoldAsVacant varchar(3)

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 0 THEN 'No'
	WHEN SoldAsVacant = 1 THEN 'Yes'
	ELSE SoldAsVacant
	END
FROM PortfolioProject.dbo.Nashville_Housing

UPDATE PortfolioProject.dbo.Nashville_Housing
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 0 THEN 'No'
	WHEN SoldAsVacant = 1 THEN 'Yes'
	ELSE SoldAsVacant
	END


-- Remove duplicates
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY UniqueID) row_num

FROM PortfolioProject.dbo.Nashville_Housing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1


-- Delete unused columns (not to be done to the raw data!)

ALTER TABLE PortfolioProject.dbo.Nashville_Housing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress, TaxDistrict