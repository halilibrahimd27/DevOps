--
-- PostgreSQL database cluster dump
--

\restrict yeNPo8S6znhIKTYahZVcABBWT8Zip4cMXQb59nO6DAYxT7Yhi2A169hSkf1FlZL

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








\unrestrict yeNPo8S6znhIKTYahZVcABBWT8Zip4cMXQb59nO6DAYxT7Yhi2A169hSkf1FlZL

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

\restrict YS6uOz2lpgojd1ifpA4zQOkPMAcDuEf4fhEEnaYV0Ddyx7vhNcpKW3Ynmk8Lmjl

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

\unrestrict YS6uOz2lpgojd1ifpA4zQOkPMAcDuEf4fhEEnaYV0Ddyx7vhNcpKW3Ynmk8Lmjl

--
-- Database "defaultdb" dump
--

--
-- PostgreSQL database dump
--

\restrict wv9HKMiF2AUOlwIzqaSJIl9cDfeTQBA5D3s6yaloYRuOLi0MAUtE2k6FfgsD7lf

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

\unrestrict wv9HKMiF2AUOlwIzqaSJIl9cDfeTQBA5D3s6yaloYRuOLi0MAUtE2k6FfgsD7lf
\connect defaultdb
\restrict wv9HKMiF2AUOlwIzqaSJIl9cDfeTQBA5D3s6yaloYRuOLi0MAUtE2k6FfgsD7lf

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

\unrestrict wv9HKMiF2AUOlwIzqaSJIl9cDfeTQBA5D3s6yaloYRuOLi0MAUtE2k6FfgsD7lf

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict awmyIlFYsFxbyy7s2iH29JunENeRETY8WOQPJXoSoq5PpIo5gwznXPFWFvzfwAZ

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

\unrestrict awmyIlFYsFxbyy7s2iH29JunENeRETY8WOQPJXoSoq5PpIo5gwznXPFWFvzfwAZ

--
-- PostgreSQL database cluster dump complete
--

