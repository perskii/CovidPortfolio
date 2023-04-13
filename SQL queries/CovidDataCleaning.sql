/*
Cleaning Data in SQL Queries
*/


Select *
From CovidPortfolio.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

select SaleDate, CONVERT(date,SaleDate)
	from CovidPortfolio.dbo.NashvilleHousing

Update CovidPortfolio.dbo.NashvilleHousing
	set SaleDate = CONVERT(date,SaleDate)
-- If it doesn't Update properly (cos of column datatype)

alter table NashvilleHousing
	add SaleDateConverted date;

Update CovidPortfolio.dbo.NashvilleHousing
	set SaleDateConverted = CONVERT(date,SaleDate)




 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

-- select all bad data and create the query 
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
	from CovidPortfolio.dbo.NashvilleHousing a
	join CovidPortfolio.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
	where a.PropertyAddress is null
	
Update a
set PropertyAddress = isnull(a.PropertyAddress,b.PropertyAddress)
	from CovidPortfolio.dbo.NashvilleHousing a
	join CovidPortfolio.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
	where a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

-- for column PropertyAddress
select 
	-- adress 
	SUBSTRING(PropertyAddress, 1,charindex(',',PropertyAddress) -1) as address,
	-- city
	SUBSTRING(PropertyAddress,charindex(',',PropertyAddress) +1, len(PropertyAddress)) as city
	from CovidPortfolio.dbo.NashvilleHousing

alter table NashvilleHousing
	add propertySplitAddress nvarchar(255);

Update CovidPortfolio.dbo.NashvilleHousing
	set propertySplitAddress = SUBSTRING(PropertyAddress, 1,charindex(',',PropertyAddress) -1)

alter table NashvilleHousing
	add propertySplitCity nvarchar(255);

Update CovidPortfolio.dbo.NashvilleHousing
	set propertySplitCity = SUBSTRING(PropertyAddress,charindex(',',PropertyAddress) +1, len(PropertyAddress))

select * from CovidPortfolio.dbo.NashvilleHousing

-- for column 'OwnerAddress'
select OwnerAddress
	from CovidPortfolio.dbo.NashvilleHousing

select
	PARSENAME(replace(OwnerAddress, ',','.'),3) as propAddress,
	PARSENAME(replace(OwnerAddress, ',','.'),2) as propCity,
	PARSENAME(replace(OwnerAddress, ',','.'),1) as propState
	from CovidPortfolio.dbo.NashvilleHousing

alter table CovidPortfolio.dbo.NashvilleHousing
	add ownerSplitAddress nvarchar(255);

Update CovidPortfolio.dbo.NashvilleHousing
	set ownerSplitAddress = PARSENAME(replace(OwnerAddress, ',','.'),3)
	
alter table CovidPortfolio.dbo.NashvilleHousing
	add ownerSplitCity nvarchar(255);

Update CovidPortfolio.dbo.NashvilleHousing
	set ownerSplitCity = PARSENAME(replace(OwnerAddress, ',','.'),2)
	
alter table CovidPortfolio.dbo.NashvilleHousing
	add ownerSplitState nvarchar(255);

Update CovidPortfolio.dbo.NashvilleHousing
	set ownerSplitState = PARSENAME(replace(OwnerAddress, ',','.'),1)

select * from CovidPortfolio.dbo.NashvilleHousing
--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldAsVacant)
	from CovidPortfolio.dbo.NashvilleHousing

select SoldAsVacant,
	case 
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	end
	from CovidPortfolio.dbo.NashvilleHousing

update CovidPortfolio.dbo.NashvilleHousing
set SoldAsVacant = 
	case 
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	end

select distinct(SoldAsVacant), count(SoldAsVacant)
	from CovidPortfolio.dbo.NashvilleHousing
	group by SoldAsVacant

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

select *
	from CovidPortfolio.dbo.NashvilleHousing

with rowNumCTE AS(
select 
	*,
	ROW_NUMBER() OVER (
	PARTITION BY
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		Order by UniqueID) row_Num
	from CovidPortfolio.dbo.NashvilleHousing
	-- order by rowNum desc
)
Delete 
	from rowNumCTE
	where row_Num >1
---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

alter table CovidPortfolio.dbo.NashvilleHousing
	drop column OwnerAddress, TaxDistrict, PropertyAddress

select *
	from CovidPortfolio.dbo.NashvilleHousing

alter table CovidPortfolio.dbo.NashvilleHousing
	drop column SaleDate
