--
-- PostgreSQL database dump
--

-- Dumped from database version 12.13 (Debian 12.13-1.pgdg100+1)
-- Dumped by pg_dump version 17.5

-- Started on 2025-08-15 11:59:39

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
-- TOC entry 14 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 13 (class 2615 OID 667258)
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- TOC entry 5849 (class 0 OID 0)
-- Dependencies: 13
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- TOC entry 7 (class 3079 OID 667259)
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- TOC entry 5851 (class 0 OID 0)
-- Dependencies: 7
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- TOC entry 6 (class 3079 OID 667270)
-- Name: lo; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS lo WITH SCHEMA public;


--
-- TOC entry 5852 (class 0 OID 0)
-- Dependencies: 6
-- Name: EXTENSION lo; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION lo IS 'Large Object maintenance';


--
-- TOC entry 5 (class 3079 OID 667275)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 5853 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 4 (class 3079 OID 667352)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5854 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 3 (class 3079 OID 667444)
-- Name: tsm_system_rows; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tsm_system_rows WITH SCHEMA public;


--
-- TOC entry 5855 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION tsm_system_rows; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION tsm_system_rows IS 'TABLESAMPLE method which accepts number of rows as a limit';


--
-- TOC entry 2 (class 3079 OID 667446)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 5856 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 808 (class 1255 OID 667457)
-- Name: _asgmlface(text, integer, regclass, text, integer, integer, text, integer); Type: FUNCTION; Schema: topology; Owner: postgres
--

CREATE FUNCTION topology._asgmlface(toponame text, face_id integer, visitedtable regclass, nsprefix_in text, prec integer, options integer, idprefix text, gmlver integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
  visited bool;
  nsprefix text;
  gml text;
  rec RECORD;
  rec2 RECORD;
  bounds geometry;
BEGIN

  nsprefix := 'gml:';
  IF nsprefix_in IS NOT NULL THEN
    IF nsprefix_in = '' THEN
      nsprefix = nsprefix_in;
    ELSE
      nsprefix = nsprefix_in || ':';
    END IF;
  END IF;

  gml := '<' || nsprefix || 'Face ' || nsprefix
    || 'id="' || idprefix || 'F' || face_id || '">';

  -- Construct the face geometry, then for each polygon:
  FOR rec IN SELECT (ST_DumpRings((ST_Dump(ST_ForceRHR(
    topology.ST_GetFaceGeometry(toponame, face_id)))).geom)).geom
  LOOP

      -- Contents of a directed face are the list of edges
      -- that cover the specific ring
      bounds = ST_Boundary(rec.geom);

      FOR rec2 IN EXECUTE
        'SELECT e.*, ST_LineLocatePoint($1'
        || ', ST_LineInterpolatePoint(e.geom, 0.2)) as pos'
        || ', ST_LineLocatePoint($1'
        || ', ST_LineInterpolatePoint(e.geom, 0.8)) as pos2 FROM '
        || quote_ident(toponame)
        || '.edge e WHERE ( e.left_face = $2'
        || ' OR e.right_face = $2'
        || ') AND ST_Covers($1'
        || ', e.geom) ORDER BY pos'
        USING bounds, face_id
      LOOP

        gml = gml || '<' || nsprefix || 'directedEdge';

        -- if this edge goes in same direction to the
        --       ring bounds, make it with negative orientation
        IF rec2.pos2 > rec2.pos THEN -- edge goes in same direction
          gml = gml || ' orientation="-"';
        END IF;

        -- Do visited bookkeeping if visitedTable was given
        IF visitedTable IS NOT NULL THEN

          EXECUTE 'SELECT true FROM '
            || visitedTable::text
            || ' WHERE element_type = 2 AND element_id = '
            || rec2.edge_id LIMIT 1 INTO visited;
          IF visited THEN
            -- Use xlink:href if visited
            gml = gml || ' xlink:href="#' || idprefix || 'E'
                      || rec2.edge_id || '" />';
            CONTINUE;
          ELSE
            -- Mark as visited otherwise
            EXECUTE 'INSERT INTO ' || visitedTable::text
              || '(element_type, element_id) VALUES (2, '
              || rec2.edge_id || ')';
          END IF;

        END IF;

        gml = gml || '>';

        gml = gml || topology._AsGMLEdge(rec2.edge_id, rec2.start_node,
                                        rec2.end_node, rec2.geom,
                                        visitedTable, nsprefix_in,
                                        prec, options, idprefix, gmlver);
        gml = gml || '</' || nsprefix || 'directedEdge>';

      END LOOP;
    END LOOP;

  gml = gml || '</' || nsprefix || 'Face>';

  RETURN gml;
END
$_$;


ALTER FUNCTION topology._asgmlface(toponame text, face_id integer, visitedtable regclass, nsprefix_in text, prec integer, options integer, idprefix text, gmlver integer) OWNER TO postgres;

--
-- TOC entry 809 (class 1255 OID 667458)
-- Name: _st_adjacentedges(character varying, integer, integer); Type: FUNCTION; Schema: topology; Owner: postgres
--

CREATE FUNCTION topology._st_adjacentedges(atopology character varying, anode integer, anedge integer) RETURNS integer[]
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  ret integer[];
BEGIN
  WITH edgestar AS (
    SELECT *, count(*) over () AS cnt
    FROM topology.GetNodeEdges(atopology, anode)
  )
  SELECT ARRAY[ (
      SELECT p.edge AS prev FROM edgestar p
      WHERE p.sequence = CASE WHEN m.sequence-1 < 1 THEN cnt
                         ELSE m.sequence-1 END
    ), (
      SELECT p.edge AS prev FROM edgestar p WHERE p.sequence = ((m.sequence)%cnt)+1
    ) ]
  FROM edgestar m
  WHERE edge = anedge
  INTO ret;

  RETURN ret;
END
$$;


ALTER FUNCTION topology._st_adjacentedges(atopology character varying, anode integer, anedge integer) OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 667459)
-- Name: abiotic_stress_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.abiotic_stress_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.abiotic_stress_id_seq OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 667461)
-- Name: actions_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.actions_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.actions_types_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 211 (class 1259 OID 667463)
-- Name: active_product_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.active_product_locations (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    location_id character varying(50) DEFAULT NULL::character varying,
    location_name character varying(100),
    status smallint DEFAULT 1,
    text_append text,
    content_append character varying(80) DEFAULT NULL::character varying,
    description text,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    url character varying(100),
    text_url_append text
);


ALTER TABLE public.active_product_locations OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 667474)
-- Name: active_subscriber_range_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.active_subscriber_range_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_subscriber_range_id_seq OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 667476)
-- Name: activity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activity_id_seq OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 667478)
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activity_logs_id_seq OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 667480)
-- Name: adoptive_menu_api_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.adoptive_menu_api_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.adoptive_menu_api_actions_id_seq OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 667482)
-- Name: adoptive_menu_content_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.adoptive_menu_content_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.adoptive_menu_content_nodes_id_seq OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 667484)
-- Name: adoptive_menu_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.adoptive_menu_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.adoptive_menu_events_id_seq OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 667486)
-- Name: adoptive_menu_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.adoptive_menu_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.adoptive_menu_files_id_seq OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 667488)
-- Name: adoptive_menu_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.adoptive_menu_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.adoptive_menu_id_seq OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 667490)
-- Name: adoptive_menu_recording_end_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.adoptive_menu_recording_end_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.adoptive_menu_recording_end_files_id_seq OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 667492)
-- Name: adoptive_menu_surveys_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.adoptive_menu_surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.adoptive_menu_surveys_id_seq OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 667494)
-- Name: adoptive_menu_trunk_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.adoptive_menu_trunk_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.adoptive_menu_trunk_actions_id_seq OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 667496)
-- Name: adv_updated; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adv_updated (
    id character varying(255),
    text character varying(5000),
    app_cta character varying(255),
    sms_cta character varying(255)
);


ALTER TABLE public.adv_updated OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 667502)
-- Name: advisory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory (
    id character varying(50) DEFAULT NULL::character varying NOT NULL,
    title_eng character varying(255),
    title_urdu character varying(255),
    content_file_id character varying(100),
    create_dt timestamp(6) with time zone,
    update_dt timestamp(6) with time zone,
    sowing_id character varying(100),
    crop_calender_id character varying(50),
    day integer DEFAULT 0,
    active smallint DEFAULT 1,
    validation_query text,
    text text,
    calender_day integer DEFAULT 0,
    mandatory smallint DEFAULT 0,
    video_url character varying(255),
    ivr_file_id character varying(100),
    group_id character varying(100),
    advisory_day_month character varying(6),
    advisory_tags character varying(255),
    app_cta uuid,
    sms_cta uuid,
    custom_cta_active boolean DEFAULT false,
    activity_type_id uuid,
    advisory_validity smallint DEFAULT 1,
    action_time_id uuid
);


ALTER TABLE public.advisory OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 667515)
-- Name: advisory_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory_conditions (
    id character varying(50) NOT NULL,
    high_value character varying(10) DEFAULT 0,
    low_value character varying(10) DEFAULT 0,
    advisory_id character varying(50),
    weather_condition_id character varying(50),
    before integer DEFAULT 0,
    after integer DEFAULT 0,
    range_type character varying(32),
    create_dt date DEFAULT CURRENT_DATE,
    update_dt date
);


ALTER TABLE public.advisory_conditions OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 667523)
-- Name: advisory_crops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisory_crops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisory_crops_id_seq OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 667525)
-- Name: advisory_feedback; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory_feedback (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(13) NOT NULL,
    advisory_id character varying(50) NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    profiled_by character varying(50),
    profiler_type character varying(20),
    description text
);


ALTER TABLE public.advisory_feedback OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 667534)
-- Name: advisory_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory_groups (
    id character varying(50) DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(50) NOT NULL,
    status smallint DEFAULT 1,
    ivr_file_id character varying(50),
    content_file_id character varying(50),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    crop_calender_id character varying(50)
);


ALTER TABLE public.advisory_groups OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 667540)
-- Name: advisory_growth_stages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory_growth_stages (
    id character varying(100) NOT NULL,
    growth_stage_id character varying(100) NOT NULL,
    advisory_id character varying(50) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1
);


ALTER TABLE public.advisory_growth_stages OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 667545)
-- Name: advisory_growth_stages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisory_growth_stages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisory_growth_stages_id_seq OWNER TO postgres;

--
-- TOC entry 5878 (class 0 OID 0)
-- Dependencies: 230
-- Name: advisory_growth_stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisory_growth_stages_id_seq OWNED BY public.advisory_growth_stages.id;


--
-- TOC entry 231 (class 1259 OID 667547)
-- Name: advisory_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisory_id_seq OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 667549)
-- Name: advisory_livestock_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisory_livestock_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisory_livestock_id_seq OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 667551)
-- Name: advisory_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory_locations (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_id character varying(50) NOT NULL,
    location_id character varying(50) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.advisory_locations OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 667556)
-- Name: advisory_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisory_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisory_locations_id_seq OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 667558)
-- Name: advisory_machineries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisory_machineries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisory_machineries_id_seq OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 667560)
-- Name: advisory_products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory_products (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_id character varying(50) DEFAULT NULL::character varying,
    product_id character varying(50) DEFAULT NULL::character varying,
    product_name character varying(50) DEFAULT NULL::character varying,
    preferred smallint DEFAULT 0,
    chemical_formula character varying(50) DEFAULT NULL::character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    status smallint DEFAULT 1,
    image_webp character varying(255),
    price character varying(20)
);


ALTER TABLE public.advisory_products OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 667574)
-- Name: crop_calender_scheduler; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_scheduler (
    id character varying(50) NOT NULL,
    crop_calender_id character varying(50),
    start_dt timestamp(6) without time zone,
    end_dt timestamp(6) without time zone,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1
);


ALTER TABLE public.crop_calender_scheduler OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 667579)
-- Name: advisory_scheduler_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisory_scheduler_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisory_scheduler_id_seq OWNER TO postgres;

--
-- TOC entry 5887 (class 0 OID 0)
-- Dependencies: 238
-- Name: advisory_scheduler_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisory_scheduler_id_seq OWNED BY public.crop_calender_scheduler.id;


--
-- TOC entry 239 (class 1259 OID 667581)
-- Name: advisory_soil_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory_soil_type (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    advisory_id character varying(255),
    soil_type_id uuid,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.advisory_soil_type OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 667586)
-- Name: advisory_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advisory_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advisory_tags_id_seq OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 667588)
-- Name: agent_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agent_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agent_roles_id_seq OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 667590)
-- Name: agent_roles_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agent_roles_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agent_roles_id_seq1 OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 667592)
-- Name: agents_activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agents_activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agents_activity_logs_id_seq OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 667594)
-- Name: agents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agents_id_seq OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 667596)
-- Name: agri_bank_advisory_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agri_bank_advisory_jobs (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_id character varying(100) NOT NULL,
    create_dt date DEFAULT CURRENT_DATE,
    update_dt timestamp(6) without time zone,
    created smallint DEFAULT 0,
    text text,
    content_file_id character varying(50),
    calender_day integer,
    day integer,
    crop_calender_id character varying(50),
    calender_wise boolean DEFAULT false,
    survey boolean DEFAULT false,
    content_append character varying(255),
    product_id character varying(255),
    survey_created smallint DEFAULT 0,
    job_type character varying(225)
);


ALTER TABLE public.agri_bank_advisory_jobs OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 667608)
-- Name: agri_bank_advisory_jobs_global; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agri_bank_advisory_jobs_global (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_id character varying(100) NOT NULL,
    create_dt date DEFAULT CURRENT_DATE,
    update_dt timestamp(6) without time zone,
    created smallint DEFAULT 0,
    text text,
    content_file_id character varying(50),
    calender_day integer,
    day integer,
    crop_calender_id character varying(50),
    calender_wise boolean DEFAULT false,
    survey boolean DEFAULT false,
    content_append character varying(255),
    product_id character varying(255),
    survey_created smallint DEFAULT 0
);


ALTER TABLE public.agri_bank_advisory_jobs_global OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 667620)
-- Name: agri_bank_advisory_jobs_old; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agri_bank_advisory_jobs_old (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_id character varying(110) NOT NULL,
    create_dt date DEFAULT CURRENT_DATE,
    update_dt timestamp(6) without time zone,
    created smallint DEFAULT 0
);


ALTER TABLE public.agri_bank_advisory_jobs_old OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 667626)
-- Name: agri_bank_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agri_bank_data (
    id character varying(255) NOT NULL,
    msisdn character varying(11) NOT NULL,
    country_code character varying(3) NOT NULL,
    full_msisdn character varying(15) NOT NULL,
    advisory_id character varying(50) NOT NULL,
    text text,
    content_file character varying(100),
    content_folder character varying(100),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.agri_bank_data OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 667632)
-- Name: api_call_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_call_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_call_details_id_seq OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 667634)
-- Name: api_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_methods_id_seq OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 667636)
-- Name: api_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_permissions_id_seq OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 667638)
-- Name: api_resource_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_resource_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_resource_category_id_seq OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 667640)
-- Name: api_resource_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_resource_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_resource_permissions_id_seq OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 667642)
-- Name: api_resource_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_resource_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_resource_roles_id_seq OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 667644)
-- Name: api_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_resources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_resources_id_seq OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 667646)
-- Name: app_cta; Type: TABLE; Schema: public; Owner: bkkdev_rw
--

CREATE TABLE public.app_cta (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active smallint DEFAULT 1
);


ALTER TABLE public.app_cta OWNER TO bkkdev_rw;

--
-- TOC entry 257 (class 1259 OID 667653)
-- Name: app_cta_translations; Type: TABLE; Schema: public; Owner: bkkdev_rw
--

CREATE TABLE public.app_cta_translations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    app_cta_id uuid NOT NULL,
    language_id uuid NOT NULL,
    text character varying(255),
    is_default boolean DEFAULT false,
    is_standard boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active smallint DEFAULT 1
);


ALTER TABLE public.app_cta_translations OWNER TO bkkdev_rw;

--
-- TOC entry 258 (class 1259 OID 667662)
-- Name: application_docs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.application_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.application_docs_id_seq OWNER TO postgres;

--
-- TOC entry 689 (class 1259 OID 1564364)
-- Name: application_methods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.application_methods (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.application_methods OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 667664)
-- Name: application_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.application_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.application_status_id_seq OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 667666)
-- Name: badges_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.badges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.badges_id_seq OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 667668)
-- Name: barani_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.barani_locations (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    location_id character varying(50) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.barani_locations OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 667706)
-- Name: blacklist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.blacklist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.blacklist_id_seq OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 667708)
-- Name: campaign_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.campaign_categories_id_seq OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 667710)
-- Name: campaign_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.campaign_files_id_seq OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 667712)
-- Name: campaign_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.campaign_profiles_id_seq OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 667714)
-- Name: campaign_promo_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_promo_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.campaign_promo_data_id_seq OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 667716)
-- Name: campaign_recording_end_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_recording_end_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.campaign_recording_end_files_id_seq OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 667718)
-- Name: campaign_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.campaign_types_id_seq OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 667720)
-- Name: case_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.case_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.case_categories_id_seq OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 667722)
-- Name: case_media_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.case_media_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.case_media_contents_id_seq OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 667724)
-- Name: case_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.case_parameters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.case_parameters_id_seq OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 667726)
-- Name: case_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.case_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.case_tags_id_seq OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 667728)
-- Name: cases_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cases_id_seq OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 667730)
-- Name: cdr_asterisk_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cdr_asterisk_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cdr_asterisk_id_seq OWNER TO postgres;

--
-- TOC entry 702 (class 1259 OID 1566386)
-- Name: chemical_types; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.chemical_types (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.chemical_types OWNER TO rameez_dev_rw;

--
-- TOC entry 703 (class 1259 OID 1566395)
-- Name: chemicals; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.chemicals (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(500) NOT NULL,
    chemical_type_id uuid NOT NULL,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.chemicals OWNER TO rameez_dev_rw;

--
-- TOC entry 280 (class 1259 OID 667732)
-- Name: clauses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clauses_id_seq OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 667734)
-- Name: content_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.content_files (
    id integer NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    file_name character varying(255) DEFAULT NULL::character varying NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    folder_path character varying(255) NOT NULL,
    folder_id bigint NOT NULL
);


ALTER TABLE public.content_files OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 667744)
-- Name: content_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.content_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.content_files_id_seq OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 667746)
-- Name: content_files_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.content_files_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.content_files_id_seq1 OWNER TO postgres;

--
-- TOC entry 5928 (class 0 OID 0)
-- Dependencies: 283
-- Name: content_files_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.content_files_id_seq1 OWNED BY public.content_files.id;


--
-- TOC entry 284 (class 1259 OID 667748)
-- Name: content_folders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.content_folders (
    id integer NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    folder_path character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.content_folders OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 667758)
-- Name: content_folders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.content_folders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.content_folders_id_seq OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 667760)
-- Name: content_folders_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.content_folders_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.content_folders_id_seq1 OWNER TO postgres;

--
-- TOC entry 5932 (class 0 OID 0)
-- Dependencies: 286
-- Name: content_folders_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.content_folders_id_seq1 OWNED BY public.content_folders.id;


--
-- TOC entry 262 (class 1259 OID 667673)
-- Name: crop_calender; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender (
    id character varying(100) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    text_ur text,
    text_en text,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    crop_id character varying(100),
    livestock_id character varying(100),
    livestock boolean DEFAULT false,
    fruit boolean DEFAULT false,
    domestic boolean DEFAULT false
);


ALTER TABLE public.crop_calender OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 667762)
-- Name: crop_calender_a_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_calender_a_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_calender_a_seq OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 667764)
-- Name: crop_calender_assosiated_crops_livestocks; Type: TABLE; Schema: public; Owner: bkkdev_rw
--

CREATE TABLE public.crop_calender_assosiated_crops_livestocks (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    crop_calender_id character varying(50),
    crop_id character varying(50),
    livestock_id character varying(50),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active integer DEFAULT 1
);


ALTER TABLE public.crop_calender_assosiated_crops_livestocks OWNER TO bkkdev_rw;

--
-- TOC entry 289 (class 1259 OID 667770)
-- Name: crop_calender_crops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_calender_crops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_calender_crops_id_seq OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 667772)
-- Name: crop_calender_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_calender_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_calender_id_seq OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 667774)
-- Name: crop_calender_languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_languages (
    id character varying(500) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_id character varying(50) NOT NULL,
    language_id character varying(50) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1
);


ALTER TABLE public.crop_calender_languages OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 667783)
-- Name: crop_calender_languages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_calender_languages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_calender_languages_id_seq OWNER TO postgres;

--
-- TOC entry 5940 (class 0 OID 0)
-- Dependencies: 292
-- Name: crop_calender_languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_calender_languages_id_seq OWNED BY public.crop_calender_languages.id;


--
-- TOC entry 263 (class 1259 OID 667684)
-- Name: crop_calender_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_locations (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_scheduler_id character varying(50),
    location_id character varying(100) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1
);


ALTER TABLE public.crop_calender_locations OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 667785)
-- Name: crop_calender_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_calender_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_calender_locations_id_seq OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 667787)
-- Name: crop_calender_scheduler_seed_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_scheduler_seed_types (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    scheduler_id character varying(50) NOT NULL,
    seed_type_id character varying(100) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1
);


ALTER TABLE public.crop_calender_scheduler_seed_types OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 667793)
-- Name: crop_calender_seed_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_calender_seed_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_calender_seed_types_id_seq OWNER TO postgres;

--
-- TOC entry 5945 (class 0 OID 0)
-- Dependencies: 295
-- Name: crop_calender_seed_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_calender_seed_types_id_seq OWNED BY public.crop_calender_scheduler_seed_types.id;


--
-- TOC entry 264 (class 1259 OID 667690)
-- Name: crop_calender_sowing_window; Type: TABLE; Schema: public; Owner: bkkdev_rw
--

CREATE TABLE public.crop_calender_sowing_window (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_id character varying(50),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.crop_calender_sowing_window OWNER TO bkkdev_rw;

--
-- TOC entry 265 (class 1259 OID 667695)
-- Name: crop_calender_sowing_window_schedule_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_sowing_window_schedule_locations (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_sowing_window_schedule_id character varying(50),
    location_id character varying(50),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.crop_calender_sowing_window_schedule_locations OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 667700)
-- Name: crop_calender_sowing_window_schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_sowing_window_schedules (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_sowing_window_id character varying(50),
    barani boolean DEFAULT false,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    start_time character varying(6) NOT NULL,
    end_time character varying(6) NOT NULL
);


ALTER TABLE public.crop_calender_sowing_window_schedules OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 667795)
-- Name: crop_calender_stages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_stages (
    id character varying(100) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_id character varying(100),
    stage_start bigint,
    stage_end bigint,
    create_dt date DEFAULT CURRENT_DATE,
    update_dt date
);


ALTER TABLE public.crop_calender_stages OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 667800)
-- Name: crop_calender_stages_growth_stages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_stages_growth_stages (
    id character varying(100) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    growth_stage_id character varying(100) NOT NULL,
    crop_calender_stage_id character varying(50) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1
);


ALTER TABLE public.crop_calender_stages_growth_stages OWNER TO postgres;

--
-- TOC entry 298 (class 1259 OID 667806)
-- Name: crop_calender_weather_favourable_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_calender_weather_favourable_conditions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_calender_weather_favourable_conditions_id_seq OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 667808)
-- Name: crop_calender_weather_unfavourable_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_calender_weather_unfavourable_conditions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_calender_weather_unfavourable_conditions_id_seq OWNER TO postgres;

--
-- TOC entry 300 (class 1259 OID 667810)
-- Name: crop_diseases_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_diseases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.crop_diseases_id_seq OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 667812)
-- Name: crop_growth_stages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crop_growth_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crop_growth_stages_id_seq OWNER TO postgres;

--
-- TOC entry 302 (class 1259 OID 667814)
-- Name: crop_variety_ml; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_variety_ml (
    title_urdu character varying(255),
    id integer
);


ALTER TABLE public.crop_variety_ml OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 667817)
-- Name: crops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crops_id_seq OWNER TO postgres;

--
-- TOC entry 304 (class 1259 OID 667819)
-- Name: crops_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.crops_parameters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crops_parameters_id_seq OWNER TO postgres;

--
-- TOC entry 691 (class 1259 OID 1564384)
-- Name: environment_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.environment_conditions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.environment_conditions OWNER TO postgres;

--
-- TOC entry 651 (class 1259 OID 707669)
-- Name: farmer_advisory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory OWNER TO postgres;

--
-- TOC entry 652 (class 1259 OID 828985)
-- Name: farmer_advisory_2025_07_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_11 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_11 OWNER TO postgres;

--
-- TOC entry 653 (class 1259 OID 829316)
-- Name: farmer_advisory_2025_07_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_12 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_12 OWNER TO postgres;

--
-- TOC entry 654 (class 1259 OID 829596)
-- Name: farmer_advisory_2025_07_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_13 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_13 OWNER TO postgres;

--
-- TOC entry 655 (class 1259 OID 829872)
-- Name: farmer_advisory_2025_07_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_14 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_14 OWNER TO postgres;

--
-- TOC entry 656 (class 1259 OID 830161)
-- Name: farmer_advisory_2025_07_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_15 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_15 OWNER TO postgres;

--
-- TOC entry 657 (class 1259 OID 830478)
-- Name: farmer_advisory_2025_07_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_16 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_16 OWNER TO postgres;

--
-- TOC entry 658 (class 1259 OID 830815)
-- Name: farmer_advisory_2025_07_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_17 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_17 OWNER TO postgres;

--
-- TOC entry 659 (class 1259 OID 831139)
-- Name: farmer_advisory_2025_07_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_18 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_18 OWNER TO postgres;

--
-- TOC entry 660 (class 1259 OID 872145)
-- Name: farmer_advisory_2025_07_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_19 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_19 OWNER TO postgres;

--
-- TOC entry 661 (class 1259 OID 872447)
-- Name: farmer_advisory_2025_07_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_20 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_20 OWNER TO postgres;

--
-- TOC entry 662 (class 1259 OID 872703)
-- Name: farmer_advisory_2025_07_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_21 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_21 OWNER TO postgres;

--
-- TOC entry 663 (class 1259 OID 983785)
-- Name: farmer_advisory_2025_07_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_22 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_22 OWNER TO postgres;

--
-- TOC entry 665 (class 1259 OID 1090480)
-- Name: farmer_advisory_2025_07_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_23 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_23 OWNER TO postgres;

--
-- TOC entry 666 (class 1259 OID 1090812)
-- Name: farmer_advisory_2025_07_24; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_24 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_24 OWNER TO postgres;

--
-- TOC entry 667 (class 1259 OID 1091116)
-- Name: farmer_advisory_2025_07_25; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_25 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_25 OWNER TO postgres;

--
-- TOC entry 668 (class 1259 OID 1134011)
-- Name: farmer_advisory_2025_07_26; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_26 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_26 OWNER TO postgres;

--
-- TOC entry 669 (class 1259 OID 1134289)
-- Name: farmer_advisory_2025_07_27; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_27 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_27 OWNER TO postgres;

--
-- TOC entry 670 (class 1259 OID 1134554)
-- Name: farmer_advisory_2025_07_28; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_28 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_28 OWNER TO postgres;

--
-- TOC entry 673 (class 1259 OID 1178015)
-- Name: farmer_advisory_2025_07_29; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_29 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_29 OWNER TO postgres;

--
-- TOC entry 674 (class 1259 OID 1560935)
-- Name: farmer_advisory_2025_07_30; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_30 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_30 OWNER TO postgres;

--
-- TOC entry 675 (class 1259 OID 1561531)
-- Name: farmer_advisory_2025_07_31; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_07_31 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_07_31 OWNER TO postgres;

--
-- TOC entry 676 (class 1259 OID 1561871)
-- Name: farmer_advisory_2025_08_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_01 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_01 OWNER TO postgres;

--
-- TOC entry 677 (class 1259 OID 1562182)
-- Name: farmer_advisory_2025_08_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_02 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_02 OWNER TO postgres;

--
-- TOC entry 678 (class 1259 OID 1562468)
-- Name: farmer_advisory_2025_08_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_03 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_03 OWNER TO postgres;

--
-- TOC entry 679 (class 1259 OID 1562800)
-- Name: farmer_advisory_2025_08_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_04 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_04 OWNER TO postgres;

--
-- TOC entry 680 (class 1259 OID 1563059)
-- Name: farmer_advisory_2025_08_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_05 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_05 OWNER TO postgres;

--
-- TOC entry 681 (class 1259 OID 1563410)
-- Name: farmer_advisory_2025_08_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_06 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_06 OWNER TO postgres;

--
-- TOC entry 682 (class 1259 OID 1563667)
-- Name: farmer_advisory_2025_08_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_07 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_07 OWNER TO postgres;

--
-- TOC entry 683 (class 1259 OID 1564001)
-- Name: farmer_advisory_2025_08_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_08 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_08 OWNER TO postgres;

--
-- TOC entry 694 (class 1259 OID 1564467)
-- Name: farmer_advisory_2025_08_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_09 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_09 OWNER TO postgres;

--
-- TOC entry 695 (class 1259 OID 1564748)
-- Name: farmer_advisory_2025_08_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_10 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_10 OWNER TO postgres;

--
-- TOC entry 696 (class 1259 OID 1565076)
-- Name: farmer_advisory_2025_08_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_11 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_11 OWNER TO postgres;

--
-- TOC entry 697 (class 1259 OID 1565347)
-- Name: farmer_advisory_2025_08_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_12 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_12 OWNER TO postgres;

--
-- TOC entry 698 (class 1259 OID 1565677)
-- Name: farmer_advisory_2025_08_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_13 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_13 OWNER TO postgres;

--
-- TOC entry 701 (class 1259 OID 1566263)
-- Name: farmer_advisory_2025_08_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_14 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_14 OWNER TO postgres;

--
-- TOC entry 706 (class 1259 OID 1566499)
-- Name: farmer_advisory_2025_08_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_2025_08_15 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_2025_08_15 OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 667821)
-- Name: farmer_advisory_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_copy1 (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100),
    livestock_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.farmer_advisory_copy1 OWNER TO postgres;

--
-- TOC entry 306 (class 1259 OID 667831)
-- Name: farmer_advisory_global; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_global (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    stage_date timestamp(0) without time zone,
    location_id character varying(50),
    growth_stage_id character varying(50),
    farm_id character varying(100),
    crop_id character varying(100)
);


ALTER TABLE public.farmer_advisory_global OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 667840)
-- Name: farmer_advisory_old; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_old (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    advisory_id character varying(50),
    advisory_content_file_id character varying,
    advisory_crop_calender_id character varying,
    advisory_day character varying(50),
    advisory_text text,
    advisory_calender_day character varying(50),
    job_id character varying(50)
);


ALTER TABLE public.farmer_advisory_old OWNER TO postgres;

