/*data cleaning project with nashville housing data */

SELECT *
FROM portfolio_project.dbo.nashville_housing

--------------------------------------------
--Padronizando datas (standardizing dates):

ALTER TABLE nashville_housing
ALTER COLUMN SaleDate date;

--------------------------------------------
---completando dados da coluna 'PropertyAddress' (Populate PropertyAddress data):

--looking for null values:
SELECT *
FROM portfolio_project.dbo.nashville_housing
WHERE PropertyAddress IS NULL

/*once we get that the same ParcelID equals to the same PropertyAddress, we need to self join the table.
By doing this, we will find and compare NULL values with the same ParcelID and then we will be able to populate them.
Furthermore, it is needed to distinguish the UniqueID.
*/

SELECT
	a.ParcelID,	a.PropertyAddress, 
	b.ParcelID, b.PropertyAddress, 
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM portfolio_project.dbo.nashville_housing a
JOIN portfolio_project.dbo.nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--getting rid of NULL values:
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM portfolio_project.dbo.nashville_housing AS a
JOIN portfolio_project.dbo.nashville_housing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--------------------------------------------
---Breaking out Address into individuals columns (address, city, state)
---Separando PropertyAddress em colunas individuais (endereço, cidade, estado)

SELECT
	SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2, LEN(PropertyAddress)) AS City
FROM portfolio_project.dbo.nashville_housing

		
--criando a coluna 'Address' na tabela (creating 'Address' column in the table):
ALTER TABLE portfolio_project.dbo.nashville_housing
Add SplitPropertyAddress nvarchar(255);

UPDATE portfolio_project.dbo.nashville_housing
SET SplitPropertyAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


--criando a coluna 'City' na tabela (creating 'City' column in the table):
ALTER TABLE portfolio_project.dbo.nashville_housing
Add SplitPropertyCity nvarchar(255);

UPDATE portfolio_project.dbo.nashville_housing
SET SplitPropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2, LEN(PropertyAddress))


--deleting old PropertyAddress column:
ALTER TABLE portfolio_project.dbo.nashville_housing
DROP COLUMN PropertyAddress

--making the same with 'OwnerAddress' using PARSENAME()
SELECT
	PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3) AS SplitOwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2) AS SplitOwnerCity,
	PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1) AS SplitOwnerState
FROM portfolio_project.dbo.nashville_housing

--owner address:
ALTER TABLE portfolio_project.dbo.nashville_housing
Add SplitOwnerAddress nvarchar(255);

UPDATE portfolio_project.dbo.nashville_housing
SET SplitOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3)

--owner city:
ALTER TABLE portfolio_project.dbo.nashville_housing
Add SplitOwnerCity nvarchar(255);

UPDATE portfolio_project.dbo.nashville_housing
SET SplitOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2)

--owner state:
ALTER TABLE portfolio_project.dbo.nashville_housing
Add SplitOwnerState nvarchar(255);

UPDATE portfolio_project.dbo.nashville_housing
SET SplitOwnerState = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1)

--deleting old column 'OwnerAddress':
ALTER TABLE portfolio_project.dbo.nashville_housing
DROP COLUMN OwnerAddress

----------------------------------------------------------------------------
--cleaning SoldAsVacant column:
---we can see that has different values on this column (Y, N, Yes and No)

SELECT
	DISTINCT(SoldAsVacant),
	COUNT(SoldAsVacant)
FROM portfolio_project.dbo.nashville_housing
GROUP BY SoldAsVacant

UPDATE portfolio_project.dbo.nashville_housing
SET SoldAsVacant = CASE 
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
					END

----------------------------------------------------------------------------
--removing duplicates:

WITH duplicates_CTE AS
(
SELECT 
	*,
	ROW_NUMBER()
		OVER
		(
		 PARTITION BY 
			ParcelID,
			SplitPropertyAddress,
			SalePrice,
			LegalReference
		 ORDER BY
			UniqueID
		) AS row_num
 FROM portfolio_project.dbo.nashville_housing
)
SELECT *
FROM duplicates_CTE
WHERE row_num > 1
