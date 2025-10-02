--
-- PostgreSQL database cluster dump
--

\restrict gd36zceymyDBEDVgZlPqbJhIBst3gUlFoR3ueao3thAOfG62QHRUhT5QgBjBZ1E

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








\unrestrict gd36zceymyDBEDVgZlPqbJhIBst3gUlFoR3ueao3thAOfG62QHRUhT5QgBjBZ1E

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

\restrict 7EYSeKKEU8lSS0EP8QRLqQGxCnGtY2BDDgXNJWaYiyw7VocXdZXQEpJgBHmPpVA

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

\unrestrict 7EYSeKKEU8lSS0EP8QRLqQGxCnGtY2BDDgXNJWaYiyw7VocXdZXQEpJgBHmPpVA

--
-- Database "defaultdb" dump
--

--
-- PostgreSQL database dump
--

\restrict 7PQhF78l7ajkmx0uFjhbWY088SFaekbaHhpmZ3P7tfVeuBWrwtU7lV7TiI2viq4

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

\unrestrict 7PQhF78l7ajkmx0uFjhbWY088SFaekbaHhpmZ3P7tfVeuBWrwtU7lV7TiI2viq4
\connect defaultdb
\restrict 7PQhF78l7ajkmx0uFjhbWY088SFaekbaHhpmZ3P7tfVeuBWrwtU7lV7TiI2viq4

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

\unrestrict 7PQhF78l7ajkmx0uFjhbWY088SFaekbaHhpmZ3P7tfVeuBWrwtU7lV7TiI2viq4

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict Tgg2KxLR80EayjFvdxlwd6Kqgwm03zKzaV9sPLCzzq7K2xysC2L9hLuirBrRGY4

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

\unrestrict Tgg2KxLR80EayjFvdxlwd6Kqgwm03zKzaV9sPLCzzq7K2xysC2L9hLuirBrRGY4

--
-- PostgreSQL database cluster dump complete
--

