--
-- PostgreSQL database cluster dump
--

\restrict ROcKxJSZTg7iM5figfbxNXzaq3P47iMATQXkXxWJ5qQGcciQw77J7lkRGEbb5fl

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








\unrestrict ROcKxJSZTg7iM5figfbxNXzaq3P47iMATQXkXxWJ5qQGcciQw77J7lkRGEbb5fl

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

\restrict hBPkKMEdXNOHdtOeThbaapbj52P9YjNsyecIGBdmGnOgIVZfdWRMEG20OfvbDak

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

\unrestrict hBPkKMEdXNOHdtOeThbaapbj52P9YjNsyecIGBdmGnOgIVZfdWRMEG20OfvbDak

--
-- Database "defaultdb" dump
--

--
-- PostgreSQL database dump
--

\restrict ClVbGEJI0QMzAsohAqcQhheHnbe6i6gphYmO6gZ0qgIck91hkwAWHA0MBdejdj9

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

\unrestrict ClVbGEJI0QMzAsohAqcQhheHnbe6i6gphYmO6gZ0qgIck91hkwAWHA0MBdejdj9
\connect defaultdb
\restrict ClVbGEJI0QMzAsohAqcQhheHnbe6i6gphYmO6gZ0qgIck91hkwAWHA0MBdejdj9

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

\unrestrict ClVbGEJI0QMzAsohAqcQhheHnbe6i6gphYmO6gZ0qgIck91hkwAWHA0MBdejdj9

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict ia85B3wIxAB8YquscK0jRKuo0GqTg3srVKZcj4odDtGrBg4wWCdDWEdB0TBwFad

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

\unrestrict ia85B3wIxAB8YquscK0jRKuo0GqTg3srVKZcj4odDtGrBg4wWCdDWEdB0TBwFad

--
-- PostgreSQL database cluster dump complete
--

