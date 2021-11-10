```sql
nymtc_test=# \d areas
                                           Table "public.areas"
      Column      |            Type             | Collation | Nullable |              Default
------------------+-----------------------------+-----------+----------+-----------------------------------
 id               | integer                     |           | not null | nextval('areas_id_seq'::regclass)
 name             | character varying(255)      |           |          |
 type             | character varying(255)      |           |          |
 created_at       | timestamp without time zone |           |          |
 updated_at       | timestamp without time zone |           |          |
 size             | double precision            |           |          |
 base_geometry_id | integer                     |           |          |
 fips_code        | bigint                      |           |          |
 year             | integer                     |           |          |
 user_id          | integer                     |           |          |
 description      | text                        |           |          |
 published        | boolean                     |           |          | false
Indexes:
    "areas_pkey" PRIMARY KEY, btree (id)
    "index_areas_on_base_geometry_id" btree (base_geometry_id)
    "index_areas_on_fips_code" btree (fips_code)
    "index_areas_on_user_id" btree (user_id)

nymtc_test=# select distinct type from areas order by 1;
     type
--------------
 census_tract
 county
 region
 study_area
 subregion
 taz
 tcc

nymtc_test=# \d base_geometries
                                        Table "public.base_geometries"
   Column   |            Type             | Collation | Nullable |                   Default
------------+-----------------------------+-----------+----------+---------------------------------------------
 id         | integer                     |           | not null | nextval('base_geometries_id_seq'::regclass)
 created_at | timestamp without time zone |           |          |
 updated_at | timestamp without time zone |           |          |
 geom       | geometry(Geometry,4326)     |           |          |
Indexes:
    "area_geometries_pkey" PRIMARY KEY, btree (id)
    "index_base_geometries_on_geom" gist (geom)

nymtc_test=# select year, count(distinct base_geometry_id) from areas where type = 'taz' group by year order by year;
 year | count
------+-------
 2005 |  3585
 2010 |  4629
 2012 |  4632
(3 rows)

nymtc_test=# select year, count(1) from base_geometries as a inner join areas as b on (a.id = b.base_geometry_id) where b.type = 'taz' group by year order by year;
 year | count
------+-------
 2005 |  3585
 2010 |  4629
 2012 |  4632
(3 rows)

nymtc_test=# select * from public.base_geometry_versions where category = 'taz' order by version;
 id | category | version |         created_at         |         updated_at
----+----------+---------+----------------------------+----------------------------
  1 | taz      | 2005    | 2016-02-22 18:20:21.251457 | 2016-02-22 18:20:21.251457
  2 | taz      | 2010    | 2016-02-22 18:20:21.259605 | 2016-02-22 18:20:21.259605
 17 | taz      | 2012    | 2019-08-21 15:55:53.834176 | 2019-08-21 15:55:53.834176
(3 rows)
```

## db tasks

```sh
$ ag taz -l db
db/schema.rb
db/bpm_2005_taz_forecast_seeds.rb
db/taz_summaries_test.csv
db/taz_summaries.csv
db/tasks/migrate_layer_configs_to_db.rb
db/tasks/update_mapbox_urls.rb
db/tasks/seed_view_geometry_base_year.rb
db/tasks/clean_up_view_data_levels.rb
db/tasks/create_2040_taz_sed_view.rb
db/tasks/enable_2021_taz_boundary.rb
db/tasks/seed_area_years.rb
db/tasks/enable_2010_taz_boundary.rb
db/tasks/enable_2012_taz_boundary.rb
db/tasks/update_view_spatial_level.rb
db/area_geometry_seeds.rb
db/seeds.rb
db/tasks/seed_geometry_versions.rb
db/NYBPM_2005_TAZ_Forecast.csv
```
