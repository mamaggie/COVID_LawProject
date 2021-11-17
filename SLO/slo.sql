-- import data
CREATE TABLE law_slo.slo (
	placekey VARCHAR(200), 
	location_name VARCHAR(200), 
	visit_date VARCHAR(200), 
	visits_by_day VARCHAR(200), 
	top_category VARCHAR(200), 
	sub_category VARCHAR(200), 
	naics_code FLOAT(8), 
	latitude VARCHAR(200), 
	longitude VARCHAR(200), 
	raw_visit_counts VARCHAR(200), 
	raw_visitor_counts VARCHAR(200)
); 

-- connect postgis to import spatial file
--create extension postgis;

-- aggregate for graph
create table law_slo.visit_by_date as
select visit_date, sum(visits_by_day::int) as n_visit
from law_slo.slo s 
group by visit_date;


--select placekey, location_name, top_category, visit_date, visits_by_day::int from law_slo.slo where visit_date = '20200210';
--select count(placekey) as count, count(distinct placekey) as distinct from law_slo.slo where visit_date = '20200210';


--- spatial analysis ---------

-- step 1: create a table of unique locations from slo table, create geom column based on lat/lon

create table law_slo.unique_locations as 
select distinct placekey as placekey, latitude, longitude 
from law_slo.slo;

ALTER TABLE law_slo.unique_locations ADD COLUMN geom geometry(Point, 4326);
UPDATE law_slo.unique_locations SET geom = ST_SetSRID(ST_MakePoint(cast(longitude as float), cast(latitude as float)), 4326);


-- step 2: spatial join this with california shapefile, attach census information

create table law_slo.geoid_location_match as
select b.placekey, a.geoid
from law_slo.california_shp a 
join law_slo.unique_locations b
ON ST_Contains(a.geom, b.geom);

-- step 3: left join new table with original slo to attach census across all rows 
create table law_slo.slo_v2 as
select a.*, b.geoid
from law_slo.slo a
left join law_slo.geoid_location_match b 
on a.placekey = b.placekey;









