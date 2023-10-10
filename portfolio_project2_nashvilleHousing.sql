--Portfolio Project: Data Cleaning

SELECT * FROM nashvillehousing

--standardize date (changing timestamp to date)
ALTER TABLE nashvillehousing
ALTER COLUMN saledate TYPE date using(saledate::date)

--Populate Property Address data 
--parcel id is unique to address. If there are addresses with parcelID, and there are rows with the same parcelID but no address, then set the address 

--check which rows have same parcelid for different rows and where one is null (gives 35 rows)
select a.parcelid,a.propertyaddress,b.parcelid,b.propertyaddress
from nashvillehousing a
inner join nashvillehousing b
on a.parcelid=b.parcelid
and a.uniqueid<>b.uniqueid
and a.propertyaddress is null

--update table and set propertyaddress
UPDATE nashvillehousing 
set propertyaddress=coalesce(a.propertyaddress,b.propertyaddress)
from nashvillehousing a
inner join nashvillehousing b
on a.parcelid=b.parcelid
and a.uniqueid<>b.uniqueid
and a.propertyaddress is null

--check: running this query again returns 0 records
select a.parcelid,a.propertyaddress,b.parcelid,b.propertyaddress
from nashvillehousing a
inner join nashvillehousing b
on a.parcelid=b.parcelid
and a.uniqueid<>b.uniqueid
and a.propertyaddress is null

--breaking out address into individual columns (address, city, state)

select substring(propertyaddress,1,(position(',' IN propertyaddress)-1)) as address,
substring(propertyaddress,position(',' IN propertyaddress)+2,length(propertyaddress)) as address
from nashvillehousing
order by parcelid

ALTER TABLE nashvillehousing
ADD COLUMN propertySplitaddress varchar(255)

UPDATE nashvillehousing
SET propertySplitaddress=substring(propertyaddress,1,(position(',' IN propertyaddress)-1)) 

ALTER TABLE nashvillehousing
ADD COLUMN propertySplitCity varchar(255)

UPDATE nashvillehousing
SET propertySplitCity = substring(propertyaddress,position(',' IN propertyaddress)+2,length(propertyaddress))

--breaking out owner address into individual columns (address, city, state)
select owneraddress,split_part(owneraddress,',',1) as address,
split_part(owneraddress,',',2) as city,
split_part(owneraddress,',',3) as state
from nashvillehousing

ALTER TABLE nashvillehousing
ADD COLUMN ownersplitaddress varchar(255)

UPDATE nashvillehousing
SET ownersplitaddress=split_part(owneraddress,',',1)

ALTER TABLE nashvillehousing
ADD COLUMN ownersplitcity varchar(255)

UPDATE nashvillehousing
SET ownersplitcity=split_part(owneraddress,',',2)

ALTER TABLE nashvillehousing
ADD COLUMN ownersplitstate varchar(255)

UPDATE nashvillehousing
SET ownersplitstate=split_part(owneraddress,',',3)

--Change Y and N to Yes and No in "Sold as Vacant" field
SELECT soldasvacant,count(*) from nashvillehousing
group by soldasvacant

UPDATE nashvillehousing
SET soldasvacant=
	CASE WHEN soldasvacant='Y' THen 'Yes'
	WHEN soldasvacant='N' THEN 'No'
	else soldasvacant
	END 
	
--remove duplicates 
--consider that where rows have same parcelid, property address, saleprice, saledate, legal reference, then that's just the same data which is unusable
--where all these partition columns are same the unique id is different which is really just the same data with different rows so where row num>1=dupes
--we need to remove those dupes
--when cte is run with select, we see 104 dupes.
WITH RowNumCTE AS(
SELECT *,
row_number() over (partition by parcelid,
				  				propertyaddress,
				  				saleprice,
				  				saledate,
				  				legalreference
				  ORDER BY uniqueid) row_num
from nashvillehousing)

--SELECT * FROM RowNumCTE
--where row_num>1
--order by propertyaddress

--replace above select statement with delete (can't delete from cte directly in postgres)
DELETE FROM nashvillehousing where uniqueid in
(SELECT uniqueid from RowNumCTE
where row_num>1)

--Delete unused columns
ALTER TABLE nashvillehousing
DROP COLUMN taxdistrict





