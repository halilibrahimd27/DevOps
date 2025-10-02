--
-- PostgreSQL database cluster dump
--

\restrict hrcg45sedzI9f0anxSE4Ibpo9mRuoLuQAgZA5arL55yytizPUEyMhAgTxg9sSY0

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








\unrestrict hrcg45sedzI9f0anxSE4Ibpo9mRuoLuQAgZA5arL55yytizPUEyMhAgTxg9sSY0

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

\restrict kdKH9VHtObyrwhYzHClfFQWn1HfQzgY1z5dnjh7k2AKyHwY0mvwOSMNh5aD6gIb

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

\unrestrict kdKH9VHtObyrwhYzHClfFQWn1HfQzgY1z5dnjh7k2AKyHwY0mvwOSMNh5aD6gIb

--
-- Database "defaultdb" dump
--

--
-- PostgreSQL database dump
--

\restrict ecx4tPivJ6rhLbsyD0wKgITF1a6LWSbTaifR0incC4YGfd1U3gIb162LljtmIE1

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

\unrestrict ecx4tPivJ6rhLbsyD0wKgITF1a6LWSbTaifR0incC4YGfd1U3gIb162LljtmIE1
\connect defaultdb
\restrict ecx4tPivJ6rhLbsyD0wKgITF1a6LWSbTaifR0incC4YGfd1U3gIb162LljtmIE1

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

\unrestrict ecx4tPivJ6rhLbsyD0wKgITF1a6LWSbTaifR0incC4YGfd1U3gIb162LljtmIE1

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict u6nu0mWp1CweeoS10pJli0o4vDF3ECoxpgElL4uR9FnQvA2r46OJViCM0q6varF

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

\unrestrict u6nu0mWp1CweeoS10pJli0o4vDF3ECoxpgElL4uR9FnQvA2r46OJViCM0q6varF

--
-- PostgreSQL database cluster dump complete
--