--
-- TOC entry 308 (class 1259 OID 667849)
-- Name: farmer_advisory_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_advisory_stats (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    rabbi json,
    kharif json,
    perennial json,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    unique_crop_users bigint DEFAULT 0 NOT NULL,
    total_crops_marked bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.farmer_advisory_stats OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 667860)
-- Name: farmer_badge_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.farmer_badge_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.farmer_badge_recommendations_id_seq OWNER TO postgres;

--
-- TOC entry 310 (class 1259 OID 667862)
-- Name: farming_activity_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farming_activity_types (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    title_urdu character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active integer DEFAULT 1
);


ALTER TABLE public.farming_activity_types OWNER TO postgres;

--
-- TOC entry 311 (class 1259 OID 667871)
-- Name: field_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.field_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.field_visits_id_seq OWNER TO postgres;

--
-- TOC entry 686 (class 1259 OID 1564334)
-- Name: formulations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.formulations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.formulations OWNER TO postgres;

--
-- TOC entry 312 (class 1259 OID 667873)
-- Name: forum_hide_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_hide_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forum_hide_posts_id_seq OWNER TO postgres;

--
-- TOC entry 313 (class 1259 OID 667875)
-- Name: forum_hide_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_hide_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forum_hide_users_id_seq OWNER TO postgres;

--
-- TOC entry 314 (class 1259 OID 667877)
-- Name: forum_media_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_media_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forum_media_id_seq OWNER TO postgres;

--
-- TOC entry 315 (class 1259 OID 667879)
-- Name: forum_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.forum_posts_id_seq OWNER TO postgres;

--
-- TOC entry 316 (class 1259 OID 667881)
-- Name: forum_report_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_report_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forum_report_posts_id_seq OWNER TO postgres;

--
-- TOC entry 317 (class 1259 OID 667883)
-- Name: forum_report_reason_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_report_reason_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forum_report_reason_actions_id_seq OWNER TO postgres;

--
-- TOC entry 318 (class 1259 OID 667885)
-- Name: forum_report_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_report_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forum_report_reasons_id_seq OWNER TO postgres;

--
-- TOC entry 319 (class 1259 OID 667887)
-- Name: forum_report_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_report_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forum_report_users_id_seq OWNER TO postgres;

--
-- TOC entry 320 (class 1259 OID 667889)
-- Name: forum_user_agreements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forum_user_agreements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forum_user_agreements_id_seq OWNER TO postgres;

--
-- TOC entry 699 (class 1259 OID 1566045)
-- Name: geographic_locations; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.geographic_locations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.geographic_locations OWNER TO rameez_dev_rw;

--
-- TOC entry 321 (class 1259 OID 667891)
-- Name: in_app_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.in_app_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.in_app_notifications_id_seq OWNER TO postgres;

--
-- TOC entry 322 (class 1259 OID 667893)
-- Name: incentive_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.incentive_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.incentive_transactions_id_seq OWNER TO postgres;

--
-- TOC entry 323 (class 1259 OID 667895)
-- Name: incentive_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.incentive_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.incentive_types_id_seq OWNER TO postgres;

--
-- TOC entry 324 (class 1259 OID 667897)
-- Name: irrigation_source_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.irrigation_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.irrigation_source_id_seq OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 667899)
-- Name: ivr_paths_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ivr_paths_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ivr_paths_id_seq OWNER TO postgres;

--
-- TOC entry 326 (class 1259 OID 667901)
-- Name: ivr_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ivr_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ivr_sessions_id_seq OWNER TO postgres;

--
-- TOC entry 327 (class 1259 OID 667903)
-- Name: job_12_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_12_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_12_logs_id_seq OWNER TO postgres;

--
-- TOC entry 328 (class 1259 OID 667905)
-- Name: job_19_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_19_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_19_logs_id_seq OWNER TO postgres;

--
-- TOC entry 329 (class 1259 OID 667907)
-- Name: job_1_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_1_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_1_logs_id_seq OWNER TO postgres;

--
-- TOC entry 330 (class 1259 OID 667909)
-- Name: job_20_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_20_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_20_logs_id_seq OWNER TO postgres;

--
-- TOC entry 331 (class 1259 OID 667911)
-- Name: job_21_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_21_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_21_logs_id_seq OWNER TO postgres;

--
-- TOC entry 332 (class 1259 OID 667913)
-- Name: job_22_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_22_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_22_logs_id_seq OWNER TO postgres;

--
-- TOC entry 333 (class 1259 OID 667915)
-- Name: job_25_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_25_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_25_logs_id_seq OWNER TO postgres;

--
-- TOC entry 334 (class 1259 OID 667917)
-- Name: job_27_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_27_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_27_logs_id_seq OWNER TO postgres;

--
-- TOC entry 335 (class 1259 OID 667919)
-- Name: job_28_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_28_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_28_logs_id_seq OWNER TO postgres;

--
-- TOC entry 336 (class 1259 OID 667921)
-- Name: job_31_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_31_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_31_logs_id_seq OWNER TO postgres;

--
-- TOC entry 337 (class 1259 OID 667923)
-- Name: job_32_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_32_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_32_logs_id_seq OWNER TO postgres;

--
-- TOC entry 338 (class 1259 OID 667925)
-- Name: job_335_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_335_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_335_logs_id_seq OWNER TO postgres;

--
-- TOC entry 339 (class 1259 OID 667927)
-- Name: job_336_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_336_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_336_logs_id_seq OWNER TO postgres;

--
-- TOC entry 340 (class 1259 OID 667929)
-- Name: job_337_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_337_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_337_logs_id_seq OWNER TO postgres;

--
-- TOC entry 341 (class 1259 OID 667931)
-- Name: job_338_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_338_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_338_logs_id_seq OWNER TO postgres;

--
-- TOC entry 342 (class 1259 OID 667933)
-- Name: job_33_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_33_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_33_logs_id_seq OWNER TO postgres;

--
-- TOC entry 343 (class 1259 OID 667935)
-- Name: job_34_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_34_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_34_logs_id_seq OWNER TO postgres;

--
-- TOC entry 344 (class 1259 OID 667937)
-- Name: job_353_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_353_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_353_logs_id_seq OWNER TO postgres;

--
-- TOC entry 345 (class 1259 OID 667939)
-- Name: job_354_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_354_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_354_logs_id_seq OWNER TO postgres;

--
-- TOC entry 346 (class 1259 OID 667941)
-- Name: job_356_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_356_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_356_logs_id_seq OWNER TO postgres;

--
-- TOC entry 347 (class 1259 OID 667943)
-- Name: job_357_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_357_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_357_logs_id_seq OWNER TO postgres;

--
-- TOC entry 348 (class 1259 OID 667945)
-- Name: job_358_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_358_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_358_logs_id_seq OWNER TO postgres;

--
-- TOC entry 349 (class 1259 OID 667947)
-- Name: job_359_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_359_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_359_logs_id_seq OWNER TO postgres;

--
-- TOC entry 350 (class 1259 OID 667949)
-- Name: job_35_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_35_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_35_logs_id_seq OWNER TO postgres;

--
-- TOC entry 351 (class 1259 OID 667951)
-- Name: job_365_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_365_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_365_logs_id_seq OWNER TO postgres;

--
-- TOC entry 352 (class 1259 OID 667953)
-- Name: job_366_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_366_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_366_logs_id_seq OWNER TO postgres;

--
-- TOC entry 353 (class 1259 OID 667955)
-- Name: job_367_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_367_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_367_logs_id_seq OWNER TO postgres;

--
-- TOC entry 354 (class 1259 OID 667957)
-- Name: job_368_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_368_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_368_logs_id_seq OWNER TO postgres;

--
-- TOC entry 355 (class 1259 OID 667959)
-- Name: job_369_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_369_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_369_logs_id_seq OWNER TO postgres;

--
-- TOC entry 356 (class 1259 OID 667961)
-- Name: job_36_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_36_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_36_logs_id_seq OWNER TO postgres;

--
-- TOC entry 357 (class 1259 OID 667963)
-- Name: job_370_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_370_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_370_logs_id_seq OWNER TO postgres;

--
-- TOC entry 358 (class 1259 OID 667965)
-- Name: job_371_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_371_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_371_logs_id_seq OWNER TO postgres;

--
-- TOC entry 359 (class 1259 OID 667967)
-- Name: job_372_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_372_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_372_logs_id_seq OWNER TO postgres;

--
-- TOC entry 360 (class 1259 OID 667969)
-- Name: job_373_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_373_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_373_logs_id_seq OWNER TO postgres;

--
-- TOC entry 361 (class 1259 OID 667971)
-- Name: job_374_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_374_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_374_logs_id_seq OWNER TO postgres;

--
-- TOC entry 362 (class 1259 OID 667973)
-- Name: job_375_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_375_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_375_logs_id_seq OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 667975)
-- Name: job_376_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_376_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_376_logs_id_seq OWNER TO postgres;

--
-- TOC entry 364 (class 1259 OID 667977)
-- Name: job_377_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_377_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_377_logs_id_seq OWNER TO postgres;

--
-- TOC entry 365 (class 1259 OID 667979)
-- Name: job_378_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_378_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_378_logs_id_seq OWNER TO postgres;

--
-- TOC entry 366 (class 1259 OID 667981)
-- Name: job_379_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_379_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_379_logs_id_seq OWNER TO postgres;

--
-- TOC entry 367 (class 1259 OID 667983)
-- Name: job_37_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_37_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_37_logs_id_seq OWNER TO postgres;

--
-- TOC entry 368 (class 1259 OID 667985)
-- Name: job_380_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_380_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_380_logs_id_seq OWNER TO postgres;

--
-- TOC entry 369 (class 1259 OID 667987)
-- Name: job_381_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_381_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_381_logs_id_seq OWNER TO postgres;

--
-- TOC entry 370 (class 1259 OID 667989)
-- Name: job_382_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_382_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_382_logs_id_seq OWNER TO postgres;

--
-- TOC entry 371 (class 1259 OID 667991)
-- Name: job_383_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_383_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_383_logs_id_seq OWNER TO postgres;

--
-- TOC entry 372 (class 1259 OID 667993)
-- Name: job_384_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_384_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_384_logs_id_seq OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 667995)
-- Name: job_386_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_386_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_386_logs_id_seq OWNER TO postgres;

--
-- TOC entry 374 (class 1259 OID 667997)
-- Name: job_387_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_387_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_387_logs_id_seq OWNER TO postgres;

--
-- TOC entry 375 (class 1259 OID 667999)
-- Name: job_389_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_389_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_389_logs_id_seq OWNER TO postgres;

--
-- TOC entry 376 (class 1259 OID 668001)
-- Name: job_38_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_38_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_38_logs_id_seq OWNER TO postgres;

--
-- TOC entry 377 (class 1259 OID 668003)
-- Name: job_390_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_390_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_390_logs_id_seq OWNER TO postgres;

--
-- TOC entry 378 (class 1259 OID 668005)
-- Name: job_391_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_391_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_391_logs_id_seq OWNER TO postgres;

--
-- TOC entry 379 (class 1259 OID 668007)
-- Name: job_392_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_392_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_392_logs_id_seq OWNER TO postgres;

--
-- TOC entry 380 (class 1259 OID 668009)
-- Name: job_393_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_393_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_393_logs_id_seq OWNER TO postgres;

--
-- TOC entry 381 (class 1259 OID 668011)
-- Name: job_394_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_394_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_394_logs_id_seq OWNER TO postgres;

--
-- TOC entry 382 (class 1259 OID 668013)
-- Name: job_395_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_395_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_395_logs_id_seq OWNER TO postgres;

--
-- TOC entry 383 (class 1259 OID 668015)
-- Name: job_396_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_396_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_396_logs_id_seq OWNER TO postgres;

--
-- TOC entry 384 (class 1259 OID 668017)
-- Name: job_397_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_397_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_397_logs_id_seq OWNER TO postgres;

--
-- TOC entry 385 (class 1259 OID 668019)
-- Name: job_398_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_398_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_398_logs_id_seq OWNER TO postgres;

--
-- TOC entry 386 (class 1259 OID 668021)
-- Name: job_399_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_399_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_399_logs_id_seq OWNER TO postgres;

--
-- TOC entry 387 (class 1259 OID 668023)
-- Name: job_39_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_39_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_39_logs_id_seq OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 668025)
-- Name: job_400_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_400_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_400_logs_id_seq OWNER TO postgres;

--
-- TOC entry 389 (class 1259 OID 668027)
-- Name: job_401_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_401_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_401_logs_id_seq OWNER TO postgres;

--
-- TOC entry 390 (class 1259 OID 668029)
-- Name: job_402_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_402_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_402_logs_id_seq OWNER TO postgres;

--
-- TOC entry 391 (class 1259 OID 668031)
-- Name: job_403_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_403_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_403_logs_id_seq OWNER TO postgres;

--
-- TOC entry 392 (class 1259 OID 668033)
-- Name: job_404_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_404_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_404_logs_id_seq OWNER TO postgres;

--
-- TOC entry 393 (class 1259 OID 668035)
-- Name: job_405_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_405_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_405_logs_id_seq OWNER TO postgres;

--
-- TOC entry 394 (class 1259 OID 668037)
-- Name: job_406_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_406_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_406_logs_id_seq OWNER TO postgres;

--
-- TOC entry 395 (class 1259 OID 668039)
-- Name: job_407_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_407_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_407_logs_id_seq OWNER TO postgres;

--
-- TOC entry 396 (class 1259 OID 668041)
-- Name: job_408_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_408_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_408_logs_id_seq OWNER TO postgres;

--
-- TOC entry 397 (class 1259 OID 668043)
-- Name: job_409_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_409_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_409_logs_id_seq OWNER TO postgres;

--
-- TOC entry 398 (class 1259 OID 668045)
-- Name: job_40_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_40_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_40_logs_id_seq OWNER TO postgres;

--
-- TOC entry 399 (class 1259 OID 668047)
-- Name: job_410_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_410_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_410_logs_id_seq OWNER TO postgres;

--
-- TOC entry 400 (class 1259 OID 668049)
-- Name: job_411_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_411_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_411_logs_id_seq OWNER TO postgres;

--
-- TOC entry 401 (class 1259 OID 668051)
-- Name: job_412_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_412_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_412_logs_id_seq OWNER TO postgres;

--
-- TOC entry 402 (class 1259 OID 668053)
-- Name: job_413_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_413_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_413_logs_id_seq OWNER TO postgres;

--
-- TOC entry 403 (class 1259 OID 668055)
-- Name: job_414_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_414_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_414_logs_id_seq OWNER TO postgres;

--
-- TOC entry 404 (class 1259 OID 668057)
-- Name: job_415_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_415_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_415_logs_id_seq OWNER TO postgres;

--
-- TOC entry 405 (class 1259 OID 668059)
-- Name: job_416_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_416_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_416_logs_id_seq OWNER TO postgres;

--
-- TOC entry 406 (class 1259 OID 668061)
-- Name: job_417_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_417_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_417_logs_id_seq OWNER TO postgres;

--
-- TOC entry 407 (class 1259 OID 668063)
-- Name: job_418_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_418_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_418_logs_id_seq OWNER TO postgres;

--
-- TOC entry 408 (class 1259 OID 668065)
-- Name: job_419_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_419_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_419_logs_id_seq OWNER TO postgres;

--
-- TOC entry 409 (class 1259 OID 668067)
-- Name: job_41_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_41_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_41_logs_id_seq OWNER TO postgres;

--
-- TOC entry 410 (class 1259 OID 668069)
-- Name: job_420_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_420_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_420_logs_id_seq OWNER TO postgres;

--
-- TOC entry 411 (class 1259 OID 668071)
-- Name: job_421_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_421_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_421_logs_id_seq OWNER TO postgres;

--
-- TOC entry 412 (class 1259 OID 668073)
-- Name: job_422_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_422_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_422_logs_id_seq OWNER TO postgres;

--
-- TOC entry 413 (class 1259 OID 668075)
-- Name: job_423_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_423_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_423_logs_id_seq OWNER TO postgres;

--
-- TOC entry 414 (class 1259 OID 668077)
-- Name: job_424_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_424_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_424_logs_id_seq OWNER TO postgres;

--
-- TOC entry 415 (class 1259 OID 668079)
-- Name: job_425_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_425_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_425_logs_id_seq OWNER TO postgres;

--
-- TOC entry 416 (class 1259 OID 668081)
-- Name: job_426_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_426_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_426_logs_id_seq OWNER TO postgres;

--
-- TOC entry 417 (class 1259 OID 668083)
-- Name: job_427_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_427_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_427_logs_id_seq OWNER TO postgres;

--
-- TOC entry 418 (class 1259 OID 668085)
-- Name: job_428_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_428_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_428_logs_id_seq OWNER TO postgres;

--
-- TOC entry 419 (class 1259 OID 668087)
-- Name: job_429_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_429_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_429_logs_id_seq OWNER TO postgres;

--
-- TOC entry 420 (class 1259 OID 668089)
-- Name: job_430_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_430_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_430_logs_id_seq OWNER TO postgres;

--
-- TOC entry 421 (class 1259 OID 668091)
-- Name: job_431_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_431_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_431_logs_id_seq OWNER TO postgres;

--
-- TOC entry 422 (class 1259 OID 668093)
-- Name: job_432_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_432_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_432_logs_id_seq OWNER TO postgres;

--
-- TOC entry 423 (class 1259 OID 668095)
-- Name: job_433_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_433_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_433_logs_id_seq OWNER TO postgres;

--
-- TOC entry 424 (class 1259 OID 668097)
-- Name: job_435_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_435_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_435_logs_id_seq OWNER TO postgres;

--
-- TOC entry 425 (class 1259 OID 668099)
-- Name: job_436_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_436_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_436_logs_id_seq OWNER TO postgres;

--
-- TOC entry 426 (class 1259 OID 668101)
-- Name: job_437_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_437_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_437_logs_id_seq OWNER TO postgres;

--
-- TOC entry 427 (class 1259 OID 668103)
-- Name: job_438_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_438_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_438_logs_id_seq OWNER TO postgres;

--
-- TOC entry 428 (class 1259 OID 668105)
-- Name: job_439_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_439_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_439_logs_id_seq OWNER TO postgres;

--
-- TOC entry 429 (class 1259 OID 668107)
-- Name: job_43_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_43_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_43_logs_id_seq OWNER TO postgres;

--
-- TOC entry 430 (class 1259 OID 668109)
-- Name: job_440_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_440_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_440_logs_id_seq OWNER TO postgres;

--
-- TOC entry 431 (class 1259 OID 668111)
-- Name: job_441_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_441_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_441_logs_id_seq OWNER TO postgres;

--
-- TOC entry 432 (class 1259 OID 668113)
-- Name: job_442_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_442_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_442_logs_id_seq OWNER TO postgres;

--
-- TOC entry 433 (class 1259 OID 668115)
-- Name: job_443_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_443_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_443_logs_id_seq OWNER TO postgres;

--
-- TOC entry 434 (class 1259 OID 668117)
-- Name: job_444_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_444_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_444_logs_id_seq OWNER TO postgres;

--
-- TOC entry 435 (class 1259 OID 668119)
-- Name: job_445_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_445_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_445_logs_id_seq OWNER TO postgres;

--
-- TOC entry 436 (class 1259 OID 668121)
-- Name: job_447_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_447_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_447_logs_id_seq OWNER TO postgres;

--
-- TOC entry 437 (class 1259 OID 668123)
-- Name: job_448_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_448_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_448_logs_id_seq OWNER TO postgres;

--
-- TOC entry 438 (class 1259 OID 668125)
-- Name: job_449_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_449_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_449_logs_id_seq OWNER TO postgres;

--
-- TOC entry 439 (class 1259 OID 668127)
-- Name: job_44_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_44_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_44_logs_id_seq OWNER TO postgres;

--
-- TOC entry 440 (class 1259 OID 668129)
-- Name: job_450_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_450_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_450_logs_id_seq OWNER TO postgres;

--
-- TOC entry 441 (class 1259 OID 668131)
-- Name: job_451_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_451_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_451_logs_id_seq OWNER TO postgres;

--
-- TOC entry 442 (class 1259 OID 668133)
-- Name: job_452_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_452_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_452_logs_id_seq OWNER TO postgres;

--
-- TOC entry 443 (class 1259 OID 668135)
-- Name: job_453_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_453_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_453_logs_id_seq OWNER TO postgres;

--
-- TOC entry 444 (class 1259 OID 668137)
-- Name: job_454_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_454_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_454_logs_id_seq OWNER TO postgres;

--
-- TOC entry 445 (class 1259 OID 668139)
-- Name: job_455_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_455_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_455_logs_id_seq OWNER TO postgres;

--
-- TOC entry 446 (class 1259 OID 668141)
-- Name: job_456_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_456_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_456_logs_id_seq OWNER TO postgres;

--
-- TOC entry 447 (class 1259 OID 668143)
-- Name: job_457_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_457_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_457_logs_id_seq OWNER TO postgres;

--
-- TOC entry 448 (class 1259 OID 668145)
-- Name: job_458_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_458_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_458_logs_id_seq OWNER TO postgres;

--
-- TOC entry 449 (class 1259 OID 668147)
-- Name: job_459_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_459_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_459_logs_id_seq OWNER TO postgres;

--
-- TOC entry 450 (class 1259 OID 668149)
-- Name: job_460_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_460_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_460_logs_id_seq OWNER TO postgres;

--
-- TOC entry 451 (class 1259 OID 668151)
-- Name: job_461_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_461_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_461_logs_id_seq OWNER TO postgres;

--
-- TOC entry 452 (class 1259 OID 668153)
-- Name: job_462_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_462_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_462_logs_id_seq OWNER TO postgres;

--
-- TOC entry 453 (class 1259 OID 668155)
-- Name: job_463_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_463_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_463_logs_id_seq OWNER TO postgres;

--
-- TOC entry 454 (class 1259 OID 668157)
-- Name: job_464_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_464_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_464_logs_id_seq OWNER TO postgres;

--
-- TOC entry 455 (class 1259 OID 668159)
-- Name: job_465_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_465_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_465_logs_id_seq OWNER TO postgres;

--
-- TOC entry 456 (class 1259 OID 668161)
-- Name: job_474_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_474_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_474_logs_id_seq OWNER TO postgres;

--
-- TOC entry 457 (class 1259 OID 668163)
-- Name: job_476_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_476_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_476_logs_id_seq OWNER TO postgres;

--
-- TOC entry 458 (class 1259 OID 668165)
-- Name: job_477_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_477_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_477_logs_id_seq OWNER TO postgres;

--
-- TOC entry 459 (class 1259 OID 668167)
-- Name: job_478_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_478_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_478_logs_id_seq OWNER TO postgres;

--
-- TOC entry 460 (class 1259 OID 668169)
-- Name: job_479_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_479_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_479_logs_id_seq OWNER TO postgres;

--
-- TOC entry 461 (class 1259 OID 668171)
-- Name: job_480_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_480_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_480_logs_id_seq OWNER TO postgres;

--
-- TOC entry 462 (class 1259 OID 668173)
-- Name: job_481_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_481_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_481_logs_id_seq OWNER TO postgres;

--
-- TOC entry 463 (class 1259 OID 668175)
-- Name: job_482_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_482_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_482_logs_id_seq OWNER TO postgres;

--
-- TOC entry 464 (class 1259 OID 668177)
-- Name: job_483_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_483_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_483_logs_id_seq OWNER TO postgres;

--
-- TOC entry 465 (class 1259 OID 668179)
-- Name: job_484_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_484_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_484_logs_id_seq OWNER TO postgres;

--
-- TOC entry 466 (class 1259 OID 668181)
-- Name: job_485_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_485_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_485_logs_id_seq OWNER TO postgres;

--
-- TOC entry 467 (class 1259 OID 668183)
-- Name: job_486_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_486_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_486_logs_id_seq OWNER TO postgres;

--
-- TOC entry 468 (class 1259 OID 668185)
-- Name: job_487_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_487_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_487_logs_id_seq OWNER TO postgres;

--
-- TOC entry 469 (class 1259 OID 668187)
-- Name: job_488_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_488_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_488_logs_id_seq OWNER TO postgres;

--
-- TOC entry 470 (class 1259 OID 668189)
-- Name: job_489_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_489_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_489_logs_id_seq OWNER TO postgres;

--
-- TOC entry 471 (class 1259 OID 668191)
-- Name: job_490_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_490_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_490_logs_id_seq OWNER TO postgres;

--
-- TOC entry 472 (class 1259 OID 668193)
-- Name: job_491_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_491_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_491_logs_id_seq OWNER TO postgres;

--
-- TOC entry 473 (class 1259 OID 668195)
-- Name: job_492_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_492_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_492_logs_id_seq OWNER TO postgres;

--
-- TOC entry 474 (class 1259 OID 668197)
-- Name: job_493_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_493_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_493_logs_id_seq OWNER TO postgres;

--
-- TOC entry 475 (class 1259 OID 668199)
-- Name: job_494_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_494_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_494_logs_id_seq OWNER TO postgres;

--
-- TOC entry 476 (class 1259 OID 668201)
-- Name: job_495_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_495_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_495_logs_id_seq OWNER TO postgres;

--
-- TOC entry 477 (class 1259 OID 668203)
-- Name: job_496_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_496_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_496_logs_id_seq OWNER TO postgres;

--
-- TOC entry 478 (class 1259 OID 668205)
-- Name: job_497_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_497_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_497_logs_id_seq OWNER TO postgres;

--
-- TOC entry 479 (class 1259 OID 668207)
-- Name: job_498_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_498_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_498_logs_id_seq OWNER TO postgres;

--
-- TOC entry 480 (class 1259 OID 668209)
-- Name: job_499_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_499_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_499_logs_id_seq OWNER TO postgres;

--
-- TOC entry 481 (class 1259 OID 668211)
-- Name: job_500_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_500_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_500_logs_id_seq OWNER TO postgres;

--
-- TOC entry 482 (class 1259 OID 668213)
-- Name: job_503_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_503_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_503_logs_id_seq OWNER TO postgres;

--
-- TOC entry 483 (class 1259 OID 668215)
-- Name: job_504_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_504_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_504_logs_id_seq OWNER TO postgres;

--
-- TOC entry 484 (class 1259 OID 668217)
-- Name: job_505_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_505_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_505_logs_id_seq OWNER TO postgres;

--
-- TOC entry 485 (class 1259 OID 668219)
-- Name: job_509_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_509_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_509_logs_id_seq OWNER TO postgres;

--
-- TOC entry 486 (class 1259 OID 668221)
-- Name: job_511_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_511_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_511_logs_id_seq OWNER TO postgres;

--
-- TOC entry 487 (class 1259 OID 668223)
-- Name: job_513_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_513_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_513_logs_id_seq OWNER TO postgres;

--
-- TOC entry 488 (class 1259 OID 668225)
-- Name: job_514_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_514_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_514_logs_id_seq OWNER TO postgres;

--
-- TOC entry 489 (class 1259 OID 668227)
-- Name: job_515_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_515_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_515_logs_id_seq OWNER TO postgres;

--
-- TOC entry 490 (class 1259 OID 668229)
-- Name: job_517_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_517_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_517_logs_id_seq OWNER TO postgres;

--
-- TOC entry 491 (class 1259 OID 668231)
-- Name: job_518_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_518_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_518_logs_id_seq OWNER TO postgres;

--
-- TOC entry 492 (class 1259 OID 668233)
-- Name: job_519_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_519_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_519_logs_id_seq OWNER TO postgres;

--
-- TOC entry 493 (class 1259 OID 668235)
-- Name: job_520_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_520_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_520_logs_id_seq OWNER TO postgres;

--
-- TOC entry 494 (class 1259 OID 668237)
-- Name: job_521_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_521_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_521_logs_id_seq OWNER TO postgres;

--
-- TOC entry 495 (class 1259 OID 668239)
-- Name: job_525_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_525_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_525_logs_id_seq OWNER TO postgres;

--
-- TOC entry 496 (class 1259 OID 668241)
-- Name: job_526_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_526_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_526_logs_id_seq OWNER TO postgres;

--
-- TOC entry 497 (class 1259 OID 668243)
-- Name: job_527_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_527_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_527_logs_id_seq OWNER TO postgres;

--
-- TOC entry 498 (class 1259 OID 668245)
-- Name: job_executor_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_executor_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_executor_stats_id_seq OWNER TO postgres;

--
-- TOC entry 499 (class 1259 OID 668247)
-- Name: job_operators_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_operators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_operators_id_seq OWNER TO postgres;

--
-- TOC entry 500 (class 1259 OID 668249)
-- Name: job_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_statuses_id_seq OWNER TO postgres;

--
-- TOC entry 501 (class 1259 OID 668251)
-- Name: job_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_types_id_seq OWNER TO postgres;

--
-- TOC entry 502 (class 1259 OID 668253)
-- Name: jobs_v2_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jobs_v2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_v2_id_seq OWNER TO postgres;

--
-- TOC entry 503 (class 1259 OID 668255)
-- Name: land_topography_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.land_topography_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.land_topography_id_seq OWNER TO postgres;

--
-- TOC entry 504 (class 1259 OID 668257)
-- Name: languages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.languages_id_seq OWNER TO postgres;

--
-- TOC entry 505 (class 1259 OID 668259)
-- Name: livestock_breeds__id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestock_breeds__id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.livestock_breeds__id_seq OWNER TO postgres;

--
-- TOC entry 506 (class 1259 OID 668261)
-- Name: livestock_disease_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestock_disease_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.livestock_disease_id_seq OWNER TO postgres;

--
-- TOC entry 507 (class 1259 OID 668263)
-- Name: livestock_farming_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestock_farming_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.livestock_farming_category_id_seq OWNER TO postgres;

--
-- TOC entry 508 (class 1259 OID 668265)
-- Name: livestock_management_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestock_management_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.livestock_management_id_seq OWNER TO postgres;

--
-- TOC entry 509 (class 1259 OID 668267)
-- Name: livestock_nutrition_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestock_nutrition_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.livestock_nutrition_id_seq OWNER TO postgres;

--
-- TOC entry 510 (class 1259 OID 668269)
-- Name: livestock_purpose_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestock_purpose_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.livestock_purpose_id_seq OWNER TO postgres;

--
-- TOC entry 511 (class 1259 OID 668271)
-- Name: livestock_stage_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestock_stage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.livestock_stage_id_seq OWNER TO postgres;

--
-- TOC entry 512 (class 1259 OID 668273)
-- Name: livestock_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestock_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.livestock_tags_id_seq OWNER TO postgres;

--
-- TOC entry 513 (class 1259 OID 668275)
-- Name: livestocks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.livestocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.livestocks_id_seq OWNER TO postgres;

--
-- TOC entry 514 (class 1259 OID 668277)
-- Name: loan_agreement_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loan_agreement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loan_agreement_id_seq OWNER TO postgres;

--
-- TOC entry 515 (class 1259 OID 668279)
-- Name: loan_application_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loan_application_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.loan_application_id_seq OWNER TO postgres;

--
-- TOC entry 516 (class 1259 OID 668281)
-- Name: loan_partners_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loan_partners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loan_partners_id_seq OWNER TO postgres;

