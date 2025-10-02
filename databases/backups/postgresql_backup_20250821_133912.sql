--
-- PostgreSQL database cluster dump
--

\restrict ZSF0lQtL68JvqRczN8stE7Zpvm9z8pIEEl7SXHCWbdsn0tYYU3QIPrttbk6Kkuc

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE root;
ALTER ROLE root WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:5Tbbw9EPVz5ZKesJQ65Ynw==$AviCFIGkVd8byEdOPvtsY7rsa2Z8bgdroSQo1Xb9PqI=:9C7WUgzG58LFmwffzQEL19v7pfgFg61J6gnxQl0gkfk=';

--
-- User Configurations
--








\unrestrict ZSF0lQtL68JvqRczN8stE7Zpvm9z8pIEEl7SXHCWbdsn0tYYU3QIPrttbk6Kkuc

--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

\restrict eoQoXHXbamrw7aQhRp4kp0JbnYuLbIMqxX9OFYvgWm9X9CwvBDRcTPOUWEGZiVU

-- Dumped from database version 17.6 (Debian 17.6-1.pgdg13+1)
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- PostgreSQL database dump complete
--

\unrestrict eoQoXHXbamrw7aQhRp4kp0JbnYuLbIMqxX9OFYvgWm9X9CwvBDRcTPOUWEGZiVU

--
-- Database "defaultdb" dump
--

--
-- PostgreSQL database dump
--

\restrict kEXgi0uWr6Naaf0t1mRCuvI2NRbbO0PLDCFZK0ZRJBvUYTHq5Lvffj5BfMo6c4c

-- Dumped from database version 17.6 (Debian 17.6-1.pgdg13+1)
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: defaultdb; Type: DATABASE; Schema: -; Owner: root
--

CREATE DATABASE defaultdb WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE defaultdb OWNER TO root;

\unrestrict kEXgi0uWr6Naaf0t1mRCuvI2NRbbO0PLDCFZK0ZRJBvUYTHq5Lvffj5BfMo6c4c
\connect defaultdb
\restrict kEXgi0uWr6Naaf0t1mRCuvI2NRbbO0PLDCFZK0ZRJBvUYTHq5Lvffj5BfMo6c4c

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- PostgreSQL database dump complete
--

\unrestrict kEXgi0uWr6Naaf0t1mRCuvI2NRbbO0PLDCFZK0ZRJBvUYTHq5Lvffj5BfMo6c4c

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict pC77RUBKsWBNjNTUUne0azVbxUrj26aAZdIPW0W8O7KlZ1W0qaA3AfoQGSP2vcT

-- Dumped from database version 17.6 (Debian 17.6-1.pgdg13+1)
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- PostgreSQL database dump complete
--

\unrestrict pC77RUBKsWBNjNTUUne0azVbxUrj26aAZdIPW0W8O7KlZ1W0qaA3AfoQGSP2vcT

--
-- PostgreSQL database cluster dump complete
--

