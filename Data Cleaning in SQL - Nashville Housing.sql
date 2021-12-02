select *
from PortofolioProject..NashvilleHousing

--Cleaning Data in SQL Queries

--1. Standardize Date Format
alter table NashvilleHousing
add SaleDateConverted Date;

update NashvilleHousing
set SaleDateConverted = convert (date, SaleDate)

select 
	SaleDateConverted
from NashvilleHousing

----------------------------------------------------------------------------------------------------------------------------------------------------------------

--2. Populate Property Address
-- So basically if you check the data there are several data in Property Address that is null
-- After a rough check we could see that all the same ParcelID have the same Property Address
-- So we will populate see if the ParcelID have a property address, then we are going to repopulate it to identical ParcelID without property address
select 
	real.PropertyAddress,
	real.ParcelID,
	dummy.PropertyAddress,
	dummy.ParcelID,
	isnull(real.PropertyAddress, dummy.PropertyAddress)
from NashvilleHousing as real
join NashvilleHousing as dummy
	on real.ParcelID = dummy.ParcelID and real.[UniqueID ] <> dummy.[UniqueID ]
where real.PropertyAddress is null

--Now we are going to move the rows from the dummy table of property address to the real table of property address
update real
set PropertyAddress = isnull(real.PropertyAddress, dummy.PropertyAddress)
from NashvilleHousing as real
join NashvilleHousing as dummy
	on real.ParcelID = dummy.ParcelID and real.[UniqueID ] <> dummy.[UniqueID ]
where real.PropertyAddress is null

--If we check again, there is no null data in property address again
select *
from NashvilleHousing
where PropertyAddress is null

----------------------------------------------------------------------------------------------------------------------------------------------------------------

--3. Breaking out address into individual columns (address, city, state)
--First we are going differentiate the address and the city
select
	PropertyAddress,
	substring(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1) as Address,
	substring(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, len(PropertyAddress)) as City
from NashvilleHousing

--And then we are going to give additional table to the dataset
alter table NashvilleHousing
add PropertyAddressSplit nvarchar(255);

update NashvilleHousing
set PropertyAddressSplit = substring(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1)

alter table NashvilleHousing
add PropertyCitySplit nvarchar(255);

update NashvilleHousing
set PropertyCitySplit = substring(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, len(PropertyAddress))

--We could check the additional column in the dataset
select *
from NashvilleHousing

--Now we are going to do the same to the Owner Address, but we are going to change on how to do it
--Make sure that in PARSENAME syntax, the counting is from the end, not from the front
select
	PARSENAME(replace(OwnerAddress, ',','.') ,3) as Address,
	PARSENAME(replace(OwnerAddress, ',','.') ,2) as City,
	PARSENAME(replace(OwnerAddress, ',','.') ,1) as State
from NashvilleHousing

--Then of course we are going to add additional owner table into the dataset
alter table NashvilleHousing
add OwnerAddressSplit nvarchar(255);

update NashvilleHousing
set OwnerAddressSplit = PARSENAME(replace(OwnerAddress, ',','.') ,3)

alter table NashvilleHousing
add OwnerCitySplit nvarchar(255);

update NashvilleHousing
set OwnerCitySplit = PARSENAME(replace(OwnerAddress, ',','.') ,2)

alter table NashvilleHousing
add OwnerStateSplit nvarchar(255);

update NashvilleHousing
set OwnerStateSplit = PARSENAME(replace(OwnerAddress, ',','.') ,1)

--Change Y and N in Sold as Vacant field
--First we need to check the unique value of the field first
select
	distinct(SoldAsVacant),
	count(SoldAsVacant)
from NashvilleHousing
group by SoldAsVacant
--As we could see the 'Yes' and 'No' are the majority class instead of the 'Y' and 'N'
--So we would change the 'Y' and 'N' into 'Yes' and 'No'
select
	SoldAsVacant,
	case
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	end
from NashvilleHousing

--Now let's update the Sold as vacant field into the condition above
update NashvilleHousing
set SoldAsVacant = case
						when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
						else SoldAsVacant
					end

----------------------------------------------------------------------------------------------------------------------------------------------------------------

--4. Remove duplicates
--The duplication removal could be done in queries, but it will change the original data
--First we are going to check the parameter that decided if a data is duplicate or not
--We are going to use CTE to Delete the duplication
with RowNumCTE AS(
select *,
	ROW_NUMBER() over(
	partition by ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 order by UniqueID
				 ) row_num
from NashvilleHousing
)
--After deleting the duplication, we could check if there is still a duplication by checking whether there is row_num > 1
--If after checking that there is no row_num > 1, we could say that the duplication removal is a success
delete
from RowNumCTE
where row_num > 1

----------------------------------------------------------------------------------------------------------------------------------------------------------------

--5. Delete Unused Columns
--This is not happen too often and also we don't use it in raw data, BUT we could delete the unused columns in queries
--The point of this is to clean up the data, you could also do or clean this data in python or R, because it won't affect the raw data
alter table NashvilleHousing
drop column PropertyAddress, SaleDate, TaxDistrict, OwnerAddress