--
-- TOC entry 517 (class 1259 OID 668283)
-- Name: loan_payment_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loan_payment_modes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loan_payment_modes_id_seq OWNER TO postgres;

--
-- TOC entry 518 (class 1259 OID 668285)
-- Name: loan_procurement_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loan_procurement_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loan_procurement_attachments_id_seq OWNER TO postgres;

--
-- TOC entry 519 (class 1259 OID 668287)
-- Name: loan_procurements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loan_procurements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loan_procurements_id_seq OWNER TO postgres;

--
-- TOC entry 520 (class 1259 OID 668289)
-- Name: loan_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loan_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.loan_types_id_seq OWNER TO postgres;

--
-- TOC entry 521 (class 1259 OID 668291)
-- Name: location_crops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.location_crops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.location_crops_id_seq OWNER TO postgres;

--
-- TOC entry 522 (class 1259 OID 668293)
-- Name: location_livestocks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.location_livestocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.location_livestocks_id_seq OWNER TO postgres;

--
-- TOC entry 523 (class 1259 OID 668295)
-- Name: location_machineries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.location_machineries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.location_machineries_id_seq OWNER TO postgres;

--
-- TOC entry 524 (class 1259 OID 668297)
-- Name: location_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_users (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    crop_calender_id character varying(50),
    crop_calender_scheduler_id character varying(50),
    total_users integer,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    locations text,
    calender_day integer,
    users_with_out_growth_stages integer
);


ALTER TABLE public.location_users OWNER TO postgres;

--
-- TOC entry 525 (class 1259 OID 668305)
-- Name: location_users_global; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_users_global (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_id character varying(50),
    crop_calender_scheduler_id character varying(50),
    total_users integer,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    locations text,
    calender_day integer,
    users_with_out_growth_stages integer
);


ALTER TABLE public.location_users_global OWNER TO postgres;

--
-- TOC entry 526 (class 1259 OID 668313)
-- Name: location_v2_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.location_v2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.location_v2_id_seq OWNER TO postgres;

--
-- TOC entry 527 (class 1259 OID 668315)
-- Name: machineries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.machineries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.machineries_id_seq OWNER TO postgres;

--
-- TOC entry 528 (class 1259 OID 668317)
-- Name: machinery_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.machinery_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.machinery_types_id_seq OWNER TO postgres;

--
-- TOC entry 529 (class 1259 OID 668319)
-- Name: mandi_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mandi_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mandi_categories_id_seq OWNER TO postgres;

--
-- TOC entry 530 (class 1259 OID 668321)
-- Name: mandi_listing_images_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mandi_listing_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mandi_listing_images_id_seq OWNER TO postgres;

--
-- TOC entry 531 (class 1259 OID 668323)
-- Name: mandi_listing_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mandi_listing_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mandi_listing_tags_id_seq OWNER TO postgres;

--
-- TOC entry 532 (class 1259 OID 668325)
-- Name: mandi_listings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mandi_listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mandi_listings_id_seq OWNER TO postgres;

--
-- TOC entry 533 (class 1259 OID 668327)
-- Name: mandi_listings_meta_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mandi_listings_meta_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mandi_listings_meta_data_id_seq OWNER TO postgres;

--
-- TOC entry 534 (class 1259 OID 668329)
-- Name: mandi_reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mandi_reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mandi_reviews_id_seq OWNER TO postgres;

--
-- TOC entry 535 (class 1259 OID 668331)
-- Name: menu_crops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_crops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.menu_crops_id_seq OWNER TO postgres;

--
-- TOC entry 536 (class 1259 OID 668333)
-- Name: menu_languages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.menu_languages_id_seq OWNER TO postgres;

--
-- TOC entry 537 (class 1259 OID 668335)
-- Name: menu_livestocks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_livestocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.menu_livestocks_id_seq OWNER TO postgres;

--
-- TOC entry 538 (class 1259 OID 668337)
-- Name: menu_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.menu_locations_id_seq OWNER TO postgres;

--
-- TOC entry 539 (class 1259 OID 668339)
-- Name: menu_machineries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menu_machineries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.menu_machineries_id_seq OWNER TO postgres;

--
-- TOC entry 540 (class 1259 OID 668341)
-- Name: mo_sms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mo_sms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mo_sms_id_seq OWNER TO postgres;

