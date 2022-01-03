-- Data Cleaning

SELECT *
FROM PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------
-- Standardize Date Format

--SELECT SaleDate, CAST(SaleDate AS date) AS SaleDateOnly
--FROM PortfolioProject..NashvilleHousing

--Update PortfolioProject..NashvilleHousing
--SET SaleDate = CONVERT(date, SaleDate)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD NewSaleDate date

UPDATE NashvilleHousing
SET NewSaleDate = CONVERT(date, SaleDate)

--------------------------------------------------------------------------------
-- Populate Property Address data using SELF JOIN

-- Location with the same ParcelID has the same PropertyAddress
SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, 
	b.ParcelID, b.PropertyAddress,
	COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
	FROM PortfolioProject..NashvilleHousing AS a
	JOIN PortfolioProject..NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID
		AND a.UniqueID <> b.UniqueID
	WHERE a.PropertyAddress IS NULL

--------------------------------------------------------------------------------
-- Separate Address into Individual Columns (Address, City, State)
-- 1. PropertyAddress (Address, City)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD 
	NewPropertyAddress VARCHAR(255),
	NewPropertyCity VARCHAR(255)

UPDATE PortfolioProject..NashvilleHousing
SET 
	NewPropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
	NewPropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousing

-- 2. OwnerAddress (Address, City, State)
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

-- Separate substrings by delimiters
SELECT
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS NewOwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS NewOwnerCity,	
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS NewOwnerState
FROM 
	PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD
	NewOwnerAddress VARCHAR(255),
	NewOwnerCity VARCHAR(255),
	NewOwnerState VARCHAR (25)

UPDATE PortfolioProject..NashvilleHousing
SET
	NewOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	NewOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	NewOwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
	(CASE SoldAsVacant
		WHEN 'Y' THEN 'Yes'
		WHEN 'N' Then 'No'
		ELSE SoldAsVacant
	END)
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = 
	(CASE SoldAsVacant
		WHEN 'Y' THEN 'Yes'
		WHEN 'N' Then 'No'
		ELSE SoldAsVacant
	END)

--------------------------------------------------------------------------------
-- Remove Duplicates
WITH RowNumCTE AS (
	SELECT *,
		ROW_NUMBER() OVER 
		(PARTITION BY
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY UniqueID) AS row_num
	FROM PortfolioProject..NashvilleHousing)

DELETE
FROM RowNumCTE
WHERE row_num > 1

--------------------------------------------------------------------------------
-- Delete unused columns
SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN
	OwnerAddress,
	TaxDistrict,
	PropertyAddress,
	SaleDate