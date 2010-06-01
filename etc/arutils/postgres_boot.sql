--
-- This probably depends on your postgres setup:
-- * su - postgres
-- * (enter password if necessary)
-- * psql < postgres_boot.sql
--
-- Create the user/role.
--
CREATE ROLE ssng LOGIN PASSWORD 'xxxxxxxx';
--
-- And the data base.
--
CREATE DATABASE ssng_dev OWNER ssng;