--
-- TOC entry 687 (class 1259 OID 1564344)
-- Name: modes_of_action; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modes_of_action (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.modes_of_action OWNER TO postgres;

--
-- TOC entry 541 (class 1259 OID 668343)
-- Name: mp_crop_crop_diseases_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mp_crop_crop_diseases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mp_crop_crop_diseases_id_seq OWNER TO postgres;

--
-- TOC entry 542 (class 1259 OID 668345)
-- Name: mp_livestock_disease_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mp_livestock_disease_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.mp_livestock_disease_id_seq OWNER TO postgres;

--
-- TOC entry 543 (class 1259 OID 668347)
-- Name: mp_livestock_farming_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mp_livestock_farming_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mp_livestock_farming_categories_id_seq OWNER TO postgres;

--
-- TOC entry 544 (class 1259 OID 668349)
-- Name: narrative_list_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.narrative_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.narrative_list_id_seq OWNER TO postgres;

--
-- TOC entry 545 (class 1259 OID 668351)
-- Name: network_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.network_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.network_types_id_seq OWNER TO postgres;

--
-- TOC entry 546 (class 1259 OID 668353)
-- Name: notification_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_history_id_seq OWNER TO postgres;

--
-- TOC entry 547 (class 1259 OID 668355)
-- Name: notification_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_modes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_modes_id_seq OWNER TO postgres;

--
-- TOC entry 548 (class 1259 OID 668357)
-- Name: notification_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_types_id_seq OWNER TO postgres;

--
-- TOC entry 549 (class 1259 OID 668359)
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- TOC entry 550 (class 1259 OID 668361)
-- Name: numbers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.numbers (
    id integer NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    "order" integer,
    msisdn character varying(12)
);


ALTER TABLE public.numbers OWNER TO postgres;

--
-- TOC entry 551 (class 1259 OID 668365)
-- Name: numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.numbers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.numbers_id_seq OWNER TO postgres;

--
-- TOC entry 6242 (class 0 OID 0)
-- Dependencies: 551
-- Name: numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.numbers_id_seq OWNED BY public.numbers.id;


--
-- TOC entry 552 (class 1259 OID 668367)
-- Name: nutrient_deficiency_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.nutrient_deficiency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.nutrient_deficiency_id_seq OWNER TO postgres;

--
-- TOC entry 553 (class 1259 OID 668369)
-- Name: oauth_access_token_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oauth_access_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth_access_token_id_seq OWNER TO postgres;

--
-- TOC entry 554 (class 1259 OID 668371)
-- Name: oauth_authorization_code_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oauth_authorization_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth_authorization_code_id_seq OWNER TO postgres;

--
-- TOC entry 555 (class 1259 OID 668373)
-- Name: oauth_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oauth_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth_clients_id_seq OWNER TO postgres;

--
-- TOC entry 556 (class 1259 OID 668375)
-- Name: oauth_refresh_token_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oauth_refresh_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth_refresh_token_id_seq OWNER TO postgres;

--
-- TOC entry 557 (class 1259 OID 668377)
-- Name: oauth_scopes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oauth_scopes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth_scopes_id_seq OWNER TO postgres;

--
-- TOC entry 558 (class 1259 OID 668379)
-- Name: oauth_user_client_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oauth_user_client_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth_user_client_grants_id_seq OWNER TO postgres;

--
-- TOC entry 559 (class 1259 OID 668381)
-- Name: oauth_user_otp_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oauth_user_otp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth_user_otp_id_seq OWNER TO postgres;

--
-- TOC entry 560 (class 1259 OID 668383)
-- Name: occupations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.occupations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.occupations_id_seq OWNER TO postgres;

--
-- TOC entry 561 (class 1259 OID 668385)
-- Name: operators_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.operators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.operators_id_seq OWNER TO postgres;

--
-- TOC entry 562 (class 1259 OID 668387)
-- Name: pak_adm3_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pak_adm3_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.pak_adm3_gid_seq OWNER TO postgres;

--
-- TOC entry 563 (class 1259 OID 668389)
-- Name: pak_admbnda_adm1_ocha_pco_gaul_20181218_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pak_admbnda_adm1_ocha_pco_gaul_20181218_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.pak_admbnda_adm1_ocha_pco_gaul_20181218_gid_seq OWNER TO postgres;

--
-- TOC entry 564 (class 1259 OID 668391)
-- Name: pak_admbnda_adm2_ocha_pco_gaul_20181218_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pak_admbnda_adm2_ocha_pco_gaul_20181218_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.pak_admbnda_adm2_ocha_pco_gaul_20181218_gid_seq OWNER TO postgres;

--
-- TOC entry 565 (class 1259 OID 668393)
-- Name: parameters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parameters (
    id integer NOT NULL,
    name character varying(255),
    data_type character varying(255),
    create_dt timestamp(0) with time zone,
    update_dt timestamp(0) with time zone,
    default_value character varying(255)
);


ALTER TABLE public.parameters OWNER TO postgres;

--
-- TOC entry 566 (class 1259 OID 668399)
-- Name: partner_procurement_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partner_procurement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.partner_procurement_id_seq OWNER TO postgres;

--
-- TOC entry 567 (class 1259 OID 668401)
-- Name: partner_services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partner_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.partner_services_id_seq OWNER TO postgres;

--
-- TOC entry 692 (class 1259 OID 1564395)
-- Name: pest_categories; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.pest_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.pest_categories OWNER TO rameez_dev_rw;

--
-- TOC entry 568 (class 1259 OID 668403)
-- Name: pests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.pests_id_seq OWNER TO postgres;

--
-- TOC entry 569 (class 1259 OID 668405)
-- Name: phrase_32_char_list_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.phrase_32_char_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.phrase_32_char_list_id_seq OWNER TO postgres;

--
-- TOC entry 570 (class 1259 OID 668407)
-- Name: player_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.player_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.player_id_seq OWNER TO postgres;

--
-- TOC entry 571 (class 1259 OID 668409)
-- Name: point10_3_gid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.point10_3_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.point10_3_gid_seq OWNER TO postgres;

--
-- TOC entry 671 (class 1259 OID 1177722)
-- Name: product_advisory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_advisory (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    msisdn character varying(20),
    advisory_create_dt date DEFAULT CURRENT_DATE,
    job_id character varying(50),
    product_id character varying(100),
    advisory_meta_data json,
    advisory_eligibility boolean DEFAULT false
);


ALTER TABLE public.product_advisory OWNER TO postgres;

--
-- TOC entry 672 (class 1259 OID 1177737)
-- Name: product_advisory_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_advisory_jobs (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    shopify_product_advisory_id character varying(100) NOT NULL,
    create_dt date DEFAULT CURRENT_DATE,
    update_dt timestamp(6) without time zone,
    created smallint DEFAULT 0,
    text text,
    shopify_product_id character varying(255),
    survey_created smallint DEFAULT 0,
    job_type character varying(225)
);


ALTER TABLE public.product_advisory_jobs OWNER TO postgres;

--
-- TOC entry 685 (class 1259 OID 1564324)
-- Name: product_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.product_categories OWNER TO postgres;

--
-- TOC entry 572 (class 1259 OID 668411)
-- Name: product_cc_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_cc_requests (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_product_id character varying(50) DEFAULT NULL::character varying,
    msisdn character varying(12) NOT NULL,
    status smallint DEFAULT 1,
    description text,
    completed smallint DEFAULT 0,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.product_cc_requests OWNER TO postgres;

--
-- TOC entry 684 (class 1259 OID 1564304)
-- Name: product_companies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_companies (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.product_companies OWNER TO postgres;

--
-- TOC entry 573 (class 1259 OID 668422)
-- Name: product_mappings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_mappings (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_product_id character varying(50) DEFAULT NULL::character varying,
    product_id character varying(50) DEFAULT NULL::character varying,
    chemical_formula character varying(50) DEFAULT NULL::character varying,
    product_name character varying(50) DEFAULT NULL::character varying,
    location_id character varying(50) DEFAULT NULL::character varying,
    location_name character varying(50) DEFAULT NULL::character varying,
    status smallint DEFAULT 0,
    key character varying(4) DEFAULT NULL::character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    city_name character varying(100),
    city_id integer
);


ALTER TABLE public.product_mappings OWNER TO postgres;

--
-- TOC entry 574 (class 1259 OID 668435)
-- Name: questionair_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.questionair_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.questionair_id_seq OWNER TO postgres;

--
-- TOC entry 575 (class 1259 OID 668437)
-- Name: questionair_response_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.questionair_response_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.questionair_response_id_seq OWNER TO postgres;

--
-- TOC entry 576 (class 1259 OID 668439)
-- Name: recording_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.recording_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recording_logs_id_seq OWNER TO postgres;

--
-- TOC entry 690 (class 1259 OID 1564374)
-- Name: safety_precautions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.safety_precautions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(500),
    name_ur character varying(500),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.safety_precautions OWNER TO postgres;

--
-- TOC entry 577 (class 1259 OID 668441)
-- Name: scenarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scenarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scenarios_id_seq OWNER TO postgres;

--
-- TOC entry 578 (class 1259 OID 668443)
-- Name: seed_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seed_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seed_types_id_seq OWNER TO postgres;

--
-- TOC entry 579 (class 1259 OID 668445)
-- Name: sentiments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sentiments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.sentiments_id_seq OWNER TO postgres;

--
-- TOC entry 580 (class 1259 OID 668447)
-- Name: seq_id_advisory; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_id_advisory
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_id_advisory OWNER TO postgres;

--
-- TOC entry 581 (class 1259 OID 668449)
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.services_id_seq OWNER TO postgres;

--
-- TOC entry 705 (class 1259 OID 1566430)
-- Name: shopify_product_advisories; Type: TABLE; Schema: public; Owner: bkkdev_rw
--

CREATE TABLE public.shopify_product_advisories (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    shopify_product_id character varying(255) NOT NULL,
    advisory text NOT NULL,
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.shopify_product_advisories OWNER TO bkkdev_rw;

--
-- TOC entry 664 (class 1259 OID 984020)
-- Name: shopify_product_advisory_recommendations; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.shopify_product_advisory_recommendations (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    shopify_product_advisories_id uuid NOT NULL,
    recommended_product_id character varying(255) NOT NULL,
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    display_order integer,
    duration character varying(50)
);


ALTER TABLE public.shopify_product_advisory_recommendations OWNER TO rameez_dev_rw;

--
-- TOC entry 704 (class 1259 OID 1566410)
-- Name: shopify_products; Type: TABLE; Schema: public; Owner: bkkdev_rw
--

CREATE TABLE public.shopify_products (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    product_name character varying(100),
    targeted_pest_id character varying(100),
    chemical_id character varying(100),
    dose_per_acre character varying(100),
    company_id character varying(100),
    price numeric(10,2),
    pack_size character varying(50),
    category_id character varying(100),
    mode_of_action_id character varying(100),
    time_of_application_id character varying(100),
    application_method_id character varying(100),
    targeted_crop_id character varying(100),
    formulation_id character varying(100),
    phi character varying(100),
    safety_precaution_id character varying(100),
    geographic_location_id character varying(256),
    environment_condition_id character varying(100),
    default_shopify_product_id character varying(255),
    image_url character varying(255),
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.shopify_products OWNER TO bkkdev_rw;

--
-- TOC entry 582 (class 1259 OID 668469)
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sites_id_seq OWNER TO postgres;

--
-- TOC entry 583 (class 1259 OID 668471)
-- Name: sites_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sites_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sites_id_seq1 OWNER TO postgres;

--
-- TOC entry 584 (class 1259 OID 668473)
-- Name: sms_cta; Type: TABLE; Schema: public; Owner: bkkdev_rw
--

CREATE TABLE public.sms_cta (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active smallint DEFAULT 1
);


ALTER TABLE public.sms_cta OWNER TO bkkdev_rw;

--
-- TOC entry 585 (class 1259 OID 668480)
-- Name: sms_cta_translations; Type: TABLE; Schema: public; Owner: bkkdev_rw
--

CREATE TABLE public.sms_cta_translations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    sms_cta_id uuid NOT NULL,
    language_id uuid NOT NULL,
    text character varying(255),
    is_default boolean DEFAULT false,
    is_standard boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active smallint DEFAULT 1
);


ALTER TABLE public.sms_cta_translations OWNER TO bkkdev_rw;

--
-- TOC entry 586 (class 1259 OID 668489)
-- Name: sms_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_history (
    id integer NOT NULL,
    msisdn character varying(12),
    crop_calender_id character varying(50),
    text text,
    sms_response text,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    calender_day integer,
    sowing_day integer,
    crop_calender_title character varying(100),
    lat character varying(20),
    lng character varying(20)
);


ALTER TABLE public.sms_history OWNER TO postgres;

--
-- TOC entry 587 (class 1259 OID 668496)
-- Name: sms_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sms_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sms_history_id_seq OWNER TO postgres;

--
-- TOC entry 6282 (class 0 OID 0)
-- Dependencies: 587
-- Name: sms_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sms_history_id_seq OWNED BY public.sms_history.id;


--
-- TOC entry 588 (class 1259 OID 668498)
-- Name: soil_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.soil_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.soil_issues_id_seq OWNER TO postgres;

--
-- TOC entry 589 (class 1259 OID 668500)
-- Name: soil_type_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.soil_type_category (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active integer DEFAULT 1,
    title_urdu character varying(255),
    parent_id uuid
);


ALTER TABLE public.soil_type_category OWNER TO postgres;

--
-- TOC entry 590 (class 1259 OID 668509)
-- Name: soil_type_parameters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.soil_type_parameters (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    soil_type_category_id uuid,
    sand_min numeric(5,2),
    sand_max numeric(5,2),
    silt_min numeric(5,2),
    silt_max numeric(5,2),
    clay_min numeric(5,2),
    clay_max numeric(5,2),
    ph_min numeric(5,2),
    ph_max numeric(5,2),
    ec_min numeric(5,2),
    ec_max numeric(5,2),
    sar_min numeric(5,2),
    sar_max numeric(5,2),
    om_min numeric(5,2),
    om_max numeric(5,2),
    p_min numeric(5,2),
    p_max numeric(5,2),
    k_min numeric(5,2),
    k_max numeric(5,2),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active integer DEFAULT 1
);


ALTER TABLE public.soil_type_parameters OWNER TO postgres;

--
-- TOC entry 591 (class 1259 OID 668515)
-- Name: soil_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.soil_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.soil_types_id_seq OWNER TO postgres;

--
-- TOC entry 592 (class 1259 OID 668517)
-- Name: source_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.source_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.source_types_id_seq OWNER TO postgres;

--
-- TOC entry 593 (class 1259 OID 668519)
-- Name: sowing_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sowing_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.sowing_methods_id_seq OWNER TO postgres;

--
-- TOC entry 594 (class 1259 OID 668521)
-- Name: sub_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sub_modes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sub_modes_id_seq OWNER TO postgres;

--
-- TOC entry 595 (class 1259 OID 668523)
-- Name: subscriber_notification_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscriber_notification_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriber_notification_types_id_seq OWNER TO postgres;

--
-- TOC entry 596 (class 1259 OID 668525)
-- Name: subscriber_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscriber_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriber_roles_id_seq OWNER TO postgres;

--
-- TOC entry 597 (class 1259 OID 668527)
-- Name: subscribers_job_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscribers_job_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscribers_job_logs_id_seq OWNER TO postgres;

--
-- TOC entry 598 (class 1259 OID 668529)
-- Name: subscription_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscription_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscription_types_id_seq OWNER TO postgres;

--
-- TOC entry 599 (class 1259 OID 668531)
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriptions_id_seq OWNER TO postgres;

--
-- TOC entry 600 (class 1259 OID 668533)
-- Name: subscriptions_subscription_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscriptions_subscription_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriptions_subscription_type_id_seq OWNER TO postgres;

--
-- TOC entry 601 (class 1259 OID 668535)
-- Name: survey_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.survey_activities_id_seq OWNER TO postgres;

--
-- TOC entry 602 (class 1259 OID 668537)
-- Name: survey_api_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_api_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_api_actions_id_seq OWNER TO postgres;

--
-- TOC entry 603 (class 1259 OID 668539)
-- Name: survey_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.survey_categories_id_seq OWNER TO postgres;

--
-- TOC entry 604 (class 1259 OID 668541)
-- Name: survey_crops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_crops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_crops_id_seq OWNER TO postgres;

--
-- TOC entry 605 (class 1259 OID 668543)
-- Name: survey_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_files_id_seq OWNER TO postgres;

--
-- TOC entry 606 (class 1259 OID 668545)
-- Name: survey_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_id_seq OWNER TO postgres;

--
-- TOC entry 607 (class 1259 OID 668547)
-- Name: survey_input_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_input_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_input_files_id_seq OWNER TO postgres;

--
-- TOC entry 608 (class 1259 OID 668549)
-- Name: survey_input_trunk_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_input_trunk_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_input_trunk_actions_id_seq OWNER TO postgres;

--
-- TOC entry 609 (class 1259 OID 668551)
-- Name: survey_inputs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_inputs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_inputs_id_seq OWNER TO postgres;

--
-- TOC entry 610 (class 1259 OID 668553)
-- Name: survey_languages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_languages_id_seq OWNER TO postgres;

--
-- TOC entry 611 (class 1259 OID 668555)
-- Name: survey_livestocks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_livestocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_livestocks_id_seq OWNER TO postgres;

--
-- TOC entry 612 (class 1259 OID 668557)
-- Name: survey_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_locations_id_seq OWNER TO postgres;

--
-- TOC entry 613 (class 1259 OID 668559)
-- Name: survey_machineries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_machineries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_machineries_id_seq OWNER TO postgres;

--
-- TOC entry 614 (class 1259 OID 668561)
-- Name: survey_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.survey_profiles_id_seq OWNER TO postgres;

--
-- TOC entry 615 (class 1259 OID 668563)
-- Name: survey_promo_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_promo_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.survey_promo_data_id_seq OWNER TO postgres;

--
-- TOC entry 616 (class 1259 OID 668565)
-- Name: sync_tables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sync_tables (
    id character varying(100) DEFAULT public.uuid_generate_v4() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    db_config json NOT NULL,
    name character varying(100) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.sync_tables OWNER TO postgres;

--
-- TOC entry 617 (class 1259 OID 668574)
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tags_id_seq OWNER TO postgres;

--
-- TOC entry 700 (class 1259 OID 1566086)
-- Name: targeted_pests; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.targeted_pests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    name_ur character varying(255),
    pest_category_id uuid NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.targeted_pests OWNER TO rameez_dev_rw;

--
-- TOC entry 618 (class 1259 OID 668576)
-- Name: tenants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenants (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    base_path character varying(255),
    active integer,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    central smallint DEFAULT 0,
    type character varying(255)
);


ALTER TABLE public.tenants OWNER TO postgres;

--
-- TOC entry 619 (class 1259 OID 668585)
-- Name: terms_of_use_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.terms_of_use_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.terms_of_use_id_seq OWNER TO postgres;

--
-- TOC entry 620 (class 1259 OID 668587)
-- Name: time_periods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.time_periods (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    title_urdu character varying(255),
    start_time time without time zone,
    end_time time without time zone,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active integer DEFAULT 1
);


ALTER TABLE public.time_periods OWNER TO postgres;

--
-- TOC entry 688 (class 1259 OID 1564354)
-- Name: times_of_application; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.times_of_application (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.times_of_application OWNER TO postgres;

--
-- TOC entry 621 (class 1259 OID 668596)
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.transactions_id_seq OWNER TO postgres;

--
-- TOC entry 622 (class 1259 OID 668598)
-- Name: trigger_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trigger_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trigger_id_seq OWNER TO postgres;

--
-- TOC entry 623 (class 1259 OID 668600)
-- Name: trigger_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trigger_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trigger_type_id_seq OWNER TO postgres;

--
-- TOC entry 624 (class 1259 OID 668602)
-- Name: trunk_call_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trunk_call_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trunk_call_details_id_seq OWNER TO postgres;

--
-- TOC entry 625 (class 1259 OID 668604)
-- Name: trunk_recording_timings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trunk_recording_timings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trunk_recording_timings_id_seq OWNER TO postgres;

--
-- TOC entry 626 (class 1259 OID 668606)
-- Name: trunk_timings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.trunk_timings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trunk_timings_id_seq OWNER TO postgres;

--
-- TOC entry 627 (class 1259 OID 668608)
-- Name: user_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_activities_id_seq OWNER TO postgres;

--
-- TOC entry 628 (class 1259 OID 668610)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id character varying(100) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    email character varying(100),
    password character varying(255)
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 629 (class 1259 OID 668615)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 630 (class 1259 OID 668617)
-- Name: weather_change_set_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_change_set_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_change_set_id_seq OWNER TO postgres;

--
-- TOC entry 631 (class 1259 OID 668619)
-- Name: weather_change_set_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_change_set_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_change_set_id_seq1 OWNER TO postgres;

--
-- TOC entry 632 (class 1259 OID 668621)
-- Name: weather_condition_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_condition_types (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    type_name character varying(50) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    max smallint,
    min smallint,
    relative smallint
);


ALTER TABLE public.weather_condition_types OWNER TO postgres;

--
-- TOC entry 633 (class 1259 OID 668627)
-- Name: weather_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_conditions (
    icon_code character varying(10),
    condition_desc character varying(100),
    file_name character varying(150),
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    condition_desc_urdu character varying,
    image_url character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weather_conditions OWNER TO postgres;

--
-- TOC entry 634 (class 1259 OID 668635)
-- Name: weather_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_conditions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_conditions_id_seq OWNER TO postgres;

--
-- TOC entry 635 (class 1259 OID 668637)
-- Name: weather_conditions_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_conditions_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.weather_conditions_id_seq1 OWNER TO postgres;

--
-- TOC entry 636 (class 1259 OID 668639)
-- Name: weather_daily_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_daily_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_daily_id_seq OWNER TO postgres;

--
-- TOC entry 637 (class 1259 OID 668641)
-- Name: weather_daily_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_daily_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_daily_id_seq1 OWNER TO postgres;

--
-- TOC entry 638 (class 1259 OID 668643)
-- Name: weather_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_data (
    id character varying NOT NULL,
    site_id integer NOT NULL,
    lat character varying(255),
    lng character varying(255),
    create_dt timestamp(6) with time zone,
    update_dt timestamp with time zone,
    weather_dt date NOT NULL,
    temperature_max character varying(255),
    temperature_min character varying(255),
    day_of_week character varying(255),
    sunrise_time_local timestamp with time zone,
    sunset_time_local timestamp with time zone,
    day_part character varying(255),
    precip_chance character varying(255),
    precip_type character varying(255),
    temperature character varying(255),
    snow_range character varying(255),
    wind_speed character varying(255),
    wx_phrase_long character varying(255),
    relative_humidity character varying(255),
    daypart_name character varying(255)
);


ALTER TABLE public.weather_data OWNER TO postgres;

--
-- TOC entry 639 (class 1259 OID 668649)
-- Name: weather_hourly_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_hourly_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_hourly_id_seq OWNER TO postgres;

--
-- TOC entry 640 (class 1259 OID 668651)
-- Name: weather_hourly_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_hourly_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_hourly_id_seq1 OWNER TO postgres;

--
-- TOC entry 641 (class 1259 OID 668653)
-- Name: weather_intraday_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_intraday_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.weather_intraday_id_seq OWNER TO postgres;

--
-- TOC entry 642 (class 1259 OID 668655)
-- Name: weather_outlook_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_outlook_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_outlook_id_seq OWNER TO postgres;

--
-- TOC entry 643 (class 1259 OID 668657)
-- Name: weather_raw_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_raw_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weather_raw_id_seq OWNER TO postgres;

--
-- TOC entry 644 (class 1259 OID 668659)
-- Name: weather_service_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weather_service_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.weather_service_events_id_seq OWNER TO postgres;

--
-- TOC entry 693 (class 1259 OID 1564405)
-- Name: weed_types; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.weed_types (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    name_ur character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.weed_types OWNER TO rameez_dev_rw;

--
-- TOC entry 645 (class 1259 OID 668661)
-- Name: weeds_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.weeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.weeds_id_seq OWNER TO postgres;

--
-- TOC entry 646 (class 1259 OID 668663)
-- Name: welcome_box_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.welcome_box_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.welcome_box_id_seq OWNER TO postgres;

--
-- TOC entry 647 (class 1259 OID 668665)
-- Name: wx_phrase_list_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wx_phrase_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wx_phrase_list_id_seq OWNER TO postgres;

--
-- TOC entry 648 (class 1259 OID 668667)
-- Name: layer; Type: TABLE; Schema: topology; Owner: postgres
--

CREATE TABLE topology.layer (
    topology_id integer NOT NULL,
    layer_id integer NOT NULL,
    schema_name character varying NOT NULL,
    table_name character varying NOT NULL,
    feature_column character varying NOT NULL,
    feature_type integer NOT NULL,
    level integer DEFAULT 0 NOT NULL,
    child_id integer
);


ALTER TABLE topology.layer OWNER TO postgres;

--
-- TOC entry 649 (class 1259 OID 668674)
-- Name: topology; Type: TABLE; Schema: topology; Owner: postgres
--

CREATE TABLE topology.topology (
    id integer NOT NULL,
    name character varying NOT NULL,
    srid integer NOT NULL,
    "precision" double precision NOT NULL,
    hasz boolean DEFAULT false NOT NULL
);


ALTER TABLE topology.topology OWNER TO postgres;

--
-- TOC entry 650 (class 1259 OID 668681)
-- Name: topology_id_seq; Type: SEQUENCE; Schema: topology; Owner: postgres
--

CREATE SEQUENCE topology.topology_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE topology.topology_id_seq OWNER TO postgres;

--
-- TOC entry 6346 (class 0 OID 0)
-- Dependencies: 650
-- Name: topology_id_seq; Type: SEQUENCE OWNED BY; Schema: topology; Owner: postgres
--

ALTER SEQUENCE topology.topology_id_seq OWNED BY topology.topology.id;


--
-- TOC entry 4864 (class 2604 OID 668683)
-- Name: advisory_growth_stages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_growth_stages ALTER COLUMN id SET DEFAULT nextval('public.advisory_growth_stages_id_seq'::regclass);


--
-- TOC entry 4925 (class 2604 OID 668684)
-- Name: content_files id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files ALTER COLUMN id SET DEFAULT nextval('public.content_files_id_seq1'::regclass);


--
-- TOC entry 4930 (class 2604 OID 668685)
-- Name: content_folders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_folders ALTER COLUMN id SET DEFAULT nextval('public.content_folders_id_seq1'::regclass);


--
-- TOC entry 4877 (class 2604 OID 668686)
-- Name: crop_calender_scheduler id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_scheduler ALTER COLUMN id SET DEFAULT nextval('public.advisory_scheduler_id_seq'::regclass);


--
-- TOC entry 4971 (class 2604 OID 668687)
-- Name: numbers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.numbers ALTER COLUMN id SET DEFAULT nextval('public.numbers_id_seq'::regclass);


--
-- TOC entry 4998 (class 2604 OID 668688)
-- Name: sms_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sms_history ALTER COLUMN id SET DEFAULT nextval('public.sms_history_id_seq'::regclass);


--
-- TOC entry 5023 (class 2604 OID 668689)
-- Name: topology id; Type: DEFAULT; Schema: topology; Owner: postgres
--

ALTER TABLE ONLY topology.topology ALTER COLUMN id SET DEFAULT nextval('topology.topology_id_seq'::regclass);


--
-- TOC entry 5219 (class 2606 OID 707216)
-- Name: active_product_locations active_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_product_locations
    ADD CONSTRAINT active_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 5233 (class 2606 OID 707218)
-- Name: advisory_conditions advisory_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_conditions
    ADD CONSTRAINT advisory_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 5235 (class 2606 OID 707220)
-- Name: advisory_feedback advisory_feedback_advisory_id_msisdn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_feedback
    ADD CONSTRAINT advisory_feedback_advisory_id_msisdn_key UNIQUE (advisory_id, msisdn);


--
-- TOC entry 5237 (class 2606 OID 707222)
-- Name: advisory_feedback advisory_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_feedback
    ADD CONSTRAINT advisory_feedback_pkey PRIMARY KEY (id);


--
-- TOC entry 5242 (class 2606 OID 707224)
-- Name: advisory_groups advisory_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_groups
    ADD CONSTRAINT advisory_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 5247 (class 2606 OID 707226)
-- Name: advisory_growth_stages advisory_growth_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_growth_stages
    ADD CONSTRAINT advisory_growth_stages_pkey PRIMARY KEY (id);


--
-- TOC entry 5249 (class 2606 OID 707228)
-- Name: advisory_locations advisory_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_locations
    ADD CONSTRAINT advisory_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 5229 (class 2606 OID 707230)
-- Name: advisory advisory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory
    ADD CONSTRAINT advisory_pkey PRIMARY KEY (id);


--
-- TOC entry 5251 (class 2606 OID 707232)
-- Name: advisory_products advisory_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_products
    ADD CONSTRAINT advisory_products_pkey PRIMARY KEY (id);


--
-- TOC entry 5255 (class 2606 OID 707234)
-- Name: crop_calender_scheduler advisory_scheduler_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_scheduler
    ADD CONSTRAINT advisory_scheduler_pkey PRIMARY KEY (id);


--
-- TOC entry 5259 (class 2606 OID 707236)
-- Name: advisory_soil_type advisory_soil_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_soil_type
    ADD CONSTRAINT advisory_soil_type_pkey PRIMARY KEY (id);


--
-- TOC entry 5269 (class 2606 OID 707238)
-- Name: agri_bank_advisory_jobs_global agri_bank_advisory_jobs_global_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agri_bank_advisory_jobs_global
    ADD CONSTRAINT agri_bank_advisory_jobs_global_pkey PRIMARY KEY (id);


--
-- TOC entry 5272 (class 2606 OID 707240)
-- Name: agri_bank_advisory_jobs_old agri_bank_advisory_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agri_bank_advisory_jobs_old
    ADD CONSTRAINT agri_bank_advisory_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 5266 (class 2606 OID 707245)
-- Name: agri_bank_advisory_jobs agri_bank_advisory_jobs_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agri_bank_advisory_jobs
    ADD CONSTRAINT agri_bank_advisory_jobs_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5274 (class 2606 OID 707264)
-- Name: agri_bank_data agri_bank_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agri_bank_data
    ADD CONSTRAINT agri_bank_data_pkey PRIMARY KEY (id);


--
-- TOC entry 5276 (class 2606 OID 707271)
-- Name: app_cta app_cta_pkey; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.app_cta
    ADD CONSTRAINT app_cta_pkey PRIMARY KEY (id);


--
-- TOC entry 5278 (class 2606 OID 707273)
-- Name: app_cta_translations app_cta_translations_app_cta_id_language_id_key; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.app_cta_translations
    ADD CONSTRAINT app_cta_translations_app_cta_id_language_id_key UNIQUE (app_cta_id, language_id);


--
-- TOC entry 5280 (class 2606 OID 707281)
-- Name: app_cta_translations app_cta_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.app_cta_translations
    ADD CONSTRAINT app_cta_translations_pkey PRIMARY KEY (id);


--
-- TOC entry 5616 (class 2606 OID 1564373)
-- Name: application_methods application_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_methods
    ADD CONSTRAINT application_methods_pkey PRIMARY KEY (id);


--
-- TOC entry 5283 (class 2606 OID 707283)
-- Name: barani_locations barani_locations_location_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barani_locations
    ADD CONSTRAINT barani_locations_location_id_key UNIQUE (location_id);


--
-- TOC entry 5285 (class 2606 OID 707285)
-- Name: barani_locations barani_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.barani_locations
    ADD CONSTRAINT barani_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 5666 (class 2606 OID 1566394)
-- Name: chemical_types chemical_types_name_key; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.chemical_types
    ADD CONSTRAINT chemical_types_name_key UNIQUE (name);


--
-- TOC entry 5668 (class 2606 OID 1566392)
-- Name: chemical_types chemical_types_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.chemical_types
    ADD CONSTRAINT chemical_types_pkey PRIMARY KEY (id);


--
-- TOC entry 5670 (class 2606 OID 1566404)
-- Name: chemicals chemicals_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.chemicals
    ADD CONSTRAINT chemicals_pkey PRIMARY KEY (id);


--
-- TOC entry 5309 (class 2606 OID 707287)
-- Name: content_files content_files_file_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_file_name_key UNIQUE (file_name);


--
-- TOC entry 5312 (class 2606 OID 707289)
-- Name: content_files content_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_pkey PRIMARY KEY (id);


--
-- TOC entry 5314 (class 2606 OID 707291)
-- Name: content_files content_files_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_title_key UNIQUE (title);


--
-- TOC entry 5316 (class 2606 OID 707293)
-- Name: content_folders content_folders_folder_path_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_folders
    ADD CONSTRAINT content_folders_folder_path_key UNIQUE (folder_path);


--
-- TOC entry 5319 (class 2606 OID 707295)
-- Name: content_folders content_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_folders
    ADD CONSTRAINT content_folders_pkey PRIMARY KEY (id);


--
-- TOC entry 5321 (class 2606 OID 707297)
-- Name: content_folders content_folders_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_folders
    ADD CONSTRAINT content_folders_title_key UNIQUE (title);


--
-- TOC entry 5323 (class 2606 OID 707299)
-- Name: crop_calender_assosiated_crops_livestocks crop_calender_assosiated_crops_livestocks_pkey; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.crop_calender_assosiated_crops_livestocks
    ADD CONSTRAINT crop_calender_assosiated_crops_livestocks_pkey PRIMARY KEY (id);


--
-- TOC entry 5328 (class 2606 OID 707301)
-- Name: crop_calender_languages crop_calender_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_languages
    ADD CONSTRAINT crop_calender_languages_pkey PRIMARY KEY (id);


--
-- TOC entry 5296 (class 2606 OID 707303)
-- Name: crop_calender_locations crop_calender_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_locations
    ADD CONSTRAINT crop_calender_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 5289 (class 2606 OID 707305)
-- Name: crop_calender crop_calender_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender
    ADD CONSTRAINT crop_calender_pkey PRIMARY KEY (id);


--
-- TOC entry 5332 (class 2606 OID 707307)
-- Name: crop_calender_scheduler_seed_types crop_calender_seed_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_scheduler_seed_types
    ADD CONSTRAINT crop_calender_seed_types_pkey PRIMARY KEY (id);


--
-- TOC entry 5298 (class 2606 OID 707309)
-- Name: crop_calender_sowing_window crop_calender_sowing_window_crop_calender_id_key; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.crop_calender_sowing_window
    ADD CONSTRAINT crop_calender_sowing_window_crop_calender_id_key UNIQUE (crop_calender_id);


--
-- TOC entry 5300 (class 2606 OID 707311)
-- Name: crop_calender_sowing_window crop_calender_sowing_window_pkey; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.crop_calender_sowing_window
    ADD CONSTRAINT crop_calender_sowing_window_pkey PRIMARY KEY (id);


--
-- TOC entry 5302 (class 2606 OID 707313)
-- Name: crop_calender_sowing_window_schedule_locations crop_calender_sowing_window_schedule_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_sowing_window_schedule_locations
    ADD CONSTRAINT crop_calender_sowing_window_schedule_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 5306 (class 2606 OID 707315)
-- Name: crop_calender_sowing_window_schedules crop_calender_sowing_window_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_sowing_window_schedules
    ADD CONSTRAINT crop_calender_sowing_window_schedules_pkey PRIMARY KEY (id);


--
-- TOC entry 5339 (class 2606 OID 707317)
-- Name: crop_calender_stages_growth_stages crop_calender_stages_growth_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_stages_growth_stages
    ADD CONSTRAINT crop_calender_stages_growth_stages_pkey PRIMARY KEY (id);


--
-- TOC entry 5336 (class 2606 OID 707319)
-- Name: crop_calender_stages crop_calender_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_stages
    ADD CONSTRAINT crop_calender_stages_pkey PRIMARY KEY (id);


--
-- TOC entry 5291 (class 2606 OID 707321)
-- Name: crop_calender crop_calender_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender
    ADD CONSTRAINT crop_calender_title_key UNIQUE (title);


--
-- TOC entry 5620 (class 2606 OID 1564393)
-- Name: environment_conditions environment_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.environment_conditions
    ADD CONSTRAINT environment_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 5421 (class 2606 OID 829149)
-- Name: farmer_advisory_2025_07_11 farmer_advisory_2025_07_11_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_11
    ADD CONSTRAINT farmer_advisory_2025_07_11_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5427 (class 2606 OID 829339)
-- Name: farmer_advisory_2025_07_12 farmer_advisory_2025_07_12_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_12
    ADD CONSTRAINT farmer_advisory_2025_07_12_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5433 (class 2606 OID 829624)
-- Name: farmer_advisory_2025_07_13 farmer_advisory_2025_07_13_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_13
    ADD CONSTRAINT farmer_advisory_2025_07_13_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5439 (class 2606 OID 829893)
-- Name: farmer_advisory_2025_07_14 farmer_advisory_2025_07_14_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_14
    ADD CONSTRAINT farmer_advisory_2025_07_14_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5445 (class 2606 OID 830193)
-- Name: farmer_advisory_2025_07_15 farmer_advisory_2025_07_15_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_15
    ADD CONSTRAINT farmer_advisory_2025_07_15_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5451 (class 2606 OID 830514)
-- Name: farmer_advisory_2025_07_16 farmer_advisory_2025_07_16_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_16
    ADD CONSTRAINT farmer_advisory_2025_07_16_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5457 (class 2606 OID 830846)
-- Name: farmer_advisory_2025_07_17 farmer_advisory_2025_07_17_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_17
    ADD CONSTRAINT farmer_advisory_2025_07_17_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5463 (class 2606 OID 831154)
-- Name: farmer_advisory_2025_07_18 farmer_advisory_2025_07_18_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_18
    ADD CONSTRAINT farmer_advisory_2025_07_18_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5469 (class 2606 OID 872159)
-- Name: farmer_advisory_2025_07_19 farmer_advisory_2025_07_19_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_19
    ADD CONSTRAINT farmer_advisory_2025_07_19_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5475 (class 2606 OID 872470)
-- Name: farmer_advisory_2025_07_20 farmer_advisory_2025_07_20_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_20
    ADD CONSTRAINT farmer_advisory_2025_07_20_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5481 (class 2606 OID 872728)
-- Name: farmer_advisory_2025_07_21 farmer_advisory_2025_07_21_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_21
    ADD CONSTRAINT farmer_advisory_2025_07_21_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5487 (class 2606 OID 983876)
-- Name: farmer_advisory_2025_07_22 farmer_advisory_2025_07_22_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_22
    ADD CONSTRAINT farmer_advisory_2025_07_22_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5495 (class 2606 OID 1090491)
-- Name: farmer_advisory_2025_07_23 farmer_advisory_2025_07_23_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_23
    ADD CONSTRAINT farmer_advisory_2025_07_23_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5501 (class 2606 OID 1090823)
-- Name: farmer_advisory_2025_07_24 farmer_advisory_2025_07_24_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_24
    ADD CONSTRAINT farmer_advisory_2025_07_24_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5507 (class 2606 OID 1091127)
-- Name: farmer_advisory_2025_07_25 farmer_advisory_2025_07_25_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_25
    ADD CONSTRAINT farmer_advisory_2025_07_25_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5513 (class 2606 OID 1134022)
-- Name: farmer_advisory_2025_07_26 farmer_advisory_2025_07_26_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_26
    ADD CONSTRAINT farmer_advisory_2025_07_26_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5519 (class 2606 OID 1134300)
-- Name: farmer_advisory_2025_07_27 farmer_advisory_2025_07_27_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_27
    ADD CONSTRAINT farmer_advisory_2025_07_27_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5525 (class 2606 OID 1134565)
-- Name: farmer_advisory_2025_07_28 farmer_advisory_2025_07_28_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_28
    ADD CONSTRAINT farmer_advisory_2025_07_28_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5541 (class 2606 OID 1178055)
-- Name: farmer_advisory_2025_07_29 farmer_advisory_2025_07_29_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_29
    ADD CONSTRAINT farmer_advisory_2025_07_29_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5547 (class 2606 OID 1560947)
-- Name: farmer_advisory_2025_07_30 farmer_advisory_2025_07_30_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_30
    ADD CONSTRAINT farmer_advisory_2025_07_30_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5553 (class 2606 OID 1561542)
-- Name: farmer_advisory_2025_07_31 farmer_advisory_2025_07_31_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_07_31
    ADD CONSTRAINT farmer_advisory_2025_07_31_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5559 (class 2606 OID 1561882)
-- Name: farmer_advisory_2025_08_01 farmer_advisory_2025_08_01_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_01
    ADD CONSTRAINT farmer_advisory_2025_08_01_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5565 (class 2606 OID 1562206)
-- Name: farmer_advisory_2025_08_02 farmer_advisory_2025_08_02_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_02
    ADD CONSTRAINT farmer_advisory_2025_08_02_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5571 (class 2606 OID 1562479)
-- Name: farmer_advisory_2025_08_03 farmer_advisory_2025_08_03_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_03
    ADD CONSTRAINT farmer_advisory_2025_08_03_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5577 (class 2606 OID 1562811)
-- Name: farmer_advisory_2025_08_04 farmer_advisory_2025_08_04_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_04
    ADD CONSTRAINT farmer_advisory_2025_08_04_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5583 (class 2606 OID 1563070)
-- Name: farmer_advisory_2025_08_05 farmer_advisory_2025_08_05_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_05
    ADD CONSTRAINT farmer_advisory_2025_08_05_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5589 (class 2606 OID 1563421)
-- Name: farmer_advisory_2025_08_06 farmer_advisory_2025_08_06_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_06
    ADD CONSTRAINT farmer_advisory_2025_08_06_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5595 (class 2606 OID 1563678)
-- Name: farmer_advisory_2025_08_07 farmer_advisory_2025_08_07_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_07
    ADD CONSTRAINT farmer_advisory_2025_08_07_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5601 (class 2606 OID 1564012)
-- Name: farmer_advisory_2025_08_08 farmer_advisory_2025_08_08_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_08
    ADD CONSTRAINT farmer_advisory_2025_08_08_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5627 (class 2606 OID 1564478)
-- Name: farmer_advisory_2025_08_09 farmer_advisory_2025_08_09_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_09
    ADD CONSTRAINT farmer_advisory_2025_08_09_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5633 (class 2606 OID 1564775)
-- Name: farmer_advisory_2025_08_10 farmer_advisory_2025_08_10_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_10
    ADD CONSTRAINT farmer_advisory_2025_08_10_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5639 (class 2606 OID 1565088)
-- Name: farmer_advisory_2025_08_11 farmer_advisory_2025_08_11_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_11
    ADD CONSTRAINT farmer_advisory_2025_08_11_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5645 (class 2606 OID 1565387)
-- Name: farmer_advisory_2025_08_12 farmer_advisory_2025_08_12_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_12
    ADD CONSTRAINT farmer_advisory_2025_08_12_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5651 (class 2606 OID 1565713)
-- Name: farmer_advisory_2025_08_13 farmer_advisory_2025_08_13_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_13
    ADD CONSTRAINT farmer_advisory_2025_08_13_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5661 (class 2606 OID 1566274)
-- Name: farmer_advisory_2025_08_14 farmer_advisory_2025_08_14_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_14
    ADD CONSTRAINT farmer_advisory_2025_08_14_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5677 (class 2606 OID 1566510)
-- Name: farmer_advisory_2025_08_15 farmer_advisory_2025_08_15_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_2025_08_15
    ADD CONSTRAINT farmer_advisory_2025_08_15_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5341 (class 2606 OID 707323)
-- Name: farmer_advisory_copy1 farmer_advisory_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_copy1
    ADD CONSTRAINT farmer_advisory_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 5348 (class 2606 OID 707325)
-- Name: farmer_advisory_global farmer_advisory_global_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_global
    ADD CONSTRAINT farmer_advisory_global_pkey PRIMARY KEY (id);


--
-- TOC entry 5351 (class 2606 OID 707338)
-- Name: farmer_advisory_old farmer_advisory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_old
    ADD CONSTRAINT farmer_advisory_pkey PRIMARY KEY (id);


--
-- TOC entry 5415 (class 2606 OID 707684)
-- Name: farmer_advisory farmer_advisory_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory
    ADD CONSTRAINT farmer_advisory_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5353 (class 2606 OID 707362)
-- Name: farmer_advisory_stats farmer_advisory_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_stats
    ADD CONSTRAINT farmer_advisory_stats_pkey PRIMARY KEY (id);


--
-- TOC entry 5355 (class 2606 OID 707364)
-- Name: farming_activity_types farming_activity_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farming_activity_types
    ADD CONSTRAINT farming_activity_types_pkey PRIMARY KEY (id);


--
-- TOC entry 5610 (class 2606 OID 1564343)
-- Name: formulations formulations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.formulations
    ADD CONSTRAINT formulations_pkey PRIMARY KEY (id);


--
-- TOC entry 5656 (class 2606 OID 1566054)
-- Name: geographic_locations geographic_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.geographic_locations
    ADD CONSTRAINT geographic_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 5360 (class 2606 OID 707366)
-- Name: location_users_global location_users_global_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_users_global
    ADD CONSTRAINT location_users_global_pkey PRIMARY KEY (id);


--
-- TOC entry 5612 (class 2606 OID 1564353)
-- Name: modes_of_action modes_of_action_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modes_of_action
    ADD CONSTRAINT modes_of_action_pkey PRIMARY KEY (id);


--
-- TOC entry 5362 (class 2606 OID 707368)
-- Name: numbers numbers_msisdn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.numbers
    ADD CONSTRAINT numbers_msisdn_key UNIQUE (msisdn);


--
-- TOC entry 5365 (class 2606 OID 707370)
-- Name: parameters parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_pkey PRIMARY KEY (id);


--
-- TOC entry 5622 (class 2606 OID 1564404)
-- Name: pest_categories pest_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.pest_categories
    ADD CONSTRAINT pest_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 5536 (class 2606 OID 1177748)
-- Name: product_advisory_jobs product_advisory_jobs_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_advisory_jobs
    ADD CONSTRAINT product_advisory_jobs_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5533 (class 2606 OID 1177733)
-- Name: product_advisory product_advisory_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_advisory
    ADD CONSTRAINT product_advisory_pkey1 PRIMARY KEY (id);


--
-- TOC entry 5608 (class 2606 OID 1564333)
-- Name: product_categories product_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_category_pkey PRIMARY KEY (id);


--
-- TOC entry 5367 (class 2606 OID 707378)
-- Name: product_cc_requests product_cc_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_cc_requests
    ADD CONSTRAINT product_cc_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 5606 (class 2606 OID 1564313)
-- Name: product_companies product_company_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_companies
    ADD CONSTRAINT product_company_pkey PRIMARY KEY (id);


--
-- TOC entry 5369 (class 2606 OID 707380)
-- Name: product_mappings product_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_mappings
    ADD CONSTRAINT product_mappings_pkey PRIMARY KEY (id);


--
-- TOC entry 5371 (class 2606 OID 707382)
-- Name: product_mappings product_mappings_product_id_chemical_formula_product_name_c_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_mappings
    ADD CONSTRAINT product_mappings_product_id_chemical_formula_product_name_c_key UNIQUE (product_id, chemical_formula, product_name, city_name);


--
-- TOC entry 5618 (class 2606 OID 1564383)
-- Name: safety_precautions safety_precautions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.safety_precautions
    ADD CONSTRAINT safety_precautions_pkey PRIMARY KEY (id);


--
-- TOC entry 5674 (class 2606 OID 1566440)
-- Name: shopify_product_advisories shopify_product_advisories_new_pkey; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.shopify_product_advisories
    ADD CONSTRAINT shopify_product_advisories_new_pkey PRIMARY KEY (id);


--
-- TOC entry 5492 (class 2606 OID 984030)
-- Name: shopify_product_advisory_recommendations shopify_product_advisory_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.shopify_product_advisory_recommendations
    ADD CONSTRAINT shopify_product_advisory_recommendations_pkey PRIMARY KEY (id);


--
-- TOC entry 5672 (class 2606 OID 1566420)
-- Name: shopify_products shopify_products_new_pkey; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.shopify_products
    ADD CONSTRAINT shopify_products_new_pkey PRIMARY KEY (id);


--
-- TOC entry 5375 (class 2606 OID 707388)
-- Name: sms_cta sms_cta_pkey; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.sms_cta
    ADD CONSTRAINT sms_cta_pkey PRIMARY KEY (id);


--
-- TOC entry 5378 (class 2606 OID 707390)
-- Name: sms_cta_translations sms_cta_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.sms_cta_translations
    ADD CONSTRAINT sms_cta_translations_pkey PRIMARY KEY (id);


--
-- TOC entry 5380 (class 2606 OID 707392)
-- Name: sms_cta_translations sms_cta_translations_sms_cta_id_language_id_key; Type: CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.sms_cta_translations
    ADD CONSTRAINT sms_cta_translations_sms_cta_id_language_id_key UNIQUE (sms_cta_id, language_id);


--
-- TOC entry 5382 (class 2606 OID 707394)
-- Name: sms_history sms_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sms_history
    ADD CONSTRAINT sms_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5384 (class 2606 OID 707396)
-- Name: soil_type_category soil_type_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_type_category
    ADD CONSTRAINT soil_type_category_pkey PRIMARY KEY (id);


--
-- TOC entry 5386 (class 2606 OID 707398)
-- Name: soil_type_category soil_type_category_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_type_category
    ADD CONSTRAINT soil_type_category_title_key UNIQUE (title);


--
-- TOC entry 5388 (class 2606 OID 707400)
-- Name: soil_type_parameters soil_type_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_type_parameters
    ADD CONSTRAINT soil_type_parameters_pkey PRIMARY KEY (id);


--
-- TOC entry 5391 (class 2606 OID 707402)
-- Name: sync_tables sync_tables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sync_tables
    ADD CONSTRAINT sync_tables_pkey PRIMARY KEY (id);


--
-- TOC entry 5658 (class 2606 OID 1566095)
-- Name: targeted_pests targeted_pests_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.targeted_pests
    ADD CONSTRAINT targeted_pests_pkey PRIMARY KEY (id);


--
-- TOC entry 5393 (class 2606 OID 707404)
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- TOC entry 5395 (class 2606 OID 707406)
-- Name: time_periods time_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.time_periods
    ADD CONSTRAINT time_periods_pkey PRIMARY KEY (id);


--
-- TOC entry 5614 (class 2606 OID 1564363)
-- Name: times_of_application times_of_application_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.times_of_application
    ADD CONSTRAINT times_of_application_pkey PRIMARY KEY (id);


--
-- TOC entry 5253 (class 2606 OID 707408)
-- Name: advisory_products unique_advisory_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_products
    ADD CONSTRAINT unique_advisory_product UNIQUE (advisory_id, chemical_formula, product_id);


--
-- TOC entry 5373 (class 2606 OID 707410)
-- Name: product_mappings unique_product_key_mapping; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_mappings
    ADD CONSTRAINT unique_product_key_mapping UNIQUE (product_id, chemical_formula, location_id, product_name);


--
-- TOC entry 5397 (class 2606 OID 707412)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5399 (class 2606 OID 707414)
-- Name: weather_condition_types weather_condition_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_condition_types
    ADD CONSTRAINT weather_condition_types_pkey PRIMARY KEY (id);


--
-- TOC entry 5402 (class 2606 OID 707416)
-- Name: weather_conditions weather_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_conditions
    ADD CONSTRAINT weather_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 5404 (class 2606 OID 707418)
-- Name: weather_data weather_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_data
    ADD CONSTRAINT weather_data_pkey PRIMARY KEY (id, site_id, weather_dt);


--
-- TOC entry 5624 (class 2606 OID 1564414)
-- Name: weed_types weed_types_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.weed_types
    ADD CONSTRAINT weed_types_pkey PRIMARY KEY (id);


--
-- TOC entry 5406 (class 2606 OID 707420)
-- Name: layer layer_pkey; Type: CONSTRAINT; Schema: topology; Owner: postgres
--

ALTER TABLE ONLY topology.layer
    ADD CONSTRAINT layer_pkey PRIMARY KEY (topology_id, layer_id);


--
-- TOC entry 5408 (class 2606 OID 707422)
-- Name: layer layer_schema_name_table_name_feature_column_key; Type: CONSTRAINT; Schema: topology; Owner: postgres
--

ALTER TABLE ONLY topology.layer
    ADD CONSTRAINT layer_schema_name_table_name_feature_column_key UNIQUE (schema_name, table_name, feature_column);


--
-- TOC entry 5410 (class 2606 OID 707424)
-- Name: topology topology_name_key; Type: CONSTRAINT; Schema: topology; Owner: postgres
--

ALTER TABLE ONLY topology.topology
    ADD CONSTRAINT topology_name_key UNIQUE (name);


--
-- TOC entry 5412 (class 2606 OID 707426)
-- Name: topology topology_pkey; Type: CONSTRAINT; Schema: topology; Owner: postgres
--

ALTER TABLE ONLY topology.topology
    ADD CONSTRAINT topology_pkey PRIMARY KEY (id);


--
-- TOC entry 5220 (class 1259 OID 707427)
-- Name: advisory_calender_day_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_calender_day_idx ON public.advisory USING btree (calender_day);


--
-- TOC entry 5231 (class 1259 OID 707428)
-- Name: advisory_conditions_advisory_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_conditions_advisory_id_idx ON public.advisory_conditions USING btree (advisory_id);


--
-- TOC entry 5221 (class 1259 OID 707429)
-- Name: advisory_content_file_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_content_file_id_idx ON public.advisory USING btree (content_file_id);


--
-- TOC entry 5222 (class 1259 OID 707430)
-- Name: advisory_content_file_id_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_content_file_id_idx1 ON public.advisory USING btree (content_file_id);


--
-- TOC entry 5223 (class 1259 OID 707431)
-- Name: advisory_crop_calender_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_crop_calender_id_idx ON public.advisory USING btree (crop_calender_id);


--
-- TOC entry 5224 (class 1259 OID 707432)
-- Name: advisory_day_month_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_day_month_idx ON public.advisory USING btree (advisory_day_month);


--
-- TOC entry 5225 (class 1259 OID 707433)
-- Name: advisory_group_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_group_id_idx ON public.advisory USING btree (group_id);


--
-- TOC entry 5243 (class 1259 OID 707434)
-- Name: advisory_growth_stages_advisory_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_growth_stages_advisory_id_idx ON public.advisory_growth_stages USING btree (advisory_id);


--
-- TOC entry 5244 (class 1259 OID 707435)
-- Name: advisory_growth_stages_growth_stage_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_growth_stages_growth_stage_id_idx ON public.advisory_growth_stages USING btree (growth_stage_id);


--
-- TOC entry 5245 (class 1259 OID 707436)
-- Name: advisory_growth_stages_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_growth_stages_id_idx ON public.advisory_growth_stages USING btree (id);


--
-- TOC entry 5226 (class 1259 OID 707437)
-- Name: advisory_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_id_idx ON public.advisory USING btree (id);


--
-- TOC entry 5227 (class 1259 OID 707438)
-- Name: advisory_id_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_id_idx1 ON public.advisory USING btree (id);


--
-- TOC entry 5230 (class 1259 OID 707439)
-- Name: advisory_sowing_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advisory_sowing_id_idx ON public.advisory USING btree (sowing_id);


--
-- TOC entry 5260 (class 1259 OID 707440)
-- Name: agb_calender_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agb_calender_day ON public.agri_bank_advisory_jobs USING btree (calender_day);


--
-- TOC entry 5261 (class 1259 OID 707441)
-- Name: agb_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agb_created ON public.agri_bank_advisory_jobs USING btree (created);


--
-- TOC entry 5262 (class 1259 OID 707442)
-- Name: agb_crop_cln_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agb_crop_cln_id ON public.agri_bank_advisory_jobs USING btree (crop_calender_id);


--
-- TOC entry 5263 (class 1259 OID 707443)
-- Name: agb_job_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agb_job_type_idx ON public.agri_bank_advisory_jobs USING btree (job_type);


--
-- TOC entry 5270 (class 1259 OID 707448)
-- Name: agri_bank_advisory_jobs_advisory_id_create_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX agri_bank_advisory_jobs_advisory_id_create_dt_idx ON public.agri_bank_advisory_jobs_old USING btree (advisory_id, create_dt);


--
-- TOC entry 5264 (class 1259 OID 707449)
-- Name: agri_bank_advisory_jobs_advisory_id_create_dt_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX agri_bank_advisory_jobs_advisory_id_create_dt_idx1 ON public.agri_bank_advisory_jobs USING btree (advisory_id, create_dt);


--
-- TOC entry 5267 (class 1259 OID 707450)
-- Name: agri_bank_advisory_jobs_global_advisory_id_create_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX agri_bank_advisory_jobs_global_advisory_id_create_dt_idx ON public.agri_bank_advisory_jobs_global USING btree (advisory_id, create_dt);


--
-- TOC entry 5356 (class 1259 OID 707457)
-- Name: cdate_agb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cdate_agb ON public.location_users USING btree (create_dt);


--
-- TOC entry 5310 (class 1259 OID 707463)
-- Name: content_files_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX content_files_id_idx ON public.content_files USING btree (id);


--
-- TOC entry 5317 (class 1259 OID 707464)
-- Name: content_folders_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX content_folders_id_idx ON public.content_folders USING btree (id);


--
-- TOC entry 5286 (class 1259 OID 707465)
-- Name: crop_calender_crop_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_crop_id_idx ON public.crop_calender USING btree (crop_id);


--
-- TOC entry 5287 (class 1259 OID 707466)
-- Name: crop_calender_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_id_idx ON public.crop_calender USING btree (id);


--
-- TOC entry 5324 (class 1259 OID 707467)
-- Name: crop_calender_languages_crop_calender_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_languages_crop_calender_id_idx ON public.crop_calender_languages USING btree (crop_calender_id);


--
-- TOC entry 5325 (class 1259 OID 707468)
-- Name: crop_calender_languages_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_languages_id_idx ON public.crop_calender_languages USING btree (id);


--
-- TOC entry 5326 (class 1259 OID 707469)
-- Name: crop_calender_languages_language_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_languages_language_id_idx ON public.crop_calender_languages USING btree (language_id);


--
-- TOC entry 5292 (class 1259 OID 707470)
-- Name: crop_calender_locations_crop_calender_scheduler_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_locations_crop_calender_scheduler_id_idx ON public.crop_calender_locations USING btree (crop_calender_scheduler_id);


--
-- TOC entry 5293 (class 1259 OID 707471)
-- Name: crop_calender_locations_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_locations_id_idx ON public.crop_calender_locations USING btree (id);


--
-- TOC entry 5294 (class 1259 OID 707472)
-- Name: crop_calender_locations_location_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_locations_location_id_idx ON public.crop_calender_locations USING btree (location_id);


--
-- TOC entry 5256 (class 1259 OID 707473)
-- Name: crop_calender_scheduler_crop_calender_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_scheduler_crop_calender_id_idx ON public.crop_calender_scheduler USING btree (crop_calender_id);


--
-- TOC entry 5257 (class 1259 OID 707474)
-- Name: crop_calender_scheduler_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_scheduler_id_idx ON public.crop_calender_scheduler USING btree (id);


--
-- TOC entry 5329 (class 1259 OID 707475)
-- Name: crop_calender_seed_types_crop_calender_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_seed_types_crop_calender_id_idx ON public.crop_calender_scheduler_seed_types USING btree (scheduler_id);


--
-- TOC entry 5330 (class 1259 OID 707476)
-- Name: crop_calender_seed_types_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_seed_types_id_idx ON public.crop_calender_scheduler_seed_types USING btree (id);


--
-- TOC entry 5333 (class 1259 OID 707477)
-- Name: crop_calender_seed_types_seed_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_seed_types_seed_type_id_idx ON public.crop_calender_scheduler_seed_types USING btree (seed_type_id);


--
-- TOC entry 5334 (class 1259 OID 707478)
-- Name: crop_calender_stages_crop_calender_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_stages_crop_calender_id_idx ON public.crop_calender_stages USING btree (crop_calender_id);


--
-- TOC entry 5337 (class 1259 OID 707479)
-- Name: crop_calender_stages_growth_stages_crop_calender_stage_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_calender_stages_growth_stages_crop_calender_stage_id_idx ON public.crop_calender_stages_growth_stages USING btree (crop_calender_stage_id);


--
-- TOC entry 5357 (class 1259 OID 707480)
-- Name: crop_cln_sch_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_cln_sch_id ON public.location_users USING btree (crop_calender_scheduler_id);


--
-- TOC entry 5358 (class 1259 OID 707481)
-- Name: crop_clndr_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX crop_clndr_id ON public.location_users USING btree (crop_calender_id);


--
-- TOC entry 5419 (class 1259 OID 829182)
-- Name: farmer_advisory_2025_07_11_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_11_msisdn_job_id_idx ON public.farmer_advisory_2025_07_11 USING btree (msisdn, job_id);


--
-- TOC entry 5425 (class 1259 OID 829350)
-- Name: farmer_advisory_2025_07_12_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_12_msisdn_job_id_idx ON public.farmer_advisory_2025_07_12 USING btree (msisdn, job_id);


--
-- TOC entry 5431 (class 1259 OID 829626)
-- Name: farmer_advisory_2025_07_13_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_13_msisdn_job_id_idx ON public.farmer_advisory_2025_07_13 USING btree (msisdn, job_id);


--
-- TOC entry 5437 (class 1259 OID 829897)
-- Name: farmer_advisory_2025_07_14_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_14_msisdn_job_id_idx ON public.farmer_advisory_2025_07_14 USING btree (msisdn, job_id);


--
-- TOC entry 5443 (class 1259 OID 830196)
-- Name: farmer_advisory_2025_07_15_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_15_msisdn_job_id_idx ON public.farmer_advisory_2025_07_15 USING btree (msisdn, job_id);


--
-- TOC entry 5449 (class 1259 OID 830515)
-- Name: farmer_advisory_2025_07_16_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_16_msisdn_job_id_idx ON public.farmer_advisory_2025_07_16 USING btree (msisdn, job_id);


--
-- TOC entry 5455 (class 1259 OID 830848)
-- Name: farmer_advisory_2025_07_17_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_17_msisdn_job_id_idx ON public.farmer_advisory_2025_07_17 USING btree (msisdn, job_id);


--
-- TOC entry 5461 (class 1259 OID 831158)
-- Name: farmer_advisory_2025_07_18_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_18_msisdn_job_id_idx ON public.farmer_advisory_2025_07_18 USING btree (msisdn, job_id);


--
-- TOC entry 5467 (class 1259 OID 872170)
-- Name: farmer_advisory_2025_07_19_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_19_msisdn_job_id_idx ON public.farmer_advisory_2025_07_19 USING btree (msisdn, job_id);


--
-- TOC entry 5473 (class 1259 OID 872477)
-- Name: farmer_advisory_2025_07_20_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_20_msisdn_job_id_idx ON public.farmer_advisory_2025_07_20 USING btree (msisdn, job_id);


--
-- TOC entry 5479 (class 1259 OID 872735)
-- Name: farmer_advisory_2025_07_21_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_21_msisdn_job_id_idx ON public.farmer_advisory_2025_07_21 USING btree (msisdn, job_id);


--
-- TOC entry 5485 (class 1259 OID 983877)
-- Name: farmer_advisory_2025_07_22_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_22_msisdn_job_id_idx ON public.farmer_advisory_2025_07_22 USING btree (msisdn, job_id);


--
-- TOC entry 5493 (class 1259 OID 1090492)
-- Name: farmer_advisory_2025_07_23_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_23_msisdn_job_id_idx ON public.farmer_advisory_2025_07_23 USING btree (msisdn, job_id);


--
-- TOC entry 5499 (class 1259 OID 1090824)
-- Name: farmer_advisory_2025_07_24_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_24_msisdn_job_id_idx ON public.farmer_advisory_2025_07_24 USING btree (msisdn, job_id);


--
-- TOC entry 5505 (class 1259 OID 1091128)
-- Name: farmer_advisory_2025_07_25_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_25_msisdn_job_id_idx ON public.farmer_advisory_2025_07_25 USING btree (msisdn, job_id);


--
-- TOC entry 5511 (class 1259 OID 1134023)
-- Name: farmer_advisory_2025_07_26_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_26_msisdn_job_id_idx ON public.farmer_advisory_2025_07_26 USING btree (msisdn, job_id);


--
-- TOC entry 5517 (class 1259 OID 1134301)
-- Name: farmer_advisory_2025_07_27_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_27_msisdn_job_id_idx ON public.farmer_advisory_2025_07_27 USING btree (msisdn, job_id);


--
-- TOC entry 5523 (class 1259 OID 1134566)
-- Name: farmer_advisory_2025_07_28_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_28_msisdn_job_id_idx ON public.farmer_advisory_2025_07_28 USING btree (msisdn, job_id);


--
-- TOC entry 5539 (class 1259 OID 1178058)
-- Name: farmer_advisory_2025_07_29_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_29_msisdn_job_id_idx ON public.farmer_advisory_2025_07_29 USING btree (msisdn, job_id);


--
-- TOC entry 5545 (class 1259 OID 1560950)
-- Name: farmer_advisory_2025_07_30_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_30_msisdn_job_id_idx ON public.farmer_advisory_2025_07_30 USING btree (msisdn, job_id);


--
-- TOC entry 5551 (class 1259 OID 1561543)
-- Name: farmer_advisory_2025_07_31_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_07_31_msisdn_job_id_idx ON public.farmer_advisory_2025_07_31 USING btree (msisdn, job_id);


--
-- TOC entry 5557 (class 1259 OID 1561883)
-- Name: farmer_advisory_2025_08_01_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_01_msisdn_job_id_idx ON public.farmer_advisory_2025_08_01 USING btree (msisdn, job_id);


--
-- TOC entry 5563 (class 1259 OID 1562207)
-- Name: farmer_advisory_2025_08_02_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_02_msisdn_job_id_idx ON public.farmer_advisory_2025_08_02 USING btree (msisdn, job_id);


--
-- TOC entry 5569 (class 1259 OID 1562483)
-- Name: farmer_advisory_2025_08_03_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_03_msisdn_job_id_idx ON public.farmer_advisory_2025_08_03 USING btree (msisdn, job_id);


--
-- TOC entry 5575 (class 1259 OID 1562812)
-- Name: farmer_advisory_2025_08_04_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_04_msisdn_job_id_idx ON public.farmer_advisory_2025_08_04 USING btree (msisdn, job_id);


--
-- TOC entry 5581 (class 1259 OID 1563071)
-- Name: farmer_advisory_2025_08_05_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_05_msisdn_job_id_idx ON public.farmer_advisory_2025_08_05 USING btree (msisdn, job_id);


--
-- TOC entry 5587 (class 1259 OID 1563422)
-- Name: farmer_advisory_2025_08_06_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_06_msisdn_job_id_idx ON public.farmer_advisory_2025_08_06 USING btree (msisdn, job_id);


--
-- TOC entry 5593 (class 1259 OID 1563679)
-- Name: farmer_advisory_2025_08_07_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_07_msisdn_job_id_idx ON public.farmer_advisory_2025_08_07 USING btree (msisdn, job_id);


--
-- TOC entry 5599 (class 1259 OID 1564013)
-- Name: farmer_advisory_2025_08_08_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_08_msisdn_job_id_idx ON public.farmer_advisory_2025_08_08 USING btree (msisdn, job_id);


--
-- TOC entry 5625 (class 1259 OID 1564479)
-- Name: farmer_advisory_2025_08_09_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_09_msisdn_job_id_idx ON public.farmer_advisory_2025_08_09 USING btree (msisdn, job_id);


--
-- TOC entry 5631 (class 1259 OID 1564779)
-- Name: farmer_advisory_2025_08_10_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_10_msisdn_job_id_idx ON public.farmer_advisory_2025_08_10 USING btree (msisdn, job_id);


--
-- TOC entry 5637 (class 1259 OID 1565089)
-- Name: farmer_advisory_2025_08_11_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_11_msisdn_job_id_idx ON public.farmer_advisory_2025_08_11 USING btree (msisdn, job_id);


--
-- TOC entry 5643 (class 1259 OID 1565394)
-- Name: farmer_advisory_2025_08_12_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_12_msisdn_job_id_idx ON public.farmer_advisory_2025_08_12 USING btree (msisdn, job_id);


--
-- TOC entry 5649 (class 1259 OID 1565718)
-- Name: farmer_advisory_2025_08_13_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_13_msisdn_job_id_idx ON public.farmer_advisory_2025_08_13 USING btree (msisdn, job_id);


--
-- TOC entry 5659 (class 1259 OID 1566275)
-- Name: farmer_advisory_2025_08_14_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_14_msisdn_job_id_idx ON public.farmer_advisory_2025_08_14 USING btree (msisdn, job_id);


--
-- TOC entry 5675 (class 1259 OID 1566511)
-- Name: farmer_advisory_2025_08_15_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_2025_08_15_msisdn_job_id_idx ON public.farmer_advisory_2025_08_15 USING btree (msisdn, job_id);


--
-- TOC entry 5346 (class 1259 OID 707482)
-- Name: farmer_advisory_global_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_global_msisdn_job_id_idx ON public.farmer_advisory_global USING btree (msisdn, job_id);


--
-- TOC entry 5349 (class 1259 OID 707483)
-- Name: farmer_advisory_msisdn_advisory_create_dt_advisory_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_msisdn_advisory_create_dt_advisory_id_idx ON public.farmer_advisory_old USING btree (msisdn, advisory_create_dt, advisory_id);


--
-- TOC entry 5413 (class 1259 OID 707679)
-- Name: farmer_advisory_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_msisdn_job_id_idx ON public.farmer_advisory USING btree (msisdn, job_id);


--
-- TOC entry 5342 (class 1259 OID 707484)
-- Name: farmer_advisory_msisdn_job_id_idx_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_advisory_msisdn_job_id_idx_copy1 ON public.farmer_advisory_copy1 USING btree (msisdn, job_id);


--
-- TOC entry 5238 (class 1259 OID 707485)
-- Name: idx_advisory_feedback_advisory; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advisory_feedback_advisory ON public.advisory_feedback USING btree (advisory_id);


--
-- TOC entry 5239 (class 1259 OID 707486)
-- Name: idx_advisory_feedback_create_dt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advisory_feedback_create_dt ON public.advisory_feedback USING btree (create_dt);


--
-- TOC entry 5240 (class 1259 OID 707487)
-- Name: idx_advisory_feedback_msisdn; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advisory_feedback_msisdn ON public.advisory_feedback USING btree (msisdn);


--
-- TOC entry 5416 (class 1259 OID 707680)
-- Name: idx_agb_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_created ON public.farmer_advisory USING btree (create_dt);


--
-- TOC entry 5343 (class 1259 OID 707488)
-- Name: idx_agb_created_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_created_copy1 ON public.farmer_advisory_copy1 USING btree (create_dt);


--
-- TOC entry 5422 (class 1259 OID 829183)
-- Name: idx_agb_farmer_advisory_2025_07_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_11 ON public.farmer_advisory_2025_07_11 USING btree (create_dt);


--
-- TOC entry 5428 (class 1259 OID 829353)
-- Name: idx_agb_farmer_advisory_2025_07_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_12 ON public.farmer_advisory_2025_07_12 USING btree (create_dt);


--
-- TOC entry 5434 (class 1259 OID 829629)
-- Name: idx_agb_farmer_advisory_2025_07_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_13 ON public.farmer_advisory_2025_07_13 USING btree (create_dt);


--
-- TOC entry 5440 (class 1259 OID 829907)
-- Name: idx_agb_farmer_advisory_2025_07_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_14 ON public.farmer_advisory_2025_07_14 USING btree (create_dt);


--
-- TOC entry 5446 (class 1259 OID 830199)
-- Name: idx_agb_farmer_advisory_2025_07_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_15 ON public.farmer_advisory_2025_07_15 USING btree (create_dt);


--
-- TOC entry 5452 (class 1259 OID 830516)
-- Name: idx_agb_farmer_advisory_2025_07_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_16 ON public.farmer_advisory_2025_07_16 USING btree (create_dt);


--
-- TOC entry 5458 (class 1259 OID 830852)
-- Name: idx_agb_farmer_advisory_2025_07_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_17 ON public.farmer_advisory_2025_07_17 USING btree (create_dt);


--
-- TOC entry 5464 (class 1259 OID 831159)
-- Name: idx_agb_farmer_advisory_2025_07_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_18 ON public.farmer_advisory_2025_07_18 USING btree (create_dt);


--
-- TOC entry 5470 (class 1259 OID 872173)
-- Name: idx_agb_farmer_advisory_2025_07_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_19 ON public.farmer_advisory_2025_07_19 USING btree (create_dt);


--
-- TOC entry 5476 (class 1259 OID 872478)
-- Name: idx_agb_farmer_advisory_2025_07_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_20 ON public.farmer_advisory_2025_07_20 USING btree (create_dt);


--
-- TOC entry 5482 (class 1259 OID 872740)
-- Name: idx_agb_farmer_advisory_2025_07_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_21 ON public.farmer_advisory_2025_07_21 USING btree (create_dt);


--
-- TOC entry 5488 (class 1259 OID 983878)
-- Name: idx_agb_farmer_advisory_2025_07_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_22 ON public.farmer_advisory_2025_07_22 USING btree (create_dt);


--
-- TOC entry 5496 (class 1259 OID 1090493)
-- Name: idx_agb_farmer_advisory_2025_07_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_23 ON public.farmer_advisory_2025_07_23 USING btree (create_dt);


--
-- TOC entry 5502 (class 1259 OID 1090825)
-- Name: idx_agb_farmer_advisory_2025_07_24; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_24 ON public.farmer_advisory_2025_07_24 USING btree (create_dt);


--
-- TOC entry 5508 (class 1259 OID 1091129)
-- Name: idx_agb_farmer_advisory_2025_07_25; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_25 ON public.farmer_advisory_2025_07_25 USING btree (create_dt);


--
-- TOC entry 5514 (class 1259 OID 1134024)
-- Name: idx_agb_farmer_advisory_2025_07_26; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_26 ON public.farmer_advisory_2025_07_26 USING btree (create_dt);


--
-- TOC entry 5520 (class 1259 OID 1134302)
-- Name: idx_agb_farmer_advisory_2025_07_27; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_27 ON public.farmer_advisory_2025_07_27 USING btree (create_dt);


--
-- TOC entry 5526 (class 1259 OID 1134567)
-- Name: idx_agb_farmer_advisory_2025_07_28; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_28 ON public.farmer_advisory_2025_07_28 USING btree (create_dt);


--
-- TOC entry 5542 (class 1259 OID 1178059)
-- Name: idx_agb_farmer_advisory_2025_07_29; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_29 ON public.farmer_advisory_2025_07_29 USING btree (create_dt);


--
-- TOC entry 5548 (class 1259 OID 1560951)
-- Name: idx_agb_farmer_advisory_2025_07_30; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_30 ON public.farmer_advisory_2025_07_30 USING btree (create_dt);


--
-- TOC entry 5554 (class 1259 OID 1561544)
-- Name: idx_agb_farmer_advisory_2025_07_31; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_07_31 ON public.farmer_advisory_2025_07_31 USING btree (create_dt);


--
-- TOC entry 5560 (class 1259 OID 1561884)
-- Name: idx_agb_farmer_advisory_2025_08_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_01 ON public.farmer_advisory_2025_08_01 USING btree (create_dt);


--
-- TOC entry 5566 (class 1259 OID 1562210)
-- Name: idx_agb_farmer_advisory_2025_08_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_02 ON public.farmer_advisory_2025_08_02 USING btree (create_dt);


--
-- TOC entry 5572 (class 1259 OID 1562484)
-- Name: idx_agb_farmer_advisory_2025_08_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_03 ON public.farmer_advisory_2025_08_03 USING btree (create_dt);


--
-- TOC entry 5578 (class 1259 OID 1562813)
-- Name: idx_agb_farmer_advisory_2025_08_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_04 ON public.farmer_advisory_2025_08_04 USING btree (create_dt);


--
-- TOC entry 5584 (class 1259 OID 1563072)
-- Name: idx_agb_farmer_advisory_2025_08_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_05 ON public.farmer_advisory_2025_08_05 USING btree (create_dt);


--
-- TOC entry 5590 (class 1259 OID 1563423)
-- Name: idx_agb_farmer_advisory_2025_08_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_06 ON public.farmer_advisory_2025_08_06 USING btree (create_dt);


--
-- TOC entry 5596 (class 1259 OID 1563680)
-- Name: idx_agb_farmer_advisory_2025_08_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_07 ON public.farmer_advisory_2025_08_07 USING btree (create_dt);


--
-- TOC entry 5602 (class 1259 OID 1564014)
-- Name: idx_agb_farmer_advisory_2025_08_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_08 ON public.farmer_advisory_2025_08_08 USING btree (create_dt);


--
-- TOC entry 5628 (class 1259 OID 1564480)
-- Name: idx_agb_farmer_advisory_2025_08_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_09 ON public.farmer_advisory_2025_08_09 USING btree (create_dt);


--
-- TOC entry 5634 (class 1259 OID 1564782)
-- Name: idx_agb_farmer_advisory_2025_08_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_10 ON public.farmer_advisory_2025_08_10 USING btree (create_dt);


--
-- TOC entry 5640 (class 1259 OID 1565090)
-- Name: idx_agb_farmer_advisory_2025_08_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_11 ON public.farmer_advisory_2025_08_11 USING btree (create_dt);


--
-- TOC entry 5646 (class 1259 OID 1565398)
-- Name: idx_agb_farmer_advisory_2025_08_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_12 ON public.farmer_advisory_2025_08_12 USING btree (create_dt);


--
-- TOC entry 5652 (class 1259 OID 1565719)
-- Name: idx_agb_farmer_advisory_2025_08_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_13 ON public.farmer_advisory_2025_08_13 USING btree (create_dt);


--
-- TOC entry 5662 (class 1259 OID 1566276)
-- Name: idx_agb_farmer_advisory_2025_08_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_14 ON public.farmer_advisory_2025_08_14 USING btree (create_dt);


--
-- TOC entry 5678 (class 1259 OID 1566512)
-- Name: idx_agb_farmer_advisory_2025_08_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_farmer_advisory_2025_08_15 ON public.farmer_advisory_2025_08_15 USING btree (create_dt);


--
-- TOC entry 5529 (class 1259 OID 1177735)
-- Name: idx_agb_product_advisory; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_agb_product_advisory ON public.product_advisory USING btree (create_dt);


--
-- TOC entry 5303 (class 1259 OID 707489)
-- Name: idx_crop_calender_sowing_window_schedule_locations; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_crop_calender_sowing_window_schedule_locations ON public.crop_calender_sowing_window_schedule_locations USING btree (crop_calender_sowing_window_schedule_id);


--
-- TOC entry 5304 (class 1259 OID 707490)
-- Name: idx_crop_calender_sowing_window_schedule_locations_locationid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_crop_calender_sowing_window_schedule_locations_locationid ON public.crop_calender_sowing_window_schedule_locations USING btree (location_id);


--
-- TOC entry 5307 (class 1259 OID 707491)
-- Name: idx_crop_calender_sowing_window_schedules; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_crop_calender_sowing_window_schedules ON public.crop_calender_sowing_window_schedules USING btree (crop_calender_sowing_window_id);


--
-- TOC entry 5417 (class 1259 OID 707681)
-- Name: job_id_agb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb ON public.farmer_advisory USING btree (job_id);


--
-- TOC entry 5344 (class 1259 OID 707492)
-- Name: job_id_agb_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_copy1 ON public.farmer_advisory_copy1 USING btree (job_id);


--
-- TOC entry 5423 (class 1259 OID 829217)
-- Name: job_id_agb_farmer_advisory_2025_07_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_11 ON public.farmer_advisory_2025_07_11 USING btree (job_id);


--
-- TOC entry 5429 (class 1259 OID 829356)
-- Name: job_id_agb_farmer_advisory_2025_07_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_12 ON public.farmer_advisory_2025_07_12 USING btree (job_id);


--
-- TOC entry 5435 (class 1259 OID 829632)
-- Name: job_id_agb_farmer_advisory_2025_07_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_13 ON public.farmer_advisory_2025_07_13 USING btree (job_id);


--
-- TOC entry 5441 (class 1259 OID 829909)
-- Name: job_id_agb_farmer_advisory_2025_07_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_14 ON public.farmer_advisory_2025_07_14 USING btree (job_id);


--
-- TOC entry 5447 (class 1259 OID 830201)
-- Name: job_id_agb_farmer_advisory_2025_07_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_15 ON public.farmer_advisory_2025_07_15 USING btree (job_id);


--
-- TOC entry 5453 (class 1259 OID 830517)
-- Name: job_id_agb_farmer_advisory_2025_07_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_16 ON public.farmer_advisory_2025_07_16 USING btree (job_id);


--
-- TOC entry 5459 (class 1259 OID 830855)
-- Name: job_id_agb_farmer_advisory_2025_07_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_17 ON public.farmer_advisory_2025_07_17 USING btree (job_id);


--
-- TOC entry 5465 (class 1259 OID 831160)
-- Name: job_id_agb_farmer_advisory_2025_07_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_18 ON public.farmer_advisory_2025_07_18 USING btree (job_id);


--
-- TOC entry 5471 (class 1259 OID 872175)
-- Name: job_id_agb_farmer_advisory_2025_07_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_19 ON public.farmer_advisory_2025_07_19 USING btree (job_id);


--
-- TOC entry 5477 (class 1259 OID 872479)
-- Name: job_id_agb_farmer_advisory_2025_07_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_20 ON public.farmer_advisory_2025_07_20 USING btree (job_id);


--
-- TOC entry 5483 (class 1259 OID 872743)
-- Name: job_id_agb_farmer_advisory_2025_07_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_21 ON public.farmer_advisory_2025_07_21 USING btree (job_id);


--
-- TOC entry 5489 (class 1259 OID 983879)
-- Name: job_id_agb_farmer_advisory_2025_07_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_22 ON public.farmer_advisory_2025_07_22 USING btree (job_id);


--
-- TOC entry 5497 (class 1259 OID 1090494)
-- Name: job_id_agb_farmer_advisory_2025_07_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_23 ON public.farmer_advisory_2025_07_23 USING btree (job_id);


--
-- TOC entry 5503 (class 1259 OID 1090826)
-- Name: job_id_agb_farmer_advisory_2025_07_24; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_24 ON public.farmer_advisory_2025_07_24 USING btree (job_id);


--
-- TOC entry 5509 (class 1259 OID 1091130)
-- Name: job_id_agb_farmer_advisory_2025_07_25; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_25 ON public.farmer_advisory_2025_07_25 USING btree (job_id);


--
-- TOC entry 5515 (class 1259 OID 1134025)
-- Name: job_id_agb_farmer_advisory_2025_07_26; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_26 ON public.farmer_advisory_2025_07_26 USING btree (job_id);


--
-- TOC entry 5521 (class 1259 OID 1134303)
-- Name: job_id_agb_farmer_advisory_2025_07_27; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_27 ON public.farmer_advisory_2025_07_27 USING btree (job_id);


--
-- TOC entry 5527 (class 1259 OID 1134568)
-- Name: job_id_agb_farmer_advisory_2025_07_28; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_28 ON public.farmer_advisory_2025_07_28 USING btree (job_id);


--
-- TOC entry 5543 (class 1259 OID 1178060)
-- Name: job_id_agb_farmer_advisory_2025_07_29; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_29 ON public.farmer_advisory_2025_07_29 USING btree (job_id);


--
-- TOC entry 5549 (class 1259 OID 1560956)
-- Name: job_id_agb_farmer_advisory_2025_07_30; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_30 ON public.farmer_advisory_2025_07_30 USING btree (job_id);


--
-- TOC entry 5555 (class 1259 OID 1561545)
-- Name: job_id_agb_farmer_advisory_2025_07_31; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_07_31 ON public.farmer_advisory_2025_07_31 USING btree (job_id);


--
-- TOC entry 5561 (class 1259 OID 1561885)
-- Name: job_id_agb_farmer_advisory_2025_08_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_01 ON public.farmer_advisory_2025_08_01 USING btree (job_id);


--
-- TOC entry 5567 (class 1259 OID 1562212)
-- Name: job_id_agb_farmer_advisory_2025_08_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_02 ON public.farmer_advisory_2025_08_02 USING btree (job_id);


--
-- TOC entry 5573 (class 1259 OID 1562485)
-- Name: job_id_agb_farmer_advisory_2025_08_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_03 ON public.farmer_advisory_2025_08_03 USING btree (job_id);


--
-- TOC entry 5579 (class 1259 OID 1562814)
-- Name: job_id_agb_farmer_advisory_2025_08_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_04 ON public.farmer_advisory_2025_08_04 USING btree (job_id);


--
-- TOC entry 5585 (class 1259 OID 1563073)
-- Name: job_id_agb_farmer_advisory_2025_08_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_05 ON public.farmer_advisory_2025_08_05 USING btree (job_id);


--
-- TOC entry 5591 (class 1259 OID 1563424)
-- Name: job_id_agb_farmer_advisory_2025_08_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_06 ON public.farmer_advisory_2025_08_06 USING btree (job_id);


--
-- TOC entry 5597 (class 1259 OID 1563681)
-- Name: job_id_agb_farmer_advisory_2025_08_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_07 ON public.farmer_advisory_2025_08_07 USING btree (job_id);


--
-- TOC entry 5603 (class 1259 OID 1564015)
-- Name: job_id_agb_farmer_advisory_2025_08_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_08 ON public.farmer_advisory_2025_08_08 USING btree (job_id);


--
-- TOC entry 5629 (class 1259 OID 1564481)
-- Name: job_id_agb_farmer_advisory_2025_08_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_09 ON public.farmer_advisory_2025_08_09 USING btree (job_id);


--
-- TOC entry 5635 (class 1259 OID 1564785)
-- Name: job_id_agb_farmer_advisory_2025_08_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_10 ON public.farmer_advisory_2025_08_10 USING btree (job_id);


--
-- TOC entry 5641 (class 1259 OID 1565091)
-- Name: job_id_agb_farmer_advisory_2025_08_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_11 ON public.farmer_advisory_2025_08_11 USING btree (job_id);


--
-- TOC entry 5647 (class 1259 OID 1565400)
-- Name: job_id_agb_farmer_advisory_2025_08_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_12 ON public.farmer_advisory_2025_08_12 USING btree (job_id);


--
-- TOC entry 5653 (class 1259 OID 1565720)
-- Name: job_id_agb_farmer_advisory_2025_08_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_13 ON public.farmer_advisory_2025_08_13 USING btree (job_id);


--
-- TOC entry 5663 (class 1259 OID 1566277)
-- Name: job_id_agb_farmer_advisory_2025_08_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_14 ON public.farmer_advisory_2025_08_14 USING btree (job_id);


--
-- TOC entry 5679 (class 1259 OID 1566513)
-- Name: job_id_agb_farmer_advisory_2025_08_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_farmer_advisory_2025_08_15 ON public.farmer_advisory_2025_08_15 USING btree (job_id);


--
-- TOC entry 5530 (class 1259 OID 1177736)
-- Name: job_id_agb_product_advisory; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_id_agb_product_advisory ON public.product_advisory USING btree (job_id);


--
-- TOC entry 5418 (class 1259 OID 707682)
-- Name: location_id_agb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb ON public.farmer_advisory USING btree (location_id);


--
-- TOC entry 5345 (class 1259 OID 707493)
-- Name: location_id_agb_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_copy1 ON public.farmer_advisory_copy1 USING btree (location_id);


--
-- TOC entry 5424 (class 1259 OID 829284)
-- Name: location_id_agb_farmer_advisory_2025_07_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_11 ON public.farmer_advisory_2025_07_11 USING btree (location_id);


--
-- TOC entry 5430 (class 1259 OID 829360)
-- Name: location_id_agb_farmer_advisory_2025_07_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_12 ON public.farmer_advisory_2025_07_12 USING btree (location_id);


--
-- TOC entry 5436 (class 1259 OID 829636)
-- Name: location_id_agb_farmer_advisory_2025_07_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_13 ON public.farmer_advisory_2025_07_13 USING btree (location_id);


--
-- TOC entry 5442 (class 1259 OID 829912)
-- Name: location_id_agb_farmer_advisory_2025_07_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_14 ON public.farmer_advisory_2025_07_14 USING btree (location_id);


--
-- TOC entry 5448 (class 1259 OID 830202)
-- Name: location_id_agb_farmer_advisory_2025_07_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_15 ON public.farmer_advisory_2025_07_15 USING btree (location_id);


--
-- TOC entry 5454 (class 1259 OID 830518)
-- Name: location_id_agb_farmer_advisory_2025_07_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_16 ON public.farmer_advisory_2025_07_16 USING btree (location_id);


--
-- TOC entry 5460 (class 1259 OID 830857)
-- Name: location_id_agb_farmer_advisory_2025_07_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_17 ON public.farmer_advisory_2025_07_17 USING btree (location_id);


--
-- TOC entry 5466 (class 1259 OID 831161)
-- Name: location_id_agb_farmer_advisory_2025_07_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_18 ON public.farmer_advisory_2025_07_18 USING btree (location_id);


--
-- TOC entry 5472 (class 1259 OID 872176)
-- Name: location_id_agb_farmer_advisory_2025_07_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_19 ON public.farmer_advisory_2025_07_19 USING btree (location_id);


--
-- TOC entry 5478 (class 1259 OID 872480)
-- Name: location_id_agb_farmer_advisory_2025_07_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_20 ON public.farmer_advisory_2025_07_20 USING btree (location_id);


--
-- TOC entry 5484 (class 1259 OID 872748)
-- Name: location_id_agb_farmer_advisory_2025_07_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_21 ON public.farmer_advisory_2025_07_21 USING btree (location_id);


--
-- TOC entry 5490 (class 1259 OID 983880)
-- Name: location_id_agb_farmer_advisory_2025_07_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_22 ON public.farmer_advisory_2025_07_22 USING btree (location_id);


--
-- TOC entry 5498 (class 1259 OID 1090495)
-- Name: location_id_agb_farmer_advisory_2025_07_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_23 ON public.farmer_advisory_2025_07_23 USING btree (location_id);


--
-- TOC entry 5504 (class 1259 OID 1090827)
-- Name: location_id_agb_farmer_advisory_2025_07_24; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_24 ON public.farmer_advisory_2025_07_24 USING btree (location_id);


--
-- TOC entry 5510 (class 1259 OID 1091131)
-- Name: location_id_agb_farmer_advisory_2025_07_25; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_25 ON public.farmer_advisory_2025_07_25 USING btree (location_id);


--
-- TOC entry 5516 (class 1259 OID 1134026)
-- Name: location_id_agb_farmer_advisory_2025_07_26; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_26 ON public.farmer_advisory_2025_07_26 USING btree (location_id);


--
-- TOC entry 5522 (class 1259 OID 1134304)
-- Name: location_id_agb_farmer_advisory_2025_07_27; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_27 ON public.farmer_advisory_2025_07_27 USING btree (location_id);


--
-- TOC entry 5528 (class 1259 OID 1134569)
-- Name: location_id_agb_farmer_advisory_2025_07_28; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_28 ON public.farmer_advisory_2025_07_28 USING btree (location_id);


--
-- TOC entry 5544 (class 1259 OID 1178061)
-- Name: location_id_agb_farmer_advisory_2025_07_29; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_29 ON public.farmer_advisory_2025_07_29 USING btree (location_id);


--
-- TOC entry 5550 (class 1259 OID 1560960)
-- Name: location_id_agb_farmer_advisory_2025_07_30; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_30 ON public.farmer_advisory_2025_07_30 USING btree (location_id);


--
-- TOC entry 5556 (class 1259 OID 1561546)
-- Name: location_id_agb_farmer_advisory_2025_07_31; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_07_31 ON public.farmer_advisory_2025_07_31 USING btree (location_id);


--
-- TOC entry 5562 (class 1259 OID 1561886)
-- Name: location_id_agb_farmer_advisory_2025_08_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_01 ON public.farmer_advisory_2025_08_01 USING btree (location_id);


--
-- TOC entry 5568 (class 1259 OID 1562213)
-- Name: location_id_agb_farmer_advisory_2025_08_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_02 ON public.farmer_advisory_2025_08_02 USING btree (location_id);


--
-- TOC entry 5574 (class 1259 OID 1562487)
-- Name: location_id_agb_farmer_advisory_2025_08_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_03 ON public.farmer_advisory_2025_08_03 USING btree (location_id);


--
-- TOC entry 5580 (class 1259 OID 1562815)
-- Name: location_id_agb_farmer_advisory_2025_08_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_04 ON public.farmer_advisory_2025_08_04 USING btree (location_id);


--
-- TOC entry 5586 (class 1259 OID 1563074)
-- Name: location_id_agb_farmer_advisory_2025_08_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_05 ON public.farmer_advisory_2025_08_05 USING btree (location_id);


--
-- TOC entry 5592 (class 1259 OID 1563425)
-- Name: location_id_agb_farmer_advisory_2025_08_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_06 ON public.farmer_advisory_2025_08_06 USING btree (location_id);


--
-- TOC entry 5598 (class 1259 OID 1563685)
-- Name: location_id_agb_farmer_advisory_2025_08_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_07 ON public.farmer_advisory_2025_08_07 USING btree (location_id);


--
-- TOC entry 5604 (class 1259 OID 1564016)
-- Name: location_id_agb_farmer_advisory_2025_08_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_08 ON public.farmer_advisory_2025_08_08 USING btree (location_id);


--
-- TOC entry 5630 (class 1259 OID 1564482)
-- Name: location_id_agb_farmer_advisory_2025_08_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_09 ON public.farmer_advisory_2025_08_09 USING btree (location_id);


--
-- TOC entry 5636 (class 1259 OID 1564793)
-- Name: location_id_agb_farmer_advisory_2025_08_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_10 ON public.farmer_advisory_2025_08_10 USING btree (location_id);


--
-- TOC entry 5642 (class 1259 OID 1565092)
-- Name: location_id_agb_farmer_advisory_2025_08_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_11 ON public.farmer_advisory_2025_08_11 USING btree (location_id);


--
-- TOC entry 5648 (class 1259 OID 1565401)
-- Name: location_id_agb_farmer_advisory_2025_08_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_12 ON public.farmer_advisory_2025_08_12 USING btree (location_id);


--
-- TOC entry 5654 (class 1259 OID 1565721)
-- Name: location_id_agb_farmer_advisory_2025_08_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_13 ON public.farmer_advisory_2025_08_13 USING btree (location_id);


--
-- TOC entry 5664 (class 1259 OID 1566278)
-- Name: location_id_agb_farmer_advisory_2025_08_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_14 ON public.farmer_advisory_2025_08_14 USING btree (location_id);


--
-- TOC entry 5680 (class 1259 OID 1566514)
-- Name: location_id_agb_farmer_advisory_2025_08_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX location_id_agb_farmer_advisory_2025_08_15 ON public.farmer_advisory_2025_08_15 USING btree (location_id);


--
-- TOC entry 5376 (class 1259 OID 707494)
-- Name: one_default_translation_per_language; Type: INDEX; Schema: public; Owner: bkkdev_rw
--

CREATE UNIQUE INDEX one_default_translation_per_language ON public.sms_cta_translations USING btree (language_id) WHERE (is_default = true);


--
-- TOC entry 5281 (class 1259 OID 707495)
-- Name: one_default_translation_per_language_app_cta; Type: INDEX; Schema: public; Owner: bkkdev_rw
--

CREATE UNIQUE INDEX one_default_translation_per_language_app_cta ON public.app_cta_translations USING btree (language_id) WHERE (is_default = true);


--
-- TOC entry 5363 (class 1259 OID 707496)
-- Name: parameters_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX parameters_id_idx ON public.parameters USING btree (id);


--
-- TOC entry 5534 (class 1259 OID 1177841)
-- Name: product_advisory_jobs_advisory_id_create_dt_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX product_advisory_jobs_advisory_id_create_dt_idx1 ON public.product_advisory_jobs USING btree (shopify_product_advisory_id, create_dt);


--
-- TOC entry 5531 (class 1259 OID 1177734)
-- Name: product_advisory_msisdn_job_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX product_advisory_msisdn_job_id_idx ON public.product_advisory USING btree (msisdn, job_id);


--
-- TOC entry 5537 (class 1259 OID 1177839)
-- Name: product_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_created ON public.product_advisory_jobs USING btree (created);


--
-- TOC entry 5538 (class 1259 OID 1177840)
-- Name: product_job_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_job_type_idx ON public.product_advisory_jobs USING btree (job_type);


--
-- TOC entry 5389 (class 1259 OID 707497)
-- Name: sync_tables_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sync_tables_name_idx ON public.sync_tables USING btree (name);


--
-- TOC entry 5400 (class 1259 OID 707498)
-- Name: weather_condition_types_type_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX weather_condition_types_type_name_idx ON public.weather_condition_types USING btree (type_name);


--
-- TOC entry 5681 (class 2606 OID 707499)
-- Name: advisory advisory_action_time_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory
    ADD CONSTRAINT advisory_action_time_id_fkey FOREIGN KEY (action_time_id) REFERENCES public.time_periods(id) ON DELETE SET NULL;


--
-- TOC entry 5682 (class 2606 OID 707504)
-- Name: advisory advisory_app_cta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory
    ADD CONSTRAINT advisory_app_cta_id_fkey FOREIGN KEY (app_cta) REFERENCES public.app_cta(id) ON DELETE SET NULL;


--
-- TOC entry 5687 (class 2606 OID 707509)
-- Name: advisory_conditions advisory_conditions_advisory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_conditions
    ADD CONSTRAINT advisory_conditions_advisory_id_fkey FOREIGN KEY (advisory_id) REFERENCES public.advisory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5688 (class 2606 OID 707514)
-- Name: advisory_conditions advisory_conditions_range_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_conditions
    ADD CONSTRAINT advisory_conditions_range_type_fkey FOREIGN KEY (range_type) REFERENCES public.weather_condition_types(type_name) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- TOC entry 5683 (class 2606 OID 707519)
-- Name: advisory advisory_crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory
    ADD CONSTRAINT advisory_crop_calender_id_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5684 (class 2606 OID 707524)
-- Name: advisory advisory_farming_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory
    ADD CONSTRAINT advisory_farming_activity_id_fkey FOREIGN KEY (activity_type_id) REFERENCES public.farming_activity_types(id) ON DELETE SET NULL;


--
-- TOC entry 5689 (class 2606 OID 707529)
-- Name: advisory_feedback advisory_feedback_advisory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_feedback
    ADD CONSTRAINT advisory_feedback_advisory_id_fkey FOREIGN KEY (advisory_id) REFERENCES public.advisory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5685 (class 2606 OID 707534)
-- Name: advisory advisory_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory
    ADD CONSTRAINT advisory_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.advisory_groups(id) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- TOC entry 5690 (class 2606 OID 707539)
-- Name: advisory_groups advisory_groups_crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_groups
    ADD CONSTRAINT advisory_groups_crop_calender_id_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5691 (class 2606 OID 707544)
-- Name: advisory_growth_stages advisory_growth_stages_advisory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_growth_stages
    ADD CONSTRAINT advisory_growth_stages_advisory_id_fkey FOREIGN KEY (advisory_id) REFERENCES public.advisory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5692 (class 2606 OID 707549)
-- Name: advisory_locations advisory_locations_advisory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_locations
    ADD CONSTRAINT advisory_locations_advisory_id_fkey FOREIGN KEY (advisory_id) REFERENCES public.advisory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5693 (class 2606 OID 707554)
-- Name: advisory_products advisory_products_advisory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_products
    ADD CONSTRAINT advisory_products_advisory_id_fkey FOREIGN KEY (advisory_id) REFERENCES public.advisory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5686 (class 2606 OID 707559)
-- Name: advisory advisory_sms_cta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory
    ADD CONSTRAINT advisory_sms_cta_id_fkey FOREIGN KEY (sms_cta) REFERENCES public.sms_cta(id) ON DELETE SET NULL;


--
-- TOC entry 5695 (class 2606 OID 707564)
-- Name: advisory_soil_type advisory_soil_type_advisory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_soil_type
    ADD CONSTRAINT advisory_soil_type_advisory_id_fkey FOREIGN KEY (advisory_id) REFERENCES public.advisory(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5696 (class 2606 OID 707569)
-- Name: advisory_soil_type advisory_soil_type_soil_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_soil_type
    ADD CONSTRAINT advisory_soil_type_soil_type_id_fkey FOREIGN KEY (soil_type_id) REFERENCES public.soil_type_category(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5697 (class 2606 OID 707574)
-- Name: app_cta_translations app_cta_translations_app_cta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.app_cta_translations
    ADD CONSTRAINT app_cta_translations_app_cta_id_fkey FOREIGN KEY (app_cta_id) REFERENCES public.app_cta(id) ON DELETE CASCADE;


--
-- TOC entry 5715 (class 2606 OID 1566405)
-- Name: chemicals chemicals_chemical_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.chemicals
    ADD CONSTRAINT chemicals_chemical_type_id_fkey FOREIGN KEY (chemical_type_id) REFERENCES public.chemical_types(id) ON DELETE CASCADE;


--
-- TOC entry 5702 (class 2606 OID 707579)
-- Name: content_files content_files_folder_path_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_folder_path_fkey FOREIGN KEY (folder_path) REFERENCES public.content_folders(folder_path) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5703 (class 2606 OID 707584)
-- Name: crop_calender_assosiated_crops_livestocks crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.crop_calender_assosiated_crops_livestocks
    ADD CONSTRAINT crop_calender_id_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON DELETE CASCADE;


--
-- TOC entry 5704 (class 2606 OID 707589)
-- Name: crop_calender_languages crop_calender_languages_crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_languages
    ADD CONSTRAINT crop_calender_languages_crop_calender_id_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5698 (class 2606 OID 707594)
-- Name: crop_calender_locations crop_calender_locations_crop_calender_scheduler_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_locations
    ADD CONSTRAINT crop_calender_locations_crop_calender_scheduler_id_fkey FOREIGN KEY (crop_calender_scheduler_id) REFERENCES public.crop_calender_scheduler(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5694 (class 2606 OID 707599)
-- Name: crop_calender_scheduler crop_calender_scheduler_crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_scheduler
    ADD CONSTRAINT crop_calender_scheduler_crop_calender_id_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5705 (class 2606 OID 707604)
-- Name: crop_calender_scheduler_seed_types crop_calender_scheduler_seed_types_scheduler_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_scheduler_seed_types
    ADD CONSTRAINT crop_calender_scheduler_seed_types_scheduler_id_fkey FOREIGN KEY (scheduler_id) REFERENCES public.crop_calender_scheduler(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5700 (class 2606 OID 707609)
-- Name: crop_calender_sowing_window_schedule_locations crop_calender_sowing_window__crop_calender_sowing_window__fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_sowing_window_schedule_locations
    ADD CONSTRAINT crop_calender_sowing_window__crop_calender_sowing_window__fkey1 FOREIGN KEY (crop_calender_sowing_window_schedule_id) REFERENCES public.crop_calender_sowing_window_schedules(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5699 (class 2606 OID 707614)
-- Name: crop_calender_sowing_window crop_calender_sowing_window_crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.crop_calender_sowing_window
    ADD CONSTRAINT crop_calender_sowing_window_crop_calender_id_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5701 (class 2606 OID 707619)
-- Name: crop_calender_sowing_window_schedules crop_calender_sowing_window_s_crop_calender_sowing_window__fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_sowing_window_schedules
    ADD CONSTRAINT crop_calender_sowing_window_s_crop_calender_sowing_window__fkey FOREIGN KEY (crop_calender_sowing_window_id) REFERENCES public.crop_calender_sowing_window(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5706 (class 2606 OID 707624)
-- Name: crop_calender_stages crop_calender_stages_crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_stages
    ADD CONSTRAINT crop_calender_stages_crop_calender_id_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5707 (class 2606 OID 707629)
-- Name: crop_calender_stages_growth_stages crop_calender_stages_growth_stages_crop_calender_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_stages_growth_stages
    ADD CONSTRAINT crop_calender_stages_growth_stages_crop_calender_stage_id_fkey FOREIGN KEY (crop_calender_stage_id) REFERENCES public.crop_calender_stages(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5708 (class 2606 OID 707634)
-- Name: farmer_advisory_old farmer_advisory_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_advisory_old
    ADD CONSTRAINT farmer_advisory_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.agri_bank_advisory_jobs_old(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5716 (class 2606 OID 1566441)
-- Name: shopify_product_advisories fk_shopify_product_new; Type: FK CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.shopify_product_advisories
    ADD CONSTRAINT fk_shopify_product_new FOREIGN KEY (shopify_product_id) REFERENCES public.shopify_products(id) ON DELETE CASCADE;


--
-- TOC entry 5709 (class 2606 OID 707644)
-- Name: product_cc_requests product_cc_requests_advisory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_cc_requests
    ADD CONSTRAINT product_cc_requests_advisory_product_id_fkey FOREIGN KEY (advisory_product_id) REFERENCES public.advisory_products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5710 (class 2606 OID 707649)
-- Name: product_mappings product_mappings_advisory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_mappings
    ADD CONSTRAINT product_mappings_advisory_product_id_fkey FOREIGN KEY (advisory_product_id) REFERENCES public.advisory_products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5711 (class 2606 OID 707654)
-- Name: sms_cta_translations sms_cta_translations_sms_cta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: bkkdev_rw
--

ALTER TABLE ONLY public.sms_cta_translations
    ADD CONSTRAINT sms_cta_translations_sms_cta_id_fkey FOREIGN KEY (sms_cta_id) REFERENCES public.sms_cta(id) ON DELETE CASCADE;


--
-- TOC entry 5712 (class 2606 OID 707659)
-- Name: soil_type_parameters soil_type_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_type_parameters
    ADD CONSTRAINT soil_type_category_id_fkey FOREIGN KEY (soil_type_category_id) REFERENCES public.soil_type_category(id) ON DELETE CASCADE;


--
-- TOC entry 5714 (class 2606 OID 1566096)
-- Name: targeted_pests targeted_pests_pest_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.targeted_pests
    ADD CONSTRAINT targeted_pests_pest_category_id_fkey FOREIGN KEY (pest_category_id) REFERENCES public.pest_categories(id);


--
-- TOC entry 5713 (class 2606 OID 707664)
-- Name: layer layer_topology_id_fkey; Type: FK CONSTRAINT; Schema: topology; Owner: postgres
--

ALTER TABLE ONLY topology.layer
    ADD CONSTRAINT layer_topology_id_fkey FOREIGN KEY (topology_id) REFERENCES topology.topology(id);


--
-- TOC entry 5848 (class 0 OID 0)
-- Dependencies: 14
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT ALL ON SCHEMA public TO robiaqa_rw;
GRANT USAGE ON SCHEMA public TO haider_qa;


--
-- TOC entry 5850 (class 0 OID 0)
-- Dependencies: 13
-- Name: SCHEMA topology; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA topology TO haider_qa;


--
-- TOC entry 5857 (class 0 OID 0)
-- Dependencies: 209
-- Name: SEQUENCE abiotic_stress_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.abiotic_stress_id_seq TO bkkdev_rw;


--
-- TOC entry 5858 (class 0 OID 0)
-- Dependencies: 210
-- Name: SEQUENCE actions_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.actions_types_id_seq TO bkkdev_rw;


--
-- TOC entry 5859 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE active_product_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.active_product_locations TO haider_qa;


--
-- TOC entry 5860 (class 0 OID 0)
-- Dependencies: 212
-- Name: SEQUENCE active_subscriber_range_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.active_subscriber_range_id_seq TO bkkdev_rw;


--
-- TOC entry 5861 (class 0 OID 0)
-- Dependencies: 213
-- Name: SEQUENCE activity_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.activity_id_seq TO bkkdev_rw;


--
-- TOC entry 5862 (class 0 OID 0)
-- Dependencies: 214
-- Name: SEQUENCE activity_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.activity_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 5863 (class 0 OID 0)
-- Dependencies: 215
-- Name: SEQUENCE adoptive_menu_api_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_api_actions_id_seq TO bkkdev_rw;


--
-- TOC entry 5864 (class 0 OID 0)
-- Dependencies: 216
-- Name: SEQUENCE adoptive_menu_content_nodes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_content_nodes_id_seq TO bkkdev_rw;


--
-- TOC entry 5865 (class 0 OID 0)
-- Dependencies: 217
-- Name: SEQUENCE adoptive_menu_events_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_events_id_seq TO bkkdev_rw;


--
-- TOC entry 5866 (class 0 OID 0)
-- Dependencies: 218
-- Name: SEQUENCE adoptive_menu_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_files_id_seq TO bkkdev_rw;


--
-- TOC entry 5867 (class 0 OID 0)
-- Dependencies: 219
-- Name: SEQUENCE adoptive_menu_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_id_seq TO bkkdev_rw;


--
-- TOC entry 5868 (class 0 OID 0)
-- Dependencies: 220
-- Name: SEQUENCE adoptive_menu_recording_end_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_recording_end_files_id_seq TO bkkdev_rw;


--
-- TOC entry 5869 (class 0 OID 0)
-- Dependencies: 221
-- Name: SEQUENCE adoptive_menu_surveys_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_surveys_id_seq TO bkkdev_rw;


--
-- TOC entry 5870 (class 0 OID 0)
-- Dependencies: 222
-- Name: SEQUENCE adoptive_menu_trunk_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_trunk_actions_id_seq TO bkkdev_rw;


--
-- TOC entry 5871 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE adv_updated; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.adv_updated TO haider_qa;


--
-- TOC entry 5872 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE advisory; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.advisory TO haider_qa;


--
-- TOC entry 5873 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE advisory_conditions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.advisory_conditions TO haider_qa;


--
-- TOC entry 5874 (class 0 OID 0)
-- Dependencies: 226
-- Name: SEQUENCE advisory_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.advisory_crops_id_seq TO bkkdev_rw;


--
-- TOC entry 5875 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE advisory_feedback; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.advisory_feedback TO haider_qa;


--
-- TOC entry 5876 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE advisory_groups; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.advisory_groups TO haider_qa;


--
-- TOC entry 5877 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE advisory_growth_stages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.advisory_growth_stages TO haider_qa;


--
-- TOC entry 5879 (class 0 OID 0)
-- Dependencies: 230
-- Name: SEQUENCE advisory_growth_stages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.advisory_growth_stages_id_seq TO bkkdev_rw;


--
-- TOC entry 5880 (class 0 OID 0)
-- Dependencies: 231
-- Name: SEQUENCE advisory_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.advisory_id_seq TO bkkdev_rw;


--
-- TOC entry 5881 (class 0 OID 0)
-- Dependencies: 232
-- Name: SEQUENCE advisory_livestock_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.advisory_livestock_id_seq TO bkkdev_rw;


--
-- TOC entry 5882 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE advisory_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.advisory_locations TO haider_qa;


--
-- TOC entry 5883 (class 0 OID 0)
-- Dependencies: 234
-- Name: SEQUENCE advisory_locations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.advisory_locations_id_seq TO bkkdev_rw;


--
-- TOC entry 5884 (class 0 OID 0)
-- Dependencies: 235
-- Name: SEQUENCE advisory_machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.advisory_machineries_id_seq TO bkkdev_rw;


--
-- TOC entry 5885 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE advisory_products; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.advisory_products TO haider_qa;


--
-- TOC entry 5886 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE crop_calender_scheduler; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender_scheduler TO haider_qa;


--
-- TOC entry 5888 (class 0 OID 0)
-- Dependencies: 238
-- Name: SEQUENCE advisory_scheduler_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.advisory_scheduler_id_seq TO bkkdev_rw;


--
-- TOC entry 5889 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE advisory_soil_type; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.advisory_soil_type TO haider_qa;


--
-- TOC entry 5890 (class 0 OID 0)
-- Dependencies: 240
-- Name: SEQUENCE advisory_tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.advisory_tags_id_seq TO bkkdev_rw;


--
-- TOC entry 5891 (class 0 OID 0)
-- Dependencies: 241
-- Name: SEQUENCE agent_roles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.agent_roles_id_seq TO bkkdev_rw;


--
-- TOC entry 5892 (class 0 OID 0)
-- Dependencies: 242
-- Name: SEQUENCE agent_roles_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.agent_roles_id_seq1 TO bkkdev_rw;


--
-- TOC entry 5893 (class 0 OID 0)
-- Dependencies: 243
-- Name: SEQUENCE agents_activity_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.agents_activity_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 5894 (class 0 OID 0)
-- Dependencies: 244
-- Name: SEQUENCE agents_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.agents_id_seq TO bkkdev_rw;


--
-- TOC entry 5895 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE agri_bank_advisory_jobs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.agri_bank_advisory_jobs TO haider_qa;


--
-- TOC entry 5896 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE agri_bank_advisory_jobs_global; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.agri_bank_advisory_jobs_global TO haider_qa;


--
-- TOC entry 5897 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE agri_bank_advisory_jobs_old; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.agri_bank_advisory_jobs_old TO haider_qa;


--
-- TOC entry 5898 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE agri_bank_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.agri_bank_data TO haider_qa;


--
-- TOC entry 5899 (class 0 OID 0)
-- Dependencies: 249
-- Name: SEQUENCE api_call_details_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_call_details_id_seq TO bkkdev_rw;


--
-- TOC entry 5900 (class 0 OID 0)
-- Dependencies: 250
-- Name: SEQUENCE api_methods_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_methods_id_seq TO bkkdev_rw;


--
-- TOC entry 5901 (class 0 OID 0)
-- Dependencies: 251
-- Name: SEQUENCE api_permissions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_permissions_id_seq TO bkkdev_rw;


--
-- TOC entry 5902 (class 0 OID 0)
-- Dependencies: 252
-- Name: SEQUENCE api_resource_category_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_resource_category_id_seq TO bkkdev_rw;


--
-- TOC entry 5903 (class 0 OID 0)
-- Dependencies: 253
-- Name: SEQUENCE api_resource_permissions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_resource_permissions_id_seq TO bkkdev_rw;


--
-- TOC entry 5904 (class 0 OID 0)
-- Dependencies: 254
-- Name: SEQUENCE api_resource_roles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_resource_roles_id_seq TO bkkdev_rw;


--
-- TOC entry 5905 (class 0 OID 0)
-- Dependencies: 255
-- Name: SEQUENCE api_resources_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_resources_id_seq TO bkkdev_rw;


--
-- TOC entry 5906 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE app_cta; Type: ACL; Schema: public; Owner: bkkdev_rw
--

GRANT SELECT ON TABLE public.app_cta TO haider_qa;


--
-- TOC entry 5907 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE app_cta_translations; Type: ACL; Schema: public; Owner: bkkdev_rw
--

GRANT SELECT ON TABLE public.app_cta_translations TO haider_qa;


--
-- TOC entry 5908 (class 0 OID 0)
-- Dependencies: 258
-- Name: SEQUENCE application_docs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.application_docs_id_seq TO bkkdev_rw;


--
-- TOC entry 5909 (class 0 OID 0)
-- Dependencies: 259
-- Name: SEQUENCE application_status_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.application_status_id_seq TO bkkdev_rw;


--
-- TOC entry 5910 (class 0 OID 0)
-- Dependencies: 260
-- Name: SEQUENCE badges_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.badges_id_seq TO bkkdev_rw;


--
-- TOC entry 5911 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE barani_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.barani_locations TO haider_qa;


--
-- TOC entry 5912 (class 0 OID 0)
-- Dependencies: 267
-- Name: SEQUENCE blacklist_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.blacklist_id_seq TO bkkdev_rw;


--
-- TOC entry 5913 (class 0 OID 0)
-- Dependencies: 268
-- Name: SEQUENCE campaign_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_categories_id_seq TO bkkdev_rw;


--
-- TOC entry 5914 (class 0 OID 0)
-- Dependencies: 269
-- Name: SEQUENCE campaign_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_files_id_seq TO bkkdev_rw;


--
-- TOC entry 5915 (class 0 OID 0)
-- Dependencies: 270
-- Name: SEQUENCE campaign_profiles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_profiles_id_seq TO bkkdev_rw;


--
-- TOC entry 5916 (class 0 OID 0)
-- Dependencies: 271
-- Name: SEQUENCE campaign_promo_data_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_promo_data_id_seq TO bkkdev_rw;


--
-- TOC entry 5917 (class 0 OID 0)
-- Dependencies: 272
-- Name: SEQUENCE campaign_recording_end_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_recording_end_files_id_seq TO bkkdev_rw;


--
-- TOC entry 5918 (class 0 OID 0)
-- Dependencies: 273
-- Name: SEQUENCE campaign_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_types_id_seq TO bkkdev_rw;


--
-- TOC entry 5919 (class 0 OID 0)
-- Dependencies: 274
-- Name: SEQUENCE case_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.case_categories_id_seq TO bkkdev_rw;


--
-- TOC entry 5920 (class 0 OID 0)
-- Dependencies: 275
-- Name: SEQUENCE case_media_contents_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.case_media_contents_id_seq TO bkkdev_rw;


--
-- TOC entry 5921 (class 0 OID 0)
-- Dependencies: 276
-- Name: SEQUENCE case_parameters_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.case_parameters_id_seq TO bkkdev_rw;


--
-- TOC entry 5922 (class 0 OID 0)
-- Dependencies: 277
-- Name: SEQUENCE case_tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.case_tags_id_seq TO bkkdev_rw;


--
-- TOC entry 5923 (class 0 OID 0)
-- Dependencies: 278
-- Name: SEQUENCE cases_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.cases_id_seq TO bkkdev_rw;


--
-- TOC entry 5924 (class 0 OID 0)
-- Dependencies: 279
-- Name: SEQUENCE cdr_asterisk_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.cdr_asterisk_id_seq TO bkkdev_rw;


--
-- TOC entry 5925 (class 0 OID 0)
-- Dependencies: 280
-- Name: SEQUENCE clauses_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.clauses_id_seq TO bkkdev_rw;


--
-- TOC entry 5926 (class 0 OID 0)
-- Dependencies: 281
-- Name: TABLE content_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.content_files TO haider_qa;


--
-- TOC entry 5927 (class 0 OID 0)
-- Dependencies: 282
-- Name: SEQUENCE content_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.content_files_id_seq TO bkkdev_rw;


--
-- TOC entry 5929 (class 0 OID 0)
-- Dependencies: 283
-- Name: SEQUENCE content_files_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.content_files_id_seq1 TO bkkdev_rw;


--
-- TOC entry 5930 (class 0 OID 0)
-- Dependencies: 284
-- Name: TABLE content_folders; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.content_folders TO haider_qa;


--
-- TOC entry 5931 (class 0 OID 0)
-- Dependencies: 285
-- Name: SEQUENCE content_folders_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.content_folders_id_seq TO bkkdev_rw;


--
-- TOC entry 5933 (class 0 OID 0)
-- Dependencies: 286
-- Name: SEQUENCE content_folders_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.content_folders_id_seq1 TO bkkdev_rw;


--
-- TOC entry 5934 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE crop_calender; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender TO haider_qa;


--
-- TOC entry 5935 (class 0 OID 0)
-- Dependencies: 287
-- Name: SEQUENCE crop_calender_a_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_a_seq TO bkkdev_rw;


--
-- TOC entry 5936 (class 0 OID 0)
-- Dependencies: 288
-- Name: TABLE crop_calender_assosiated_crops_livestocks; Type: ACL; Schema: public; Owner: bkkdev_rw
--

GRANT SELECT ON TABLE public.crop_calender_assosiated_crops_livestocks TO haider_qa;


--
-- TOC entry 5937 (class 0 OID 0)
-- Dependencies: 289
-- Name: SEQUENCE crop_calender_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_crops_id_seq TO bkkdev_rw;


--
-- TOC entry 5938 (class 0 OID 0)
-- Dependencies: 290
-- Name: SEQUENCE crop_calender_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_id_seq TO bkkdev_rw;


--
-- TOC entry 5939 (class 0 OID 0)
-- Dependencies: 291
-- Name: TABLE crop_calender_languages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender_languages TO haider_qa;


--
-- TOC entry 5941 (class 0 OID 0)
-- Dependencies: 292
-- Name: SEQUENCE crop_calender_languages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_languages_id_seq TO bkkdev_rw;


--
-- TOC entry 5942 (class 0 OID 0)
-- Dependencies: 263
-- Name: TABLE crop_calender_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender_locations TO haider_qa;


--
-- TOC entry 5943 (class 0 OID 0)
-- Dependencies: 293
-- Name: SEQUENCE crop_calender_locations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_locations_id_seq TO bkkdev_rw;


--
-- TOC entry 5944 (class 0 OID 0)
-- Dependencies: 294
-- Name: TABLE crop_calender_scheduler_seed_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender_scheduler_seed_types TO haider_qa;


--
-- TOC entry 5946 (class 0 OID 0)
-- Dependencies: 295
-- Name: SEQUENCE crop_calender_seed_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_seed_types_id_seq TO bkkdev_rw;


--
-- TOC entry 5947 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE crop_calender_sowing_window; Type: ACL; Schema: public; Owner: bkkdev_rw
--

GRANT SELECT ON TABLE public.crop_calender_sowing_window TO haider_qa;


--
-- TOC entry 5948 (class 0 OID 0)
-- Dependencies: 265
-- Name: TABLE crop_calender_sowing_window_schedule_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender_sowing_window_schedule_locations TO haider_qa;


--
-- TOC entry 5949 (class 0 OID 0)
-- Dependencies: 266
-- Name: TABLE crop_calender_sowing_window_schedules; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender_sowing_window_schedules TO haider_qa;


--
-- TOC entry 5950 (class 0 OID 0)
-- Dependencies: 296
-- Name: TABLE crop_calender_stages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender_stages TO haider_qa;


--
-- TOC entry 5951 (class 0 OID 0)
-- Dependencies: 297
-- Name: TABLE crop_calender_stages_growth_stages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_calender_stages_growth_stages TO haider_qa;


--
-- TOC entry 5952 (class 0 OID 0)
-- Dependencies: 298
-- Name: SEQUENCE crop_calender_weather_favourable_conditions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_weather_favourable_conditions_id_seq TO bkkdev_rw;


--
-- TOC entry 5953 (class 0 OID 0)
-- Dependencies: 299
-- Name: SEQUENCE crop_calender_weather_unfavourable_conditions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_weather_unfavourable_conditions_id_seq TO bkkdev_rw;


--
-- TOC entry 5954 (class 0 OID 0)
-- Dependencies: 300
-- Name: SEQUENCE crop_diseases_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_diseases_id_seq TO bkkdev_rw;


--
-- TOC entry 5955 (class 0 OID 0)
-- Dependencies: 301
-- Name: SEQUENCE crop_growth_stages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_growth_stages_id_seq TO bkkdev_rw;


--
-- TOC entry 5956 (class 0 OID 0)
-- Dependencies: 302
-- Name: TABLE crop_variety_ml; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.crop_variety_ml TO haider_qa;


--
-- TOC entry 5957 (class 0 OID 0)
-- Dependencies: 303
-- Name: SEQUENCE crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crops_id_seq TO bkkdev_rw;


--
-- TOC entry 5958 (class 0 OID 0)
-- Dependencies: 304
-- Name: SEQUENCE crops_parameters_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crops_parameters_id_seq TO bkkdev_rw;


--
-- TOC entry 5959 (class 0 OID 0)
-- Dependencies: 651
-- Name: TABLE farmer_advisory; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory TO haider_qa;


--
-- TOC entry 5960 (class 0 OID 0)
-- Dependencies: 652
-- Name: TABLE farmer_advisory_2025_07_11; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_11 TO haider_qa;


--
-- TOC entry 5961 (class 0 OID 0)
-- Dependencies: 653
-- Name: TABLE farmer_advisory_2025_07_12; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_12 TO haider_qa;


--
-- TOC entry 5962 (class 0 OID 0)
-- Dependencies: 654
-- Name: TABLE farmer_advisory_2025_07_13; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_13 TO haider_qa;


--
-- TOC entry 5963 (class 0 OID 0)
-- Dependencies: 655
-- Name: TABLE farmer_advisory_2025_07_14; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_14 TO haider_qa;


--
-- TOC entry 5964 (class 0 OID 0)
-- Dependencies: 656
-- Name: TABLE farmer_advisory_2025_07_15; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_15 TO haider_qa;


--
-- TOC entry 5965 (class 0 OID 0)
-- Dependencies: 657
-- Name: TABLE farmer_advisory_2025_07_16; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_16 TO haider_qa;


--
-- TOC entry 5966 (class 0 OID 0)
-- Dependencies: 658
-- Name: TABLE farmer_advisory_2025_07_17; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_17 TO haider_qa;


--
-- TOC entry 5967 (class 0 OID 0)
-- Dependencies: 659
-- Name: TABLE farmer_advisory_2025_07_18; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_18 TO haider_qa;


--
-- TOC entry 5968 (class 0 OID 0)
-- Dependencies: 660
-- Name: TABLE farmer_advisory_2025_07_19; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_19 TO haider_qa;


--
-- TOC entry 5969 (class 0 OID 0)
-- Dependencies: 661
-- Name: TABLE farmer_advisory_2025_07_20; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_20 TO haider_qa;


--
-- TOC entry 5970 (class 0 OID 0)
-- Dependencies: 662
-- Name: TABLE farmer_advisory_2025_07_21; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_21 TO haider_qa;


--
-- TOC entry 5971 (class 0 OID 0)
-- Dependencies: 663
-- Name: TABLE farmer_advisory_2025_07_22; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_22 TO haider_qa;


--
-- TOC entry 5972 (class 0 OID 0)
-- Dependencies: 665
-- Name: TABLE farmer_advisory_2025_07_23; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_23 TO haider_qa;


--
-- TOC entry 5973 (class 0 OID 0)
-- Dependencies: 666
-- Name: TABLE farmer_advisory_2025_07_24; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_24 TO haider_qa;


--
-- TOC entry 5974 (class 0 OID 0)
-- Dependencies: 667
-- Name: TABLE farmer_advisory_2025_07_25; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_25 TO haider_qa;


--
-- TOC entry 5975 (class 0 OID 0)
-- Dependencies: 668
-- Name: TABLE farmer_advisory_2025_07_26; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_26 TO haider_qa;


--
-- TOC entry 5976 (class 0 OID 0)
-- Dependencies: 669
-- Name: TABLE farmer_advisory_2025_07_27; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_27 TO haider_qa;


--
-- TOC entry 5977 (class 0 OID 0)
-- Dependencies: 670
-- Name: TABLE farmer_advisory_2025_07_28; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_28 TO haider_qa;


--
-- TOC entry 5978 (class 0 OID 0)
-- Dependencies: 673
-- Name: TABLE farmer_advisory_2025_07_29; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_29 TO haider_qa;


--
-- TOC entry 5979 (class 0 OID 0)
-- Dependencies: 674
-- Name: TABLE farmer_advisory_2025_07_30; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_30 TO haider_qa;


--
-- TOC entry 5980 (class 0 OID 0)
-- Dependencies: 675
-- Name: TABLE farmer_advisory_2025_07_31; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_07_31 TO haider_qa;


--
-- TOC entry 5981 (class 0 OID 0)
-- Dependencies: 676
-- Name: TABLE farmer_advisory_2025_08_01; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_01 TO haider_qa;


--
-- TOC entry 5982 (class 0 OID 0)
-- Dependencies: 677
-- Name: TABLE farmer_advisory_2025_08_02; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_02 TO haider_qa;


--
-- TOC entry 5983 (class 0 OID 0)
-- Dependencies: 678
-- Name: TABLE farmer_advisory_2025_08_03; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_03 TO haider_qa;


--
-- TOC entry 5984 (class 0 OID 0)
-- Dependencies: 679
-- Name: TABLE farmer_advisory_2025_08_04; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_04 TO haider_qa;


--
-- TOC entry 5985 (class 0 OID 0)
-- Dependencies: 680
-- Name: TABLE farmer_advisory_2025_08_05; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_05 TO haider_qa;


--
-- TOC entry 5986 (class 0 OID 0)
-- Dependencies: 681
-- Name: TABLE farmer_advisory_2025_08_06; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_06 TO haider_qa;


--
-- TOC entry 5987 (class 0 OID 0)
-- Dependencies: 682
-- Name: TABLE farmer_advisory_2025_08_07; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_07 TO haider_qa;


--
-- TOC entry 5988 (class 0 OID 0)
-- Dependencies: 683
-- Name: TABLE farmer_advisory_2025_08_08; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_08 TO haider_qa;


--
-- TOC entry 5989 (class 0 OID 0)
-- Dependencies: 694
-- Name: TABLE farmer_advisory_2025_08_09; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_09 TO haider_qa;


--
-- TOC entry 5990 (class 0 OID 0)
-- Dependencies: 695
-- Name: TABLE farmer_advisory_2025_08_10; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_10 TO haider_qa;


--
-- TOC entry 5991 (class 0 OID 0)
-- Dependencies: 696
-- Name: TABLE farmer_advisory_2025_08_11; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_11 TO haider_qa;


--
-- TOC entry 5992 (class 0 OID 0)
-- Dependencies: 697
-- Name: TABLE farmer_advisory_2025_08_12; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_12 TO haider_qa;


--
-- TOC entry 5993 (class 0 OID 0)
-- Dependencies: 698
-- Name: TABLE farmer_advisory_2025_08_13; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_13 TO haider_qa;


--
-- TOC entry 5994 (class 0 OID 0)
-- Dependencies: 701
-- Name: TABLE farmer_advisory_2025_08_14; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_14 TO haider_qa;


--
-- TOC entry 5995 (class 0 OID 0)
-- Dependencies: 706
-- Name: TABLE farmer_advisory_2025_08_15; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_2025_08_15 TO haider_qa;


--
-- TOC entry 5996 (class 0 OID 0)
-- Dependencies: 305
-- Name: TABLE farmer_advisory_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_copy1 TO haider_qa;


--
-- TOC entry 5997 (class 0 OID 0)
-- Dependencies: 306
-- Name: TABLE farmer_advisory_global; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_global TO haider_qa;


--
-- TOC entry 5998 (class 0 OID 0)
-- Dependencies: 307
-- Name: TABLE farmer_advisory_old; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_old TO haider_qa;


--
-- TOC entry 5999 (class 0 OID 0)
-- Dependencies: 308
-- Name: TABLE farmer_advisory_stats; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_advisory_stats TO haider_qa;


--
-- TOC entry 6000 (class 0 OID 0)
-- Dependencies: 309
-- Name: SEQUENCE farmer_badge_recommendations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.farmer_badge_recommendations_id_seq TO bkkdev_rw;


--
-- TOC entry 6001 (class 0 OID 0)
-- Dependencies: 310
-- Name: TABLE farming_activity_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farming_activity_types TO haider_qa;


--
-- TOC entry 6002 (class 0 OID 0)
-- Dependencies: 311
-- Name: SEQUENCE field_visits_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.field_visits_id_seq TO bkkdev_rw;


--
-- TOC entry 6003 (class 0 OID 0)
-- Dependencies: 312
-- Name: SEQUENCE forum_hide_posts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_hide_posts_id_seq TO bkkdev_rw;


--
-- TOC entry 6004 (class 0 OID 0)
-- Dependencies: 313
-- Name: SEQUENCE forum_hide_users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_hide_users_id_seq TO bkkdev_rw;


--
-- TOC entry 6005 (class 0 OID 0)
-- Dependencies: 314
-- Name: SEQUENCE forum_media_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_media_id_seq TO bkkdev_rw;


--
-- TOC entry 6006 (class 0 OID 0)
-- Dependencies: 315
-- Name: SEQUENCE forum_posts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_posts_id_seq TO bkkdev_rw;


--
-- TOC entry 6007 (class 0 OID 0)
-- Dependencies: 316
-- Name: SEQUENCE forum_report_posts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_report_posts_id_seq TO bkkdev_rw;


--
-- TOC entry 6008 (class 0 OID 0)
-- Dependencies: 317
-- Name: SEQUENCE forum_report_reason_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_report_reason_actions_id_seq TO bkkdev_rw;


--
-- TOC entry 6009 (class 0 OID 0)
-- Dependencies: 318
-- Name: SEQUENCE forum_report_reasons_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_report_reasons_id_seq TO bkkdev_rw;


--
-- TOC entry 6010 (class 0 OID 0)
-- Dependencies: 319
-- Name: SEQUENCE forum_report_users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_report_users_id_seq TO bkkdev_rw;


--
-- TOC entry 6011 (class 0 OID 0)
-- Dependencies: 320
-- Name: SEQUENCE forum_user_agreements_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_user_agreements_id_seq TO bkkdev_rw;


--
-- TOC entry 6012 (class 0 OID 0)
-- Dependencies: 321
-- Name: SEQUENCE in_app_notifications_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.in_app_notifications_id_seq TO bkkdev_rw;


--
-- TOC entry 6013 (class 0 OID 0)
-- Dependencies: 322
-- Name: SEQUENCE incentive_transactions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.incentive_transactions_id_seq TO bkkdev_rw;


--
-- TOC entry 6014 (class 0 OID 0)
-- Dependencies: 323
-- Name: SEQUENCE incentive_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.incentive_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6015 (class 0 OID 0)
-- Dependencies: 324
-- Name: SEQUENCE irrigation_source_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.irrigation_source_id_seq TO bkkdev_rw;


--
-- TOC entry 6016 (class 0 OID 0)
-- Dependencies: 325
-- Name: SEQUENCE ivr_paths_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.ivr_paths_id_seq TO bkkdev_rw;


--
-- TOC entry 6017 (class 0 OID 0)
-- Dependencies: 326
-- Name: SEQUENCE ivr_sessions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.ivr_sessions_id_seq TO bkkdev_rw;


--
-- TOC entry 6018 (class 0 OID 0)
-- Dependencies: 327
-- Name: SEQUENCE job_12_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_12_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6019 (class 0 OID 0)
-- Dependencies: 328
-- Name: SEQUENCE job_19_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_19_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6020 (class 0 OID 0)
-- Dependencies: 329
-- Name: SEQUENCE job_1_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_1_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6021 (class 0 OID 0)
-- Dependencies: 330
-- Name: SEQUENCE job_20_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_20_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6022 (class 0 OID 0)
-- Dependencies: 331
-- Name: SEQUENCE job_21_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_21_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6023 (class 0 OID 0)
-- Dependencies: 332
-- Name: SEQUENCE job_22_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_22_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6024 (class 0 OID 0)
-- Dependencies: 333
-- Name: SEQUENCE job_25_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_25_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6025 (class 0 OID 0)
-- Dependencies: 334
-- Name: SEQUENCE job_27_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_27_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6026 (class 0 OID 0)
-- Dependencies: 335
-- Name: SEQUENCE job_28_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_28_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6027 (class 0 OID 0)
-- Dependencies: 336
-- Name: SEQUENCE job_31_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_31_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6028 (class 0 OID 0)
-- Dependencies: 337
-- Name: SEQUENCE job_32_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_32_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6029 (class 0 OID 0)
-- Dependencies: 338
-- Name: SEQUENCE job_335_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_335_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6030 (class 0 OID 0)
-- Dependencies: 339
-- Name: SEQUENCE job_336_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_336_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6031 (class 0 OID 0)
-- Dependencies: 340
-- Name: SEQUENCE job_337_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_337_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6032 (class 0 OID 0)
-- Dependencies: 341
-- Name: SEQUENCE job_338_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_338_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6033 (class 0 OID 0)
-- Dependencies: 342
-- Name: SEQUENCE job_33_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_33_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6034 (class 0 OID 0)
-- Dependencies: 343
-- Name: SEQUENCE job_34_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_34_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6035 (class 0 OID 0)
-- Dependencies: 344
-- Name: SEQUENCE job_353_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_353_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6036 (class 0 OID 0)
-- Dependencies: 345
-- Name: SEQUENCE job_354_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_354_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6037 (class 0 OID 0)
-- Dependencies: 346
-- Name: SEQUENCE job_356_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_356_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6038 (class 0 OID 0)
-- Dependencies: 347
-- Name: SEQUENCE job_357_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_357_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6039 (class 0 OID 0)
-- Dependencies: 348
-- Name: SEQUENCE job_358_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_358_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6040 (class 0 OID 0)
-- Dependencies: 349
-- Name: SEQUENCE job_359_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_359_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6041 (class 0 OID 0)
-- Dependencies: 350
-- Name: SEQUENCE job_35_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_35_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6042 (class 0 OID 0)
-- Dependencies: 351
-- Name: SEQUENCE job_365_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_365_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6043 (class 0 OID 0)
-- Dependencies: 352
-- Name: SEQUENCE job_366_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_366_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6044 (class 0 OID 0)
-- Dependencies: 353
-- Name: SEQUENCE job_367_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_367_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6045 (class 0 OID 0)
-- Dependencies: 354
-- Name: SEQUENCE job_368_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_368_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6046 (class 0 OID 0)
-- Dependencies: 355
-- Name: SEQUENCE job_369_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_369_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6047 (class 0 OID 0)
-- Dependencies: 356
-- Name: SEQUENCE job_36_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_36_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6048 (class 0 OID 0)
-- Dependencies: 357
-- Name: SEQUENCE job_370_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_370_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6049 (class 0 OID 0)
-- Dependencies: 358
-- Name: SEQUENCE job_371_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_371_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6050 (class 0 OID 0)
-- Dependencies: 359
-- Name: SEQUENCE job_372_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_372_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6051 (class 0 OID 0)
-- Dependencies: 360
-- Name: SEQUENCE job_373_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_373_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6052 (class 0 OID 0)
-- Dependencies: 361
-- Name: SEQUENCE job_374_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_374_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6053 (class 0 OID 0)
-- Dependencies: 362
-- Name: SEQUENCE job_375_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_375_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6054 (class 0 OID 0)
-- Dependencies: 363
-- Name: SEQUENCE job_376_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_376_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6055 (class 0 OID 0)
-- Dependencies: 364
-- Name: SEQUENCE job_377_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_377_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6056 (class 0 OID 0)
-- Dependencies: 365
-- Name: SEQUENCE job_378_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_378_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6057 (class 0 OID 0)
-- Dependencies: 366
-- Name: SEQUENCE job_379_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_379_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6058 (class 0 OID 0)
-- Dependencies: 367
-- Name: SEQUENCE job_37_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_37_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6059 (class 0 OID 0)
-- Dependencies: 368
-- Name: SEQUENCE job_380_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_380_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6060 (class 0 OID 0)
-- Dependencies: 369
-- Name: SEQUENCE job_381_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_381_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6061 (class 0 OID 0)
-- Dependencies: 370
-- Name: SEQUENCE job_382_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_382_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6062 (class 0 OID 0)
-- Dependencies: 371
-- Name: SEQUENCE job_383_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_383_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6063 (class 0 OID 0)
-- Dependencies: 372
-- Name: SEQUENCE job_384_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_384_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6064 (class 0 OID 0)
-- Dependencies: 373
-- Name: SEQUENCE job_386_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_386_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6065 (class 0 OID 0)
-- Dependencies: 374
-- Name: SEQUENCE job_387_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_387_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6066 (class 0 OID 0)
-- Dependencies: 375
-- Name: SEQUENCE job_389_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_389_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6067 (class 0 OID 0)
-- Dependencies: 376
-- Name: SEQUENCE job_38_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_38_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6068 (class 0 OID 0)
-- Dependencies: 377
-- Name: SEQUENCE job_390_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_390_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6069 (class 0 OID 0)
-- Dependencies: 378
-- Name: SEQUENCE job_391_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_391_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6070 (class 0 OID 0)
-- Dependencies: 379
-- Name: SEQUENCE job_392_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_392_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6071 (class 0 OID 0)
-- Dependencies: 380
-- Name: SEQUENCE job_393_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_393_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6072 (class 0 OID 0)
-- Dependencies: 381
-- Name: SEQUENCE job_394_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_394_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6073 (class 0 OID 0)
-- Dependencies: 382
-- Name: SEQUENCE job_395_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_395_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6074 (class 0 OID 0)
-- Dependencies: 383
-- Name: SEQUENCE job_396_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_396_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6075 (class 0 OID 0)
-- Dependencies: 384
-- Name: SEQUENCE job_397_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_397_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6076 (class 0 OID 0)
-- Dependencies: 385
-- Name: SEQUENCE job_398_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_398_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6077 (class 0 OID 0)
-- Dependencies: 386
-- Name: SEQUENCE job_399_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_399_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6078 (class 0 OID 0)
-- Dependencies: 387
-- Name: SEQUENCE job_39_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_39_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6079 (class 0 OID 0)
-- Dependencies: 388
-- Name: SEQUENCE job_400_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_400_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6080 (class 0 OID 0)
-- Dependencies: 389
-- Name: SEQUENCE job_401_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_401_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6081 (class 0 OID 0)
-- Dependencies: 390
-- Name: SEQUENCE job_402_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_402_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6082 (class 0 OID 0)
-- Dependencies: 391
-- Name: SEQUENCE job_403_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_403_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6083 (class 0 OID 0)
-- Dependencies: 392
-- Name: SEQUENCE job_404_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_404_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6084 (class 0 OID 0)
-- Dependencies: 393
-- Name: SEQUENCE job_405_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_405_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6085 (class 0 OID 0)
-- Dependencies: 394
-- Name: SEQUENCE job_406_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_406_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6086 (class 0 OID 0)
-- Dependencies: 395
-- Name: SEQUENCE job_407_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_407_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6087 (class 0 OID 0)
-- Dependencies: 396
-- Name: SEQUENCE job_408_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_408_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6088 (class 0 OID 0)
-- Dependencies: 397
-- Name: SEQUENCE job_409_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_409_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6089 (class 0 OID 0)
-- Dependencies: 398
-- Name: SEQUENCE job_40_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_40_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6090 (class 0 OID 0)
-- Dependencies: 399
-- Name: SEQUENCE job_410_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_410_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6091 (class 0 OID 0)
-- Dependencies: 400
-- Name: SEQUENCE job_411_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_411_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6092 (class 0 OID 0)
-- Dependencies: 401
-- Name: SEQUENCE job_412_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_412_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6093 (class 0 OID 0)
-- Dependencies: 402
-- Name: SEQUENCE job_413_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_413_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6094 (class 0 OID 0)
-- Dependencies: 403
-- Name: SEQUENCE job_414_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_414_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6095 (class 0 OID 0)
-- Dependencies: 404
-- Name: SEQUENCE job_415_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_415_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6096 (class 0 OID 0)
-- Dependencies: 405
-- Name: SEQUENCE job_416_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_416_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6097 (class 0 OID 0)
-- Dependencies: 406
-- Name: SEQUENCE job_417_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_417_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6098 (class 0 OID 0)
-- Dependencies: 407
-- Name: SEQUENCE job_418_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_418_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6099 (class 0 OID 0)
-- Dependencies: 408
-- Name: SEQUENCE job_419_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_419_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6100 (class 0 OID 0)
-- Dependencies: 409
-- Name: SEQUENCE job_41_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_41_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6101 (class 0 OID 0)
-- Dependencies: 410
-- Name: SEQUENCE job_420_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_420_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6102 (class 0 OID 0)
-- Dependencies: 411
-- Name: SEQUENCE job_421_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_421_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6103 (class 0 OID 0)
-- Dependencies: 412
-- Name: SEQUENCE job_422_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_422_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6104 (class 0 OID 0)
-- Dependencies: 413
-- Name: SEQUENCE job_423_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_423_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6105 (class 0 OID 0)
-- Dependencies: 414
-- Name: SEQUENCE job_424_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_424_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6106 (class 0 OID 0)
-- Dependencies: 415
-- Name: SEQUENCE job_425_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_425_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6107 (class 0 OID 0)
-- Dependencies: 416
-- Name: SEQUENCE job_426_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_426_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6108 (class 0 OID 0)
-- Dependencies: 417
-- Name: SEQUENCE job_427_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_427_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6109 (class 0 OID 0)
-- Dependencies: 418
-- Name: SEQUENCE job_428_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_428_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6110 (class 0 OID 0)
-- Dependencies: 419
-- Name: SEQUENCE job_429_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_429_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6111 (class 0 OID 0)
-- Dependencies: 420
-- Name: SEQUENCE job_430_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_430_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6112 (class 0 OID 0)
-- Dependencies: 421
-- Name: SEQUENCE job_431_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_431_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6113 (class 0 OID 0)
-- Dependencies: 422
-- Name: SEQUENCE job_432_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_432_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6114 (class 0 OID 0)
-- Dependencies: 423
-- Name: SEQUENCE job_433_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_433_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6115 (class 0 OID 0)
-- Dependencies: 424
-- Name: SEQUENCE job_435_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_435_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6116 (class 0 OID 0)
-- Dependencies: 425
-- Name: SEQUENCE job_436_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_436_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6117 (class 0 OID 0)
-- Dependencies: 426
-- Name: SEQUENCE job_437_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_437_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6118 (class 0 OID 0)
-- Dependencies: 427
-- Name: SEQUENCE job_438_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_438_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6119 (class 0 OID 0)
-- Dependencies: 428
-- Name: SEQUENCE job_439_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_439_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6120 (class 0 OID 0)
-- Dependencies: 429
-- Name: SEQUENCE job_43_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_43_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6121 (class 0 OID 0)
-- Dependencies: 430
-- Name: SEQUENCE job_440_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_440_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6122 (class 0 OID 0)
-- Dependencies: 431
-- Name: SEQUENCE job_441_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_441_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6123 (class 0 OID 0)
-- Dependencies: 432
-- Name: SEQUENCE job_442_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_442_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6124 (class 0 OID 0)
-- Dependencies: 433
-- Name: SEQUENCE job_443_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_443_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6125 (class 0 OID 0)
-- Dependencies: 434
-- Name: SEQUENCE job_444_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_444_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6126 (class 0 OID 0)
-- Dependencies: 435
-- Name: SEQUENCE job_445_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_445_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6127 (class 0 OID 0)
-- Dependencies: 436
-- Name: SEQUENCE job_447_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_447_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6128 (class 0 OID 0)
-- Dependencies: 437
-- Name: SEQUENCE job_448_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_448_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6129 (class 0 OID 0)
-- Dependencies: 438
-- Name: SEQUENCE job_449_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_449_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6130 (class 0 OID 0)
-- Dependencies: 439
-- Name: SEQUENCE job_44_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_44_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6131 (class 0 OID 0)
-- Dependencies: 440
-- Name: SEQUENCE job_450_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_450_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6132 (class 0 OID 0)
-- Dependencies: 441
-- Name: SEQUENCE job_451_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_451_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6133 (class 0 OID 0)
-- Dependencies: 442
-- Name: SEQUENCE job_452_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_452_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6134 (class 0 OID 0)
-- Dependencies: 443
-- Name: SEQUENCE job_453_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_453_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6135 (class 0 OID 0)
-- Dependencies: 444
-- Name: SEQUENCE job_454_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_454_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6136 (class 0 OID 0)
-- Dependencies: 445
-- Name: SEQUENCE job_455_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_455_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6137 (class 0 OID 0)
-- Dependencies: 446
-- Name: SEQUENCE job_456_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_456_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6138 (class 0 OID 0)
-- Dependencies: 447
-- Name: SEQUENCE job_457_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_457_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6139 (class 0 OID 0)
-- Dependencies: 448
-- Name: SEQUENCE job_458_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_458_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6140 (class 0 OID 0)
-- Dependencies: 449
-- Name: SEQUENCE job_459_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_459_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6141 (class 0 OID 0)
-- Dependencies: 450
-- Name: SEQUENCE job_460_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_460_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6142 (class 0 OID 0)
-- Dependencies: 451
-- Name: SEQUENCE job_461_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_461_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6143 (class 0 OID 0)
-- Dependencies: 452
-- Name: SEQUENCE job_462_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_462_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6144 (class 0 OID 0)
-- Dependencies: 453
-- Name: SEQUENCE job_463_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_463_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6145 (class 0 OID 0)
-- Dependencies: 454
-- Name: SEQUENCE job_464_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_464_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6146 (class 0 OID 0)
-- Dependencies: 455
-- Name: SEQUENCE job_465_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_465_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6147 (class 0 OID 0)
-- Dependencies: 456
-- Name: SEQUENCE job_474_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_474_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6148 (class 0 OID 0)
-- Dependencies: 457
-- Name: SEQUENCE job_476_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_476_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6149 (class 0 OID 0)
-- Dependencies: 458
-- Name: SEQUENCE job_477_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_477_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6150 (class 0 OID 0)
-- Dependencies: 459
-- Name: SEQUENCE job_478_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_478_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6151 (class 0 OID 0)
-- Dependencies: 460
-- Name: SEQUENCE job_479_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_479_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6152 (class 0 OID 0)
-- Dependencies: 461
-- Name: SEQUENCE job_480_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_480_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6153 (class 0 OID 0)
-- Dependencies: 462
-- Name: SEQUENCE job_481_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_481_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6154 (class 0 OID 0)
-- Dependencies: 463
-- Name: SEQUENCE job_482_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_482_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6155 (class 0 OID 0)
-- Dependencies: 464
-- Name: SEQUENCE job_483_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_483_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6156 (class 0 OID 0)
-- Dependencies: 465
-- Name: SEQUENCE job_484_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_484_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6157 (class 0 OID 0)
-- Dependencies: 466
-- Name: SEQUENCE job_485_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_485_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6158 (class 0 OID 0)
-- Dependencies: 467
-- Name: SEQUENCE job_486_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_486_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6159 (class 0 OID 0)
-- Dependencies: 468
-- Name: SEQUENCE job_487_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_487_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6160 (class 0 OID 0)
-- Dependencies: 469
-- Name: SEQUENCE job_488_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_488_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6161 (class 0 OID 0)
-- Dependencies: 470
-- Name: SEQUENCE job_489_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_489_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6162 (class 0 OID 0)
-- Dependencies: 471
-- Name: SEQUENCE job_490_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_490_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6163 (class 0 OID 0)
-- Dependencies: 472
-- Name: SEQUENCE job_491_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_491_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6164 (class 0 OID 0)
-- Dependencies: 473
-- Name: SEQUENCE job_492_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_492_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6165 (class 0 OID 0)
-- Dependencies: 474
-- Name: SEQUENCE job_493_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_493_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6166 (class 0 OID 0)
-- Dependencies: 475
-- Name: SEQUENCE job_494_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_494_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6167 (class 0 OID 0)
-- Dependencies: 476
-- Name: SEQUENCE job_495_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_495_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6168 (class 0 OID 0)
-- Dependencies: 477
-- Name: SEQUENCE job_496_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_496_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6169 (class 0 OID 0)
-- Dependencies: 478
-- Name: SEQUENCE job_497_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_497_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6170 (class 0 OID 0)
-- Dependencies: 479
-- Name: SEQUENCE job_498_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_498_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6171 (class 0 OID 0)
-- Dependencies: 480
-- Name: SEQUENCE job_499_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_499_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6172 (class 0 OID 0)
-- Dependencies: 481
-- Name: SEQUENCE job_500_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_500_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6173 (class 0 OID 0)
-- Dependencies: 482
-- Name: SEQUENCE job_503_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_503_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6174 (class 0 OID 0)
-- Dependencies: 483
-- Name: SEQUENCE job_504_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_504_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6175 (class 0 OID 0)
-- Dependencies: 484
-- Name: SEQUENCE job_505_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_505_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6176 (class 0 OID 0)
-- Dependencies: 485
-- Name: SEQUENCE job_509_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_509_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6177 (class 0 OID 0)
-- Dependencies: 486
-- Name: SEQUENCE job_511_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_511_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6178 (class 0 OID 0)
-- Dependencies: 487
-- Name: SEQUENCE job_513_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_513_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6179 (class 0 OID 0)
-- Dependencies: 488
-- Name: SEQUENCE job_514_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_514_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6180 (class 0 OID 0)
-- Dependencies: 489
-- Name: SEQUENCE job_515_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_515_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6181 (class 0 OID 0)
-- Dependencies: 490
-- Name: SEQUENCE job_517_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_517_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6182 (class 0 OID 0)
-- Dependencies: 491
-- Name: SEQUENCE job_518_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_518_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6183 (class 0 OID 0)
-- Dependencies: 492
-- Name: SEQUENCE job_519_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_519_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6184 (class 0 OID 0)
-- Dependencies: 493
-- Name: SEQUENCE job_520_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_520_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6185 (class 0 OID 0)
-- Dependencies: 494
-- Name: SEQUENCE job_521_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_521_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6186 (class 0 OID 0)
-- Dependencies: 495
-- Name: SEQUENCE job_525_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_525_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6187 (class 0 OID 0)
-- Dependencies: 496
-- Name: SEQUENCE job_526_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_526_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6188 (class 0 OID 0)
-- Dependencies: 497
-- Name: SEQUENCE job_527_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_527_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6189 (class 0 OID 0)
-- Dependencies: 498
-- Name: SEQUENCE job_executor_stats_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_executor_stats_id_seq TO bkkdev_rw;


--
-- TOC entry 6190 (class 0 OID 0)
-- Dependencies: 499
-- Name: SEQUENCE job_operators_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_operators_id_seq TO bkkdev_rw;


--
-- TOC entry 6191 (class 0 OID 0)
-- Dependencies: 500
-- Name: SEQUENCE job_statuses_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_statuses_id_seq TO bkkdev_rw;


--
-- TOC entry 6192 (class 0 OID 0)
-- Dependencies: 501
-- Name: SEQUENCE job_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6193 (class 0 OID 0)
-- Dependencies: 502
-- Name: SEQUENCE jobs_v2_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.jobs_v2_id_seq TO bkkdev_rw;


--
-- TOC entry 6194 (class 0 OID 0)
-- Dependencies: 503
-- Name: SEQUENCE land_topography_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.land_topography_id_seq TO bkkdev_rw;


--
-- TOC entry 6195 (class 0 OID 0)
-- Dependencies: 504
-- Name: SEQUENCE languages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.languages_id_seq TO bkkdev_rw;


--
-- TOC entry 6196 (class 0 OID 0)
-- Dependencies: 505
-- Name: SEQUENCE livestock_breeds__id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_breeds__id_seq TO bkkdev_rw;


--
-- TOC entry 6197 (class 0 OID 0)
-- Dependencies: 506
-- Name: SEQUENCE livestock_disease_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_disease_id_seq TO bkkdev_rw;


--
-- TOC entry 6198 (class 0 OID 0)
-- Dependencies: 507
-- Name: SEQUENCE livestock_farming_category_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_farming_category_id_seq TO bkkdev_rw;


--
-- TOC entry 6199 (class 0 OID 0)
-- Dependencies: 508
-- Name: SEQUENCE livestock_management_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_management_id_seq TO bkkdev_rw;


--
-- TOC entry 6200 (class 0 OID 0)
-- Dependencies: 509
-- Name: SEQUENCE livestock_nutrition_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_nutrition_id_seq TO bkkdev_rw;


--
-- TOC entry 6201 (class 0 OID 0)
-- Dependencies: 510
-- Name: SEQUENCE livestock_purpose_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_purpose_id_seq TO bkkdev_rw;


--
-- TOC entry 6202 (class 0 OID 0)
-- Dependencies: 511
-- Name: SEQUENCE livestock_stage_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_stage_id_seq TO bkkdev_rw;


--
-- TOC entry 6203 (class 0 OID 0)
-- Dependencies: 512
-- Name: SEQUENCE livestock_tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_tags_id_seq TO bkkdev_rw;


--
-- TOC entry 6204 (class 0 OID 0)
-- Dependencies: 513
-- Name: SEQUENCE livestocks_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestocks_id_seq TO bkkdev_rw;


--
-- TOC entry 6205 (class 0 OID 0)
-- Dependencies: 514
-- Name: SEQUENCE loan_agreement_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_agreement_id_seq TO bkkdev_rw;


--
-- TOC entry 6206 (class 0 OID 0)
-- Dependencies: 515
-- Name: SEQUENCE loan_application_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_application_id_seq TO bkkdev_rw;


--
-- TOC entry 6207 (class 0 OID 0)
-- Dependencies: 516
-- Name: SEQUENCE loan_partners_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_partners_id_seq TO bkkdev_rw;


--
-- TOC entry 6208 (class 0 OID 0)
-- Dependencies: 517
-- Name: SEQUENCE loan_payment_modes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_payment_modes_id_seq TO bkkdev_rw;


--
-- TOC entry 6209 (class 0 OID 0)
-- Dependencies: 518
-- Name: SEQUENCE loan_procurement_attachments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_procurement_attachments_id_seq TO bkkdev_rw;


--
-- TOC entry 6210 (class 0 OID 0)
-- Dependencies: 519
-- Name: SEQUENCE loan_procurements_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_procurements_id_seq TO bkkdev_rw;


--
-- TOC entry 6211 (class 0 OID 0)
-- Dependencies: 520
-- Name: SEQUENCE loan_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6212 (class 0 OID 0)
-- Dependencies: 521
-- Name: SEQUENCE location_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.location_crops_id_seq TO bkkdev_rw;


--
-- TOC entry 6213 (class 0 OID 0)
-- Dependencies: 522
-- Name: SEQUENCE location_livestocks_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.location_livestocks_id_seq TO bkkdev_rw;


--
-- TOC entry 6214 (class 0 OID 0)
-- Dependencies: 523
-- Name: SEQUENCE location_machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.location_machineries_id_seq TO bkkdev_rw;


--
-- TOC entry 6215 (class 0 OID 0)
-- Dependencies: 524
-- Name: TABLE location_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.location_users TO haider_qa;


--
-- TOC entry 6216 (class 0 OID 0)
-- Dependencies: 525
-- Name: TABLE location_users_global; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.location_users_global TO haider_qa;


--
-- TOC entry 6217 (class 0 OID 0)
-- Dependencies: 526
-- Name: SEQUENCE location_v2_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.location_v2_id_seq TO bkkdev_rw;


--
-- TOC entry 6218 (class 0 OID 0)
-- Dependencies: 527
-- Name: SEQUENCE machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.machineries_id_seq TO bkkdev_rw;


--
-- TOC entry 6219 (class 0 OID 0)
-- Dependencies: 528
-- Name: SEQUENCE machinery_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.machinery_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6220 (class 0 OID 0)
-- Dependencies: 529
-- Name: SEQUENCE mandi_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_categories_id_seq TO bkkdev_rw;


--
-- TOC entry 6221 (class 0 OID 0)
-- Dependencies: 530
-- Name: SEQUENCE mandi_listing_images_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_listing_images_id_seq TO bkkdev_rw;


--
-- TOC entry 6222 (class 0 OID 0)
-- Dependencies: 531
-- Name: SEQUENCE mandi_listing_tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_listing_tags_id_seq TO bkkdev_rw;


--
-- TOC entry 6223 (class 0 OID 0)
-- Dependencies: 532
-- Name: SEQUENCE mandi_listings_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_listings_id_seq TO bkkdev_rw;


--
-- TOC entry 6224 (class 0 OID 0)
-- Dependencies: 533
-- Name: SEQUENCE mandi_listings_meta_data_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_listings_meta_data_id_seq TO bkkdev_rw;


--
-- TOC entry 6225 (class 0 OID 0)
-- Dependencies: 534
-- Name: SEQUENCE mandi_reviews_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_reviews_id_seq TO bkkdev_rw;


--
-- TOC entry 6226 (class 0 OID 0)
-- Dependencies: 535
-- Name: SEQUENCE menu_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_crops_id_seq TO bkkdev_rw;


--
-- TOC entry 6227 (class 0 OID 0)
-- Dependencies: 536
-- Name: SEQUENCE menu_languages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_languages_id_seq TO bkkdev_rw;


--
-- TOC entry 6228 (class 0 OID 0)
-- Dependencies: 537
-- Name: SEQUENCE menu_livestocks_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_livestocks_id_seq TO bkkdev_rw;


--
-- TOC entry 6229 (class 0 OID 0)
-- Dependencies: 538
-- Name: SEQUENCE menu_locations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_locations_id_seq TO bkkdev_rw;


--
-- TOC entry 6230 (class 0 OID 0)
-- Dependencies: 539
-- Name: SEQUENCE menu_machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_machineries_id_seq TO bkkdev_rw;


--
-- TOC entry 6231 (class 0 OID 0)
-- Dependencies: 540
-- Name: SEQUENCE mo_sms_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mo_sms_id_seq TO bkkdev_rw;


--
-- TOC entry 6232 (class 0 OID 0)
-- Dependencies: 541
-- Name: SEQUENCE mp_crop_crop_diseases_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mp_crop_crop_diseases_id_seq TO bkkdev_rw;


--
-- TOC entry 6233 (class 0 OID 0)
-- Dependencies: 542
-- Name: SEQUENCE mp_livestock_disease_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mp_livestock_disease_id_seq TO bkkdev_rw;


--
-- TOC entry 6234 (class 0 OID 0)
-- Dependencies: 543
-- Name: SEQUENCE mp_livestock_farming_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mp_livestock_farming_categories_id_seq TO bkkdev_rw;


--
-- TOC entry 6235 (class 0 OID 0)
-- Dependencies: 544
-- Name: SEQUENCE narrative_list_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.narrative_list_id_seq TO bkkdev_rw;


--
-- TOC entry 6236 (class 0 OID 0)
-- Dependencies: 545
-- Name: SEQUENCE network_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.network_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6237 (class 0 OID 0)
-- Dependencies: 546
-- Name: SEQUENCE notification_history_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.notification_history_id_seq TO bkkdev_rw;


--
-- TOC entry 6238 (class 0 OID 0)
-- Dependencies: 547
-- Name: SEQUENCE notification_modes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.notification_modes_id_seq TO bkkdev_rw;


--
-- TOC entry 6239 (class 0 OID 0)
-- Dependencies: 548
-- Name: SEQUENCE notification_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.notification_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6240 (class 0 OID 0)
-- Dependencies: 549
-- Name: SEQUENCE notifications_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.notifications_id_seq TO bkkdev_rw;


--
-- TOC entry 6241 (class 0 OID 0)
-- Dependencies: 550
-- Name: TABLE numbers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.numbers TO haider_qa;


--
-- TOC entry 6243 (class 0 OID 0)
-- Dependencies: 551
-- Name: SEQUENCE numbers_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.numbers_id_seq TO bkkdev_rw;


--
-- TOC entry 6244 (class 0 OID 0)
-- Dependencies: 552
-- Name: SEQUENCE nutrient_deficiency_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.nutrient_deficiency_id_seq TO bkkdev_rw;


--
-- TOC entry 6245 (class 0 OID 0)
-- Dependencies: 553
-- Name: SEQUENCE oauth_access_token_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_access_token_id_seq TO bkkdev_rw;


--
-- TOC entry 6246 (class 0 OID 0)
-- Dependencies: 554
-- Name: SEQUENCE oauth_authorization_code_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_authorization_code_id_seq TO bkkdev_rw;


--
-- TOC entry 6247 (class 0 OID 0)
-- Dependencies: 555
-- Name: SEQUENCE oauth_clients_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_clients_id_seq TO bkkdev_rw;


--
-- TOC entry 6248 (class 0 OID 0)
-- Dependencies: 556
-- Name: SEQUENCE oauth_refresh_token_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_refresh_token_id_seq TO bkkdev_rw;


--
-- TOC entry 6249 (class 0 OID 0)
-- Dependencies: 557
-- Name: SEQUENCE oauth_scopes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_scopes_id_seq TO bkkdev_rw;


--
-- TOC entry 6250 (class 0 OID 0)
-- Dependencies: 558
-- Name: SEQUENCE oauth_user_client_grants_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_user_client_grants_id_seq TO bkkdev_rw;


--
-- TOC entry 6251 (class 0 OID 0)
-- Dependencies: 559
-- Name: SEQUENCE oauth_user_otp_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_user_otp_id_seq TO bkkdev_rw;


--
-- TOC entry 6252 (class 0 OID 0)
-- Dependencies: 560
-- Name: SEQUENCE occupations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.occupations_id_seq TO bkkdev_rw;


--
-- TOC entry 6253 (class 0 OID 0)
-- Dependencies: 561
-- Name: SEQUENCE operators_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.operators_id_seq TO bkkdev_rw;


--
-- TOC entry 6254 (class 0 OID 0)
-- Dependencies: 562
-- Name: SEQUENCE pak_adm3_gid_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.pak_adm3_gid_seq TO bkkdev_rw;


--
-- TOC entry 6255 (class 0 OID 0)
-- Dependencies: 563
-- Name: SEQUENCE pak_admbnda_adm1_ocha_pco_gaul_20181218_gid_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.pak_admbnda_adm1_ocha_pco_gaul_20181218_gid_seq TO bkkdev_rw;


--
-- TOC entry 6256 (class 0 OID 0)
-- Dependencies: 564
-- Name: SEQUENCE pak_admbnda_adm2_ocha_pco_gaul_20181218_gid_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.pak_admbnda_adm2_ocha_pco_gaul_20181218_gid_seq TO bkkdev_rw;


--
-- TOC entry 6257 (class 0 OID 0)
-- Dependencies: 565
-- Name: TABLE parameters; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.parameters TO haider_qa;


--
-- TOC entry 6258 (class 0 OID 0)
-- Dependencies: 566
-- Name: SEQUENCE partner_procurement_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.partner_procurement_id_seq TO bkkdev_rw;


--
-- TOC entry 6259 (class 0 OID 0)
-- Dependencies: 567
-- Name: SEQUENCE partner_services_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.partner_services_id_seq TO bkkdev_rw;


--
-- TOC entry 6260 (class 0 OID 0)
-- Dependencies: 568
-- Name: SEQUENCE pests_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.pests_id_seq TO bkkdev_rw;


--
-- TOC entry 6261 (class 0 OID 0)
-- Dependencies: 569
-- Name: SEQUENCE phrase_32_char_list_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.phrase_32_char_list_id_seq TO bkkdev_rw;


--
-- TOC entry 6262 (class 0 OID 0)
-- Dependencies: 570
-- Name: SEQUENCE player_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.player_id_seq TO bkkdev_rw;


--
-- TOC entry 6263 (class 0 OID 0)
-- Dependencies: 571
-- Name: SEQUENCE point10_3_gid_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.point10_3_gid_seq TO bkkdev_rw;


--
-- TOC entry 6264 (class 0 OID 0)
-- Dependencies: 671
-- Name: TABLE product_advisory; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.product_advisory TO haider_qa;


--
-- TOC entry 6265 (class 0 OID 0)
-- Dependencies: 672
-- Name: TABLE product_advisory_jobs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.product_advisory_jobs TO haider_qa;


--
-- TOC entry 6266 (class 0 OID 0)
-- Dependencies: 572
-- Name: TABLE product_cc_requests; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.product_cc_requests TO haider_qa;


--
-- TOC entry 6267 (class 0 OID 0)
-- Dependencies: 573
-- Name: TABLE product_mappings; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.product_mappings TO haider_qa;


--
-- TOC entry 6268 (class 0 OID 0)
-- Dependencies: 574
-- Name: SEQUENCE questionair_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.questionair_id_seq TO bkkdev_rw;


--
-- TOC entry 6269 (class 0 OID 0)
-- Dependencies: 575
-- Name: SEQUENCE questionair_response_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.questionair_response_id_seq TO bkkdev_rw;


--
-- TOC entry 6270 (class 0 OID 0)
-- Dependencies: 576
-- Name: SEQUENCE recording_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.recording_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6271 (class 0 OID 0)
-- Dependencies: 577
-- Name: SEQUENCE scenarios_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.scenarios_id_seq TO bkkdev_rw;


--
-- TOC entry 6272 (class 0 OID 0)
-- Dependencies: 578
-- Name: SEQUENCE seed_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.seed_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6273 (class 0 OID 0)
-- Dependencies: 579
-- Name: SEQUENCE sentiments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sentiments_id_seq TO bkkdev_rw;


--
-- TOC entry 6274 (class 0 OID 0)
-- Dependencies: 580
-- Name: SEQUENCE seq_id_advisory; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.seq_id_advisory TO bkkdev_rw;


--
-- TOC entry 6275 (class 0 OID 0)
-- Dependencies: 581
-- Name: SEQUENCE services_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.services_id_seq TO bkkdev_rw;


--
-- TOC entry 6276 (class 0 OID 0)
-- Dependencies: 664
-- Name: TABLE shopify_product_advisory_recommendations; Type: ACL; Schema: public; Owner: rameez_dev_rw
--

GRANT SELECT ON TABLE public.shopify_product_advisory_recommendations TO haider_qa;


--
-- TOC entry 6277 (class 0 OID 0)
-- Dependencies: 582
-- Name: SEQUENCE sites_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sites_id_seq TO bkkdev_rw;


--
-- TOC entry 6278 (class 0 OID 0)
-- Dependencies: 583
-- Name: SEQUENCE sites_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sites_id_seq1 TO bkkdev_rw;


--
-- TOC entry 6279 (class 0 OID 0)
-- Dependencies: 584
-- Name: TABLE sms_cta; Type: ACL; Schema: public; Owner: bkkdev_rw
--

GRANT SELECT ON TABLE public.sms_cta TO haider_qa;


--
-- TOC entry 6280 (class 0 OID 0)
-- Dependencies: 585
-- Name: TABLE sms_cta_translations; Type: ACL; Schema: public; Owner: bkkdev_rw
--

GRANT SELECT ON TABLE public.sms_cta_translations TO haider_qa;


--
-- TOC entry 6281 (class 0 OID 0)
-- Dependencies: 586
-- Name: TABLE sms_history; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.sms_history TO haider_qa;


--
-- TOC entry 6283 (class 0 OID 0)
-- Dependencies: 587
-- Name: SEQUENCE sms_history_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sms_history_id_seq TO bkkdev_rw;


--
-- TOC entry 6284 (class 0 OID 0)
-- Dependencies: 588
-- Name: SEQUENCE soil_issues_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.soil_issues_id_seq TO bkkdev_rw;


--
-- TOC entry 6285 (class 0 OID 0)
-- Dependencies: 589
-- Name: TABLE soil_type_category; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.soil_type_category TO haider_qa;


--
-- TOC entry 6286 (class 0 OID 0)
-- Dependencies: 590
-- Name: TABLE soil_type_parameters; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.soil_type_parameters TO haider_qa;


--
-- TOC entry 6287 (class 0 OID 0)
-- Dependencies: 591
-- Name: SEQUENCE soil_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.soil_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6288 (class 0 OID 0)
-- Dependencies: 592
-- Name: SEQUENCE source_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.source_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6289 (class 0 OID 0)
-- Dependencies: 593
-- Name: SEQUENCE sowing_methods_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sowing_methods_id_seq TO bkkdev_rw;


--
-- TOC entry 6290 (class 0 OID 0)
-- Dependencies: 594
-- Name: SEQUENCE sub_modes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sub_modes_id_seq TO bkkdev_rw;


--
-- TOC entry 6291 (class 0 OID 0)
-- Dependencies: 595
-- Name: SEQUENCE subscriber_notification_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriber_notification_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6292 (class 0 OID 0)
-- Dependencies: 596
-- Name: SEQUENCE subscriber_roles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriber_roles_id_seq TO bkkdev_rw;


--
-- TOC entry 6293 (class 0 OID 0)
-- Dependencies: 597
-- Name: SEQUENCE subscribers_job_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscribers_job_logs_id_seq TO bkkdev_rw;


--
-- TOC entry 6294 (class 0 OID 0)
-- Dependencies: 598
-- Name: SEQUENCE subscription_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscription_types_id_seq TO bkkdev_rw;


--
-- TOC entry 6295 (class 0 OID 0)
-- Dependencies: 599
-- Name: SEQUENCE subscriptions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriptions_id_seq TO bkkdev_rw;


--
-- TOC entry 6296 (class 0 OID 0)
-- Dependencies: 600
-- Name: SEQUENCE subscriptions_subscription_type_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriptions_subscription_type_id_seq TO bkkdev_rw;


--
-- TOC entry 6297 (class 0 OID 0)
-- Dependencies: 601
-- Name: SEQUENCE survey_activities_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_activities_id_seq TO bkkdev_rw;


--
-- TOC entry 6298 (class 0 OID 0)
-- Dependencies: 602
-- Name: SEQUENCE survey_api_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_api_actions_id_seq TO bkkdev_rw;


--
-- TOC entry 6299 (class 0 OID 0)
-- Dependencies: 603
-- Name: SEQUENCE survey_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_categories_id_seq TO bkkdev_rw;


--
-- TOC entry 6300 (class 0 OID 0)
-- Dependencies: 604
-- Name: SEQUENCE survey_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_crops_id_seq TO bkkdev_rw;


--
-- TOC entry 6301 (class 0 OID 0)
-- Dependencies: 605
-- Name: SEQUENCE survey_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_files_id_seq TO bkkdev_rw;


--
-- TOC entry 6302 (class 0 OID 0)
-- Dependencies: 606
-- Name: SEQUENCE survey_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_id_seq TO bkkdev_rw;


--
-- TOC entry 6303 (class 0 OID 0)
-- Dependencies: 607
-- Name: SEQUENCE survey_input_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_input_files_id_seq TO bkkdev_rw;


--
-- TOC entry 6304 (class 0 OID 0)
-- Dependencies: 608
-- Name: SEQUENCE survey_input_trunk_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_input_trunk_actions_id_seq TO bkkdev_rw;


--
-- TOC entry 6305 (class 0 OID 0)
-- Dependencies: 609
-- Name: SEQUENCE survey_inputs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_inputs_id_seq TO bkkdev_rw;


--
-- TOC entry 6306 (class 0 OID 0)
-- Dependencies: 610
-- Name: SEQUENCE survey_languages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_languages_id_seq TO bkkdev_rw;


--
-- TOC entry 6307 (class 0 OID 0)
-- Dependencies: 611
-- Name: SEQUENCE survey_livestocks_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_livestocks_id_seq TO bkkdev_rw;


--
-- TOC entry 6308 (class 0 OID 0)
-- Dependencies: 612
-- Name: SEQUENCE survey_locations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_locations_id_seq TO bkkdev_rw;


--
-- TOC entry 6309 (class 0 OID 0)
-- Dependencies: 613
-- Name: SEQUENCE survey_machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_machineries_id_seq TO bkkdev_rw;


--
-- TOC entry 6310 (class 0 OID 0)
-- Dependencies: 614
-- Name: SEQUENCE survey_profiles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_profiles_id_seq TO bkkdev_rw;


--
-- TOC entry 6311 (class 0 OID 0)
-- Dependencies: 615
-- Name: SEQUENCE survey_promo_data_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_promo_data_id_seq TO bkkdev_rw;


--
-- TOC entry 6312 (class 0 OID 0)
-- Dependencies: 616
-- Name: TABLE sync_tables; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.sync_tables TO haider_qa;


--
-- TOC entry 6313 (class 0 OID 0)
-- Dependencies: 617
-- Name: SEQUENCE tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.tags_id_seq TO bkkdev_rw;


--
-- TOC entry 6314 (class 0 OID 0)
-- Dependencies: 618
-- Name: TABLE tenants; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.tenants TO haider_qa;


--
-- TOC entry 6315 (class 0 OID 0)
-- Dependencies: 619
-- Name: SEQUENCE terms_of_use_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.terms_of_use_id_seq TO bkkdev_rw;


--
-- TOC entry 6316 (class 0 OID 0)
-- Dependencies: 620
-- Name: TABLE time_periods; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.time_periods TO haider_qa;


--
-- TOC entry 6317 (class 0 OID 0)
-- Dependencies: 621
-- Name: SEQUENCE transactions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.transactions_id_seq TO bkkdev_rw;


--
-- TOC entry 6318 (class 0 OID 0)
-- Dependencies: 622
-- Name: SEQUENCE trigger_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.trigger_id_seq TO bkkdev_rw;


--
-- TOC entry 6319 (class 0 OID 0)
-- Dependencies: 623
-- Name: SEQUENCE trigger_type_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.trigger_type_id_seq TO bkkdev_rw;


--
-- TOC entry 6320 (class 0 OID 0)
-- Dependencies: 624
-- Name: SEQUENCE trunk_call_details_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.trunk_call_details_id_seq TO bkkdev_rw;


--
-- TOC entry 6321 (class 0 OID 0)
-- Dependencies: 625
-- Name: SEQUENCE trunk_recording_timings_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.trunk_recording_timings_id_seq TO bkkdev_rw;


--
-- TOC entry 6322 (class 0 OID 0)
-- Dependencies: 626
-- Name: SEQUENCE trunk_timings_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.trunk_timings_id_seq TO bkkdev_rw;


--
-- TOC entry 6323 (class 0 OID 0)
-- Dependencies: 627
-- Name: SEQUENCE user_activities_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.user_activities_id_seq TO bkkdev_rw;


--
-- TOC entry 6324 (class 0 OID 0)
-- Dependencies: 628
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.users TO haider_qa;


--
-- TOC entry 6325 (class 0 OID 0)
-- Dependencies: 629
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.users_id_seq TO bkkdev_rw;


--
-- TOC entry 6326 (class 0 OID 0)
-- Dependencies: 630
-- Name: SEQUENCE weather_change_set_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_change_set_id_seq TO bkkdev_rw;


--
-- TOC entry 6327 (class 0 OID 0)
-- Dependencies: 631
-- Name: SEQUENCE weather_change_set_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_change_set_id_seq1 TO bkkdev_rw;


--
-- TOC entry 6328 (class 0 OID 0)
-- Dependencies: 632
-- Name: TABLE weather_condition_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.weather_condition_types TO haider_qa;


--
-- TOC entry 6329 (class 0 OID 0)
-- Dependencies: 633
-- Name: TABLE weather_conditions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.weather_conditions TO haider_qa;


--
-- TOC entry 6330 (class 0 OID 0)
-- Dependencies: 634
-- Name: SEQUENCE weather_conditions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_conditions_id_seq TO bkkdev_rw;


--
-- TOC entry 6331 (class 0 OID 0)
-- Dependencies: 635
-- Name: SEQUENCE weather_conditions_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_conditions_id_seq1 TO bkkdev_rw;


--
-- TOC entry 6332 (class 0 OID 0)
-- Dependencies: 636
-- Name: SEQUENCE weather_daily_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_daily_id_seq TO bkkdev_rw;


--
-- TOC entry 6333 (class 0 OID 0)
-- Dependencies: 637
-- Name: SEQUENCE weather_daily_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_daily_id_seq1 TO bkkdev_rw;


--
-- TOC entry 6334 (class 0 OID 0)
-- Dependencies: 638
-- Name: TABLE weather_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.weather_data TO haider_qa;


--
-- TOC entry 6335 (class 0 OID 0)
-- Dependencies: 639
-- Name: SEQUENCE weather_hourly_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_hourly_id_seq TO bkkdev_rw;


--
-- TOC entry 6336 (class 0 OID 0)
-- Dependencies: 640
-- Name: SEQUENCE weather_hourly_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_hourly_id_seq1 TO bkkdev_rw;


--
-- TOC entry 6337 (class 0 OID 0)
-- Dependencies: 641
-- Name: SEQUENCE weather_intraday_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_intraday_id_seq TO bkkdev_rw;


--
-- TOC entry 6338 (class 0 OID 0)
-- Dependencies: 642
-- Name: SEQUENCE weather_outlook_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_outlook_id_seq TO bkkdev_rw;


--
-- TOC entry 6339 (class 0 OID 0)
-- Dependencies: 643
-- Name: SEQUENCE weather_raw_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_raw_id_seq TO bkkdev_rw;


--
-- TOC entry 6340 (class 0 OID 0)
-- Dependencies: 644
-- Name: SEQUENCE weather_service_events_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_service_events_id_seq TO bkkdev_rw;


--
-- TOC entry 6341 (class 0 OID 0)
-- Dependencies: 645
-- Name: SEQUENCE weeds_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weeds_id_seq TO bkkdev_rw;


--
-- TOC entry 6342 (class 0 OID 0)
-- Dependencies: 646
-- Name: SEQUENCE welcome_box_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.welcome_box_id_seq TO bkkdev_rw;


--
-- TOC entry 6343 (class 0 OID 0)
-- Dependencies: 647
-- Name: SEQUENCE wx_phrase_list_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.wx_phrase_list_id_seq TO bkkdev_rw;


--
-- TOC entry 6344 (class 0 OID 0)
-- Dependencies: 648
-- Name: TABLE layer; Type: ACL; Schema: topology; Owner: postgres
--

GRANT SELECT ON TABLE topology.layer TO haider_qa;


--
-- TOC entry 6345 (class 0 OID 0)
-- Dependencies: 649
-- Name: TABLE topology; Type: ACL; Schema: topology; Owner: postgres
--

GRANT SELECT ON TABLE topology.topology TO haider_qa;


--
-- TOC entry 3110 (class 826 OID 1564269)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO haider_qa;


--
-- TOC entry 3109 (class 826 OID 1564268)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: topology; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA topology GRANT SELECT ON TABLES TO haider_qa;


-- Completed on 2025-08-15 11:59:47

--
-- PostgreSQL database dump complete
--

