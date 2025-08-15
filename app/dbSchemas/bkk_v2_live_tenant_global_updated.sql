--
-- PostgreSQL database dump
--

-- Dumped from database version 12.13 (Debian 12.13-1.pgdg100+1)
-- Dumped by pg_dump version 17.5

-- Started on 2025-08-15 12:00:50

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
-- TOC entry 10 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 4 (class 3079 OID 546247)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 9688 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 2 (class 3079 OID 265676)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 9689 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 3 (class 3079 OID 307814)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 9690 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 2083 (class 1247 OID 266751)
-- Name: application_status_title; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.application_status_title AS ENUM (
    'Applied',
    'In Review',
    'Agent Assigned',
    'In Agent Review'
);


ALTER TYPE public.application_status_title OWNER TO postgres;

--
-- TOC entry 2086 (class 1247 OID 266760)
-- Name: loc_types; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.loc_types AS ENUM (
    'province',
    'district',
    'tehsil'
);


ALTER TYPE public.loc_types OWNER TO postgres;

--
-- TOC entry 2089 (class 1247 OID 266768)
-- Name: sub_recurrences; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.sub_recurrences AS ENUM (
    'daily',
    'weekly',
    'monthly',
    'fixed'
);


ALTER TYPE public.sub_recurrences OWNER TO postgres;

--
-- TOC entry 1576 (class 1255 OID 266777)
-- Name: fun_farmer_profile_update(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.fun_farmer_profile_update()
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO fun_farmer_profile_update (RecentUpdate, AgentEmail, ProfileCount) VALUES ('1','1',1);
END;
$$;


ALTER PROCEDURE public.fun_farmer_profile_update() OWNER TO postgres;

--
-- TOC entry 1577 (class 1255 OID 266778)
-- Name: generate_farmer_uid(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_farmer_uid() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
				user_key VARCHAR;
				is_used_key BOOLEAN;
BEGIN	
	user_key := '';
	is_used_key := false;
	
	WHILE user_key = '' OR is_used_key = true LOOP
		SELECT
		array_to_string(
			ARRAY ( SELECT SUBSTRING ( 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' 
			FROM ( random( ) * 62 ) :: INT FOR 1 ) FROM generate_series ( 1, 4 ) ),
			'' 
		) INTO user_key;
		
		SELECT EXISTS(SELECT 1 FROM farmers where key=user_key) INTO is_used_key;
	END LOOP;
	
	IF is_used_key = false THEN
		UPDATE farmers set key = user_key where id = NEW.id;
	END IF;
	
	return NEW;

END;
$$;


ALTER FUNCTION public.generate_farmer_uid() OWNER TO postgres;

--
-- TOC entry 1578 (class 1255 OID 266779)
-- Name: is_valid_json(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_valid_json(p_json text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
begin
  return (p_json::json is not null);
exception 
  when others then
     return false;  
end;
$$;


ALTER FUNCTION public.is_valid_json(p_json text) OWNER TO postgres;

--
-- TOC entry 1579 (class 1255 OID 266780)
-- Name: is_valid_json_array(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_valid_json_array(p_json text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
begin
  return json_array_length( p_json::json) >= 0;
exception 
  when others then
     return false;  
end;
$$;


ALTER FUNCTION public.is_valid_json_array(p_json text) OWNER TO postgres;

--
-- TOC entry 1580 (class 1255 OID 266781)
-- Name: is_valid_json_array_with_data(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_valid_json_array_with_data(p_json text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
begin
  return json_array_length( p_json::json) > 0;
exception 
  when others then
     return false;  
end;
$$;


ALTER FUNCTION public.is_valid_json_array_with_data(p_json text) OWNER TO postgres;

--
-- TOC entry 1581 (class 1255 OID 266782)
-- Name: make_uid(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.make_uid() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_uid text;
    done bool;
BEGIN
		new_uid := md5(''||now()::text||random()::text);
    RETURN new_uid;
END;
$$;


ALTER FUNCTION public.make_uid() OWNER TO postgres;

--
-- TOC entry 1582 (class 1255 OID 266783)
-- Name: pro_farmer_profile_update(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.pro_farmer_profile_update()
    LANGUAGE plpgsql
    AS $$
Declare
	c Cursor For
	SELECT A.email AS "email" , COUNT(*) AS "count",CURRENT_DATE AS "date" FROM agents A JOIN farmcrops B ON A.email = B.profiled_by GROUP BY A.email UNION
	SELECT A.email AS "email" , COUNT(*) AS "count", CURRENT_DATE AS "date" FROM agents A JOIN farmer_livestocks B ON A.email = B.profiled_by GROUP BY A.email UNION
	SELECT A.email AS "email" , COUNT(*) AS "count", CURRENT_DATE AS "date" FROM agents A JOIN farmer_machineries B ON A.email = B.profiled_by GROUP BY A.email UNION
	SELECT A.email AS "email" , COUNT(*) AS "count", CURRENT_DATE AS "date" FROM agents A JOIN farms B ON A.email = B.profiled_by GROUP BY A.email UNION 
  SELECT A.email AS "email" , COUNT(*) AS "count", CURRENT_DATE AS "date" FROM agents A JOIN subscribers B ON A.email = B.profiled_by GROUP BY A.email UNION 
	SELECT A.email AS "email" , COUNT(*) AS "count", CURRENT_DATE AS "date" FROM agents A JOIN farmers B ON A.email = B.profiled_by GROUP BY A.email;
		
BEGIN
  FOR row IN c LOOP
	  --count = row.count + count
    INSERT INTO pro_farmer_profile_update (email,count,date) 
		VALUES (row.email,row.count,row.date) ON CONFLICT (email,date) DO UPDATE
    SET count = row.count + pro_farmer_profile_update.count
    WHERE pro_farmer_profile_update.email = row.email AND pro_farmer_profile_update.date = row.date;
  END LOOP;
END; $$;


ALTER PROCEDURE public.pro_farmer_profile_update() OWNER TO postgres;

--
-- TOC entry 1583 (class 1255 OID 266784)
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.update_dt = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_set_timestamp() OWNER TO postgres;

--
-- TOC entry 1635 (class 1255 OID 580627)
-- Name: update_farmer_formatted_names(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_farmer_formatted_names() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    original_name_part VARCHAR;
    corrected_name_part VARCHAR;
    full_corrected_name VARCHAR;
    farmer_name VARCHAR;
    formatted_name VARCHAR;
    msisdn_value VARCHAR;
    name_parts TEXT[];
    i INT;
BEGIN
    -- Loop through each row in test_farmers_names
    FOR msisdn_value, farmer_name IN
        SELECT msisdn, name FROM test_farmers_names
    LOOP
        -- Initialize formatted_name as empty string
        formatted_name := '';
        
        -- Split farmer_name into individual words
        name_parts := string_to_array(farmer_name, ' ');
        
        -- Loop through each part of the name
        FOR i IN 1..array_length(name_parts, 1) LOOP
            original_name_part := name_parts[i];
            
            -- Find corrected name part from farmer_updated_names table
            SELECT corrected_name INTO corrected_name_part
            FROM farmer_updated_names
            WHERE original_name = original_name_part
            LIMIT 1;
            
            -- If found, use corrected_name_part, otherwise use original_name_part
            IF corrected_name_part IS NOT NULL THEN
                full_corrected_name := corrected_name_part;
            ELSE
                full_corrected_name := original_name_part;
            END IF;
            
            -- Append the corrected part to formatted_name
            IF formatted_name = '' THEN
                formatted_name := full_corrected_name;
            ELSE
                formatted_name := formatted_name || ' ' || full_corrected_name;
            END IF;
        END LOOP;
        
        -- Update the test_farmers_names table with the corrected name in the formatted_name column
        UPDATE test_farmers_names
        SET formated_name = formatted_name
        WHERE msisdn = msisdn_value;
    END LOOP;
END;
$$;


ALTER FUNCTION public.update_farmer_formatted_names() OWNER TO postgres;

--
-- TOC entry 1636 (class 1255 OID 580629)
-- Name: update_formated_farmer_names_all_parts(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_formated_farmer_names_all_parts()
    LANGUAGE plpgsql
    AS $$
DECLARE
    farmer_row RECORD;         
    update_row RECORD;         
    original_parts text[];     
    formated_parts text[];     
    name_matches boolean;      
    i integer;            
BEGIN
    FOR farmer_row IN
        SELECT * FROM test_farmer_names
    LOOP
        formated_parts := regexp_split_to_array(farmer_row.formated_name, '\s+');
        
        FOR update_row IN
            SELECT * FROM farmer_updated_names
        LOOP
            original_parts := regexp_split_to_array(update_row.original_name, '\s+');

            IF array_length(formated_parts, 1) = array_length(original_parts, 1) THEN
                name_matches := true; 

                FOR i IN 1..array_length(formated_parts, 1)
                LOOP
                    RAISE NOTICE 'Comparing: "%s" with "%s"', TRIM(LOWER(formated_parts[i])), TRIM(LOWER(original_parts[i]));

                    IF TRIM(LOWER(formated_parts[i])) != TRIM(LOWER(original_parts[i])) THEN
                        name_matches := false;
                        EXIT;
                    END IF;
                END LOOP;

                IF name_matches THEN
                    RAISE NOTICE 'Updating msisdn: % with corrected_name: %', farmer_row.msisdn, update_row.corrected_name; 
                    UPDATE test_farmer_names
                    SET formated_name = update_row.corrected_name
                    WHERE msisdn = farmer_row.msisdn;
                END IF;
            ELSE
                RAISE NOTICE 'Length mismatch for msisdn: % - formated_parts: % - original_parts: %', farmer_row.msisdn, array_length(formated_parts, 1), array_length(original_parts, 1);
            END IF;
        END LOOP;
    END LOOP;
END;
$$;


ALTER PROCEDURE public.update_formated_farmer_names_all_parts() OWNER TO postgres;

--
-- TOC entry 1584 (class 1255 OID 266785)
-- Name: update_modified_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_modified_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   IF row(NEW.*) IS DISTINCT FROM row(OLD.*) THEN
      NEW.update_dt = now(); 
      RETURN NEW;
   ELSE
      RETURN OLD;
   END IF;
END; 
$$;


ALTER FUNCTION public.update_modified_column() OWNER TO postgres;

--
-- TOC entry 1598 (class 1255 OID 389319)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW(); -- Set the updated_at column to the current timestamp
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

--
-- TOC entry 1585 (class 1255 OID 266786)
-- Name: update_updated_dt(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_dt() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_dt = current_timestamp;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_dt() OWNER TO postgres;

--
-- TOC entry 1586 (class 1255 OID 266787)
-- Name: update_weather_daily_date(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_weather_daily_date()
    LANGUAGE plpgsql
    AS $$
Declare
	c Cursor For
		Select id, weather_dt from weather_hourly order by weather_dt desc
		For update;
BEGIN
  FOR row IN c LOOP
    UPDATE weather_hourly
    SET weather_dt = row.weather_dt + interval '1 day'
    WHERE CURRENT OF c;
  END LOOP;
END; $$;


ALTER PROCEDURE public.update_weather_daily_date() OWNER TO postgres;

--
-- TOC entry 1587 (class 1255 OID 266788)
-- Name: update_weather_date(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_weather_date()
    LANGUAGE plpgsql
    AS $$
Declare
	c Cursor For
		Select id, weather_dt from weather_hourly order by weather_dt desc
		For update;
BEGIN
  FOR row IN c LOOP
    UPDATE weather_hourly
    SET weather_dt = row.weather_dt + interval '1 day'
    WHERE id = row.id;
  END LOOP;
END; 
$$;


ALTER PROCEDURE public.update_weather_date() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 210 (class 1259 OID 266789)
-- Name: KP_Data_Swabi_msisdns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."KP_Data_Swabi_msisdns" (
    msisdn character varying(255)
);


ALTER TABLE public."KP_Data_Swabi_msisdns" OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 266792)
-- Name: abiotic_stress; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.abiotic_stress (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    title_urdu character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    file_name character varying(255),
    content_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.abiotic_stress OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 266801)
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
-- TOC entry 9693 (class 0 OID 0)
-- Dependencies: 212
-- Name: abiotic_stress_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.abiotic_stress_id_seq OWNED BY public.abiotic_stress.id;


--
-- TOC entry 809 (class 1259 OID 643852)
-- Name: abusive_callers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.abusive_callers (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(255) NOT NULL,
    profiled_by character varying(255),
    profiler_type character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.abusive_callers OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 266803)
-- Name: actions_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.actions_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.actions_types OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 266813)
-- Name: actions_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.actions_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.actions_types_id_seq OWNER TO postgres;

--
-- TOC entry 9697 (class 0 OID 0)
-- Dependencies: 214
-- Name: actions_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.actions_types_id_seq OWNED BY public.actions_types.id;


--
-- TOC entry 215 (class 1259 OID 266815)
-- Name: active_subscriber_range; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.active_subscriber_range (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    number_of_days bigint NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.active_subscriber_range OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 266824)
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
-- TOC entry 9700 (class 0 OID 0)
-- Dependencies: 216
-- Name: active_subscriber_range_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.active_subscriber_range_id_seq OWNED BY public.active_subscriber_range.id;


--
-- TOC entry 217 (class 1259 OID 266826)
-- Name: actively_engaged_users_bkk_cc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.actively_engaged_users_bkk_cc (
    "MSISDN" character varying(255)
);


ALTER TABLE public.actively_engaged_users_bkk_cc OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 266829)
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_logs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    table_name character varying NOT NULL,
    description character varying NOT NULL,
    create_dt timestamp(6) with time zone NOT NULL,
    update_dt timestamp(6) with time zone,
    profiled_by character varying NOT NULL,
    profiler_type character varying NOT NULL,
    info character varying,
    msisdn character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.activity_logs OWNER TO postgres;

--
-- TOC entry 744 (class 1259 OID 504927)
-- Name: adoptive_ivr_apps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_ivr_apps (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    app_name character varying(255),
    tenant character varying(255)
);


ALTER TABLE public.adoptive_ivr_apps OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 266837)
-- Name: adoptive_menu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    child_node_uuid character varying(255) DEFAULT NULL::character varying,
    parent_node_uuid character varying(255) DEFAULT NULL::character varying,
    root_node smallint DEFAULT 0 NOT NULL,
    validation_query text,
    node_repeat integer DEFAULT 1 NOT NULL,
    child_repeat integer DEFAULT 1 NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    special_char character varying(1) DEFAULT NULL::character varying,
    has_input smallint DEFAULT 1 NOT NULL,
    success_node_uuid character varying(255) DEFAULT NULL::character varying,
    failed_node_uuid character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 0 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    file_name_query text,
    max_child_nodes integer DEFAULT 9 NOT NULL,
    patch_data_query text,
    link_node smallint DEFAULT 0 NOT NULL,
    child_order_key character varying(255),
    skip_dtmf_content smallint DEFAULT 0,
    recording_enabled boolean DEFAULT false NOT NULL,
    max_duration_seconds bigint DEFAULT 60 NOT NULL,
    max_silence_seconds bigint DEFAULT 5 NOT NULL,
    recording_path_id character varying(255),
    play_success_node_content boolean DEFAULT false NOT NULL,
    play_failed_node_content boolean DEFAULT false NOT NULL,
    menu_lov_id character varying(255),
    content_node_query text,
    guid character varying(255) DEFAULT NULL::character varying,
    execute_link_node smallint,
    app_name character varying(255),
    jump_to_child_nodes smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.adoptive_menu OWNER TO postgres;

--
-- TOC entry 745 (class 1259 OID 504936)
-- Name: adoptive_menu_api_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_api_actions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    action_id character varying(255) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 0 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.adoptive_menu_api_actions OWNER TO postgres;

--
-- TOC entry 746 (class 1259 OID 504948)
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
-- TOC entry 9707 (class 0 OID 0)
-- Dependencies: 746
-- Name: adoptive_menu_api_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.adoptive_menu_api_actions_id_seq OWNED BY public.adoptive_menu_api_actions.id;


--
-- TOC entry 747 (class 1259 OID 504967)
-- Name: adoptive_menu_campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_campaigns (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    seq_order character varying(255) DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query character varying(255)
);


ALTER TABLE public.adoptive_menu_campaigns OWNER TO postgres;

--
-- TOC entry 749 (class 1259 OID 504997)
-- Name: adoptive_menu_content_nodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_content_nodes (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    content_file_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    seq_order integer DEFAULT 0 NOT NULL,
    title character varying(255),
    validation_query text,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.adoptive_menu_content_nodes OWNER TO postgres;

--
-- TOC entry 750 (class 1259 OID 505008)
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
-- TOC entry 9711 (class 0 OID 0)
-- Dependencies: 750
-- Name: adoptive_menu_content_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.adoptive_menu_content_nodes_id_seq OWNED BY public.adoptive_menu_content_nodes.id;


--
-- TOC entry 751 (class 1259 OID 505025)
-- Name: adoptive_menu_crops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_crops (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    stage_id character varying(255),
    crop_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.adoptive_menu_crops OWNER TO postgres;

--
-- TOC entry 748 (class 1259 OID 504978)
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
-- TOC entry 9714 (class 0 OID 0)
-- Dependencies: 748
-- Name: adoptive_menu_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.adoptive_menu_events_id_seq OWNED BY public.adoptive_menu_campaigns.id;


--
-- TOC entry 753 (class 1259 OID 505064)
-- Name: adoptive_menu_file_name_apis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_file_name_apis (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    action_id character varying(255) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.adoptive_menu_file_name_apis OWNER TO postgres;

--
-- TOC entry 754 (class 1259 OID 505089)
-- Name: adoptive_menu_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_files (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    content_file_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    seq_order integer DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.adoptive_menu_files OWNER TO postgres;

--
-- TOC entry 755 (class 1259 OID 505100)
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
-- TOC entry 9718 (class 0 OID 0)
-- Dependencies: 755
-- Name: adoptive_menu_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.adoptive_menu_files_id_seq OWNED BY public.adoptive_menu_files.id;


--
-- TOC entry 743 (class 1259 OID 504920)
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
-- TOC entry 9720 (class 0 OID 0)
-- Dependencies: 743
-- Name: adoptive_menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.adoptive_menu_id_seq OWNED BY public.adoptive_menu.id;


--
-- TOC entry 756 (class 1259 OID 505119)
-- Name: adoptive_menu_languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_languages (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    language_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.adoptive_menu_languages OWNER TO postgres;

--
-- TOC entry 758 (class 1259 OID 505142)
-- Name: adoptive_menu_livestocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_livestocks (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    livestock_id character varying(255) NOT NULL,
    category_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.adoptive_menu_livestocks OWNER TO postgres;

--
-- TOC entry 760 (class 1259 OID 505170)
-- Name: adoptive_menu_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_locations (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    location_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.adoptive_menu_locations OWNER TO postgres;

--
-- TOC entry 762 (class 1259 OID 505193)
-- Name: adoptive_menu_machineries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_machineries (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    machinery_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.adoptive_menu_machineries OWNER TO postgres;

--
-- TOC entry 771 (class 1259 OID 508392)
-- Name: adoptive_menu_operators; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_operators (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    operator_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255)
);


ALTER TABLE public.adoptive_menu_operators OWNER TO postgres;

--
-- TOC entry 772 (class 1259 OID 508415)
-- Name: adoptive_menu_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_profiles (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    msisdn character varying(15) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255)
);


ALTER TABLE public.adoptive_menu_profiles OWNER TO postgres;

--
-- TOC entry 764 (class 1259 OID 505221)
-- Name: adoptive_menu_recording_end_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_recording_end_files (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    content_file_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    seq_order integer DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.adoptive_menu_recording_end_files OWNER TO postgres;

--
-- TOC entry 765 (class 1259 OID 505232)
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
-- TOC entry 9729 (class 0 OID 0)
-- Dependencies: 765
-- Name: adoptive_menu_recording_end_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.adoptive_menu_recording_end_files_id_seq OWNED BY public.adoptive_menu_recording_end_files.id;


--
-- TOC entry 766 (class 1259 OID 505249)
-- Name: adoptive_menu_surveys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_surveys (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    survey_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query character varying(255)
);


ALTER TABLE public.adoptive_menu_surveys OWNER TO postgres;

--
-- TOC entry 767 (class 1259 OID 505260)
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
-- TOC entry 9732 (class 0 OID 0)
-- Dependencies: 767
-- Name: adoptive_menu_surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.adoptive_menu_surveys_id_seq OWNED BY public.adoptive_menu_surveys.id;


--
-- TOC entry 768 (class 1259 OID 505279)
-- Name: adoptive_menu_trunk_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_trunk_actions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    action_id character varying(255) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 0 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.adoptive_menu_trunk_actions OWNER TO postgres;

--
-- TOC entry 769 (class 1259 OID 505291)
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
-- TOC entry 9735 (class 0 OID 0)
-- Dependencies: 769
-- Name: adoptive_menu_trunk_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.adoptive_menu_trunk_actions_id_seq OWNED BY public.adoptive_menu_trunk_actions.id;


--
-- TOC entry 770 (class 1259 OID 505310)
-- Name: adoptive_menu_validation_apis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.adoptive_menu_validation_apis (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    action_id character varying(255) NOT NULL,
    adoptive_menu_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp without time zone,
    title character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.adoptive_menu_validation_apis OWNER TO postgres;

--
-- TOC entry 690 (class 1259 OID 502728)
-- Name: campaign_crops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_crops (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    stage_id character varying(255),
    crop_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_crops OWNER TO postgres;

--
-- TOC entry 691 (class 1259 OID 502736)
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
-- TOC entry 9739 (class 0 OID 0)
-- Dependencies: 691
-- Name: advisory_crops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisory_crops_id_seq OWNED BY public.campaign_crops.id;


--
-- TOC entry 676 (class 1259 OID 371833)
-- Name: campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaigns (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    content_text text,
    content_audio character varying,
    content_video character varying,
    start_dt timestamp(0) without time zone NOT NULL,
    end_dt timestamp(0) without time zone NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    content_image character varying,
    campaign_type_id character varying(255) NOT NULL,
    seq_order bigint,
    is_user_purged boolean,
    is_user_charged boolean,
    content_id character varying(255),
    mode character varying,
    validation_query character varying,
    content_text_long character varying,
    in_app_enabled boolean DEFAULT false NOT NULL,
    obd_enabled boolean DEFAULT false NOT NULL,
    ivr_enabled boolean DEFAULT false NOT NULL,
    sms_enabled boolean DEFAULT false NOT NULL,
    campaign_category_id character varying(255),
    data_query text,
    file_name_query text,
    recording_enabled boolean DEFAULT false NOT NULL,
    max_duration_seconds bigint DEFAULT 60 NOT NULL,
    max_silence_seconds bigint DEFAULT 5 NOT NULL,
    recording_path_id character varying(255),
    recording_end_file_name_query text,
    once_per_call boolean DEFAULT false NOT NULL,
    active_subscriber_range bigint,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    once_per_call_global boolean DEFAULT false NOT NULL,
    post_id character varying(255),
    callback_start_dt timestamp(6) without time zone DEFAULT NULL::timestamp without time zone,
    callback_end_dt timestamp(6) without time zone DEFAULT NULL::timestamp without time zone,
    callback_enabled boolean DEFAULT false,
    campaign_node_uuid character varying(100) DEFAULT NULL::character varying,
    salutation_id uuid
);


ALTER TABLE public.campaigns OWNER TO postgres;

--
-- TOC entry 677 (class 1259 OID 371854)
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
-- TOC entry 9742 (class 0 OID 0)
-- Dependencies: 677
-- Name: advisory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisory_id_seq OWNED BY public.campaigns.id;


--
-- TOC entry 697 (class 1259 OID 502826)
-- Name: campaign_livestocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_livestocks (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    livestock_id character varying(255) NOT NULL,
    category_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_livestocks OWNER TO postgres;

--
-- TOC entry 698 (class 1259 OID 502834)
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
-- TOC entry 9745 (class 0 OID 0)
-- Dependencies: 698
-- Name: advisory_livestock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisory_livestock_id_seq OWNED BY public.campaign_livestocks.id;


--
-- TOC entry 699 (class 1259 OID 502850)
-- Name: campaign_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_locations (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    location_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_locations OWNER TO postgres;

--
-- TOC entry 700 (class 1259 OID 502858)
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
-- TOC entry 9748 (class 0 OID 0)
-- Dependencies: 700
-- Name: advisory_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisory_locations_id_seq OWNED BY public.campaign_locations.id;


--
-- TOC entry 701 (class 1259 OID 502874)
-- Name: campaign_machineries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_machineries (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    machinery_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_machineries OWNER TO postgres;

--
-- TOC entry 702 (class 1259 OID 502882)
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
-- TOC entry 9751 (class 0 OID 0)
-- Dependencies: 702
-- Name: advisory_machineries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisory_machineries_id_seq OWNED BY public.campaign_machineries.id;


--
-- TOC entry 780 (class 1259 OID 546290)
-- Name: advisory_salutations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisory_salutations (
    text character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    is_active boolean DEFAULT true,
    id uuid DEFAULT public.gen_random_uuid() NOT NULL
);


ALTER TABLE public.advisory_salutations OWNER TO postgres;

--
-- TOC entry 695 (class 1259 OID 502802)
-- Name: campaign_languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_languages (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    language_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_languages OWNER TO postgres;

--
-- TOC entry 696 (class 1259 OID 502810)
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
-- TOC entry 9755 (class 0 OID 0)
-- Dependencies: 696
-- Name: advisory_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advisory_tags_id_seq OWNED BY public.campaign_languages.id;


--
-- TOC entry 220 (class 1259 OID 267072)
-- Name: agent_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_roles (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    role_id character varying(255) NOT NULL,
    agent_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.agent_roles OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 267080)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    app boolean,
    portal boolean,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 267088)
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
-- TOC entry 9759 (class 0 OID 0)
-- Dependencies: 222
-- Name: agent_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agent_roles_id_seq OWNED BY public.roles.id;


--
-- TOC entry 223 (class 1259 OID 267090)
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
-- TOC entry 9761 (class 0 OID 0)
-- Dependencies: 223
-- Name: agent_roles_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agent_roles_id_seq1 OWNED BY public.agent_roles.id;


--
-- TOC entry 224 (class 1259 OID 267092)
-- Name: agents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents (
    name character varying(60),
    last_signin_dt timestamp(6) without time zone,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    email character varying NOT NULL,
    status boolean,
    msisdn character varying,
    extension character varying,
    profile_image_url character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.agents OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 267100)
-- Name: agents_activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_activity_logs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    table_name character varying(255) NOT NULL,
    old_value character varying(255),
    new_value character varying(255),
    create_dt timestamp(6) with time zone NOT NULL,
    update_dt timestamp(6) with time zone,
    profiled_by character varying(255) NOT NULL,
    profiler_type character varying(255) NOT NULL,
    info character varying(255),
    msisdn character varying(255),
    key_value character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.agents_activity_logs OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 267108)
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
-- TOC entry 639 (class 1259 OID 323884)
-- Name: agents_backup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_backup (
    name character varying(60),
    last_signin_dt timestamp(6) without time zone,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    email character varying NOT NULL,
    status boolean,
    msisdn character varying,
    extension character varying,
    profile_image_url character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.agents_backup OWNER TO postgres;

--
-- TOC entry 646 (class 1259 OID 324001)
-- Name: agents_removed_20230607; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_removed_20230607 (
    name character varying(60),
    last_signin_dt timestamp(6) without time zone,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    id character varying(255),
    email character varying,
    status boolean,
    msisdn character varying,
    extension character varying,
    profile_image_url character varying,
    guid character varying(255)
);


ALTER TABLE public.agents_removed_20230607 OWNER TO postgres;

--
-- TOC entry 640 (class 1259 OID 323896)
-- Name: agri_businesess_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agri_businesess_tags (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.agri_businesess_tags OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 267110)
-- Name: ahmed_base; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ahmed_base (
    msisdn character varying(255)
);


ALTER TABLE public.ahmed_base OWNER TO postgres;

--
-- TOC entry 688 (class 1259 OID 412303)
-- Name: alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alerts (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    polygon jsonb NOT NULL,
    title_en text,
    text_en text,
    title_ur text,
    text_ur text,
    hyper_link text,
    posted_on text,
    title text,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    data json,
    location_id character varying(255),
    category character varying(225)
);


ALTER TABLE public.alerts OWNER TO postgres;

--
-- TOC entry 820 (class 1259 OID 663192)
-- Name: anomalies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.anomalies (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.anomalies OWNER TO postgres;

--
-- TOC entry 813 (class 1259 OID 647741)
-- Name: anomaly_response; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.anomaly_response (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    ai_response json,
    feedback boolean,
    is_response_added boolean,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone,
    farm_id character varying(255),
    anomaly_dt date,
    is_correct_crop boolean,
    is_correct_disease boolean,
    advisory_feedback smallint
);


ALTER TABLE public.anomaly_response OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 267113)
-- Name: api_call_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_call_details (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    auth_enabled smallint DEFAULT 0 NOT NULL,
    auth_type smallint DEFAULT 1 NOT NULL,
    token character varying(255) DEFAULT NULL::character varying,
    method character varying(255) NOT NULL,
    url character varying(255) NOT NULL,
    body text,
    query_string character varying(255) DEFAULT NULL::character varying,
    update_core smallint DEFAULT 1 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    headers text,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.api_call_details OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 267128)
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
-- TOC entry 9774 (class 0 OID 0)
-- Dependencies: 229
-- Name: api_call_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_call_details_id_seq OWNED BY public.api_call_details.id;


--
-- TOC entry 685 (class 1259 OID 406400)
-- Name: api_call_details_updated; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_call_details_updated (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    auth_enabled smallint DEFAULT 0 NOT NULL,
    auth_type smallint DEFAULT 1 NOT NULL,
    token character varying(255) DEFAULT NULL::character varying,
    method character varying(255) NOT NULL,
    url character varying(255) NOT NULL,
    body text,
    query_string character varying(255) DEFAULT NULL::character varying,
    update_core smallint DEFAULT 1 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    headers text,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.api_call_details_updated OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 267130)
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
-- TOC entry 231 (class 1259 OID 267132)
-- Name: api_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_permissions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.api_permissions OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 267140)
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
-- TOC entry 9779 (class 0 OID 0)
-- Dependencies: 232
-- Name: api_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_permissions_id_seq OWNED BY public.api_permissions.id;


--
-- TOC entry 233 (class 1259 OID 267142)
-- Name: api_resource_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_resource_category (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.api_resource_category OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 267150)
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
-- TOC entry 9782 (class 0 OID 0)
-- Dependencies: 234
-- Name: api_resource_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_resource_category_id_seq OWNED BY public.api_resource_category.id;


--
-- TOC entry 235 (class 1259 OID 267152)
-- Name: api_resource_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_resource_permissions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    resource_id character varying(255) NOT NULL,
    permission_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.api_resource_permissions OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 267160)
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
-- TOC entry 9785 (class 0 OID 0)
-- Dependencies: 236
-- Name: api_resource_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_resource_permissions_id_seq OWNED BY public.api_resource_permissions.id;


--
-- TOC entry 237 (class 1259 OID 267162)
-- Name: api_resource_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_resource_roles (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    role_id character varying(255) NOT NULL,
    resource_id character varying(255) NOT NULL,
    permission_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.api_resource_roles OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 267171)
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
-- TOC entry 9788 (class 0 OID 0)
-- Dependencies: 238
-- Name: api_resource_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_resource_roles_id_seq OWNED BY public.api_resource_roles.id;


--
-- TOC entry 239 (class 1259 OID 267173)
-- Name: api_resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_resources (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    path character varying NOT NULL,
    path_regex character varying NOT NULL,
    category_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.api_resources OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 267181)
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
-- TOC entry 9791 (class 0 OID 0)
-- Dependencies: 240
-- Name: api_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_resources_id_seq OWNED BY public.api_resources.id;


--
-- TOC entry 241 (class 1259 OID 267183)
-- Name: loan_agreements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_agreements (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone,
    application_id character varying(255) NOT NULL,
    update_dt timestamp(6) without time zone,
    type_id character varying(255),
    worth numeric(10,2),
    procurement_price numeric(10,2),
    procurement_unit character varying,
    procurement_crop bigint,
    service_charges numeric(10,2),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_agreements OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 267191)
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
-- TOC entry 9794 (class 0 OID 0)
-- Dependencies: 242
-- Name: application_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.application_docs_id_seq OWNED BY public.loan_agreements.id;


--
-- TOC entry 243 (class 1259 OID 267193)
-- Name: application_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.application_status (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.application_status OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 267203)
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
-- TOC entry 9797 (class 0 OID 0)
-- Dependencies: 244
-- Name: application_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.application_status_id_seq OWNED BY public.application_status.id;


--
-- TOC entry 245 (class 1259 OID 267205)
-- Name: badges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.badges (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(25) NOT NULL,
    image_url character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.badges OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 267213)
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
-- TOC entry 9800 (class 0 OID 0)
-- Dependencies: 246
-- Name: badges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.badges_id_seq OWNED BY public.badges.id;


--
-- TOC entry 641 (class 1259 OID 323908)
-- Name: banners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.banners (
    id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    title character varying(150),
    description character varying(255),
    image_url character varying(255),
    content_id character varying(255),
    app_data boolean,
    status boolean,
    "order" integer
);


ALTER TABLE public.banners OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 267215)
-- Name: bkk_wrong_charging; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bkk_wrong_charging (
    msisdn character varying(15),
    last_sub_dt timestamp(6) without time zone,
    sub_mode character varying(15),
    network_type character varying(15),
    last_charge_dt timestamp(6) without time zone
);


ALTER TABLE public.bkk_wrong_charging OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 267218)
-- Name: blacklist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.blacklist (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 0 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.blacklist OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 267229)
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
-- TOC entry 9805 (class 0 OID 0)
-- Dependencies: 249
-- Name: blacklist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.blacklist_id_seq OWNED BY public.blacklist.id;


--
-- TOC entry 647 (class 1259 OID 324007)
-- Name: business; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.business (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    address text,
    lat character varying(255),
    lng character varying(255),
    tehsil character varying(255),
    district character varying(255),
    is_verified boolean,
    email character varying(255),
    phone_number character varying(255),
    fax_number character varying(255),
    website character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    subcategory_id character varying(255),
    is_deleted boolean DEFAULT false,
    fkey character varying(255),
    bid character varying(255),
    compound_a character varying(255),
    priority character varying(255),
    type character varying(255),
    unique_title character varying(255),
    location_id character varying(255)
);


ALTER TABLE public.business OWNER TO postgres;

--
-- TOC entry 642 (class 1259 OID 323961)
-- Name: business_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.business_categories (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255),
    parent_id character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.business_categories OWNER TO postgres;

--
-- TOC entry 643 (class 1259 OID 323971)
-- Name: business_contact_person; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.business_contact_person (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    business_id character varying(255),
    contact_person_id character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.business_contact_person OWNER TO postgres;

--
-- TOC entry 644 (class 1259 OID 323981)
-- Name: business_media_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.business_media_files (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    business_id character varying(255),
    media_path text,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.business_media_files OWNER TO postgres;

--
-- TOC entry 645 (class 1259 OID 323991)
-- Name: business_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.business_tags (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    business_id character varying(255),
    tag_id character varying(255) DEFAULT CURRENT_TIMESTAMP,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.business_tags OWNER TO postgres;

--
-- TOC entry 782 (class 1259 OID 559274)
-- Name: buyer_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.buyer_types (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    active boolean DEFAULT true NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.buyer_types OWNER TO postgres;

--
-- TOC entry 805 (class 1259 OID 640450)
-- Name: buyers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.buyers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying,
    buyer_type character varying,
    is_kats_buyer boolean DEFAULT false,
    is_shopify_buyer boolean DEFAULT false,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.buyers OWNER TO postgres;

--
-- TOC entry 681 (class 1259 OID 389320)
-- Name: call_end_notification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_end_notification (
    id character varying(50) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(20),
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(6) without time zone
);


ALTER TABLE public.call_end_notification OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 267231)
-- Name: call_hangup_cause; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.call_hangup_cause (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) NOT NULL,
    call_uuid character varying(255) NOT NULL,
    cause_code character varying(10) DEFAULT NULL::character varying,
    cause_txt character varying(255) DEFAULT NULL::character varying,
    ringing_time timestamp(6) without time zone,
    updatecount bigint DEFAULT '0'::bigint NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.call_hangup_cause OWNER TO postgres;

--
-- TOC entry 689 (class 1259 OID 502717)
-- Name: campaign_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_categories (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    campaign_category character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_categories OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 267252)
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
-- TOC entry 692 (class 1259 OID 502757)
-- Name: campaign_file_name_apis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_file_name_apis (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    action_id character varying(255) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_file_name_apis OWNER TO postgres;

--
-- TOC entry 693 (class 1259 OID 502782)
-- Name: campaign_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_files (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    content_file_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    seq_order integer DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_files OWNER TO postgres;

--
-- TOC entry 694 (class 1259 OID 502793)
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
-- TOC entry 9820 (class 0 OID 0)
-- Dependencies: 694
-- Name: campaign_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_files_id_seq OWNED BY public.campaign_files.id;


--
-- TOC entry 703 (class 1259 OID 502893)
-- Name: campaign_operator; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_operator (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    operator_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_operator OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 267275)
-- Name: campaign_operator_a_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campaign_operator_a_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.campaign_operator_a_seq OWNER TO postgres;

--
-- TOC entry 704 (class 1259 OID 502913)
-- Name: campaign_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_profiles (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(15) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    campaign_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_profiles OWNER TO postgres;

--
-- TOC entry 705 (class 1259 OID 502923)
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
-- TOC entry 9825 (class 0 OID 0)
-- Dependencies: 705
-- Name: campaign_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_profiles_id_seq OWNED BY public.campaign_profiles.id;


--
-- TOC entry 706 (class 1259 OID 502932)
-- Name: campaign_promo_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_promo_data (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying NOT NULL,
    campaign_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_meta_data json
);


ALTER TABLE public.campaign_promo_data OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 267298)
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
-- TOC entry 707 (class 1259 OID 502945)
-- Name: campaign_recording_end_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_recording_end_files (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    content_file_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    seq_order integer DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_recording_end_files OWNER TO postgres;

--
-- TOC entry 708 (class 1259 OID 502956)
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
-- TOC entry 9830 (class 0 OID 0)
-- Dependencies: 708
-- Name: campaign_recording_end_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_recording_end_files_id_seq OWNED BY public.campaign_recording_end_files.id;


--
-- TOC entry 675 (class 1259 OID 371821)
-- Name: campaign_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    selector character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_types OWNER TO postgres;

--
-- TOC entry 709 (class 1259 OID 502970)
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
-- TOC entry 9833 (class 0 OID 0)
-- Dependencies: 709
-- Name: campaign_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campaign_types_id_seq OWNED BY public.campaign_types.id;


--
-- TOC entry 710 (class 1259 OID 502972)
-- Name: campaign_validation_apis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campaign_validation_apis (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    action_id character varying(255) NOT NULL,
    campaign_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp without time zone,
    title character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.campaign_validation_apis OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 267323)
-- Name: case_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.case_categories (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    parent_id character varying(255),
    font character varying(255),
    content_table character varying(255),
    mandatory_fields character varying[],
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.case_categories OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 267331)
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
-- TOC entry 9837 (class 0 OID 0)
-- Dependencies: 255
-- Name: case_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.case_categories_id_seq OWNED BY public.case_categories.id;


--
-- TOC entry 256 (class 1259 OID 267333)
-- Name: case_media_contents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.case_media_contents (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    file_path character varying NOT NULL,
    type character varying NOT NULL,
    case_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.case_media_contents OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 267341)
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
-- TOC entry 9840 (class 0 OID 0)
-- Dependencies: 257
-- Name: case_media_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.case_media_contents_id_seq OWNED BY public.case_media_contents.id;


--
-- TOC entry 258 (class 1259 OID 267343)
-- Name: case_parameters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.case_parameters (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    case_id character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    value character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.case_parameters OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 267352)
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
-- TOC entry 9843 (class 0 OID 0)
-- Dependencies: 259
-- Name: case_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.case_parameters_id_seq OWNED BY public.case_parameters.id;


--
-- TOC entry 260 (class 1259 OID 267354)
-- Name: case_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.case_tags (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    case_id character varying(255),
    tag_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.case_tags OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 267362)
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
-- TOC entry 9846 (class 0 OID 0)
-- Dependencies: 261
-- Name: case_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.case_tags_id_seq OWNED BY public.case_tags.id;


--
-- TOC entry 262 (class 1259 OID 267364)
-- Name: cases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cases (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying,
    disease character varying,
    description character varying,
    title character varying(255) DEFAULT NULL::character varying,
    category character varying(255) DEFAULT NULL::character varying NOT NULL,
    crop character varying(255) DEFAULT NULL::character varying,
    pests character varying(255) DEFAULT NULL::character varying,
    weeds character varying(255) DEFAULT NULL::character varying,
    case_report_dt timestamp(6) with time zone DEFAULT CURRENT_DATE,
    sub_category character varying(255) DEFAULT NULL::character varying NOT NULL,
    status character varying DEFAULT 'Pending'::character varying,
    profiled_by character varying,
    profiler_type character varying,
    create_dt timestamp(6) with time zone,
    update_dt timestamp(6) with time zone,
    agent_id character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    category_type character varying(255),
    location_id character varying(255)
);


ALTER TABLE public.cases OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 267380)
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
-- TOC entry 9849 (class 0 OID 0)
-- Dependencies: 263
-- Name: cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cases_id_seq OWNED BY public.cases.id;


--
-- TOC entry 264 (class 1259 OID 267382)
-- Name: cc_agents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cc_agents (
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name character varying(60),
    email character varying(255) NOT NULL,
    msisdn character varying
);


ALTER TABLE public.cc_agents OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 267389)
-- Name: cc_call_end_survey_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cc_call_end_survey_logs (
    id character varying(100) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(11) NOT NULL,
    dt timestamp(6) without time zone NOT NULL,
    unique_id character varying(50) NOT NULL,
    activity_type character varying(50) NOT NULL,
    duration character varying(50) NOT NULL,
    dtmf character varying(50) NOT NULL,
    context character varying NOT NULL,
    survey_id character varying(100) NOT NULL,
    channel_id character varying(100) NOT NULL
);


ALTER TABLE public.cc_call_end_survey_logs OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 267396)
-- Name: cc_call_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cc_call_logs (
    id character varying(40) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    caller character varying(25) NOT NULL,
    daily_call_count smallint DEFAULT '0'::smallint NOT NULL,
    paidwall_id character varying(40) NOT NULL,
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dt timestamp(6) without time zone DEFAULT NULL::timestamp without time zone
);


ALTER TABLE public.cc_call_logs OWNER TO postgres;

--
-- TOC entry 817 (class 1259 OID 659010)
-- Name: cc_engaged_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cc_engaged_users (
    engaged_dt date NOT NULL,
    msisdn character varying(15),
    mode character varying(20),
    queue character varying(50),
    agent_name character varying(50),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
)
PARTITION BY RANGE (engaged_dt);


ALTER TABLE public.cc_engaged_users OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 267403)
-- Name: cc_msisdn_check_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cc_msisdn_check_profile (
    id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.cc_msisdn_check_profile OWNER TO postgres;

--
-- TOC entry 637 (class 1259 OID 323776)
-- Name: cc_outbound_whitelist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cc_outbound_whitelist (
    msisdn character varying(11) NOT NULL
);


ALTER TABLE public.cc_outbound_whitelist OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 267407)
-- Name: cdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cdr (
    calldate timestamp(6) without time zone DEFAULT '1000-01-01 00:00:00'::timestamp without time zone NOT NULL,
    clid character varying(80) NOT NULL,
    src character varying(80) DEFAULT ''::character varying NOT NULL,
    dst character varying(80) DEFAULT ''::character varying NOT NULL,
    dcontext character varying(80) DEFAULT ''::character varying NOT NULL,
    channel character varying(80) DEFAULT ''::character varying NOT NULL,
    dstchannel character varying(80) DEFAULT ''::character varying NOT NULL,
    lastapp character varying(80) DEFAULT ''::character varying NOT NULL,
    lastdata character varying(80) DEFAULT ''::character varying NOT NULL,
    callid character varying(255) DEFAULT ' '::character varying,
    duration integer DEFAULT 0 NOT NULL,
    billsec integer DEFAULT 0 NOT NULL,
    disposition character varying(45) DEFAULT ''::character varying NOT NULL,
    amaflags integer DEFAULT 0 NOT NULL,
    accountcode character varying(20) DEFAULT ''::character varying NOT NULL,
    uniqueid character varying(32) DEFAULT ''::character varying NOT NULL,
    userfield character varying(255) DEFAULT ''::character varying NOT NULL,
    did character varying(50) DEFAULT ''::character varying NOT NULL,
    recordingfile character varying(255) DEFAULT ''::character varying NOT NULL,
    cnum character varying(80) DEFAULT ''::character varying NOT NULL,
    cnam character varying(80) DEFAULT ''::character varying NOT NULL,
    outbound_cnum character varying(80) DEFAULT ''::character varying NOT NULL,
    outbound_cnam character varying(80) DEFAULT ''::character varying NOT NULL,
    dst_cnam character varying(80) DEFAULT ''::character varying NOT NULL,
    linkedid character varying(32) DEFAULT ''::character varying NOT NULL,
    peeraccount character varying(80) DEFAULT ''::character varying NOT NULL,
    sequence integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.cdr OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 267439)
-- Name: cdr_asterisk; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cdr_asterisk (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    calldate timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    clid character varying(80) DEFAULT ''::character varying NOT NULL,
    src character varying(80) DEFAULT ''::character varying NOT NULL,
    dst character varying(80) DEFAULT ''::character varying NOT NULL,
    dcontext character varying(255) DEFAULT ''::character varying NOT NULL,
    channel character varying(255) DEFAULT ''::character varying NOT NULL,
    dstchannel character varying(255) DEFAULT ''::character varying NOT NULL,
    lastapp character varying(255) DEFAULT ''::character varying NOT NULL,
    lastdata character varying(255) DEFAULT ''::character varying NOT NULL,
    duration integer DEFAULT 0 NOT NULL,
    billsec integer DEFAULT 0 NOT NULL,
    disposition character varying(255) DEFAULT ''::character varying NOT NULL,
    amaflags integer DEFAULT 0 NOT NULL,
    accountcode character varying(255) DEFAULT ''::character varying NOT NULL,
    uniqueid character varying(255) DEFAULT ''::character varying NOT NULL,
    userfield character varying(255) DEFAULT ''::character varying NOT NULL,
    did character varying(255) DEFAULT ''::character varying NOT NULL,
    recordingfile character varying(255) DEFAULT ''::character varying NOT NULL,
    uuid character varying(255) DEFAULT NULL::character varying,
    serverip character varying(255) DEFAULT NULL::character varying,
    callfile_name character varying(255) DEFAULT NULL::character varying,
    trunk_name character varying(255) DEFAULT NULL::character varying,
    stasis_name character varying(255) DEFAULT NULL::character varying,
    from_number character varying(255) DEFAULT NULL::character varying,
    to_number character varying(255) DEFAULT NULL::character varying,
    jobid character varying(255),
    survey_id character varying(255),
    campaign_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.cdr_asterisk OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 267472)
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
-- TOC entry 9859 (class 0 OID 0)
-- Dependencies: 270
-- Name: cdr_asterisk_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cdr_asterisk_id_seq OWNED BY public.cdr_asterisk.id;


--
-- TOC entry 271 (class 1259 OID 267474)
-- Name: chashma_operator_tagg; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chashma_operator_tagg (
    msisdn character varying(255),
    operator character varying(50)
);


ALTER TABLE public.chashma_operator_tagg OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 267477)
-- Name: chasmha_operator_check; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chasmha_operator_check (
    msisdn character varying(255)
);


ALTER TABLE public.chasmha_operator_check OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 267480)
-- Name: clauses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clauses (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    value numeric(10,2),
    description character varying(255),
    loan_agreement_id character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(25),
    attachment character varying(255),
    service_charges numeric(10,2),
    receiving_date date,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.clauses OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 267490)
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
-- TOC entry 9864 (class 0 OID 0)
-- Dependencies: 274
-- Name: clauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clauses_id_seq OWNED BY public.clauses.id;


--
-- TOC entry 779 (class 1259 OID 519700)
-- Name: community_blacklist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_blacklist (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    farmer_id character varying(255),
    msisdn character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.community_blacklist OWNER TO postgres;

--
-- TOC entry 648 (class 1259 OID 324020)
-- Name: contact_person; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contact_person (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255),
    email character varying(255),
    phone_number character varying(255),
    fax_number character varying(255),
    is_verified boolean,
    image_url character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    source character varying(255)
);


ALTER TABLE public.contact_person OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 267492)
-- Name: content_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.content_files (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    file_name character varying(255) DEFAULT NULL::character varying NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    folder_path character varying(255) NOT NULL,
    folder_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.content_files OWNER TO postgres;

--
-- TOC entry 711 (class 1259 OID 502996)
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
-- TOC entry 9869 (class 0 OID 0)
-- Dependencies: 711
-- Name: content_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.content_files_id_seq OWNED BY public.content_files.id;


--
-- TOC entry 276 (class 1259 OID 267506)
-- Name: content_folders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.content_folders (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    folder_path character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.content_folders OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 267518)
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
-- TOC entry 9872 (class 0 OID 0)
-- Dependencies: 277
-- Name: content_folders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.content_folders_id_seq OWNED BY public.content_folders.id;


--
-- TOC entry 278 (class 1259 OID 267520)
-- Name: crop_calender; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    land_topography_id character varying(255) NOT NULL,
    sowing_method_id character varying(255) NOT NULL,
    text_ur text,
    text_en text,
    content_url text,
    advisory_on integer NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crop_calender OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 267530)
-- Name: crop_calender_crops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_crops (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_id character varying(255) NOT NULL,
    crop_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crop_calender_crops OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 267540)
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
-- TOC entry 9876 (class 0 OID 0)
-- Dependencies: 280
-- Name: crop_calender_crops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_calender_crops_id_seq OWNED BY public.crop_calender_crops.id;


--
-- TOC entry 281 (class 1259 OID 267542)
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
-- TOC entry 9878 (class 0 OID 0)
-- Dependencies: 281
-- Name: crop_calender_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_calender_id_seq OWNED BY public.crop_calender.id;


--
-- TOC entry 282 (class 1259 OID 267544)
-- Name: crop_calender_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_locations (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_id character varying(255) NOT NULL,
    location_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crop_calender_locations OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 267554)
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
-- TOC entry 9881 (class 0 OID 0)
-- Dependencies: 283
-- Name: crop_calender_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_calender_locations_id_seq OWNED BY public.crop_calender_locations.id;


--
-- TOC entry 284 (class 1259 OID 267556)
-- Name: crop_calender_weather_favourable_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_weather_favourable_conditions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_id character varying(255) NOT NULL,
    weather_condition_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crop_calender_weather_favourable_conditions OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 267566)
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
-- TOC entry 9884 (class 0 OID 0)
-- Dependencies: 285
-- Name: crop_calender_weather_favourable_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_calender_weather_favourable_conditions_id_seq OWNED BY public.crop_calender_weather_favourable_conditions.id;


--
-- TOC entry 286 (class 1259 OID 267568)
-- Name: crop_calender_weather_unfavourable_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_calender_weather_unfavourable_conditions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_calender_id character varying(255) NOT NULL,
    weather_condition_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crop_calender_weather_unfavourable_conditions OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 267578)
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
-- TOC entry 9887 (class 0 OID 0)
-- Dependencies: 287
-- Name: crop_calender_weather_unfavourable_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_calender_weather_unfavourable_conditions_id_seq OWNED BY public.crop_calender_weather_unfavourable_conditions.id;


--
-- TOC entry 288 (class 1259 OID 267580)
-- Name: crop_diseases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_diseases (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    name_alt character varying(255),
    content_id character varying(255),
    category character varying(255),
    title_urdu character varying(255),
    "order" integer,
    file_name character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255)
);


ALTER TABLE public.crop_diseases OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 267589)
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
-- TOC entry 9890 (class 0 OID 0)
-- Dependencies: 289
-- Name: crop_diseases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_diseases_id_seq OWNED BY public.crop_diseases.id;


--
-- TOC entry 290 (class 1259 OID 267591)
-- Name: growth_stages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.growth_stages (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    level integer,
    parent_id character varying(255),
    title_urdu character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.growth_stages OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 267599)
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
-- TOC entry 9893 (class 0 OID 0)
-- Dependencies: 291
-- Name: crop_growth_stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crop_growth_stages_id_seq OWNED BY public.growth_stages.id;


--
-- TOC entry 292 (class 1259 OID 267601)
-- Name: crop_insects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_insects (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    title_urdu character varying(255),
    file_name character varying(255),
    content_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255)
);


ALTER TABLE public.crop_insects OWNER TO postgres;

--
-- TOC entry 682 (class 1259 OID 390399)
-- Name: crop_season; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_season (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    title_urdu character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.crop_season OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 267625)
-- Name: crops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crops (
    crop_type character varying(255),
    image_url character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    name_alt character varying(255),
    content_id character varying(255),
    title character varying NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title_urdu character varying,
    status boolean,
    "order" integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    app_data boolean,
    advisory smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.crops OWNER TO postgres;

--
-- TOC entry 777 (class 1259 OID 519311)
-- Name: farmcrops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmcrops (
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    sowing_method_id character varying(255),
    cultivated_area double precision,
    seed_type_id character varying(255),
    crop_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    farm_id character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_season_id uuid,
    seq_order integer DEFAULT 0
);


ALTER TABLE public.farmcrops OWNER TO postgres;

--
-- TOC entry 322 (class 1259 OID 267810)
-- Name: farmers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmers (
    id character varying(255) NOT NULL,
    cnic character varying(15),
    name character varying(60),
    email character varying(60),
    location_id character varying(255),
    address character varying(100),
    status smallint,
    create_dt timestamp without time zone,
    update_dt timestamp without time zone,
    language_id character varying(255),
    occupation character varying,
    gender character varying,
    dob date,
    phone_type character varying,
    profiled_by character varying,
    profile_image character varying,
    profiler_type character varying,
    key character varying,
    occupation_id character varying(255),
    fcm_token character varying,
    cnic_front_image character varying,
    cnic_back_image character varying,
    cnic_issue_date date,
    total_incentive_ammount bigint,
    badge_id bigint,
    default_location_enabled boolean,
    last_sms_in_dt timestamp without time zone,
    last_sms_out_dt timestamp without time zone,
    last_ivr_dt timestamp without time zone,
    last_obd_dt timestamp without time zone,
    recent_activity_dt timestamp without time zone,
    in_app_enabled boolean DEFAULT true NOT NULL,
    obd_enabled boolean DEFAULT true NOT NULL,
    sms_enabled boolean DEFAULT true NOT NULL,
    is_cc_blocked boolean DEFAULT false NOT NULL,
    is_blocked boolean DEFAULT false NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    comments text,
    is_verified boolean,
    profile_level_id character varying,
    transaction_id character varying,
    gender_id character varying,
    lat numeric(8,6),
    lng numeric(8,6),
    wallet_consent character varying(255),
    reference_id character varying,
    is_expert boolean DEFAULT false,
    blacklisted boolean DEFAULT false,
    buyer boolean DEFAULT false,
    shopify_customer_id character varying(255)
);


ALTER TABLE public.farmers OWNER TO postgres;

--
-- TOC entry 324 (class 1259 OID 267834)
-- Name: farms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farms (
    land_area double precision,
    land_unit character varying(255),
    location_id character varying(255),
    is_default smallint,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    soil_type_id character varying(255) DEFAULT 'bb6d4451-abc1-4ec8-92e7-4901c122cb67'::character varying NOT NULL,
    irrigation_source_id character varying(255),
    soil_issue_id character varying(255),
    farm_title character varying,
    lat numeric(8,6),
    lng numeric(8,6),
    land_topography_id character varying(255),
    shape public.geometry(Geometry,4326),
    geo_point public.geometry,
    address character varying,
    farmer_id character varying NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    profiled_by character varying,
    profiler_type character varying,
    is_model_farm boolean DEFAULT false,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    shape_id character varying,
    temp_id character varying,
    issue_in_farm boolean,
    image text,
    seq_order integer DEFAULT 0
);


ALTER TABLE public.farms OWNER TO postgres;

--
-- TOC entry 418 (class 1259 OID 268379)
-- Name: locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.locations (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    type character varying,
    parent_id character varying(255),
    name_alt character varying,
    shape public.geometry(MultiPolygon,4326),
    geo_point public.geometry(Point,4326),
    priority integer DEFAULT 100 NOT NULL,
    file_name character varying,
    content_id character varying(255),
    name_urdu character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    location_id character varying(32)
);


ALTER TABLE public.locations OWNER TO postgres;

--
-- TOC entry 778 (class 1259 OID 519368)
-- Name: crop_segregation_material; Type: MATERIALIZED VIEW; Schema: public; Owner: bkkdev_rw
--

CREATE MATERIALIZED VIEW public.crop_segregation_material AS
 SELECT subquery.crops,
    subquery.crop_id,
    sum(subquery.farmers) AS sum,
    subquery.location,
    subquery.location_id
   FROM ( SELECT DISTINCT d.title AS crops,
            d.id AS crop_id,
            count(DISTINCT a.id) AS farmers,
                CASE
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Balochistan'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Balochistan'::text))))) THEN 'Balochistan'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Khyber Pakhtunkhwa'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Khyber Pakhtunkhwa'::text))))) THEN 'Khyber Pakhtunkhwa'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Punjab'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Punjab'::text))))) THEN 'Punjab'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Sindh'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Sindh'::text))))) THEN 'Sindh'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Gilgit Baltistan'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Gilgit Baltistan'::text))))) THEN 'Gilgit Baltistan'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Azad Jammu & Kashmir'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Azad Jammu & Kashmir'::text))))) THEN 'Azad Jammu & Kashmir'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Federal Capital Territory'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Federal Capital Territory'::text))))) THEN 'Federal Capital Territory'::text
                    ELSE NULL::text
                END AS location,
                CASE
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Balochistan'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Balochistan'::text))))) THEN '832b078e-d37f-676f-cd74-f70ce1c69b8b'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Khyber Pakhtunkhwa'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Khyber Pakhtunkhwa'::text))))) THEN 'f9656399-e3df-8ef4-4479-16e45cd22b43'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Punjab'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Punjab'::text))))) THEN '9e438650-0907-83b9-aadb-22ee76aabf71'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Sindh'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Sindh'::text))))) THEN '9b979684-2db1-57c4-3348-65de144e398f'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Gilgit Baltistan'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Gilgit Baltistan'::text))))) THEN '0a1404f5-816d-460e-35fd-6e62362e19f3'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Azad Jammu & Kashmir'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Azad Jammu & Kashmir'::text))))) THEN '97665e76-9af2-9a1c-e272-ab69e12588cf'::text
                    WHEN ((a.location_id)::text IN ( SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.parent_id)::text IN ( SELECT locations_2.id
                                       FROM public.locations locations_2
                                      WHERE ((locations_2.name)::text = 'Federal Capital Territory'::text)))))
                    UNION ALL
                     SELECT locations.id
                       FROM public.locations
                      WHERE ((locations.parent_id)::text IN ( SELECT locations_1.id
                               FROM public.locations locations_1
                              WHERE ((locations_1.name)::text = 'Federal Capital Territory'::text))))) THEN '84655b4f-e62b-c65c-6dec-ca53b090939e'::text
                    ELSE NULL::text
                END AS location_id
           FROM ((((public.farmers a
             LEFT JOIN public.farms b ON (((a.id)::text = (b.farmer_id)::text)))
             LEFT JOIN public.farmcrops c ON (((c.farm_id)::text = (b.id)::text)))
             LEFT JOIN public.crops d ON (((d.id)::text = (c.crop_id)::text)))
             LEFT JOIN public.locations e ON (((b.location_id)::text = (e.id)::text)))
          WHERE ((d.id IS NOT NULL) AND (a.location_id IS NOT NULL))
          GROUP BY d.title, d.id, a.location_id) subquery
  GROUP BY subquery.crops, subquery.crop_id, subquery.location, subquery.location_id
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.crop_segregation_material OWNER TO bkkdev_rw;

--
-- TOC entry 293 (class 1259 OID 267610)
-- Name: crop_testing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_testing (
    msisdn character varying(255),
    crop_name character varying(255),
    crop_id character varying(255),
    crop_variety character varying(255),
    variety_id character varying(255),
    recognized_text character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crop_testing OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 267617)
-- Name: crop_variety_ml; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crop_variety_ml (
    title_urdu character varying(255),
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crop_variety_ml OWNER TO postgres;

--
-- TOC entry 649 (class 1259 OID 324030)
-- Name: crops_2023_07_26; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crops_2023_07_26 (
    crop_type character varying(255),
    image_url character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    name_alt character varying(255),
    content_id character varying(255),
    title character varying NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title_urdu character varying,
    status boolean,
    "order" integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    app_data boolean
);


ALTER TABLE public.crops_2023_07_26 OWNER TO postgres;

--
-- TOC entry 650 (class 1259 OID 324043)
-- Name: crops_backup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crops_backup (
    crop_type character varying(255),
    image_url character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    name_alt character varying(255),
    content_id bigint NOT NULL,
    title character varying NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title_urdu character varying,
    status boolean,
    "order" integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crops_backup OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 267634)
-- Name: crops_data_ml; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crops_data_ml (
    title_urdu character varying(255),
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crops_data_ml OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 267642)
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
-- TOC entry 9908 (class 0 OID 0)
-- Dependencies: 297
-- Name: crops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.crops_id_seq OWNED BY public.crops.id;


--
-- TOC entry 298 (class 1259 OID 267644)
-- Name: crops_lightsail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.crops_lightsail (
    crop_type character varying(255),
    image_url character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    name_alt character varying(255),
    content_id bigint NOT NULL,
    title character varying NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title_urdu character varying,
    status boolean,
    "order" integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.crops_lightsail OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 267652)
-- Name: cross_promo_DTMF_subs ; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."cross_promo_DTMF_subs " (
    msisdn character varying(255),
    campaign character varying(255),
    response character varying(255),
    "timestamp" character varying(255)
);


ALTER TABLE public."cross_promo_DTMF_subs " OWNER TO postgres;

--
-- TOC entry 300 (class 1259 OID 267658)
-- Name: cross_promo_dtmf_sub; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cross_promo_dtmf_sub (
    id integer NOT NULL,
    date date DEFAULT CURRENT_DATE,
    msisdn character varying(255) NOT NULL
);


ALTER TABLE public.cross_promo_dtmf_sub OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 267662)
-- Name: cross_promo_dtmf_sub_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cross_promo_dtmf_sub_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cross_promo_dtmf_sub_id_seq OWNER TO postgres;

--
-- TOC entry 9913 (class 0 OID 0)
-- Dependencies: 301
-- Name: cross_promo_dtmf_sub_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cross_promo_dtmf_sub_id_seq OWNED BY public.cross_promo_dtmf_sub.id;


--
-- TOC entry 302 (class 1259 OID 267664)
-- Name: csm_farmcrops_garaj; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.csm_farmcrops_garaj (
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    sowing_method_id bigint,
    cultivated_area double precision,
    seed_type_id bigint,
    crop_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    farm_id character varying,
    id character varying
);


ALTER TABLE public.csm_farmcrops_garaj OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 267670)
-- Name: csm_farmers_garaj; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.csm_farmers_garaj (
    id character varying(15),
    cnic character varying(15),
    name character varying(60),
    email character varying(60),
    location_id character varying(255),
    address character varying(100),
    status smallint,
    create_dt timestamp(6) with time zone,
    update_dt timestamp(6) with time zone,
    language_id character varying(255),
    occupation character varying,
    gender character varying,
    dob date,
    phone_type character varying,
    profiled_by character varying,
    profile_image character varying,
    profiler_type character varying,
    key character varying,
    occupation_id character varying(255),
    fcm_token character varying,
    cnic_front_image character varying,
    cnic_back_image character varying,
    default_location_enabled boolean,
    cnic_issue_date date,
    total_incentive_ammount bigint,
    badge_id bigint,
    is_blocked boolean,
    in_app_enabled boolean,
    obd_enabled boolean,
    sms_enabled boolean,
    is_cc_blocked boolean
);


ALTER TABLE public.csm_farmers_garaj OWNER TO postgres;

--
-- TOC entry 304 (class 1259 OID 267676)
-- Name: csm_farms_garaj; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.csm_farms_garaj (
    land_area double precision,
    land_unit character varying(255),
    location_id character varying(255),
    is_default smallint,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    soil_type_id bigint,
    irrigation_source_id bigint,
    soil_issue_id bigint,
    farm_title character varying,
    lat numeric(8,6),
    lng numeric(8,6),
    land_topography_id bigint,
    shape public.geometry,
    geo_point public.geometry,
    address character varying,
    farmer_id character varying,
    id character varying,
    profiled_by character varying,
    profiler_type character varying,
    is_model_farm boolean
);


ALTER TABLE public.csm_farms_garaj OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 267682)
-- Name: csm_subscribers_garaj; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.csm_subscribers_garaj (
    msisdn character varying(15),
    country_code character varying(5),
    location_id character varying(255),
    first_sub_dt timestamp(6) without time zone,
    last_sub_dt timestamp(6) without time zone,
    last_charge_dt timestamp(6) without time zone,
    grace_expire_dt timestamp(6) without time zone,
    firebase_session character varying(255),
    last_signin_dt timestamp(6) without time zone,
    operator_id character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    lat numeric(8,6),
    lng numeric(8,6),
    language_id character varying(255),
    sub_mode_id character varying(255),
    last_call_dt timestamp(6) without time zone,
    recent_activity_dt timestamp(6) without time zone,
    is_charging_enabled boolean,
    profiled_by character varying,
    profiler_type character varying,
    source character varying,
    is_blocked boolean,
    is_purged boolean,
    last_purge_date timestamp(6) without time zone,
    charge_count integer,
    category_type character varying,
    default_location_enabled boolean,
    dbss_sync_dt timestamp(6) without time zone,
    next_charge_dt timestamp(6) without time zone,
    call_success bigint,
    is_verified boolean
);


ALTER TABLE public.csm_subscribers_garaj OWNER TO postgres;

--
-- TOC entry 306 (class 1259 OID 267688)
-- Name: districts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.districts (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    province_id character varying(255) NOT NULL,
    active smallint NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.districts OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 267696)
-- Name: drl_count_ml; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drl_count_ml (
    id integer NOT NULL,
    count integer,
    create_dt timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone
);


ALTER TABLE public.drl_count_ml OWNER TO postgres;

--
-- TOC entry 308 (class 1259 OID 267700)
-- Name: drl_unprocessed_filename_ml; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drl_unprocessed_filename_ml (
    unprocessed_filename character varying(255),
    create_dt timestamp(6) with time zone,
    update_dt timestamp(6) with time zone
);


ALTER TABLE public.drl_unprocessed_filename_ml OWNER TO postgres;

--
-- TOC entry 800 (class 1259 OID 619655)
-- Name: endpoints; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.endpoints (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    url character varying(255),
    method character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.endpoints OWNER TO postgres;

--
-- TOC entry 801 (class 1259 OID 619687)
-- Name: endpoints_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.endpoints_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    endpoint_id uuid,
    role_id character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.endpoints_permissions OWNER TO postgres;

--
-- TOC entry 818 (class 1259 OID 659014)
-- Name: engaged_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.engaged_user (
    engaged_date timestamp(6) without time zone NOT NULL,
    msisdn text NOT NULL,
    mode text NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL
)
PARTITION BY RANGE (engaged_date);


ALTER TABLE public.engaged_user OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 267703)
-- Name: event_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    active smallint DEFAULT 0 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.event_types OWNER TO postgres;

--
-- TOC entry 815 (class 1259 OID 648452)
-- Name: expert_call_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expert_call_requests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(255),
    active boolean DEFAULT false,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.expert_call_requests OWNER TO postgres;

--
-- TOC entry 821 (class 1259 OID 663203)
-- Name: farm_crop_growth_stage_anomalies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farm_crop_growth_stage_anomalies (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    farm_crop_growth_stage_id character varying(255) NOT NULL,
    anomaly_id character varying(255) NOT NULL,
    shape public.geometry(Geometry,4326) NOT NULL,
    start_dt timestamp(6) without time zone NOT NULL,
    end_dt timestamp(6) without time zone,
    profiled_by character varying(255),
    profiler_type character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.farm_crop_growth_stage_anomalies OWNER TO postgres;

--
-- TOC entry 310 (class 1259 OID 267713)
-- Name: farm_crop_growth_stages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farm_crop_growth_stages (
    growth_stage_id character varying(255),
    date date,
    description character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    profiled_by character varying,
    profiler_type character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    farm_crop_id character varying NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    shape public.geometry(Geometry,4326),
    user_date date,
    gis_date date,
    CONSTRAINT at_least_one_date_column_not_null CHECK (((date IS NOT NULL) OR (gis_date IS NOT NULL) OR (user_date IS NOT NULL)))
);


ALTER TABLE public.farm_crop_growth_stages OWNER TO postgres;

--
-- TOC entry 773 (class 1259 OID 516635)
-- Name: farm_crop_growth_stages_duplicate_record; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farm_crop_growth_stages_duplicate_record (
    growth_stage_id character varying(255),
    date date,
    description character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    profiled_by character varying,
    profiler_type character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    farm_crop_id character varying NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farm_crop_growth_stages_duplicate_record OWNER TO postgres;

--
-- TOC entry 683 (class 1259 OID 390554)
-- Name: farm_crops_seed_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farm_crops_seed_types (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    farm_crop_id character varying(255) NOT NULL,
    crop_id character varying(255) NOT NULL,
    seed_type_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.farm_crops_seed_types OWNER TO postgres;

--
-- TOC entry 651 (class 1259 OID 324055)
-- Name: farmcrops_backup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmcrops_backup (
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    sowing_method_id character varying(255),
    cultivated_area double precision,
    seed_type_id character varying(255),
    crop_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    farm_id character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farmcrops_backup OWNER TO postgres;

--
-- TOC entry 775 (class 1259 OID 519264)
-- Name: farmcrops_duplicate_record; Type: TABLE; Schema: public; Owner: ateebqa_rw
--

CREATE TABLE public.farmcrops_duplicate_record (
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    sowing_method_id character varying(255),
    cultivated_area double precision,
    seed_type_id character varying(255),
    crop_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    farm_id character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_season_id character varying(225)
);


ALTER TABLE public.farmcrops_duplicate_record OWNER TO ateebqa_rw;

--
-- TOC entry 652 (class 1259 OID 324063)
-- Name: farmcrops_old; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmcrops_old (
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    sowing_method_id bigint,
    cultivated_area double precision,
    seed_type_id bigint,
    crop_id bigint,
    profiled_by character varying,
    profiler_type character varying,
    farm_id character varying NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farmcrops_old OWNER TO postgres;

--
-- TOC entry 776 (class 1259 OID 519274)
-- Name: farmcrops_unique_record; Type: TABLE; Schema: public; Owner: ateebqa_rw
--

CREATE TABLE public.farmcrops_unique_record (
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    sowing_method_id character varying(255),
    cultivated_area double precision,
    seed_type_id character varying(255),
    crop_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    farm_id character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_season_id uuid
);


ALTER TABLE public.farmcrops_unique_record OWNER TO ateebqa_rw;

--
-- TOC entry 311 (class 1259 OID 267729)
-- Name: farme_land_final; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farme_land_final (
    num_ character varying(255),
    land double precision,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farme_land_final OWNER TO postgres;

--
-- TOC entry 312 (class 1259 OID 267736)
-- Name: farmer_badge_recommendations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_badge_recommendations (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    farmer_id bigint NOT NULL,
    badge_id bigint NOT NULL,
    agent_id bigint NOT NULL,
    recommendation_note character varying(255),
    status character varying(25),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farmer_badge_recommendations OWNER TO postgres;

--
-- TOC entry 313 (class 1259 OID 267746)
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
-- TOC entry 9937 (class 0 OID 0)
-- Dependencies: 313
-- Name: farmer_badge_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.farmer_badge_recommendations_id_seq OWNED BY public.farmer_badge_recommendations.id;


--
-- TOC entry 314 (class 1259 OID 267748)
-- Name: farmer_friends; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_friends (
    farmer_id character varying(255) NOT NULL,
    friend_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone,
    profiled_by character varying,
    update_dt timestamp(6) without time zone,
    profiler_type character varying,
    country_code character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farmer_friends OWNER TO postgres;

--
-- TOC entry 315 (class 1259 OID 267755)
-- Name: farmer_gender; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_gender (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    title_urdu character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    file_name character varying(255),
    content_id character varying,
    name_alt character varying(255)
);


ALTER TABLE public.farmer_gender OWNER TO postgres;

--
-- TOC entry 653 (class 1259 OID 324072)
-- Name: farmer_interest; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_interest (
    farmer_id character varying(255) NOT NULL,
    interest_id character varying(255),
    create_dt timestamp(6) without time zone
);


ALTER TABLE public.farmer_interest OWNER TO postgres;

--
-- TOC entry 316 (class 1259 OID 267763)
-- Name: farmer_livestock_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_livestock_tags (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    livestock_id character varying(255),
    tag_id character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farmer_livestock_tags OWNER TO postgres;

--
-- TOC entry 317 (class 1259 OID 267772)
-- Name: farmer_livestocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_livestocks (
    count integer DEFAULT 0,
    livestock_id character varying(255) NOT NULL,
    description character varying(255),
    category_id character varying(255),
    purpose_id character varying(255),
    stage_id character varying(255),
    breed_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    farmer_id character varying NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farmer_livestocks OWNER TO postgres;

--
-- TOC entry 318 (class 1259 OID 267781)
-- Name: farmer_machineries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_machineries (
    count integer DEFAULT 0 NOT NULL,
    description character varying(255),
    machinery_id character varying(255) NOT NULL,
    profiled_by character varying,
    profiler_type character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    farmer_id character varying NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farmer_machineries OWNER TO postgres;

--
-- TOC entry 319 (class 1259 OID 267790)
-- Name: farmer_name_change; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_name_change (
    name character varying NOT NULL,
    msisdn character varying(255) NOT NULL
);


ALTER TABLE public.farmer_name_change OWNER TO postgres;

--
-- TOC entry 320 (class 1259 OID 267796)
-- Name: farmer_name_content; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_name_content (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    file_name character varying(255),
    folder_path character varying(255),
    file_path character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.farmer_name_content OWNER TO postgres;

--
-- TOC entry 321 (class 1259 OID 267803)
-- Name: farmer_names_ml; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_names_ml (
    names character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.farmer_names_ml OWNER TO postgres;

--
-- TOC entry 787 (class 1259 OID 579850)
-- Name: farmer_updated_names; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmer_updated_names (
    original_name character varying(255),
    corrected_name character varying(255)
);


ALTER TABLE public.farmer_updated_names OWNER TO postgres;

--
-- TOC entry 654 (class 1259 OID 324078)
-- Name: farmers_copy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmers_copy (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    cnic character varying(15),
    name character varying(60),
    email character varying(60),
    location_id bigint,
    address character varying(100),
    status smallint,
    create_dt timestamp(6) with time zone,
    update_dt timestamp(6) with time zone,
    language_id bigint,
    occupation character varying,
    gender character varying,
    dob date,
    phone_type character varying,
    profiled_by character varying,
    profile_image character varying,
    profiler_type character varying,
    key character varying,
    occupation_id bigint,
    fcm_token character varying,
    cnic_front_image character varying,
    cnic_back_image character varying,
    default_location_enabled boolean,
    cnic_issue_date date,
    total_incentive_ammount bigint,
    badge_id bigint
);


ALTER TABLE public.farmers_copy OWNER TO postgres;

--
-- TOC entry 784 (class 1259 OID 563287)
-- Name: farmers_eng_urdu_names; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmers_eng_urdu_names (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    create_dt timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) with time zone,
    name_en character varying(255),
    name_ur character varying(255)
);


ALTER TABLE public.farmers_eng_urdu_names OWNER TO postgres;

--
-- TOC entry 655 (class 1259 OID 324089)
-- Name: farmers_old; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmers_old (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    cnic character varying(15),
    name character varying(60),
    email character varying(60),
    location_id bigint,
    address character varying(100),
    status smallint,
    create_dt timestamp(6) with time zone,
    update_dt timestamp(6) with time zone,
    language_id bigint,
    occupation character varying,
    gender character varying,
    dob date,
    phone_type character varying,
    profiled_by character varying,
    profile_image character varying,
    profiler_type character varying,
    key character varying,
    occupation_id bigint,
    fcm_token character varying,
    cnic_front_image character varying,
    cnic_back_image character varying,
    default_location_enabled boolean,
    cnic_issue_date date,
    total_incentive_ammount bigint,
    badge_id bigint
);


ALTER TABLE public.farmers_old OWNER TO postgres;

--
-- TOC entry 323 (class 1259 OID 267822)
-- Name: farmers_testing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farmers_testing (
    id character varying(255) NOT NULL,
    cnic character varying(15),
    name character varying(60),
    email character varying(60),
    location_id character varying(255),
    address character varying(100),
    status smallint,
    create_dt timestamp(6) with time zone,
    update_dt timestamp(6) with time zone,
    language_id character varying(255),
    occupation character varying,
    gender character varying,
    dob date,
    phone_type character varying,
    profiled_by character varying,
    profile_image character varying,
    profiler_type character varying,
    key character varying,
    occupation_id character varying(255),
    fcm_token character varying,
    cnic_front_image character varying,
    cnic_back_image character varying,
    cnic_issue_date date,
    total_incentive_ammount bigint,
    badge_id bigint,
    default_location_enabled boolean,
    last_sms_in_dt timestamp(6) with time zone,
    last_sms_out_dt timestamp(6) with time zone,
    last_ivr_dt timestamp(6) with time zone,
    last_obd_dt timestamp(6) with time zone,
    recent_activity_dt timestamp(6) with time zone,
    in_app_enabled boolean DEFAULT true NOT NULL,
    obd_enabled boolean DEFAULT true NOT NULL,
    sms_enabled boolean DEFAULT true NOT NULL,
    is_cc_blocked boolean DEFAULT false NOT NULL,
    is_blocked boolean DEFAULT false NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    comments text,
    is_verified boolean,
    profile_level_id character varying(255),
    transaction_id character varying,
    gender_id character varying
);


ALTER TABLE public.farmers_testing OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 267844)
-- Name: farms_final; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farms_final (
    land_area double precision,
    land_unit character varying(255),
    location_id bigint,
    is_default smallint,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    soil_type_id bigint,
    irrigation_source_id bigint,
    soil_issue_id bigint,
    farm_title character varying,
    lat numeric(8,6),
    lng numeric(8,6),
    land_topography_id bigint,
    shape public.geometry,
    geo_point public.geometry,
    address character varying,
    farmer_id character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    profiled_by character varying,
    profiler_type character varying,
    is_model_farm boolean
);


ALTER TABLE public.farms_final OWNER TO postgres;

--
-- TOC entry 326 (class 1259 OID 267851)
-- Name: farms_tagg; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.farms_tagg (
    id character varying(255)
);


ALTER TABLE public.farms_tagg OWNER TO postgres;

--
-- TOC entry 786 (class 1259 OID 579405)
-- Name: fav_crops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fav_crops (
    id integer NOT NULL,
    farmer_id character varying,
    crop_id character varying,
    fav_level integer NOT NULL
);


ALTER TABLE public.fav_crops OWNER TO postgres;

--
-- TOC entry 785 (class 1259 OID 579403)
-- Name: fav_crops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.fav_crops ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.fav_crops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 327 (class 1259 OID 267854)
-- Name: field_visits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.field_visits (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    application_id integer NOT NULL,
    agent_id integer NOT NULL,
    partner_id integer NOT NULL,
    description character varying(255) NOT NULL,
    status character varying(52) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.field_visits OWNER TO postgres;

--
-- TOC entry 328 (class 1259 OID 267864)
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
-- TOC entry 9957 (class 0 OID 0)
-- Dependencies: 328
-- Name: field_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.field_visits_id_seq OWNED BY public.field_visits.id;


--
-- TOC entry 329 (class 1259 OID 267866)
-- Name: final_names; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.final_names (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    name character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.final_names OWNER TO postgres;

--
-- TOC entry 330 (class 1259 OID 267874)
-- Name: final_names1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.final_names1 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    "Name" character varying(255)
);


ALTER TABLE public.final_names1 OWNER TO postgres;

--
-- TOC entry 331 (class 1259 OID 267881)
-- Name: forum_hide_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_hide_posts (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    hide_post_id character varying(255) NOT NULL,
    update_dt timestamp(6) without time zone,
    create_dt timestamp(6) without time zone NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_hide_posts OWNER TO postgres;

--
-- TOC entry 656 (class 1259 OID 324096)
-- Name: forum_hide_posts_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_hide_posts_copy1 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    hide_post_id character varying(255) NOT NULL,
    update_dt timestamp(6) without time zone,
    create_dt timestamp(6) without time zone NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_hide_posts_copy1 OWNER TO postgres;

--
-- TOC entry 332 (class 1259 OID 267889)
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
-- TOC entry 9963 (class 0 OID 0)
-- Dependencies: 332
-- Name: forum_hide_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forum_hide_posts_id_seq OWNED BY public.forum_hide_posts.id;


--
-- TOC entry 333 (class 1259 OID 267891)
-- Name: forum_hide_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_hide_users (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    hide_user_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_hide_users OWNER TO postgres;

--
-- TOC entry 657 (class 1259 OID 324108)
-- Name: forum_hide_users_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_hide_users_copy1 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    hide_user_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_hide_users_copy1 OWNER TO postgres;

--
-- TOC entry 334 (class 1259 OID 267899)
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
-- TOC entry 9967 (class 0 OID 0)
-- Dependencies: 334
-- Name: forum_hide_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forum_hide_users_id_seq OWNED BY public.forum_hide_users.id;


--
-- TOC entry 335 (class 1259 OID 267901)
-- Name: forum_media; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_media (
    path character varying(255) DEFAULT NULL::character varying NOT NULL,
    type character varying(255) NOT NULL,
    forum_post_id character varying(255) NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    approved boolean DEFAULT true
);


ALTER TABLE public.forum_media OWNER TO postgres;

--
-- TOC entry 658 (class 1259 OID 324120)
-- Name: forum_media_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_media_copy1 (
    path character varying(255) DEFAULT NULL::character varying NOT NULL,
    type character varying(255) NOT NULL,
    forum_post_id character varying(255) NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_media_copy1 OWNER TO postgres;

--
-- TOC entry 336 (class 1259 OID 267910)
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
-- TOC entry 9971 (class 0 OID 0)
-- Dependencies: 336
-- Name: forum_media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forum_media_id_seq OWNED BY public.forum_media.id;


--
-- TOC entry 774 (class 1259 OID 516840)
-- Name: forum_post_rejection_reasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_post_rejection_reasons (
    id character varying(255) DEFAULT (public.uuid_generate_v4())::character varying(255) NOT NULL,
    reason character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.forum_post_rejection_reasons OWNER TO postgres;

--
-- TOC entry 337 (class 1259 OID 267912)
-- Name: forum_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_posts (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    creator_id character varying(15) NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type text NOT NULL,
    parent_id character varying(255),
    image text,
    audio text,
    video text,
    content text,
    lat character varying(255),
    lng character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt character varying,
    geo_point public.geometry(Geometry,4326),
    overlay_enabled boolean DEFAULT false,
    is_blocked boolean DEFAULT false,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    approved_dt timestamp(6) without time zone,
    post_id character varying(255),
    file text,
    files text,
    thumbnail text,
    duration double precision,
    rejected_dt timestamp(6) without time zone,
    reason_id character varying(255),
    status_id uuid
);


ALTER TABLE public.forum_posts OWNER TO postgres;

--
-- TOC entry 659 (class 1259 OID 324131)
-- Name: forum_posts_cc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_posts_cc (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    creator_id character varying(15) NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type text NOT NULL,
    parent_id character varying(255),
    image text,
    audio text,
    video text,
    content text,
    status boolean DEFAULT false,
    lat character varying(255),
    lng character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt character varying,
    geo_point public.geometry,
    overlay_enabled boolean DEFAULT false,
    is_blocked boolean DEFAULT false,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    approved_dt timestamp(6) without time zone,
    file text,
    files text,
    post_id integer
);


ALTER TABLE public.forum_posts_cc OWNER TO postgres;

--
-- TOC entry 338 (class 1259 OID 267924)
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
-- TOC entry 9976 (class 0 OID 0)
-- Dependencies: 338
-- Name: forum_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forum_posts_id_seq OWNED BY public.forum_posts.id;


--
-- TOC entry 339 (class 1259 OID 267926)
-- Name: forum_posts_rejected; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_posts_rejected (
    id character varying(255) NOT NULL,
    creator_id character varying(15) NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type text NOT NULL,
    parent_id character varying(255),
    image text,
    audio text,
    video text,
    content text,
    status boolean DEFAULT false,
    lat character varying(255),
    lng character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt character varying,
    geo_point public.geometry,
    overlay_enabled boolean DEFAULT false,
    is_blocked boolean DEFAULT false,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    approved_dt timestamp(6) without time zone,
    rejected_dt timestamp(6) without time zone,
    reason_id character varying(255),
    post_id integer,
    file character varying(255),
    files character varying(255),
    thumbnail text,
    duration double precision
);


ALTER TABLE public.forum_posts_rejected OWNER TO postgres;

--
-- TOC entry 660 (class 1259 OID 324145)
-- Name: forum_posts_rejected_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_posts_rejected_copy1 (
    id character varying(255) NOT NULL,
    creator_id character varying(15) NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type text NOT NULL,
    parent_id character varying(255),
    image text,
    audio text,
    video text,
    content text,
    status boolean DEFAULT false,
    lat character varying(255),
    lng character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt character varying,
    geo_point public.geometry,
    overlay_enabled boolean DEFAULT false,
    is_blocked boolean DEFAULT false,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    rejected_dt timestamp(6) without time zone,
    reason_id character varying,
    post_id integer,
    approved_dt timestamp(6) without time zone
);


ALTER TABLE public.forum_posts_rejected_copy1 OWNER TO postgres;

--
-- TOC entry 686 (class 1259 OID 406779)
-- Name: forum_posts_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_posts_tags (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    forum_post_id character varying(255),
    post_tag_id character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.forum_posts_tags OWNER TO postgres;

--
-- TOC entry 799 (class 1259 OID 617269)
-- Name: forum_posts_views_shares; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_posts_views_shares (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    forum_post_id character varying(255),
    msisdn character varying(255),
    views integer,
    shares integer,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.forum_posts_views_shares OWNER TO postgres;

--
-- TOC entry 340 (class 1259 OID 267937)
-- Name: forum_report_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_report_posts (
    user_id character varying(255) NOT NULL,
    report_post_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    reason_id character varying(64),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_report_posts OWNER TO postgres;

--
-- TOC entry 661 (class 1259 OID 324158)
-- Name: forum_report_posts_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_report_posts_copy1 (
    user_id character varying(255) NOT NULL,
    report_post_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    reason_id character varying(64),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_report_posts_copy1 OWNER TO postgres;

--
-- TOC entry 341 (class 1259 OID 267945)
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
-- TOC entry 9984 (class 0 OID 0)
-- Dependencies: 341
-- Name: forum_report_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forum_report_posts_id_seq OWNED BY public.forum_report_posts.id;


--
-- TOC entry 342 (class 1259 OID 267947)
-- Name: forum_report_reason_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_report_reason_actions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    reason_id character varying(255) NOT NULL,
    description_urdu character varying,
    title_urdu character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_report_reason_actions OWNER TO postgres;

--
-- TOC entry 662 (class 1259 OID 324170)
-- Name: forum_report_reason_actions_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_report_reason_actions_copy1 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    reason_id character varying(255) NOT NULL,
    description_urdu character varying,
    title_urdu character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_report_reason_actions_copy1 OWNER TO postgres;

--
-- TOC entry 343 (class 1259 OID 267955)
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
-- TOC entry 9988 (class 0 OID 0)
-- Dependencies: 343
-- Name: forum_report_reason_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forum_report_reason_actions_id_seq OWNED BY public.forum_report_reason_actions.id;


--
-- TOC entry 344 (class 1259 OID 267957)
-- Name: forum_report_reasons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_report_reasons (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    type character varying[] NOT NULL,
    title_urdu character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_report_reasons OWNER TO postgres;

--
-- TOC entry 663 (class 1259 OID 324180)
-- Name: forum_report_reasons_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_report_reasons_copy1 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    type character varying[] NOT NULL,
    title_urdu character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_report_reasons_copy1 OWNER TO postgres;

--
-- TOC entry 345 (class 1259 OID 267965)
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
-- TOC entry 9992 (class 0 OID 0)
-- Dependencies: 345
-- Name: forum_report_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forum_report_reasons_id_seq OWNED BY public.forum_report_reasons.id;


--
-- TOC entry 346 (class 1259 OID 267967)
-- Name: forum_report_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_report_users (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    report_user_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    reason_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_report_users OWNER TO postgres;

--
-- TOC entry 664 (class 1259 OID 324190)
-- Name: forum_report_users_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_report_users_copy1 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    report_user_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    reason_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_report_users_copy1 OWNER TO postgres;

--
-- TOC entry 347 (class 1259 OID 267975)
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
-- TOC entry 9996 (class 0 OID 0)
-- Dependencies: 347
-- Name: forum_report_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forum_report_users_id_seq OWNED BY public.forum_report_users.id;


--
-- TOC entry 348 (class 1259 OID 267977)
-- Name: forum_user_agreements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_user_agreements (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    is_agreed boolean DEFAULT false NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    terms_of_use_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_user_agreements OWNER TO postgres;

--
-- TOC entry 665 (class 1259 OID 324202)
-- Name: forum_user_agreements_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forum_user_agreements_copy1 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    is_agreed boolean DEFAULT false NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    terms_of_use_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.forum_user_agreements_copy1 OWNER TO postgres;

--
-- TOC entry 349 (class 1259 OID 267987)
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
-- TOC entry 350 (class 1259 OID 267989)
-- Name: gmlc_check; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gmlc_check (
    msisdn character varying(15)
);


ALTER TABLE public.gmlc_check OWNER TO postgres;

--
-- TOC entry 666 (class 1259 OID 324216)
-- Name: gsma_advisory_2022_02_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gsma_advisory_2022_02_22 (
    msisdn character varying(255)
);


ALTER TABLE public.gsma_advisory_2022_02_22 OWNER TO postgres;

--
-- TOC entry 351 (class 1259 OID 267992)
-- Name: gsma_base_advisory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gsma_base_advisory (
    msisdn character varying(255)
);


ALTER TABLE public.gsma_base_advisory OWNER TO postgres;

--
-- TOC entry 352 (class 1259 OID 267995)
-- Name: haseeb_testing_profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.haseeb_testing_profile (
    msisdn character varying(255),
    profile_stage character varying(255),
    profiled_by character varying(255),
    farmer_type character varying(255),
    action character varying(255),
    comments text,
    create_dt timestamp without time zone,
    update_dt timestamp without time zone,
    action_dt timestamp without time zone,
    occupation character varying(255),
    previous_stage character varying(255)
);


ALTER TABLE public.haseeb_testing_profile OWNER TO postgres;

--
-- TOC entry 353 (class 1259 OID 268001)
-- Name: he_alerts_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.he_alerts_data (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    daily_weather_alerts character varying(50) DEFAULT 0,
    weather_disaster_alerts character varying(50) DEFAULT 0,
    crop_disaster_alerts character varying(50) DEFAULT 0,
    livestock_disease_alerts character varying(50) DEFAULT 0,
    pest_disease_outbreak character varying(50) DEFAULT 0,
    subcidy_information character varying(50) DEFAULT 0,
    msisdn character varying(255)
);


ALTER TABLE public.he_alerts_data OWNER TO postgres;

--
-- TOC entry 354 (class 1259 OID 268014)
-- Name: he_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.he_data (
    id integer NOT NULL,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    "daily_weather_aLerts" character varying(255) DEFAULT 0,
    weather_disaster_alerts character varying(255) DEFAULT 0,
    crop_disaster_alerts character varying(255) DEFAULT 0,
    livestock_disease_alerts character varying(255) DEFAULT 0,
    pest_disease_outbreak character varying(255) DEFAULT 0,
    subcidy_information character varying(255) DEFAULT 0
);


ALTER TABLE public.he_data OWNER TO postgres;

--
-- TOC entry 355 (class 1259 OID 268026)
-- Name: stats_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stats_notifications (
    id integer NOT NULL,
    name character varying(50),
    cellno character varying(20),
    email character varying(50),
    department character varying(50),
    designation character varying(50),
    task_id character varying(50),
    hourly_sms_notifications boolean,
    hourly_email_notifications boolean,
    daily_sms_notifications boolean,
    daily_email_notifications boolean
);


ALTER TABLE public.stats_notifications OWNER TO postgres;

--
-- TOC entry 10009 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.name IS 'Employee Name';


--
-- TOC entry 10010 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.cellno; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.cellno IS 'Employee Cell No';


--
-- TOC entry 10011 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.email IS 'Employee Email ID';


--
-- TOC entry 10012 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.department; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.department IS 'Department Name (BKK-Product)';


--
-- TOC entry 10013 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.task_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.task_id IS 'Azure DevOps Task ID for refernce';


--
-- TOC entry 10014 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.hourly_sms_notifications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.hourly_sms_notifications IS 'Set TRUE to send hourly SMS notification';


--
-- TOC entry 10015 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.hourly_email_notifications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.hourly_email_notifications IS 'Set TRUE to send hourly email notification';


--
-- TOC entry 10016 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.daily_sms_notifications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.daily_sms_notifications IS 'Set TRUE to send daily SMS notification';


--
-- TOC entry 10017 (class 0 OID 0)
-- Dependencies: 355
-- Name: COLUMN stats_notifications.daily_email_notifications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.stats_notifications.daily_email_notifications IS 'Set TRUE to send daily email notification';


--
-- TOC entry 356 (class 1259 OID 268029)
-- Name: hourly_stat_receivers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hourly_stat_receivers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hourly_stat_receivers_id_seq OWNER TO postgres;

--
-- TOC entry 10019 (class 0 OID 0)
-- Dependencies: 356
-- Name: hourly_stat_receivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.hourly_stat_receivers_id_seq OWNED BY public.stats_notifications.id;


--
-- TOC entry 357 (class 1259 OID 268031)
-- Name: in_app_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.in_app_notifications (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    content character varying(255) NOT NULL,
    is_read boolean NOT NULL,
    user_type character varying(50) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.in_app_notifications OWNER TO postgres;

--
-- TOC entry 358 (class 1259 OID 268041)
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
-- TOC entry 10022 (class 0 OID 0)
-- Dependencies: 358
-- Name: in_app_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.in_app_notifications_id_seq OWNED BY public.in_app_notifications.id;


--
-- TOC entry 359 (class 1259 OID 268043)
-- Name: incentive_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.incentive_transactions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    incentive_type_id character varying(255) NOT NULL,
    host_farmer_id character varying(255) NOT NULL,
    ammount numeric(10,2),
    type character varying(25),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.incentive_transactions OWNER TO postgres;

--
-- TOC entry 360 (class 1259 OID 268053)
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
-- TOC entry 10025 (class 0 OID 0)
-- Dependencies: 360
-- Name: incentive_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.incentive_transactions_id_seq OWNED BY public.incentive_transactions.id;


--
-- TOC entry 361 (class 1259 OID 268055)
-- Name: incentive_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.incentive_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(25),
    value numeric(10,2),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.incentive_types OWNER TO postgres;

--
-- TOC entry 362 (class 1259 OID 268065)
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
-- TOC entry 10028 (class 0 OID 0)
-- Dependencies: 362
-- Name: incentive_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.incentive_types_id_seq OWNED BY public.incentive_types.id;


--
-- TOC entry 667 (class 1259 OID 324219)
-- Name: interests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.interests (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying,
    title_urdu character varying,
    key character varying,
    image_url character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.interests OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 268067)
-- Name: irrigation_sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.irrigation_sources (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    title_urdu character varying,
    content_id character varying(64),
    profiled_by character varying,
    profiler_type character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    image_url text
);


ALTER TABLE public.irrigation_sources OWNER TO postgres;

--
-- TOC entry 364 (class 1259 OID 268075)
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
-- TOC entry 10032 (class 0 OID 0)
-- Dependencies: 364
-- Name: irrigation_source_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.irrigation_source_id_seq OWNED BY public.irrigation_sources.id;


--
-- TOC entry 365 (class 1259 OID 268077)
-- Name: isl_weather_subs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.isl_weather_subs (
    msisdn character varying(255)
);


ALTER TABLE public.isl_weather_subs OWNER TO postgres;

--
-- TOC entry 366 (class 1259 OID 268080)
-- Name: ivr_activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ivr_activities (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) NOT NULL,
    channel_id character varying(255) NOT NULL,
    from_context character varying(255) NOT NULL,
    to_context character varying(255) NOT NULL,
    from_node_uuid character varying(255),
    to_node_uuid character varying(255),
    duration integer,
    dtmf character varying(255) DEFAULT NULL::character varying,
    api_call_id character varying(255) DEFAULT NULL::character varying,
    trunk_call_id character varying(255) DEFAULT NULL::character varying,
    event_id character varying(255) DEFAULT NULL::character varying,
    activity_type character varying(255) NOT NULL,
    activity_name character varying(255) NOT NULL,
    description text,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    content_data text
);


ALTER TABLE public.ivr_activities OWNER TO postgres;

--
-- TOC entry 367 (class 1259 OID 268093)
-- Name: ivr_paths; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ivr_paths (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    description character varying(255) DEFAULT NULL::character varying,
    path text NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.ivr_paths OWNER TO postgres;

--
-- TOC entry 368 (class 1259 OID 268104)
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
-- TOC entry 10037 (class 0 OID 0)
-- Dependencies: 368
-- Name: ivr_paths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ivr_paths_id_seq OWNED BY public.ivr_paths.id;


--
-- TOC entry 369 (class 1259 OID 268106)
-- Name: ivr_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ivr_sessions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(11) NOT NULL,
    channel_uuid character varying(255) NOT NULL,
    node_uuid character varying(255) DEFAULT NULL::character varying,
    playback_uuid character varying(255) DEFAULT NULL::character varying,
    recorder_uuid character varying(255) DEFAULT NULL::character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.ivr_sessions OWNER TO postgres;

--
-- TOC entry 370 (class 1259 OID 268118)
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
-- TOC entry 10040 (class 0 OID 0)
-- Dependencies: 370
-- Name: ivr_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ivr_sessions_id_seq OWNED BY public.ivr_sessions.id;


--
-- TOC entry 371 (class 1259 OID 268120)
-- Name: jazz_op_check; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jazz_op_check (
    msisdn character varying(15)
);


ALTER TABLE public.jazz_op_check OWNER TO postgres;

--
-- TOC entry 372 (class 1259 OID 268123)
-- Name: jazz_other; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jazz_other (
    msisdn character varying(15)
);


ALTER TABLE public.jazz_other OWNER TO postgres;

--
-- TOC entry 794 (class 1259 OID 599057)
-- Name: jazzcash_merchant_accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jazzcash_merchant_accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    merchant_id character varying(255),
    password character varying(255),
    salt character varying(255),
    return_url character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.jazzcash_merchant_accounts OWNER TO postgres;

--
-- TOC entry 798 (class 1259 OID 606191)
-- Name: jazzcash_onetime_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jazzcash_onetime_transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    txn_type character varying(255),
    version character varying(255),
    amount character varying(255),
    auth_code character varying(255),
    bill_reference character varying(255),
    language character varying(255),
    merchant_id character varying(255),
    response_code character varying(255),
    response_message character varying(255),
    retreival_reference_no character varying(255),
    sub_merchant_id character varying(255),
    txn_currency character varying(255),
    txn_date_time character varying(255),
    txn_ref_no character varying(255),
    mobile_number character varying(255),
    cnic character varying(255),
    discounted_amount character varying(255),
    ppmpf1 character varying(255),
    ppmpf2 character varying(255),
    ppmpf3 character varying(255),
    ppmpf4 character varying(255),
    ppmpf5 character varying(255),
    secure_hash character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.jazzcash_onetime_transactions OWNER TO postgres;

--
-- TOC entry 797 (class 1259 OID 599101)
-- Name: jazzcash_recurring_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jazzcash_recurring_transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    response_code character varying(255),
    response_message character varying(255),
    amount character varying(255),
    retreival_reference_no character varying(255),
    txn_ref_no character varying(255),
    payment_token character varying(255),
    discounted_amount character varying(255),
    secure_hash character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.jazzcash_recurring_transactions OWNER TO postgres;

--
-- TOC entry 793 (class 1259 OID 598784)
-- Name: jazzcash_user_accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jazzcash_user_accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(255),
    response_code character varying(255),
    response_message character varying(255),
    payment_token character varying(255),
    merchant_id character varying(255),
    secure_hash character varying(255),
    request_id character varying(255),
    return_url character varying(255),
    cnic character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.jazzcash_user_accounts OWNER TO postgres;

--
-- TOC entry 796 (class 1259 OID 599081)
-- Name: jazzcash_user_wallet_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jazzcash_user_wallet_transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(255),
    response_code character varying(255),
    response_message character varying(255),
    payment_token character varying(255),
    merchant_id character varying(255),
    secure_hash character varying(255),
    request_id character varying(255),
    return_url character varying(255),
    cnic character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.jazzcash_user_wallet_transactions OWNER TO postgres;

--
-- TOC entry 795 (class 1259 OID 599069)
-- Name: jazzcash_user_wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jazzcash_user_wallets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(255),
    request_id character varying(255),
    payment_token character varying(255),
    cnic character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.jazzcash_user_wallets OWNER TO postgres;

--
-- TOC entry 636 (class 1259 OID 315196)
-- Name: job_executor_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_executor_stats (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    in_app_enabled boolean DEFAULT false NOT NULL,
    obd_enabled boolean DEFAULT false NOT NULL,
    ivr_enabled boolean DEFAULT false NOT NULL,
    sms_enabled boolean DEFAULT false NOT NULL,
    job_type_id character varying(255) NOT NULL,
    tsql_query text,
    campaign_id character varying(255),
    campaign_type_id character varying(255),
    survey_id character varying(255),
    survey_type_id character varying(255),
    total_count bigint DEFAULT 0 NOT NULL,
    queued_count bigint DEFAULT 0 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    start_time time(6) without time zone,
    end_time time(6) without time zone,
    start_dt date,
    end_dt date,
    crops json,
    livestocks json,
    machineries json,
    languages json,
    locations json,
    contents json,
    subscribers_job_logs_status boolean,
    content_text text,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    profiles json
);


ALTER TABLE public.job_executor_stats OWNER TO postgres;

--
-- TOC entry 828 (class 1259 OID 1090995)
-- Name: job_logs_2025_07_24; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_07_24 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_07_24 OWNER TO postgres;

--
-- TOC entry 829 (class 1259 OID 1091251)
-- Name: job_logs_2025_07_25; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_07_25 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_07_25 OWNER TO postgres;

--
-- TOC entry 830 (class 1259 OID 1134151)
-- Name: job_logs_2025_07_26; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_07_26 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_07_26 OWNER TO postgres;

--
-- TOC entry 831 (class 1259 OID 1134424)
-- Name: job_logs_2025_07_27; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_07_27 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_07_27 OWNER TO postgres;

--
-- TOC entry 832 (class 1259 OID 1134690)
-- Name: job_logs_2025_07_28; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_07_28 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_07_28 OWNER TO postgres;

--
-- TOC entry 833 (class 1259 OID 1178342)
-- Name: job_logs_2025_07_29; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_07_29 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_07_29 OWNER TO postgres;

--
-- TOC entry 834 (class 1259 OID 1561208)
-- Name: job_logs_2025_07_30; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_07_30 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_07_30 OWNER TO postgres;

--
-- TOC entry 835 (class 1259 OID 1561792)
-- Name: job_logs_2025_07_31; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_07_31 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_07_31 OWNER TO postgres;

--
-- TOC entry 837 (class 1259 OID 1566032)
-- Name: job_logs_2025_08_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_08_13 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_08_13 OWNER TO postgres;

--
-- TOC entry 838 (class 1259 OID 1566374)
-- Name: job_logs_2025_08_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_08_14 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_08_14 OWNER TO postgres;

--
-- TOC entry 839 (class 1259 OID 1566774)
-- Name: job_logs_2025_08_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_logs_2025_08_15 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    queued_dt timestamp without time zone,
    dispatched_sms_dt timestamp without time zone,
    dispatched_obd_dt timestamp without time zone,
    dispatched_inapp_dt timestamp without time zone,
    sms_stat integer,
    obd_stat integer,
    inapp_stat integer,
    sms_content text,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.job_logs_2025_08_15 OWNER TO postgres;

--
-- TOC entry 631 (class 1259 OID 308184)
-- Name: job_operators; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_operators (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255),
    operator_id character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.job_operators OWNER TO postgres;

--
-- TOC entry 632 (class 1259 OID 308305)
-- Name: job_state_flow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_state_flow (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    status_id character varying(255) NOT NULL,
    parent_id character varying(255) NOT NULL,
    active bigint,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.job_state_flow OWNER TO postgres;

--
-- TOC entry 633 (class 1259 OID 308313)
-- Name: job_state_flow_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_state_flow_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_state_flow_id_seq OWNER TO postgres;

--
-- TOC entry 10064 (class 0 OID 0)
-- Dependencies: 633
-- Name: job_state_flow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.job_state_flow_id_seq OWNED BY public.job_state_flow.id;


--
-- TOC entry 634 (class 1259 OID 308389)
-- Name: job_statuses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_statuses (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    job_status character varying(255) NOT NULL,
    active smallint DEFAULT 0,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.job_statuses OWNER TO postgres;

--
-- TOC entry 635 (class 1259 OID 308467)
-- Name: job_testing_msisdns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_testing_msisdns (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    "position" character varying(255),
    job_id character varying(255) NOT NULL,
    msisdns character varying(255) NOT NULL,
    status character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.job_testing_msisdns OWNER TO postgres;

--
-- TOC entry 630 (class 1259 OID 308057)
-- Name: job_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    job_type character varying(255) NOT NULL,
    active smallint DEFAULT 0,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.job_types OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 268126)
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    start_dt date,
    end_dt date,
    campaign_id character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    survey_id character varying(255),
    start_time time(6) without time zone,
    end_time time(6) without time zone,
    context character varying(255) DEFAULT 'default'::character varying NOT NULL,
    extension character varying(255),
    week_days text,
    month_days text,
    year_months text,
    active smallint DEFAULT 1 NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    job_type_id character varying(255) NOT NULL,
    job_status_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.jobs OWNER TO postgres;

--
-- TOC entry 374 (class 1259 OID 268138)
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
-- TOC entry 826 (class 1259 OID 871676)
-- Name: khasra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.khasra (
    gid character varying,
    id character varying,
    m character varying,
    sk character varying,
    k character varying,
    mouza character varying,
    district character varying,
    tehsil character varying,
    pc character varying,
    label character varying,
    remarks character varying,
    dist_id character varying,
    tehsil_id character varying,
    pc_id character varying,
    mouza_id character varying,
    join_shp character varying,
    qh character varying,
    karam character varying,
    type character varying,
    mn character varying,
    b character varying,
    qh_id character varying,
    khasra_id character varying,
    sr_id character varying,
    geo_point character varying,
    shape public.geometry(MultiPolygon,4326)
);


ALTER TABLE public.khasra OWNER TO postgres;

--
-- TOC entry 375 (class 1259 OID 268140)
-- Name: land_topography; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.land_topography (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255) NOT NULL,
    title_urdu character varying(255),
    content_id character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    profiled_by character varying,
    profiler_type character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.land_topography OWNER TO postgres;

--
-- TOC entry 376 (class 1259 OID 268148)
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
-- TOC entry 10073 (class 0 OID 0)
-- Dependencies: 376
-- Name: land_topography_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.land_topography_id_seq OWNED BY public.land_topography.id;


--
-- TOC entry 377 (class 1259 OID 268150)
-- Name: languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.languages (
    name character varying(60) NOT NULL,
    active smallint NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name_alt character varying(255),
    content_id character varying(255),
    title_urdu character varying(255),
    short_name character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.languages OWNER TO postgres;

--
-- TOC entry 378 (class 1259 OID 268158)
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
-- TOC entry 10076 (class 0 OID 0)
-- Dependencies: 378
-- Name: languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.languages_id_seq OWNED BY public.languages.id;


--
-- TOC entry 379 (class 1259 OID 268160)
-- Name: livestock_breeds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_breeds (
    name character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    livestock_id character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_DATE,
    name_alt character varying(255),
    update_dt timestamp(6) without time zone,
    content_id character varying(255),
    title_urdu character varying,
    image_url character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    "order" integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.livestock_breeds OWNER TO postgres;

--
-- TOC entry 380 (class 1259 OID 268169)
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
-- TOC entry 10079 (class 0 OID 0)
-- Dependencies: 380
-- Name: livestock_breeds__id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestock_breeds__id_seq OWNED BY public.livestock_breeds.id;


--
-- TOC entry 381 (class 1259 OID 268171)
-- Name: livestock_disease; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_disease (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    name_alt character varying(255),
    content_id character varying(64),
    title_urdu character varying,
    image_url character varying,
    profiled_by character varying,
    profiler_type character varying,
    livestock_id character varying(64),
    "order" integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.livestock_disease OWNER TO postgres;

--
-- TOC entry 382 (class 1259 OID 268180)
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
-- TOC entry 10082 (class 0 OID 0)
-- Dependencies: 382
-- Name: livestock_disease_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestock_disease_id_seq OWNED BY public.livestock_disease.id;


--
-- TOC entry 792 (class 1259 OID 598278)
-- Name: livestock_farm_livestocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_farm_livestocks (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    count integer DEFAULT 0,
    livestock_id character varying(255) NOT NULL,
    description character varying(255),
    category_id character varying(255),
    purpose_id character varying(255),
    stage_id character varying(255),
    breed_id character varying(255),
    livestock_farm_id character varying(255),
    profiled_by character varying(255),
    profiler_type character varying(255),
    seq_order integer DEFAULT 0,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.livestock_farm_livestocks OWNER TO postgres;

--
-- TOC entry 383 (class 1259 OID 268182)
-- Name: livestock_farming_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_farming_categories (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying,
    active smallint DEFAULT 1 NOT NULL,
    file_name character varying,
    name_alt character varying,
    create_dt date DEFAULT CURRENT_DATE,
    update_dt date,
    content_id character varying(255),
    image_url character varying(255),
    title_urdu character varying,
    profiled_by character varying,
    profiler_type character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.livestock_farming_categories OWNER TO postgres;

--
-- TOC entry 384 (class 1259 OID 268192)
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
-- TOC entry 10086 (class 0 OID 0)
-- Dependencies: 384
-- Name: livestock_farming_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestock_farming_category_id_seq OWNED BY public.livestock_farming_categories.id;


--
-- TOC entry 791 (class 1259 OID 598252)
-- Name: livestock_farms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_farms (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    location_id character varying(255),
    lat numeric(8,6),
    lng numeric(8,6),
    address character varying(255),
    farmer_id character varying(255) NOT NULL,
    is_default boolean DEFAULT false,
    seq_order integer DEFAULT 0,
    profiled_by character varying(255),
    profiler_type character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.livestock_farms OWNER TO postgres;

--
-- TOC entry 385 (class 1259 OID 268194)
-- Name: livestock_management; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_management (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    title_urdu character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    content_id character varying(255),
    image_url character varying(255),
    file_name character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.livestock_management OWNER TO postgres;

--
-- TOC entry 386 (class 1259 OID 268203)
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
-- TOC entry 10090 (class 0 OID 0)
-- Dependencies: 386
-- Name: livestock_management_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestock_management_id_seq OWNED BY public.livestock_management.id;


--
-- TOC entry 387 (class 1259 OID 268205)
-- Name: livestock_nutrition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_nutrition (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    title_urdu character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    content_id character varying(255),
    file_name character varying(255),
    image_url character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.livestock_nutrition OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 268214)
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
-- TOC entry 10093 (class 0 OID 0)
-- Dependencies: 388
-- Name: livestock_nutrition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestock_nutrition_id_seq OWNED BY public.livestock_nutrition.id;


--
-- TOC entry 389 (class 1259 OID 268216)
-- Name: livestock_purpose; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_purpose (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    name_alt character varying(255),
    content_id character varying(255),
    image_url character varying(255),
    title_urdu character varying,
    profiled_by character varying,
    profiler_type character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.livestock_purpose OWNER TO postgres;

--
-- TOC entry 390 (class 1259 OID 268225)
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
-- TOC entry 10096 (class 0 OID 0)
-- Dependencies: 390
-- Name: livestock_purpose_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestock_purpose_id_seq OWNED BY public.livestock_purpose.id;


--
-- TOC entry 391 (class 1259 OID 268227)
-- Name: livestock_stage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestock_stage (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    name_alt character varying(255),
    content_id character varying(255),
    title_urdu character varying,
    image_url character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    livestock_id character varying(255),
    type character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.livestock_stage OWNER TO postgres;

--
-- TOC entry 392 (class 1259 OID 268236)
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
-- TOC entry 10099 (class 0 OID 0)
-- Dependencies: 392
-- Name: livestock_stage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestock_stage_id_seq OWNED BY public.livestock_stage.id;


--
-- TOC entry 393 (class 1259 OID 268238)
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
-- TOC entry 10101 (class 0 OID 0)
-- Dependencies: 393
-- Name: livestock_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestock_tags_id_seq OWNED BY public.farmer_livestock_tags.id;


--
-- TOC entry 394 (class 1259 OID 268240)
-- Name: livestocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livestocks (
    title character varying(255),
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    image_url character varying,
    active smallint DEFAULT 1 NOT NULL,
    create_dt date DEFAULT CURRENT_DATE,
    update_dt date,
    name_alt character varying(255),
    content_id character varying(255),
    title_urdu character varying,
    profiled_by character varying,
    profiler_type character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    "order" bigint
);


ALTER TABLE public.livestocks OWNER TO postgres;

--
-- TOC entry 395 (class 1259 OID 268250)
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
-- TOC entry 10104 (class 0 OID 0)
-- Dependencies: 395
-- Name: livestocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.livestocks_id_seq OWNED BY public.livestocks.id;


--
-- TOC entry 396 (class 1259 OID 268252)
-- Name: loan_agreement_docs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_agreement_docs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    doc_image_url character varying(100),
    seq_order bigint,
    create_dt timestamp(6) without time zone,
    application_id character varying(255),
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_agreement_docs OWNER TO postgres;

--
-- TOC entry 397 (class 1259 OID 268260)
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
-- TOC entry 398 (class 1259 OID 268262)
-- Name: loan_applications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_applications (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    partner_id character varying(32) NOT NULL,
    farmer_id character varying(15) NOT NULL,
    field_agent_id character varying(32),
    administrator_id character varying(32),
    status_id character varying(32),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    farm_id character varying,
    friend_id character varying(15) DEFAULT NULL::character varying,
    agent_comments character varying(255),
    amount_payable numeric(10,2) DEFAULT 0,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_applications OWNER TO postgres;

--
-- TOC entry 399 (class 1259 OID 268274)
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
-- TOC entry 10109 (class 0 OID 0)
-- Dependencies: 399
-- Name: loan_application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loan_application_id_seq OWNED BY public.loan_applications.id;


--
-- TOC entry 400 (class 1259 OID 268276)
-- Name: loan_partners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_partners (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    image_url character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_partners OWNER TO postgres;

--
-- TOC entry 401 (class 1259 OID 268285)
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
-- TOC entry 10112 (class 0 OID 0)
-- Dependencies: 401
-- Name: loan_partners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loan_partners_id_seq OWNED BY public.loan_partners.id;


--
-- TOC entry 402 (class 1259 OID 268287)
-- Name: loan_payment_modes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_payment_modes (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    image_url character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_payment_modes OWNER TO postgres;

--
-- TOC entry 403 (class 1259 OID 268295)
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
-- TOC entry 10115 (class 0 OID 0)
-- Dependencies: 403
-- Name: loan_payment_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loan_payment_modes_id_seq OWNED BY public.loan_payment_modes.id;


--
-- TOC entry 404 (class 1259 OID 268297)
-- Name: loan_procurement_docs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_procurement_docs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    procurement_id bigint NOT NULL,
    attachment character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_procurement_docs OWNER TO postgres;

--
-- TOC entry 405 (class 1259 OID 268305)
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
-- TOC entry 10118 (class 0 OID 0)
-- Dependencies: 405
-- Name: loan_procurement_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loan_procurement_attachments_id_seq OWNED BY public.loan_procurement_docs.id;


--
-- TOC entry 406 (class 1259 OID 268307)
-- Name: loan_procurements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_procurements (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    application_id character varying(255) NOT NULL,
    quantity bigint,
    grade character varying(25),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_procurements OWNER TO postgres;

--
-- TOC entry 407 (class 1259 OID 268317)
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
-- TOC entry 10121 (class 0 OID 0)
-- Dependencies: 407
-- Name: loan_procurements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loan_procurements_id_seq OWNED BY public.loan_procurements.id;


--
-- TOC entry 408 (class 1259 OID 268319)
-- Name: loan_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_transactions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    platform_id character varying(20),
    dt timestamp(6) without time zone DEFAULT CURRENT_DATE,
    transaction_id character varying(30) NOT NULL,
    application_id character varying(32) NOT NULL,
    profiler_type character varying(50),
    profiled_by character varying(50),
    mode_id character varying(64),
    amount_paid bigint,
    quantity numeric(11,0),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    image_url character varying(255),
    service_charges numeric(11,0) DEFAULT 0,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_transactions OWNER TO postgres;

--
-- TOC entry 409 (class 1259 OID 268329)
-- Name: loan_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loan_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.loan_types OWNER TO postgres;

--
-- TOC entry 410 (class 1259 OID 268339)
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
-- TOC entry 10125 (class 0 OID 0)
-- Dependencies: 410
-- Name: loan_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loan_types_id_seq OWNED BY public.loan_types.id;


--
-- TOC entry 411 (class 1259 OID 268341)
-- Name: location_crops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_crops (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    location_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    crop_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.location_crops OWNER TO postgres;

--
-- TOC entry 412 (class 1259 OID 268351)
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
-- TOC entry 10128 (class 0 OID 0)
-- Dependencies: 412
-- Name: location_crops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.location_crops_id_seq OWNED BY public.location_crops.id;


--
-- TOC entry 413 (class 1259 OID 268353)
-- Name: location_livestocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_livestocks (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    livestock_id character varying(255) NOT NULL,
    location_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.location_livestocks OWNER TO postgres;

--
-- TOC entry 414 (class 1259 OID 268363)
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
-- TOC entry 10131 (class 0 OID 0)
-- Dependencies: 414
-- Name: location_livestocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.location_livestocks_id_seq OWNED BY public.location_livestocks.id;


--
-- TOC entry 415 (class 1259 OID 268365)
-- Name: location_machineries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_machineries (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    location_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    machinery_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.location_machineries OWNER TO postgres;

--
-- TOC entry 416 (class 1259 OID 268375)
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
-- TOC entry 10134 (class 0 OID 0)
-- Dependencies: 416
-- Name: location_machineries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.location_machineries_id_seq OWNED BY public.location_machineries.id;


--
-- TOC entry 668 (class 1259 OID 324273)
-- Name: location_temp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_temp (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    geo_point character varying,
    province_id character varying(100),
    district_id character varying(100),
    tehsil_id character varying(100),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.location_temp OWNER TO postgres;

--
-- TOC entry 417 (class 1259 OID 268377)
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
-- TOC entry 827 (class 1259 OID 875344)
-- Name: locations_copy1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.locations_copy1 (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    type character varying,
    parent_id character varying(255),
    name_alt character varying,
    shape public.geometry,
    geo_point public.geometry,
    priority integer DEFAULT 100 NOT NULL,
    file_name character varying NOT NULL,
    content_id character varying(255) NOT NULL,
    name_urdu character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    location_id character varying(32)
);


ALTER TABLE public.locations_copy1 OWNER TO postgres;

--
-- TOC entry 419 (class 1259 OID 268388)
-- Name: machineries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.machineries (
    image_url character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    machinery_type_id character varying(255),
    title character varying,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    content_id character varying(255),
    name_alt character varying,
    title_urdu character varying,
    profiled_by character varying,
    profiler_type character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.machineries OWNER TO postgres;

--
-- TOC entry 420 (class 1259 OID 268399)
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
-- TOC entry 10140 (class 0 OID 0)
-- Dependencies: 420
-- Name: machineries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.machineries_id_seq OWNED BY public.machineries.id;


--
-- TOC entry 421 (class 1259 OID 268401)
-- Name: machinery_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.machinery_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying,
    image_url character varying,
    name_alt character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    content_id character varying(64),
    title_urdu character varying,
    profiled_by character varying,
    profiler_type character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.machinery_types OWNER TO postgres;

--
-- TOC entry 422 (class 1259 OID 268410)
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
-- TOC entry 10143 (class 0 OID 0)
-- Dependencies: 422
-- Name: machinery_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.machinery_types_id_seq OWNED BY public.machinery_types.id;


--
-- TOC entry 423 (class 1259 OID 268412)
-- Name: mandi_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mandi_categories (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying,
    description character varying,
    parent_id character varying(64),
    content_table character varying,
    title_urdu character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mandi_categories OWNER TO postgres;

--
-- TOC entry 424 (class 1259 OID 268420)
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
-- TOC entry 10146 (class 0 OID 0)
-- Dependencies: 424
-- Name: mandi_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mandi_categories_id_seq OWNED BY public.mandi_categories.id;


--
-- TOC entry 425 (class 1259 OID 268422)
-- Name: mandi_listing_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mandi_listing_images (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    listing_id character varying(255) NOT NULL,
    image character varying NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mandi_listing_images OWNER TO postgres;

--
-- TOC entry 426 (class 1259 OID 268430)
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
-- TOC entry 10149 (class 0 OID 0)
-- Dependencies: 426
-- Name: mandi_listing_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mandi_listing_images_id_seq OWNED BY public.mandi_listing_images.id;


--
-- TOC entry 427 (class 1259 OID 268432)
-- Name: mandi_listing_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mandi_listing_tags (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    listing_id character varying(255) NOT NULL,
    tag_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mandi_listing_tags OWNER TO postgres;

--
-- TOC entry 428 (class 1259 OID 268440)
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
-- TOC entry 10152 (class 0 OID 0)
-- Dependencies: 428
-- Name: mandi_listing_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mandi_listing_tags_id_seq OWNED BY public.mandi_listing_tags.id;


--
-- TOC entry 429 (class 1259 OID 268442)
-- Name: mandi_listings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mandi_listings (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    category_id character varying(255),
    description character varying,
    unit_price numeric(10,2),
    unit character varying,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    expiry_dt timestamp(6) without time zone NOT NULL,
    creator character varying,
    contact_no character varying,
    status character varying,
    location_id character varying(255),
    quantity double precision,
    quality character varying,
    item_id character varying(255),
    is_active boolean,
    is_deleted boolean DEFAULT false,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mandi_listings OWNER TO postgres;

--
-- TOC entry 430 (class 1259 OID 268451)
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
-- TOC entry 10155 (class 0 OID 0)
-- Dependencies: 430
-- Name: mandi_listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mandi_listings_id_seq OWNED BY public.mandi_listings.id;


--
-- TOC entry 431 (class 1259 OID 268453)
-- Name: mandi_listings_meta_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mandi_listings_meta_data (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    listing_id character varying(255),
    key character varying,
    value character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mandi_listings_meta_data OWNER TO postgres;

--
-- TOC entry 432 (class 1259 OID 268461)
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
-- TOC entry 10158 (class 0 OID 0)
-- Dependencies: 432
-- Name: mandi_listings_meta_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mandi_listings_meta_data_id_seq OWNED BY public.mandi_listings_meta_data.id;


--
-- TOC entry 433 (class 1259 OID 268463)
-- Name: mandi_reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mandi_reviews (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying,
    listing_id character varying(255),
    rating integer,
    description character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mandi_reviews OWNER TO postgres;

--
-- TOC entry 434 (class 1259 OID 268471)
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
-- TOC entry 10161 (class 0 OID 0)
-- Dependencies: 434
-- Name: mandi_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mandi_reviews_id_seq OWNED BY public.mandi_reviews.id;


--
-- TOC entry 435 (class 1259 OID 268473)
-- Name: master_dncr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.master_dncr (
    msisdn character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.master_dncr OWNER TO postgres;

--
-- TOC entry 752 (class 1259 OID 505033)
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
-- TOC entry 10164 (class 0 OID 0)
-- Dependencies: 752
-- Name: menu_crops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_crops_id_seq OWNED BY public.adoptive_menu_crops.id;


--
-- TOC entry 757 (class 1259 OID 505127)
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
-- TOC entry 10166 (class 0 OID 0)
-- Dependencies: 757
-- Name: menu_languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_languages_id_seq OWNED BY public.adoptive_menu_languages.id;


--
-- TOC entry 759 (class 1259 OID 505150)
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
-- TOC entry 10168 (class 0 OID 0)
-- Dependencies: 759
-- Name: menu_livestocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_livestocks_id_seq OWNED BY public.adoptive_menu_livestocks.id;


--
-- TOC entry 761 (class 1259 OID 505178)
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
-- TOC entry 10170 (class 0 OID 0)
-- Dependencies: 761
-- Name: menu_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_locations_id_seq OWNED BY public.adoptive_menu_locations.id;


--
-- TOC entry 763 (class 1259 OID 505201)
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
-- TOC entry 10172 (class 0 OID 0)
-- Dependencies: 763
-- Name: menu_machineries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menu_machineries_id_seq OWNED BY public.adoptive_menu_machineries.id;


--
-- TOC entry 436 (class 1259 OID 268487)
-- Name: mmbl_base; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mmbl_base (
    msisdn character varying(255),
    network_type character varying(255),
    operator_id integer
);


ALTER TABLE public.mmbl_base OWNER TO postgres;

--
-- TOC entry 437 (class 1259 OID 268493)
-- Name: mmbl_base_alisufi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mmbl_base_alisufi (
    "Customer_Msisdn" character varying(255),
    "Length" character varying(255),
    "Remarks" character varying(255),
    "Prefix" character varying(255),
    "Operator" character varying(255),
    "Customer_Number_in_Value" character varying(255),
    "Sequential_Number_Check" character varying(255),
    "Cnic_Segmentation_1" character varying(255),
    "Cnic_Segmentation_2" character varying(255),
    "Name" character varying(255),
    "Single_Location" character varying(255),
    "Lat_Long" character varying(255),
    "Farmer_Type" character varying(255),
    "Total_Acres" character varying(255),
    "Final_Check" character varying(255),
    "Customer_Msisdn1" character varying(255),
    "Cnic" character varying(255),
    "Gender" character varying(255),
    "Farmer_Name" character varying(255),
    "Farmer_Location" character varying(255),
    "Lat" character varying(255),
    "Long" character varying(255),
    "Lat_Long_Cross_Check" character varying(255),
    "Farmer_Type1" character varying(255),
    "Total_Acres(2)" character varying(255),
    "Crop_Live_Stock_Information" character varying(255)
);


ALTER TABLE public.mmbl_base_alisufi OWNER TO postgres;

--
-- TOC entry 438 (class 1259 OID 268499)
-- Name: mmbl_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mmbl_data (
    lat character varying(255),
    lng character varying(255),
    account_number_iban character varying(255),
    full_name character varying(255),
    cnic_no character varying(255),
    city character varying(255),
    mobile_number character varying(255),
    harvesting_date_kharif character varying(255),
    cultivation_date_kharif character varying(255),
    land_area_detail character varying(255),
    livestocktype_quantity_other character varying(255),
    livestock_estimate_cost_other character varying(255),
    livestocktype_quantity_goat character varying(255),
    livestock_estimate_cost_goat character varying(255),
    livestocktype_quantity_cow_buf character varying(255),
    livestock_estimate_cost_cow_buf character varying(255),
    agri_land_livestock_details character varying(255),
    agri_land_livestock_ownership character varying(255),
    rl_crop_name character varying(255),
    crop_details character varying(255),
    date_of_sowing character varying(255),
    land_area_detail_rental character varying(255),
    b2_livestocktype_quantity_other character varying(255),
    b2_livestock_estimate_cost_other character varying(255),
    b2_livestocktype_quantity_goat character varying(255),
    b2_livestock_estimate_cost_goat character varying(255),
    b2_livestocktype_quantity_cow_buf character varying(255),
    b2_livestock_estimate_cost_cow_buf character varying(255),
    livestocktype_quantity_cow character varying(255),
    livestock_estimate_cost_cow character varying(255),
    livestocktype_quantity_buffalo character varying(255),
    livestock_estimate_cost_buffalo character varying(255),
    livestocktype_quantity_sheep character varying(255),
    livestock_estimate_cost_sheep character varying(255),
    livestocktype_quantity_bull character varying(255),
    livestock_estimate_cost_bull character varying(255),
    landdetail_cultivation_acer character varying(255),
    id integer NOT NULL,
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    obd_sent boolean DEFAULT false,
    mmbl_reversal_id character varying(255),
    mmbl_trans_id character varying(255),
    reason_for_loan_type character varying(255),
    is_already_subscribed boolean DEFAULT false,
    bkk_trans_id character varying(255)
);


ALTER TABLE public.mmbl_data OWNER TO postgres;

--
-- TOC entry 439 (class 1259 OID 268508)
-- Name: mmbl_incorrect_tagging; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mmbl_incorrect_tagging (
    msisdn character varying(15),
    country_code character varying(5),
    location_id character varying(255),
    first_sub_dt timestamp(6) without time zone,
    last_sub_dt timestamp(6) without time zone,
    last_charge_dt timestamp(6) without time zone,
    grace_expire_dt timestamp(6) without time zone,
    firebase_session character varying(255),
    last_signin_dt timestamp(6) without time zone,
    operator_id character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    lat numeric(8,6),
    lng numeric(8,6),
    language_id character varying(255),
    sub_mode_id character varying(255),
    last_call_dt timestamp(6) without time zone,
    recent_activity_dt timestamp(6) without time zone,
    is_charging_enabled boolean,
    profiled_by character varying,
    profiler_type character varying,
    source character varying,
    is_purged boolean,
    last_purge_date timestamp(6) without time zone,
    charge_count integer,
    default_location_enabled boolean,
    category_type character varying,
    dbss_sync_dt timestamp(6) without time zone,
    next_charge_dt timestamp(6) without time zone,
    call_success bigint,
    is_verified boolean,
    guid character varying(255),
    partner_service_id character varying(255)
);


ALTER TABLE public.mmbl_incorrect_tagging OWNER TO postgres;

--
-- TOC entry 440 (class 1259 OID 268514)
-- Name: mmbl_test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mmbl_test (
    "GPS Coordinates (Latitude)" character varying(255),
    "GPS Coordinates (Longitude)" character varying(255),
    account_number_iban character varying(255),
    "FULL_NAME" character varying(255),
    "CNIC_NO" character varying(255),
    "CITY" character varying(255),
    mobile_number character varying(255),
    "Harvesting_Date_KHARIF" character varying(255),
    "Cultivation_date_KHARIF" character varying(255),
    "LAND_AREA_DETAIL" character varying(255),
    "LIVESTOCKTYPE_QUANTITY_OTHER" character varying(255),
    "LIVESTOCK_ESTIMATE_COST_OTHER" character varying(255),
    "LIVESTOCKTYPE_QUANTITY_GOAT" character varying(255),
    "LIVESTOCK_ESTIMATE_COST_GOAT" character varying(255),
    "LIVESTOCKTYPE_QUANTITY_Cow_Buf" character varying(255),
    "LIVESTOCK_ESTIMATE_COST_COW_BUF" character varying(255),
    "Agri_Land_Livestock_details" character varying(255),
    "Agri_Land_Livestock_OWNERSHIP" character varying(255),
    "RL_Crop_Name" character varying(255),
    "CROP_DETAILS" character varying(255),
    "DATE_OF_SOWING" character varying(255),
    "Land_Area_Detail_Rental" character varying(255),
    "B2_LIVESTOCKTYPE_QUANTITY_OTHER" character varying(255),
    "B2_LIVESTOCK_ESTIMATE_COST_OTHER" character varying(255),
    "B2_LIVESTOCKTYPE_QUANTITY_GOAT" character varying(255),
    "B2_LIVESTOCK_ESTIMATE_COST_GOAT" character varying(255),
    "B2_LIVESTOCKTYPE_QUANTITY_Cow_Buf" character varying(255),
    "B2_LIVESTOCK_ESTIMATE_COST_COW_BUF" character varying(255),
    "LIVESTOCKTYPE_QUANTITY_COW" character varying(255),
    "LIVESTOCK_ESTIMATE_COST_COW" character varying(255),
    "LIVESTOCKTYPE_QUANTITY_BUFFALO" character varying(255),
    "LIVESTOCK_ESTIMATE_COST_BUFFALO" character varying(255),
    "LIVESTOCKTYPE_QUANTITY_SHEEP" character varying(255),
    "LIVESTOCK_ESTIMATE_COST_SHEEP" character varying(255),
    "LIVESTOCKTYPE_QUANTITY_BULL" character varying(255),
    "LIVESTOCK_ESTIMATE_COST_BULL" character varying(255),
    "LandDetail_Cultivation_Acer" character varying(255),
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    "CreateDt" timestamp(6) without time zone,
    "UpdateDt" timestamp(6) without time zone,
    "OBD_sent" boolean DEFAULT false
);


ALTER TABLE public.mmbl_test OWNER TO postgres;

--
-- TOC entry 441 (class 1259 OID 268522)
-- Name: mmbl_transaction_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mmbl_transaction_logs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    transaction_id character varying(255) NOT NULL,
    account_number character varying(255) NOT NULL,
    corelation_id character varying(255) NOT NULL,
    product_name character varying(255) NOT NULL,
    service_name character varying(255) NOT NULL,
    product_amount character varying(255) NOT NULL,
    transaction_status character varying(255),
    reason character varying(255),
    narration character varying(255),
    transaction_type character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    reference_tid character varying(255)
);


ALTER TABLE public.mmbl_transaction_logs OWNER TO postgres;

--
-- TOC entry 442 (class 1259 OID 268529)
-- Name: mmbl_transaction_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mmbl_transaction_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.mmbl_transaction_logs_id_seq OWNER TO postgres;

--
-- TOC entry 10180 (class 0 OID 0)
-- Dependencies: 442
-- Name: mmbl_transaction_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mmbl_transaction_logs_id_seq OWNED BY public.mmbl_transaction_logs.id;


--
-- TOC entry 443 (class 1259 OID 268531)
-- Name: mo_sms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mo_sms (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) NOT NULL,
    extension character varying(255) NOT NULL,
    message text NOT NULL,
    message_dt timestamp(6) without time zone NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mo_sms OWNER TO postgres;

--
-- TOC entry 825 (class 1259 OID 831410)
-- Name: mouza; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mouza (
    district_name character varying(255),
    tehsil_name character varying(255),
    mauza_name character varying(255),
    shape public.geometry(MultiPolygon,4326),
    geo_point public.geometry(Point,4326)
);


ALTER TABLE public.mouza OWNER TO postgres;

--
-- TOC entry 444 (class 1259 OID 268540)
-- Name: mp_crop_diseases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mp_crop_diseases (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    crop_growth_stage_id character varying(255),
    crop_disease_id character varying(255) NOT NULL,
    crop_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mp_crop_diseases OWNER TO postgres;

--
-- TOC entry 445 (class 1259 OID 268548)
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
-- TOC entry 10185 (class 0 OID 0)
-- Dependencies: 445
-- Name: mp_crop_crop_diseases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mp_crop_crop_diseases_id_seq OWNED BY public.mp_crop_diseases.id;


--
-- TOC entry 446 (class 1259 OID 268550)
-- Name: mp_livestock_disease; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mp_livestock_disease (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mp_livestock_disease OWNER TO postgres;

--
-- TOC entry 447 (class 1259 OID 268558)
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
-- TOC entry 10188 (class 0 OID 0)
-- Dependencies: 447
-- Name: mp_livestock_disease_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mp_livestock_disease_id_seq OWNED BY public.mp_livestock_disease.id;


--
-- TOC entry 448 (class 1259 OID 268560)
-- Name: mp_livestock_farming_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mp_livestock_farming_categories (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    livestock_id character varying(64) NOT NULL,
    livestock_farming_category_id character varying(64) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.mp_livestock_farming_categories OWNER TO postgres;

--
-- TOC entry 449 (class 1259 OID 268568)
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
-- TOC entry 10191 (class 0 OID 0)
-- Dependencies: 449
-- Name: mp_livestock_farming_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mp_livestock_farming_categories_id_seq OWNED BY public.mp_livestock_farming_categories.id;


--
-- TOC entry 450 (class 1259 OID 268570)
-- Name: msisdn_tagged_as_csm1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.msisdn_tagged_as_csm1 (
    msisdn character varying(255)
);


ALTER TABLE public.msisdn_tagged_as_csm1 OWNER TO postgres;

--
-- TOC entry 451 (class 1259 OID 268573)
-- Name: msisdn_tagged_as_csm2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.msisdn_tagged_as_csm2 (
    msisdn character varying(255)
);


ALTER TABLE public.msisdn_tagged_as_csm2 OWNER TO postgres;

--
-- TOC entry 452 (class 1259 OID 268576)
-- Name: my_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.my_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.my_sequence OWNER TO postgres;

--
-- TOC entry 453 (class 1259 OID 268578)
-- Name: name_suggestions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.name_suggestions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.name_suggestions OWNER TO postgres;

--
-- TOC entry 454 (class 1259 OID 268586)
-- Name: narrative_list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.narrative_list (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    narrative_description character varying(255)
);


ALTER TABLE public.narrative_list OWNER TO postgres;

--
-- TOC entry 455 (class 1259 OID 268593)
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
-- TOC entry 10198 (class 0 OID 0)
-- Dependencies: 455
-- Name: narrative_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.narrative_list_id_seq OWNED BY public.narrative_list.id;


--
-- TOC entry 456 (class 1259 OID 268595)
-- Name: neighbouring_tehsils; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.neighbouring_tehsils (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    location_id character varying(64) NOT NULL,
    neighbouring_tehsil_id character varying(64) NOT NULL,
    seq_order integer DEFAULT 0,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    active smallint DEFAULT 1,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.neighbouring_tehsils OWNER TO postgres;

--
-- TOC entry 457 (class 1259 OID 268606)
-- Name: network_tagging; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.network_tagging (
    date date DEFAULT CURRENT_DATE,
    msisdn character varying(15) NOT NULL,
    db_network_type character varying(255),
    api_network_type character varying(255),
    api_reponse_id character varying(50),
    is_charging_enabled character varying(50),
    operator_id character varying(50)
);


ALTER TABLE public.network_tagging OWNER TO postgres;

--
-- TOC entry 458 (class 1259 OID 268613)
-- Name: network_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.network_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.network_types OWNER TO postgres;

--
-- TOC entry 459 (class 1259 OID 268624)
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
-- TOC entry 10203 (class 0 OID 0)
-- Dependencies: 459
-- Name: network_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.network_types_id_seq OWNED BY public.network_types.id;


--
-- TOC entry 806 (class 1259 OID 642067)
-- Name: notification_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_categories (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(60) NOT NULL,
    active boolean NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.notification_categories OWNER TO postgres;

--
-- TOC entry 460 (class 1259 OID 268626)
-- Name: notification_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_history (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    body text NOT NULL,
    data json,
    create_dt timestamp(6) without time zone DEFAULT now() NOT NULL,
    update_dt timestamp(6) without time zone,
    farmer_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    type_id character varying(255),
    type character varying(255) NOT NULL,
    read_by_admin boolean DEFAULT false NOT NULL,
    is_read boolean DEFAULT false,
    notification_category_id character varying,
    title_ur character varying(255)
);


ALTER TABLE public.notification_history OWNER TO postgres;

--
-- TOC entry 461 (class 1259 OID 268635)
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
-- TOC entry 10207 (class 0 OID 0)
-- Dependencies: 461
-- Name: notification_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_history_id_seq OWNED BY public.notification_history.id;


--
-- TOC entry 462 (class 1259 OID 268637)
-- Name: notification_modes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_modes (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying,
    active boolean,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.notification_modes OWNER TO postgres;

--
-- TOC entry 463 (class 1259 OID 268645)
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
-- TOC entry 10210 (class 0 OID 0)
-- Dependencies: 463
-- Name: notification_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_modes_id_seq OWNED BY public.notification_modes.id;


--
-- TOC entry 464 (class 1259 OID 268647)
-- Name: notification_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_types (
    title character varying(60) NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    active boolean NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.notification_types OWNER TO postgres;

--
-- TOC entry 465 (class 1259 OID 268655)
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
-- TOC entry 10213 (class 0 OID 0)
-- Dependencies: 465
-- Name: notification_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_types_id_seq OWNED BY public.notification_types.id;


--
-- TOC entry 466 (class 1259 OID 268657)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    msisdn character varying(15) NOT NULL,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    notification_mode_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 467 (class 1259 OID 268665)
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
-- TOC entry 10216 (class 0 OID 0)
-- Dependencies: 467
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 468 (class 1259 OID 268667)
-- Name: nutrient_deficiency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nutrient_deficiency (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    title_urdu character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    file_name character varying(255),
    content_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.nutrient_deficiency OWNER TO postgres;

--
-- TOC entry 469 (class 1259 OID 268676)
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
-- TOC entry 10219 (class 0 OID 0)
-- Dependencies: 469
-- Name: nutrient_deficiency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.nutrient_deficiency_id_seq OWNED BY public.nutrient_deficiency.id;


--
-- TOC entry 470 (class 1259 OID 268678)
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_access_tokens (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    access_token character varying,
    access_token_expires_at timestamp(6) without time zone,
    scope character varying,
    client_id character varying(255),
    user_id character varying(255),
    refresh_token character varying,
    refresh_token_expires_at timestamp(6) without time zone
);


ALTER TABLE public.oauth_access_tokens OWNER TO postgres;

--
-- TOC entry 471 (class 1259 OID 268685)
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
-- TOC entry 10222 (class 0 OID 0)
-- Dependencies: 471
-- Name: oauth_access_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oauth_access_token_id_seq OWNED BY public.oauth_access_tokens.id;


--
-- TOC entry 472 (class 1259 OID 268687)
-- Name: oauth_authorization_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_authorization_codes (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    authorization_code character varying,
    redirect_uri character varying,
    scope character varying,
    client_id character varying(255),
    user_id character varying(255)
);


ALTER TABLE public.oauth_authorization_codes OWNER TO postgres;

--
-- TOC entry 473 (class 1259 OID 268694)
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
-- TOC entry 10225 (class 0 OID 0)
-- Dependencies: 473
-- Name: oauth_authorization_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oauth_authorization_code_id_seq OWNED BY public.oauth_authorization_codes.id;


--
-- TOC entry 474 (class 1259 OID 268696)
-- Name: oauth_clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_clients (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    client_id character varying,
    client_secret character varying,
    name character varying,
    redirect_uri character varying,
    scope character varying
);


ALTER TABLE public.oauth_clients OWNER TO postgres;

--
-- TOC entry 475 (class 1259 OID 268703)
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
-- TOC entry 10228 (class 0 OID 0)
-- Dependencies: 475
-- Name: oauth_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oauth_clients_id_seq OWNED BY public.oauth_clients.id;


--
-- TOC entry 476 (class 1259 OID 268705)
-- Name: oauth_refresh_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_refresh_tokens (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    refresh_token character varying,
    refresh_token_expiry character varying,
    scope character varying,
    client_id character varying(255),
    user_id character varying(255)
);


ALTER TABLE public.oauth_refresh_tokens OWNER TO postgres;

--
-- TOC entry 477 (class 1259 OID 268712)
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
-- TOC entry 10231 (class 0 OID 0)
-- Dependencies: 477
-- Name: oauth_refresh_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oauth_refresh_token_id_seq OWNED BY public.oauth_refresh_tokens.id;


--
-- TOC entry 478 (class 1259 OID 268714)
-- Name: oauth_scopes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_scopes (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    scope character varying,
    is_default boolean
);


ALTER TABLE public.oauth_scopes OWNER TO postgres;

--
-- TOC entry 479 (class 1259 OID 268721)
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
-- TOC entry 10234 (class 0 OID 0)
-- Dependencies: 479
-- Name: oauth_scopes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oauth_scopes_id_seq OWNED BY public.oauth_scopes.id;


--
-- TOC entry 480 (class 1259 OID 268723)
-- Name: oauth_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_sessions (
    sid character varying(255) NOT NULL,
    sess json NOT NULL,
    expire timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.oauth_sessions OWNER TO postgres;

--
-- TOC entry 481 (class 1259 OID 268729)
-- Name: oauth_user_client_grants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_user_client_grants (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    client_id character varying(255),
    user_id character varying(255)
);


ALTER TABLE public.oauth_user_client_grants OWNER TO postgres;

--
-- TOC entry 482 (class 1259 OID 268736)
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
-- TOC entry 10238 (class 0 OID 0)
-- Dependencies: 482
-- Name: oauth_user_client_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oauth_user_client_grants_id_seq OWNED BY public.oauth_user_client_grants.id;


--
-- TOC entry 483 (class 1259 OID 268738)
-- Name: oauth_user_otp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_user_otp (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    user_id character varying(255) NOT NULL,
    otp character varying NOT NULL,
    valid_till timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.oauth_user_otp OWNER TO postgres;

--
-- TOC entry 484 (class 1259 OID 268745)
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
-- TOC entry 10241 (class 0 OID 0)
-- Dependencies: 484
-- Name: oauth_user_otp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oauth_user_otp_id_seq OWNED BY public.oauth_user_otp.id;


--
-- TOC entry 485 (class 1259 OID 268747)
-- Name: oauth_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_users (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    username character varying NOT NULL,
    password character varying,
    scope character varying,
    operator_id character varying(255),
    user_type character varying,
    firebase_uid character varying,
    is_2fa_enabled boolean DEFAULT false,
    user_type_id character varying(255)
);


ALTER TABLE public.oauth_users OWNER TO postgres;

--
-- TOC entry 486 (class 1259 OID 268755)
-- Name: obd_activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.obd_activities (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) NOT NULL,
    acitivty_name character varying(255) NOT NULL,
    context character varying(255) NOT NULL,
    channelid character varying(255) NOT NULL,
    uuid character varying(255) NOT NULL,
    dtmf character varying(1) DEFAULT NULL::character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.obd_activities OWNER TO postgres;

--
-- TOC entry 487 (class 1259 OID 268765)
-- Name: occupations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.occupations (
    title character varying NOT NULL,
    title_urdu character varying,
    content_id character varying(255),
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    key character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    app_data boolean,
    occupation_order bigint,
    image_url character varying(255)
);


ALTER TABLE public.occupations OWNER TO postgres;

--
-- TOC entry 488 (class 1259 OID 268773)
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
-- TOC entry 10246 (class 0 OID 0)
-- Dependencies: 488
-- Name: occupations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.occupations_id_seq OWNED BY public.occupations.id;


--
-- TOC entry 489 (class 1259 OID 268775)
-- Name: operator_check; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operator_check (
    msisdn character varying(15)
);


ALTER TABLE public.operator_check OWNER TO postgres;

--
-- TOC entry 490 (class 1259 OID 268778)
-- Name: operators; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operators (
    title character varying(50),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    image_url character varying,
    active boolean NOT NULL,
    country character varying,
    country_code character varying,
    sync_api_url character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title_urdu character varying(255),
    operator_order bigint
);


ALTER TABLE public.operators OWNER TO postgres;

--
-- TOC entry 491 (class 1259 OID 268787)
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
-- TOC entry 10250 (class 0 OID 0)
-- Dependencies: 491
-- Name: operators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.operators_id_seq OWNED BY public.operators.id;


--
-- TOC entry 804 (class 1259 OID 640438)
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    external_order_id character varying,
    order_source text NOT NULL,
    invoice_no character varying,
    customer_id character varying,
    customer_name character varying,
    initiator_id character varying,
    initiator_name character varying,
    msisdn character varying,
    city character varying,
    district character varying,
    tehsil character varying,
    farm_name character varying,
    delivery_address text,
    delivery_dt timestamp(6) without time zone,
    buyer_type character varying,
    visit_type character varying,
    lat numeric(8,6),
    lng numeric(8,6),
    sale_amount numeric,
    payment_status character varying,
    payment_mode character varying,
    payment_collected numeric,
    crop_livestock character varying,
    order_status character varying,
    order_dt timestamp(6) without time zone,
    order_update_dt timestamp(6) without time zone,
    note text,
    profit numeric,
    product_list text,
    cancelled_at timestamp(6) without time zone,
    cancel_reason text,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- TOC entry 836 (class 1259 OID 1563032)
-- Name: otp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.otp (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    otp character varying(255),
    create_dt character varying(255),
    update_dt character varying(255),
    msisdn character varying(255)
);


ALTER TABLE public.otp OWNER TO postgres;

--
-- TOC entry 802 (class 1259 OID 633436)
-- Name: otp_whitelisted_numbers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.otp_whitelisted_numbers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.otp_whitelisted_numbers OWNER TO postgres;

--
-- TOC entry 492 (class 1259 OID 268789)
-- Name: paidwalls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paidwalls (
    id character varying(40) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(100) NOT NULL,
    service_name character varying(20),
    service_code character varying(20),
    queue_tag character varying(50) NOT NULL,
    daily_call_limit smallint DEFAULT 1,
    active smallint DEFAULT 1 NOT NULL,
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dt timestamp(6) without time zone
);


ALTER TABLE public.paidwalls OWNER TO postgres;

--
-- TOC entry 493 (class 1259 OID 268796)
-- Name: partner_procurement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner_procurement (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    application_id character varying(255) NOT NULL,
    partner_id character varying(255) NOT NULL,
    total_amount integer NOT NULL,
    yeild character varying(255) NOT NULL,
    procurement_date date NOT NULL,
    paid_amount integer NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.partner_procurement OWNER TO postgres;

--
-- TOC entry 494 (class 1259 OID 268806)
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
-- TOC entry 10257 (class 0 OID 0)
-- Dependencies: 494
-- Name: partner_procurement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partner_procurement_id_seq OWNED BY public.partner_procurement.id;


--
-- TOC entry 495 (class 1259 OID 268808)
-- Name: partner_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner_services (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    charge_interval integer,
    sub_sms text,
    unsub_sms text,
    charge_sms text,
    partner_id character varying(255),
    sequence_order integer,
    title character varying(255),
    subscribed_sms text,
    unsubscribed_sms text,
    charges character varying(255),
    service_id character varying(255) NOT NULL,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.partner_services OWNER TO postgres;

--
-- TOC entry 496 (class 1259 OID 268817)
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
-- TOC entry 10260 (class 0 OID 0)
-- Dependencies: 496
-- Name: partner_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partner_services_id_seq OWNED BY public.partner_services.id;


--
-- TOC entry 497 (class 1259 OID 268819)
-- Name: partners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partners (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    name character varying(255),
    is_weather_sms boolean NOT NULL,
    is_dbss_sync boolean NOT NULL,
    is_charging_enabled boolean NOT NULL,
    is_obd_enabled boolean NOT NULL,
    is_sms_enabled boolean NOT NULL,
    in_app_enabled boolean NOT NULL,
    active boolean NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    start_dt timestamp(6) without time zone NOT NULL,
    end_dt timestamp(6) without time zone NOT NULL,
    is_sms_service_enabled boolean
);


ALTER TABLE public.partners OWNER TO postgres;

--
-- TOC entry 498 (class 1259 OID 268827)
-- Name: partners_msisdn; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partners_msisdn (
    partner_id character varying(255) NOT NULL,
    msisdn character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.partners_msisdn OWNER TO postgres;

--
-- TOC entry 669 (class 1259 OID 324302)
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    method character varying(255) NOT NULL,
    url character varying(255) NOT NULL
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- TOC entry 499 (class 1259 OID 268834)
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
-- TOC entry 10265 (class 0 OID 0)
-- Dependencies: 499
-- Name: pests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pests_id_seq OWNED BY public.crop_insects.id;


--
-- TOC entry 500 (class 1259 OID 268836)
-- Name: phrase_32_char_list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.phrase_32_char_list (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    phrase_description character varying(255)
);


ALTER TABLE public.phrase_32_char_list OWNER TO postgres;

--
-- TOC entry 501 (class 1259 OID 268843)
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
-- TOC entry 10268 (class 0 OID 0)
-- Dependencies: 501
-- Name: phrase_32_char_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.phrase_32_char_list_id_seq OWNED BY public.phrase_32_char_list.id;


--
-- TOC entry 789 (class 1259 OID 583709)
-- Name: pin_crops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pin_crops (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    farmer_id character varying(255),
    crop_id character varying(255),
    seq_order integer DEFAULT 0,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.pin_crops OWNER TO postgres;

--
-- TOC entry 790 (class 1259 OID 583725)
-- Name: pin_farms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pin_farms (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    farmer_id character varying(255),
    pin_crop_id uuid,
    farm_id character varying(255),
    seq_order integer DEFAULT 0,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone,
    fav_farm boolean DEFAULT false
);


ALTER TABLE public.pin_farms OWNER TO postgres;

--
-- TOC entry 502 (class 1259 OID 268845)
-- Name: pivot_exapmle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pivot_exapmle (
    student character varying(255),
    subject character varying(255),
    grade character varying(255)
);


ALTER TABLE public.pivot_exapmle OWNER TO postgres;

--
-- TOC entry 503 (class 1259 OID 268851)
-- Name: player; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name text,
    points integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.player OWNER TO postgres;

--
-- TOC entry 504 (class 1259 OID 268859)
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
-- TOC entry 10274 (class 0 OID 0)
-- Dependencies: 504
-- Name: player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.player_id_seq OWNED BY public.player.id;


--
-- TOC entry 814 (class 1259 OID 647751)
-- Name: post_anomaly; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_anomaly (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    post_id character varying(255),
    anomaly_id uuid,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.post_anomaly OWNER TO postgres;

--
-- TOC entry 819 (class 1259 OID 660674)
-- Name: post_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_status (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone
);


ALTER TABLE public.post_status OWNER TO postgres;

--
-- TOC entry 687 (class 1259 OID 406793)
-- Name: posts_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posts_tags (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    title_urdu character varying(255) NOT NULL,
    is_auto_approved boolean DEFAULT false
);


ALTER TABLE public.posts_tags OWNER TO postgres;

--
-- TOC entry 505 (class 1259 OID 268861)
-- Name: pro_farmer_profile_update; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pro_farmer_profile_update (
    email character varying(255) NOT NULL,
    count integer DEFAULT 0,
    date date DEFAULT CURRENT_DATE NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.pro_farmer_profile_update OWNER TO postgres;

--
-- TOC entry 506 (class 1259 OID 268870)
-- Name: process_partners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.process_partners (
    msisdn character varying(255) NOT NULL,
    charged_dt timestamp without time zone,
    charged_status character varying(255) DEFAULT '-100'::integer,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone,
    category_type character varying(255),
    partner_id character varying(255),
    partner_name character varying(255),
    file_name character varying(255),
    transaction_id character varying(255)
);


ALTER TABLE public.process_partners OWNER TO postgres;

--
-- TOC entry 507 (class 1259 OID 268878)
-- Name: processed_tehsils; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.processed_tehsils (
    location_id bigint,
    farmer_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.processed_tehsils OWNER TO postgres;

--
-- TOC entry 508 (class 1259 OID 268885)
-- Name: profile_change_set; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile_change_set (
    id uuid DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) NOT NULL,
    farm_id character varying(255) DEFAULT NULL::character varying,
    table_name character varying(255) NOT NULL,
    column_key character varying(255) NOT NULL,
    column_value character varying(255) DEFAULT NULL::character varying,
    operation_type character varying(255) NOT NULL,
    profiled_by character varying(255) NOT NULL,
    profiled_dt timestamp(6) without time zone NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    livestock_farm_id character varying(255)
);


ALTER TABLE public.profile_change_set OWNER TO postgres;

--
-- TOC entry 10282 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.id IS 'auto genrated uuid';


--
-- TOC entry 10283 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.msisdn; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.msisdn IS 'profile identity by';


--
-- TOC entry 10284 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.table_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.table_name IS 'name of the table';


--
-- TOC entry 10285 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.column_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.column_key IS 'name of the column';


--
-- TOC entry 10286 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.column_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.column_value IS 'column''s value';


--
-- TOC entry 10287 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.operation_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.operation_type IS 'add, update, delete';


--
-- TOC entry 10288 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.profiled_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.profiled_by IS 'agent, system etc';


--
-- TOC entry 10289 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.profiled_dt; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.profiled_dt IS 'time when vale was added ';


--
-- TOC entry 10290 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.create_dt; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.create_dt IS 'record created date';


--
-- TOC entry 10291 (class 0 OID 0)
-- Dependencies: 508
-- Name: COLUMN profile_change_set.update_dt; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profile_change_set.update_dt IS 'record updated date';


--
-- TOC entry 509 (class 1259 OID 268895)
-- Name: profile_change_set_default; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile_change_set_default (
    id uuid DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) NOT NULL,
    farm_id character varying(255) DEFAULT NULL::character varying,
    table_name character varying(255) NOT NULL,
    column_key character varying(255) NOT NULL,
    column_value text DEFAULT NULL::character varying,
    operation_type character varying(255) NOT NULL,
    profiled_by character varying(255) NOT NULL,
    profiled_dt timestamp(6) without time zone NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.profile_change_set_default OWNER TO postgres;

--
-- TOC entry 510 (class 1259 OID 268905)
-- Name: profile_change_set_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile_change_set_stats (
    id uuid DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    stats_sync_dt date NOT NULL,
    farmers bigint DEFAULT 0 NOT NULL,
    subscribers bigint DEFAULT 0 NOT NULL,
    unsubscribers bigint DEFAULT 0 NOT NULL,
    zero_profiles bigint DEFAULT 0 NOT NULL,
    partial_profiles bigint DEFAULT 0 NOT NULL,
    basic_profiles bigint DEFAULT 0 NOT NULL,
    advanced_profiles bigint DEFAULT 0 NOT NULL,
    advanced_plus_profiles bigint DEFAULT 0 NOT NULL,
    crop_total_profiles bigint DEFAULT 0 NOT NULL,
    crop_basic_profiles bigint DEFAULT 0 NOT NULL,
    crop_advanced_profiles bigint DEFAULT 0 NOT NULL,
    crop_advanced_plus_profiles bigint DEFAULT 0 NOT NULL,
    livestock_total_profiles bigint DEFAULT 0 NOT NULL,
    livestock_basic_profiles bigint DEFAULT 0 NOT NULL,
    livestock_advanced_profiles bigint DEFAULT 0 NOT NULL,
    livestock_advanced_plus_profiles bigint DEFAULT 0 NOT NULL,
    crop_and_livestock_total_profiles bigint DEFAULT 0 NOT NULL,
    crop_and_livestock_basic_profiles bigint DEFAULT 0 NOT NULL,
    crop_and_livestock_advanced_profiles bigint DEFAULT 0 NOT NULL,
    crop_and_livestock_advanced_plus_profiles bigint DEFAULT 0 NOT NULL,
    non_farmer_total_profiles bigint DEFAULT 0 NOT NULL,
    non_farmer_basic_profiles bigint DEFAULT 0 NOT NULL,
    non_farmer_advanced_profiles bigint DEFAULT 0 NOT NULL,
    non_farmer_advanced_plus_profiles bigint DEFAULT 0 NOT NULL,
    sync_start_dt timestamp(6) without time zone NOT NULL,
    sync_end_dt timestamp(6) without time zone NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.profile_change_set_stats OWNER TO postgres;

--
-- TOC entry 511 (class 1259 OID 268934)
-- Name: profile_levels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile_levels (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone,
    active smallint DEFAULT 1 NOT NULL,
    rank integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.profile_levels OWNER TO postgres;

--
-- TOC entry 684 (class 1259 OID 405705)
-- Name: profile_stages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile_stages (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(255) NOT NULL,
    old_stage character varying(255) DEFAULT 'Non-Profiled'::character varying NOT NULL,
    new_stage character varying(255) NOT NULL,
    profiled_by character varying(255) NOT NULL,
    farmer_name character varying(255) DEFAULT NULL::character varying,
    farmer_cnic character varying(255) DEFAULT NULL::character varying,
    farmer_occupation character varying(255) DEFAULT NULL::character varying,
    farmer_location character varying(255) DEFAULT NULL::character varying,
    farmer_livestock character varying(255) DEFAULT NULL::character varying,
    farm_id character varying(255) DEFAULT NULL::character varying,
    farm_location character varying(255) DEFAULT NULL::character varying,
    farm_shape text DEFAULT NULL::character varying,
    farm_land_area character varying(255) DEFAULT NULL::character varying,
    farm_soil_type character varying(255) DEFAULT NULL::character varying,
    crop_name character varying(255) DEFAULT NULL::character varying,
    crop_seed_name character varying(255) DEFAULT NULL::character varying,
    crop_growth_stage character varying(255) DEFAULT NULL::character varying,
    crop_growth_stage_dt timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    action_type character varying(255) NOT NULL,
    action_dt timestamp(0) without time zone NOT NULL,
    comments text,
    create_dt timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(0) without time zone
);


ALTER TABLE public.profile_stages OWNER TO postgres;

--
-- TOC entry 512 (class 1259 OID 268942)
-- Name: profile_stages_testing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile_stages_testing (
    msisdn character varying(255) NOT NULL,
    profile_stage character varying(255),
    profiled_by character varying(255),
    farmer_type character varying(255),
    action character varying(255),
    comments text,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    action_dt timestamp(6) without time zone,
    occupation character varying(255),
    previous_stage character varying(255)
);


ALTER TABLE public.profile_stages_testing OWNER TO postgres;

--
-- TOC entry 638 (class 1259 OID 323857)
-- Name: profiling_nps_survey; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiling_nps_survey (
    id character varying(100) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(11) NOT NULL,
    survey_id character varying(100) NOT NULL,
    priority smallint DEFAULT 1 NOT NULL,
    satisfied smallint DEFAULT 0,
    satisfied_dt timestamp(6) without time zone DEFAULT NULL::timestamp without time zone,
    dissatisfied_count integer DEFAULT 0,
    last_dissatisfied_dt timestamp(6) without time zone DEFAULT NULL::timestamp without time zone,
    survey_enabled smallint DEFAULT 0,
    cc_enabled smallint DEFAULT 0,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone DEFAULT NULL::timestamp without time zone,
    flagged integer DEFAULT 0,
    last_flagged_dt timestamp(6) with time zone
);


ALTER TABLE public.profiling_nps_survey OWNER TO postgres;

--
-- TOC entry 513 (class 1259 OID 268949)
-- Name: promo_data_count; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.promo_data_count (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255),
    campaign_id character varying(255),
    total_data_count character varying(255) DEFAULT '0'::character varying,
    processed_data_count character varying(255) DEFAULT '0'::character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    uploaded_data_count character varying(255) DEFAULT '0'::character varying
);


ALTER TABLE public.promo_data_count OWNER TO postgres;

--
-- TOC entry 514 (class 1259 OID 268960)
-- Name: province; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.province (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    advisory_type integer,
    menu_type integer,
    status integer,
    aw_type integer,
    default_lang character varying(10),
    eve_start_time time(6) without time zone,
    eve_end_time time(6) without time zone,
    has_default_srvc integer,
    has_live_show integer,
    tp_id character varying(30),
    aw_validity_min integer,
    has_menu integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.province OWNER TO postgres;

--
-- TOC entry 515 (class 1259 OID 268968)
-- Name: provinces; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.provinces (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    active smallint NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.provinces OWNER TO postgres;

--
-- TOC entry 824 (class 1259 OID 831078)
-- Name: punjab_agri_profiled_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.punjab_agri_profiled_users (
    kissan_card character varying(255),
    cotton_rec character varying(255),
    divison character varying(255),
    district character varying(255),
    tehsil character varying(255),
    uc character varying(255),
    address character varying(255),
    name character varying(255),
    f_name character varying(255),
    cnic character varying(255),
    total_land_in_acres character varying(255),
    cotton_sown_in_acres character varying(255),
    date_of_sowing character varying(255),
    sowing_dt character varying(255),
    card_limit character varying(255),
    loan_status character varying(255),
    district_id character varying(255),
    tehsil_id character varying(255),
    variety_name character varying(255),
    msisdn character varying(255),
    bkk_sub_status character varying(255),
    operator character varying(255),
    operator_type character varying(255),
    last_updated character varying(255)
);


ALTER TABLE public.punjab_agri_profiled_users OWNER TO postgres;

--
-- TOC entry 816 (class 1259 OID 649279)
-- Name: qrp_case_products; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.qrp_case_products (
    id text DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    qrp_case_id text NOT NULL,
    chemical_ai text,
    trade_name text,
    company text,
    price numeric,
    product_url text,
    created_dt timestamp without time zone DEFAULT now()
);


ALTER TABLE public.qrp_case_products OWNER TO rameez_dev_rw;

--
-- TOC entry 810 (class 1259 OID 645534)
-- Name: qrp_cases; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.qrp_cases (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    category text,
    sub_category text,
    topic text,
    agent_id text,
    farmer_id character varying(255),
    created_dt timestamp without time zone DEFAULT now(),
    updated_dt timestamp without time zone DEFAULT now(),
    chemical_details jsonb,
    crop text
);


ALTER TABLE public.qrp_cases OWNER TO rameez_dev_rw;

--
-- TOC entry 812 (class 1259 OID 645545)
-- Name: qrp_searches; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.qrp_searches (
    id integer NOT NULL,
    query text,
    created_dt timestamp without time zone DEFAULT now(),
    updated_dt timestamp without time zone DEFAULT now()
);


ALTER TABLE public.qrp_searches OWNER TO rameez_dev_rw;

--
-- TOC entry 811 (class 1259 OID 645543)
-- Name: qrp_searches_id_seq; Type: SEQUENCE; Schema: public; Owner: rameez_dev_rw
--

CREATE SEQUENCE public.qrp_searches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.qrp_searches_id_seq OWNER TO rameez_dev_rw;

--
-- TOC entry 10306 (class 0 OID 0)
-- Dependencies: 811
-- Name: qrp_searches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rameez_dev_rw
--

ALTER SEQUENCE public.qrp_searches_id_seq OWNED BY public.qrp_searches.id;


--
-- TOC entry 516 (class 1259 OID 268976)
-- Name: questionair; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.questionair (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    options json NOT NULL,
    status boolean NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.questionair OWNER TO postgres;

--
-- TOC entry 517 (class 1259 OID 268986)
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
-- TOC entry 10308 (class 0 OID 0)
-- Dependencies: 517
-- Name: questionair_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.questionair_id_seq OWNED BY public.questionair.id;


--
-- TOC entry 518 (class 1259 OID 268988)
-- Name: questionair_response; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.questionair_response (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    farmer_id character varying(255) NOT NULL,
    question_id character varying(255) NOT NULL,
    partner_id character varying(255) NOT NULL,
    response character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.questionair_response OWNER TO postgres;

--
-- TOC entry 519 (class 1259 OID 268998)
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
-- TOC entry 10311 (class 0 OID 0)
-- Dependencies: 519
-- Name: questionair_response_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.questionair_response_id_seq OWNED BY public.questionair_response.id;


--
-- TOC entry 520 (class 1259 OID 269000)
-- Name: queue_position; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.queue_position (
    id character varying(64) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    position_code character varying(255) NOT NULL,
    create_dt character varying(255) DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.queue_position OWNER TO postgres;

--
-- TOC entry 521 (class 1259 OID 269008)
-- Name: queue_position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.queue_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.queue_position_id_seq OWNER TO postgres;

--
-- TOC entry 522 (class 1259 OID 269010)
-- Name: reapagro_promts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reapagro_promts (
    msisdn character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.reapagro_promts OWNER TO postgres;

--
-- TOC entry 523 (class 1259 OID 269017)
-- Name: recording_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recording_logs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) NOT NULL,
    file_name character varying(255) NOT NULL,
    context character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    state character varying(255),
    channel_id character varying(255) NOT NULL,
    duration bigint,
    talking_duration bigint,
    silence_duration bigint,
    status integer DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.recording_logs OWNER TO postgres;

--
-- TOC entry 524 (class 1259 OID 269027)
-- Name: remove_from_partners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.remove_from_partners (
    msisdn character varying(15)
);


ALTER TABLE public.remove_from_partners OWNER TO postgres;

--
-- TOC entry 670 (class 1259 OID 324343)
-- Name: roles_backup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles_backup (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    app boolean,
    portal boolean,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.roles_backup OWNER TO postgres;

--
-- TOC entry 671 (class 1259 OID 324353)
-- Name: roles_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles_permissions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    role_id character varying(255),
    permission_id character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.roles_permissions OWNER TO postgres;

--
-- TOC entry 525 (class 1259 OID 269030)
-- Name: scenarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scenarios (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    scenario_uuid character varying(255) NOT NULL,
    active smallint DEFAULT 0 NOT NULL,
    validation_query text NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    start_dt timestamp(6) without time zone,
    end_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.scenarios OWNER TO postgres;

--
-- TOC entry 526 (class 1259 OID 269040)
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
-- TOC entry 10321 (class 0 OID 0)
-- Dependencies: 526
-- Name: scenarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scenarios_id_seq OWNED BY public.scenarios.id;


--
-- TOC entry 527 (class 1259 OID 269042)
-- Name: seed_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.seed_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying,
    active boolean DEFAULT true,
    title_urdu character varying,
    content_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    crop_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.seed_types OWNER TO postgres;

--
-- TOC entry 528 (class 1259 OID 269051)
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
-- TOC entry 10324 (class 0 OID 0)
-- Dependencies: 528
-- Name: seed_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.seed_types_id_seq OWNED BY public.seed_types.id;


--
-- TOC entry 529 (class 1259 OID 269053)
-- Name: sentiments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sentiments (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    creator_id character varying(255) NOT NULL,
    post_id character varying(255) NOT NULL,
    sentiment smallint NOT NULL,
    reaction character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.sentiments OWNER TO postgres;

--
-- TOC entry 530 (class 1259 OID 269061)
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
-- TOC entry 10327 (class 0 OID 0)
-- Dependencies: 530
-- Name: sentiments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sentiments_id_seq OWNED BY public.sentiments.id;


--
-- TOC entry 531 (class 1259 OID 269063)
-- Name: services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.services (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    profiled_by character varying(50),
    profiler_type character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.services OWNER TO postgres;

--
-- TOC entry 532 (class 1259 OID 269073)
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
-- TOC entry 10330 (class 0 OID 0)
-- Dependencies: 532
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- TOC entry 783 (class 1259 OID 559285)
-- Name: shopify_buyers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shopify_buyers (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(20) NOT NULL,
    buyer_type_id character varying(255) NOT NULL,
    first_order_id character varying(255) NOT NULL,
    last_order_id character varying(255) NOT NULL,
    first_order_dt timestamp(6) without time zone NOT NULL,
    last_order_dt timestamp(6) without time zone NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.shopify_buyers OWNER TO postgres;

--
-- TOC entry 807 (class 1259 OID 642078)
-- Name: shopify_visitors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shopify_visitors (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    msisdn character varying(20) NOT NULL,
    visited_at timestamp(6) without time zone DEFAULT now()
);


ALTER TABLE public.shopify_visitors OWNER TO postgres;

--
-- TOC entry 808 (class 1259 OID 642085)
-- Name: shopify_visitors_interests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shopify_visitors_interests (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    msisdn character varying(20) NOT NULL,
    interests text NOT NULL,
    visit_id uuid,
    create_dt timestamp(6) without time zone DEFAULT now()
);


ALTER TABLE public.shopify_visitors_interests OWNER TO postgres;

--
-- TOC entry 533 (class 1259 OID 269075)
-- Name: sites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sites (
    name character varying(100),
    lat numeric(8,6),
    lng numeric(8,6),
    geo_point character varying,
    geom public.geometry(Point,4326),
    event_id bigint,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.sites OWNER TO postgres;

--
-- TOC entry 534 (class 1259 OID 269083)
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
-- TOC entry 535 (class 1259 OID 269085)
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
-- TOC entry 10337 (class 0 OID 0)
-- Dependencies: 535
-- Name: sites_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sites_id_seq1 OWNED BY public.sites.id;


--
-- TOC entry 672 (class 1259 OID 324363)
-- Name: sites_temp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sites_temp (
    name character varying(100),
    lat numeric(8,6),
    lng numeric(8,6),
    geo_point character varying,
    geom public.geometry,
    event_id bigint,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.sites_temp OWNER TO postgres;

--
-- TOC entry 781 (class 1259 OID 558207)
-- Name: sms_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_keys (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    table_name character varying(255),
    columns character varying(255),
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sms_keys OWNER TO postgres;

--
-- TOC entry 536 (class 1259 OID 269087)
-- Name: sms_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_logs (
    user_details text,
    context text,
    msisdn character varying(255),
    extension character varying(255),
    create_dt timestamp(6) without time zone
);


ALTER TABLE public.sms_logs OWNER TO postgres;

--
-- TOC entry 537 (class 1259 OID 269093)
-- Name: sms_profiling; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_profiling (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    menu_title character varying(255),
    parent_id character varying(255),
    menu_type character varying(255),
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sms_profiling OWNER TO postgres;

--
-- TOC entry 538 (class 1259 OID 269101)
-- Name: sms_profiling_activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_profiling_activities (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    menu_id character varying(255),
    answer character varying(255) DEFAULT NULL::character varying,
    msisdn character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sms_profiling_activities OWNER TO postgres;

--
-- TOC entry 539 (class 1259 OID 269110)
-- Name: sms_survey_form_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_survey_form_status (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255),
    send boolean,
    viewed_status boolean,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    completed_status boolean,
    sms_status boolean,
    obd_status boolean DEFAULT false,
    obd_date timestamp(6) without time zone,
    form_src character varying(255)
);


ALTER TABLE public.sms_survey_form_status OWNER TO postgres;

--
-- TOC entry 540 (class 1259 OID 269119)
-- Name: sms_survey_question_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_survey_question_log (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    menu_id character varying(255),
    question_id character varying(255),
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(6) without time zone
);


ALTER TABLE public.sms_survey_question_log OWNER TO postgres;

--
-- TOC entry 541 (class 1259 OID 269127)
-- Name: sms_survey_questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_survey_questions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    question text,
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dt timestamp(6) without time zone,
    context boolean,
    type character varying(255)
);


ALTER TABLE public.sms_survey_questions OWNER TO postgres;

--
-- TOC entry 542 (class 1259 OID 269135)
-- Name: sms_surveyform_params; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sms_surveyform_params (
    id integer DEFAULT nextval('public.queue_position_id_seq'::regclass) NOT NULL,
    msisdn character varying(255),
    params text,
    random_id character varying(255),
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(6) without time zone
);


ALTER TABLE public.sms_surveyform_params OWNER TO postgres;

--
-- TOC entry 543 (class 1259 OID 269143)
-- Name: soil_issues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.soil_issues (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    title_urdu character varying,
    content_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.soil_issues OWNER TO postgres;

--
-- TOC entry 544 (class 1259 OID 269151)
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
-- TOC entry 10349 (class 0 OID 0)
-- Dependencies: 544
-- Name: soil_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.soil_issues_id_seq OWNED BY public.soil_issues.id;


--
-- TOC entry 545 (class 1259 OID 269153)
-- Name: soil_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.soil_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    title_urdu character varying,
    content_id character varying(64),
    profiled_by character varying,
    profiler_type character varying,
    create_dt timestamp(6) without time zone,
    "order" timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.soil_types OWNER TO postgres;

--
-- TOC entry 546 (class 1259 OID 269161)
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
-- TOC entry 10352 (class 0 OID 0)
-- Dependencies: 546
-- Name: soil_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.soil_types_id_seq OWNED BY public.soil_types.id;


--
-- TOC entry 547 (class 1259 OID 269163)
-- Name: source_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.source_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    sync_api_url character varying,
    preference character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.source_types OWNER TO postgres;

--
-- TOC entry 548 (class 1259 OID 269171)
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
-- TOC entry 10355 (class 0 OID 0)
-- Dependencies: 548
-- Name: source_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.source_types_id_seq OWNED BY public.source_types.id;


--
-- TOC entry 549 (class 1259 OID 269173)
-- Name: sowing_methods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sowing_methods (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    title_urdu character varying(255),
    content_id character varying(255),
    profiled_by character varying,
    profiler_type character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    "order" integer,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.sowing_methods OWNER TO postgres;

--
-- TOC entry 550 (class 1259 OID 269182)
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
-- TOC entry 10358 (class 0 OID 0)
-- Dependencies: 550
-- Name: sowing_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sowing_methods_id_seq OWNED BY public.sowing_methods.id;


--
-- TOC entry 551 (class 1259 OID 269184)
-- Name: stats_notifications_replica; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stats_notifications_replica (
    id integer DEFAULT nextval('public.hourly_stat_receivers_id_seq'::regclass) NOT NULL,
    name character varying(50),
    cellno character varying(20),
    email character varying(50),
    department character varying(50),
    designation character varying(50),
    task_id character varying(50),
    hourly_sms_notifications boolean,
    hourly_email_notifications boolean,
    daily_sms_notifications boolean,
    daily_email_notifications boolean
);


ALTER TABLE public.stats_notifications_replica OWNER TO postgres;

--
-- TOC entry 552 (class 1259 OID 269188)
-- Name: sub_dbss_sync_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sub_dbss_sync_log (
    msisdn character varying(255),
    create_dt timestamp(6) without time zone,
    dbss_response character varying(255),
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.sub_dbss_sync_log OWNER TO postgres;

--
-- TOC entry 553 (class 1259 OID 269195)
-- Name: sub_modes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sub_modes (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.sub_modes OWNER TO postgres;

--
-- TOC entry 554 (class 1259 OID 269206)
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
-- TOC entry 10364 (class 0 OID 0)
-- Dependencies: 554
-- Name: sub_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sub_modes_id_seq OWNED BY public.sub_modes.id;


--
-- TOC entry 555 (class 1259 OID 269208)
-- Name: subscriber_base_network_tagging_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscriber_base_network_tagging_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriber_base_network_tagging_id_seq OWNER TO postgres;

--
-- TOC entry 556 (class 1259 OID 269210)
-- Name: subscriber_base_network_tagging; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriber_base_network_tagging (
    id integer DEFAULT nextval('public.subscriber_base_network_tagging_id_seq'::regclass) NOT NULL,
    date date DEFAULT CURRENT_DATE,
    msisdn character varying(15) NOT NULL,
    db_network_type character varying(255),
    api_network_type character varying(255),
    api_reponse_id character varying(50),
    is_charging_enabled character varying(50),
    operator_id character varying(50)
);


ALTER TABLE public.subscriber_base_network_tagging OWNER TO postgres;

--
-- TOC entry 557 (class 1259 OID 269218)
-- Name: subscriber_base_other_network_tagging; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriber_base_other_network_tagging (
    id integer NOT NULL,
    date date DEFAULT CURRENT_DATE,
    msisdn character varying(15) NOT NULL,
    db_network_type character varying(255),
    api_network_type character varying(255),
    api_reponse_id character varying(50),
    is_charging_enabled character varying(50),
    operator_id character varying(50)
);


ALTER TABLE public.subscriber_base_other_network_tagging OWNER TO postgres;

--
-- TOC entry 558 (class 1259 OID 269225)
-- Name: subscriber_base_other_network_tagging_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.subscriber_base_other_network_tagging ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.subscriber_base_other_network_tagging_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 559 (class 1259 OID 269227)
-- Name: subscriber_notification_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriber_notification_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    notification_type_id character varying(255) NOT NULL,
    msisdn character varying NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    is_enabled boolean,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.subscriber_notification_types OWNER TO postgres;

--
-- TOC entry 560 (class 1259 OID 269236)
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
-- TOC entry 10371 (class 0 OID 0)
-- Dependencies: 560
-- Name: subscriber_notification_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscriber_notification_types_id_seq OWNED BY public.subscriber_notification_types.id;


--
-- TOC entry 561 (class 1259 OID 269238)
-- Name: subscriber_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriber_roles (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying NOT NULL,
    role_id character varying(255) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.subscriber_roles OWNER TO postgres;

--
-- TOC entry 562 (class 1259 OID 269247)
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
-- TOC entry 10374 (class 0 OID 0)
-- Dependencies: 562
-- Name: subscriber_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscriber_roles_id_seq OWNED BY public.subscriber_roles.id;


--
-- TOC entry 563 (class 1259 OID 269249)
-- Name: subscriber_tagging_update; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriber_tagging_update (
    msisdn character varying(15) NOT NULL,
    country_code character varying(5) NOT NULL,
    location_id character varying(255),
    first_sub_dt timestamp(6) without time zone NOT NULL,
    last_sub_dt timestamp(6) without time zone,
    last_charge_dt timestamp(6) without time zone,
    grace_expire_dt timestamp(6) without time zone,
    firebase_session character varying(255),
    last_signin_dt timestamp(6) without time zone,
    operator_id character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    lat numeric(8,6),
    lng numeric(8,6),
    language_id character varying(255),
    sub_mode_id character varying(255) NOT NULL,
    last_call_dt timestamp(6) without time zone,
    recent_activity_dt timestamp(6) without time zone,
    is_charging_enabled boolean NOT NULL,
    profiled_by character varying,
    profiler_type character varying,
    source character varying NOT NULL,
    is_purged boolean NOT NULL,
    last_purge_date timestamp(6) without time zone,
    charge_count integer,
    default_location_enabled boolean,
    category_type character varying,
    dbss_sync_dt timestamp(6) without time zone,
    next_charge_dt timestamp(6) without time zone,
    call_success bigint NOT NULL,
    is_verified boolean,
    guid character varying(255) NOT NULL,
    partner_service_id character varying(255),
    id character varying(255) NOT NULL
);


ALTER TABLE public.subscriber_tagging_update OWNER TO postgres;

--
-- TOC entry 564 (class 1259 OID 269255)
-- Name: subscribers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscribers (
    msisdn character varying(15) NOT NULL,
    country_code character varying(5) NOT NULL,
    location_id character varying(255),
    first_sub_dt timestamp(6) without time zone NOT NULL,
    last_sub_dt timestamp(6) without time zone,
    last_charge_dt timestamp(6) without time zone,
    grace_expire_dt timestamp(6) without time zone,
    firebase_session character varying(255),
    last_signin_dt timestamp(6) without time zone,
    operator_id character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    lat numeric(8,6),
    lng numeric(8,6),
    language_id character varying(255),
    sub_mode_id character varying(255) NOT NULL,
    last_call_dt timestamp(6) without time zone,
    recent_activity_dt timestamp(6) without time zone,
    is_charging_enabled boolean DEFAULT true NOT NULL,
    profiled_by character varying,
    profiler_type character varying,
    source character varying NOT NULL,
    is_purged boolean DEFAULT false NOT NULL,
    last_purge_date timestamp(6) without time zone,
    charge_count integer,
    default_location_enabled boolean DEFAULT true,
    category_type character varying,
    dbss_sync_dt timestamp(6) without time zone,
    next_charge_dt timestamp(6) without time zone,
    call_success bigint DEFAULT 0 NOT NULL,
    is_verified boolean,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    partner_service_id character varying(255),
    is_blocked boolean,
    tenant character varying(100) DEFAULT 'global'::character varying NOT NULL,
    form_sent integer DEFAULT '-1'::integer,
    CONSTRAINT subscribers_form_sent_check CHECK ((form_sent = ANY (ARRAY['-1'::integer, 0, 1])))
);


ALTER TABLE public.subscribers OWNER TO postgres;

--
-- TOC entry 565 (class 1259 OID 269267)
-- Name: subscribers_job_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscribers_job_logs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    job_id character varying(255) NOT NULL,
    request_id character varying(255) NOT NULL,
    msisdn character varying(15),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.subscribers_job_logs OWNER TO postgres;

--
-- TOC entry 566 (class 1259 OID 269276)
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
-- TOC entry 10379 (class 0 OID 0)
-- Dependencies: 566
-- Name: subscribers_job_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscribers_job_logs_id_seq OWNED BY public.subscribers_job_logs.id;


--
-- TOC entry 567 (class 1259 OID 269278)
-- Name: subscribers_test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscribers_test (
    msisdn character varying(15) NOT NULL,
    country_code character varying(5) NOT NULL,
    location_id character varying(255),
    first_sub_dt timestamp(6) without time zone NOT NULL,
    last_sub_dt timestamp(6) without time zone,
    last_charge_dt timestamp(6) without time zone,
    grace_expire_dt timestamp(6) without time zone,
    firebase_session character varying(255),
    last_signin_dt timestamp(6) without time zone,
    operator_id character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    lat numeric(8,6),
    lng numeric(8,6),
    language_id character varying(255) DEFAULT '497b928d-14f9-99be-2e18-653b0328653b'::character varying,
    sub_mode_id character varying(255) NOT NULL,
    last_call_dt timestamp(6) without time zone,
    recent_activity_dt timestamp(6) without time zone,
    is_charging_enabled boolean DEFAULT true NOT NULL,
    profiled_by character varying,
    profiler_type character varying,
    source character varying NOT NULL,
    is_purged boolean DEFAULT false NOT NULL,
    last_purge_date timestamp(6) without time zone,
    charge_count integer,
    default_location_enabled boolean DEFAULT true,
    category_type character varying,
    dbss_sync_dt timestamp(6) without time zone,
    next_charge_dt timestamp(6) without time zone,
    call_success bigint DEFAULT 0 NOT NULL,
    is_verified boolean,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.subscribers_test OWNER TO postgres;

--
-- TOC entry 568 (class 1259 OID 269290)
-- Name: subscribers_testt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscribers_testt (
    msisdn character varying(15) NOT NULL,
    country_code character varying(5) NOT NULL,
    location_id character varying(255),
    first_sub_dt timestamp(6) without time zone NOT NULL,
    last_sub_dt timestamp(6) without time zone,
    last_charge_dt timestamp(6) without time zone,
    grace_expire_dt timestamp(6) without time zone,
    firebase_session character varying(255),
    last_signin_dt timestamp(6) without time zone,
    operator_id character varying(255),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    lat numeric(8,6),
    lng numeric(8,6),
    language_id character varying(255) DEFAULT '497b928d-14f9-99be-2e18-653b0328653b'::character varying,
    sub_mode_id character varying(255) NOT NULL,
    last_call_dt timestamp(6) without time zone,
    recent_activity_dt timestamp(6) without time zone,
    is_charging_enabled boolean DEFAULT true NOT NULL,
    profiled_by character varying,
    profiler_type character varying,
    source character varying NOT NULL,
    is_purged boolean DEFAULT false NOT NULL,
    last_purge_date timestamp(6) without time zone,
    charge_count integer,
    default_location_enabled boolean DEFAULT true,
    category_type character varying,
    dbss_sync_dt timestamp(6) without time zone,
    next_charge_dt timestamp(6) without time zone,
    call_success bigint DEFAULT 0 NOT NULL,
    is_verified boolean,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.subscribers_testt OWNER TO postgres;

--
-- TOC entry 569 (class 1259 OID 269302)
-- Name: subscription_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscription_types (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    price numeric(10,2) DEFAULT NULL::numeric,
    recurrence public.sub_recurrences,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.subscription_types OWNER TO postgres;

--
-- TOC entry 570 (class 1259 OID 269313)
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
-- TOC entry 10384 (class 0 OID 0)
-- Dependencies: 570
-- Name: subscription_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscription_types_id_seq OWNED BY public.subscription_types.id;


--
-- TOC entry 571 (class 1259 OID 269315)
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriptions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    subscription_type_id character varying(255) NOT NULL,
    msisdn character varying(12) NOT NULL,
    charge_attempt_dt timestamp(6) without time zone,
    last_charge_dt timestamp(6) without time zone,
    next_charge_dt timestamp(6) without time zone,
    grace_expire_dt timestamp(6) without time zone,
    last_ibd_dt timestamp(6) without time zone,
    last_obd_dt timestamp(6) without time zone,
    last_purged_dt timestamp(6) without time zone,
    purged smallint DEFAULT 0 NOT NULL,
    charge_count bigint DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp without time zone,
    update_dt timestamp without time zone
);


ALTER TABLE public.subscriptions OWNER TO postgres;

--
-- TOC entry 572 (class 1259 OID 269325)
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
-- TOC entry 10387 (class 0 OID 0)
-- Dependencies: 572
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- TOC entry 573 (class 1259 OID 269327)
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
-- TOC entry 10389 (class 0 OID 0)
-- Dependencies: 573
-- Name: subscriptions_subscription_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscriptions_subscription_type_id_seq OWNED BY public.subscriptions.subscription_type_id;


--
-- TOC entry 712 (class 1259 OID 503012)
-- Name: survey_activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_activities (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(15),
    survey_id character varying(255),
    dtmf character varying(1) DEFAULT NULL::character varying,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    channel_id character varying(255),
    activity_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    mode character varying(255)
);


ALTER TABLE public.survey_activities OWNER TO postgres;

--
-- TOC entry 713 (class 1259 OID 503023)
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
-- TOC entry 10392 (class 0 OID 0)
-- Dependencies: 713
-- Name: survey_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_activities_id_seq OWNED BY public.survey_activities.id;


--
-- TOC entry 721 (class 1259 OID 503121)
-- Name: survey_input_api_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_input_api_actions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    action_id character varying(255) NOT NULL,
    survey_input_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 1 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.survey_input_api_actions OWNER TO postgres;

--
-- TOC entry 722 (class 1259 OID 503132)
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
-- TOC entry 10395 (class 0 OID 0)
-- Dependencies: 722
-- Name: survey_api_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_api_actions_id_seq OWNED BY public.survey_input_api_actions.id;


--
-- TOC entry 714 (class 1259 OID 503028)
-- Name: survey_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_categories (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    survey_category character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_categories OWNER TO postgres;

--
-- TOC entry 715 (class 1259 OID 503037)
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
-- TOC entry 10398 (class 0 OID 0)
-- Dependencies: 715
-- Name: survey_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_categories_id_seq OWNED BY public.survey_categories.id;


--
-- TOC entry 716 (class 1259 OID 503041)
-- Name: survey_crops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_crops (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255) NOT NULL,
    stage_id character varying(255) DEFAULT 1,
    crop_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_crops OWNER TO postgres;

--
-- TOC entry 717 (class 1259 OID 503050)
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
-- TOC entry 10401 (class 0 OID 0)
-- Dependencies: 717
-- Name: survey_crops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_crops_id_seq OWNED BY public.survey_crops.id;


--
-- TOC entry 718 (class 1259 OID 503069)
-- Name: survey_file_name_apis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_file_name_apis (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) DEFAULT NULL::character varying,
    action_id character varying(255) NOT NULL,
    survey_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_file_name_apis OWNER TO postgres;

--
-- TOC entry 719 (class 1259 OID 503094)
-- Name: survey_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_files (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255) NOT NULL,
    content_file_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    seq_order integer DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_files OWNER TO postgres;

--
-- TOC entry 720 (class 1259 OID 503105)
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
-- TOC entry 10405 (class 0 OID 0)
-- Dependencies: 720
-- Name: survey_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_files_id_seq OWNED BY public.survey_files.id;


--
-- TOC entry 678 (class 1259 OID 387390)
-- Name: surveys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.surveys (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    start_dt timestamp(6) without time zone,
    end_dt timestamp(6) without time zone,
    survey_category_id character varying(255) NOT NULL,
    in_app_enabled boolean DEFAULT false NOT NULL,
    obd_enabled boolean DEFAULT false NOT NULL,
    ivr_enabled boolean DEFAULT false NOT NULL,
    sms_enabled boolean DEFAULT false NOT NULL,
    validation_query text,
    data_query text,
    file_name_query text,
    content_text character varying(255),
    survey_type_id character varying(255),
    is_user_charged boolean,
    is_user_purged boolean,
    active_subscriber_range bigint,
    operator_id character varying(255),
    once_per_call boolean DEFAULT false NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    once_per_call_global boolean DEFAULT false NOT NULL,
    repeat_per_call boolean,
    callback_start_dt timestamp(6) without time zone DEFAULT NULL::timestamp without time zone,
    callback_end_dt timestamp(6) without time zone DEFAULT NULL::timestamp without time zone,
    callback_enabled boolean DEFAULT false
);


ALTER TABLE public.surveys OWNER TO postgres;

--
-- TOC entry 679 (class 1259 OID 387409)
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
-- TOC entry 10408 (class 0 OID 0)
-- Dependencies: 679
-- Name: survey_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_id_seq OWNED BY public.surveys.id;


--
-- TOC entry 724 (class 1259 OID 503152)
-- Name: survey_input_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_input_files (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_input_id character varying(255) NOT NULL,
    content_file_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    seq_order integer DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_input_files OWNER TO postgres;

--
-- TOC entry 725 (class 1259 OID 503163)
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
-- TOC entry 10411 (class 0 OID 0)
-- Dependencies: 725
-- Name: survey_input_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_input_files_id_seq OWNED BY public.survey_input_files.id;


--
-- TOC entry 726 (class 1259 OID 503177)
-- Name: survey_input_trunk_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_input_trunk_actions (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    action_id character varying(255) NOT NULL,
    survey_input_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 1 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.survey_input_trunk_actions OWNER TO postgres;

--
-- TOC entry 727 (class 1259 OID 503188)
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
-- TOC entry 10414 (class 0 OID 0)
-- Dependencies: 727
-- Name: survey_input_trunk_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_input_trunk_actions_id_seq OWNED BY public.survey_input_trunk_actions.id;


--
-- TOC entry 680 (class 1259 OID 387617)
-- Name: survey_inputs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_inputs (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255) NOT NULL,
    input_digit character varying(1) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_inputs OWNER TO postgres;

--
-- TOC entry 723 (class 1259 OID 503143)
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
-- TOC entry 10417 (class 0 OID 0)
-- Dependencies: 723
-- Name: survey_inputs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_inputs_id_seq OWNED BY public.survey_inputs.id;


--
-- TOC entry 728 (class 1259 OID 503199)
-- Name: survey_languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_languages (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255) NOT NULL,
    language_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_languages OWNER TO postgres;

--
-- TOC entry 729 (class 1259 OID 503207)
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
-- TOC entry 10420 (class 0 OID 0)
-- Dependencies: 729
-- Name: survey_languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_languages_id_seq OWNED BY public.survey_languages.id;


--
-- TOC entry 730 (class 1259 OID 503221)
-- Name: survey_livestocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_livestocks (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255) NOT NULL,
    livestock_id character varying(255) NOT NULL,
    category_id character varying(255) DEFAULT 1,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_livestocks OWNER TO postgres;

--
-- TOC entry 731 (class 1259 OID 503230)
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
-- TOC entry 10423 (class 0 OID 0)
-- Dependencies: 731
-- Name: survey_livestocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_livestocks_id_seq OWNED BY public.survey_livestocks.id;


--
-- TOC entry 732 (class 1259 OID 503249)
-- Name: survey_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_locations (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255) NOT NULL,
    location_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_locations OWNER TO postgres;

--
-- TOC entry 733 (class 1259 OID 503257)
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
-- TOC entry 10426 (class 0 OID 0)
-- Dependencies: 733
-- Name: survey_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_locations_id_seq OWNED BY public.survey_locations.id;


--
-- TOC entry 734 (class 1259 OID 503271)
-- Name: survey_machineries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_machineries (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255) NOT NULL,
    machinery_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_machineries OWNER TO postgres;

--
-- TOC entry 735 (class 1259 OID 503279)
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
-- TOC entry 10429 (class 0 OID 0)
-- Dependencies: 735
-- Name: survey_machineries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_machineries_id_seq OWNED BY public.survey_machineries.id;


--
-- TOC entry 736 (class 1259 OID 503288)
-- Name: survey_operator; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_operator (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    survey_id character varying(255) NOT NULL,
    operator_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_operator OWNER TO postgres;

--
-- TOC entry 574 (class 1259 OID 269495)
-- Name: survey_operator_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.survey_operator_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.survey_operator_id_seq OWNER TO postgres;

--
-- TOC entry 737 (class 1259 OID 503308)
-- Name: survey_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_profiles (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(15) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    survey_id character varying(255) NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_profiles OWNER TO postgres;

--
-- TOC entry 738 (class 1259 OID 503318)
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
-- TOC entry 10434 (class 0 OID 0)
-- Dependencies: 738
-- Name: survey_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_profiles_id_seq OWNED BY public.survey_profiles.id;


--
-- TOC entry 739 (class 1259 OID 503327)
-- Name: survey_promo_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_promo_data (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    survey_id character varying(64),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_promo_data OWNER TO postgres;

--
-- TOC entry 740 (class 1259 OID 503336)
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
-- TOC entry 10437 (class 0 OID 0)
-- Dependencies: 740
-- Name: survey_promo_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.survey_promo_data_id_seq OWNED BY public.survey_promo_data.id;


--
-- TOC entry 741 (class 1259 OID 503340)
-- Name: survey_questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_questions (
    id character varying NOT NULL,
    question_smart_phone_possesion boolean,
    question_download_app boolean,
    question_subscribe_user boolean
);


ALTER TABLE public.survey_questions OWNER TO postgres;

--
-- TOC entry 742 (class 1259 OID 503348)
-- Name: survey_validation_apis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.survey_validation_apis (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    action_id character varying(255) NOT NULL,
    survey_id character varying(255) NOT NULL,
    seq_order integer DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp without time zone,
    title character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.survey_validation_apis OWNER TO postgres;

--
-- TOC entry 803 (class 1259 OID 638590)
-- Name: sync_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sync_jobs (
    id character varying(255) DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.sync_jobs OWNER TO postgres;

--
-- TOC entry 575 (class 1259 OID 269526)
-- Name: system_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_settings (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    key character varying,
    value character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone
);


ALTER TABLE public.system_settings OWNER TO postgres;

--
-- TOC entry 576 (class 1259 OID 269534)
-- Name: system_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_users (
    username character varying(255),
    password character varying(255)
);


ALTER TABLE public.system_users OWNER TO postgres;

--
-- TOC entry 577 (class 1259 OID 269540)
-- Name: tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tags (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying NOT NULL,
    is_enabled boolean DEFAULT false,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt character varying(255)
);


ALTER TABLE public.tags OWNER TO postgres;

--
-- TOC entry 578 (class 1259 OID 269549)
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
-- TOC entry 10445 (class 0 OID 0)
-- Dependencies: 578
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- TOC entry 579 (class 1259 OID 269551)
-- Name: tehsil_data_ml; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tehsil_data_ml (
    names character varying(255),
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.tehsil_data_ml OWNER TO postgres;

--
-- TOC entry 673 (class 1259 OID 324384)
-- Name: tehsil_temp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tehsil_temp (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    district character varying(255),
    lat numeric(8,6),
    lng numeric(8,6)
);


ALTER TABLE public.tehsil_temp OWNER TO postgres;

--
-- TOC entry 580 (class 1259 OID 269559)
-- Name: tehsils; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tehsils (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    district_id character varying(255) NOT NULL,
    geo_point character varying,
    active smallint NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.tehsils OWNER TO postgres;

--
-- TOC entry 674 (class 1259 OID 324391)
-- Name: temp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.temp (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring),
    name character varying,
    translation character varying
);


ALTER TABLE public.temp OWNER TO postgres;

--
-- TOC entry 581 (class 1259 OID 269567)
-- Name: tenants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenants (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    base_path character varying(255),
    active integer,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    key character varying(255),
    extension character varying(255)
);


ALTER TABLE public.tenants OWNER TO postgres;

--
-- TOC entry 582 (class 1259 OID 269576)
-- Name: terms_of_use; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.terms_of_use (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    version numeric(4,2) NOT NULL,
    url character varying,
    is_active boolean DEFAULT false NOT NULL,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.terms_of_use OWNER TO postgres;

--
-- TOC entry 583 (class 1259 OID 269585)
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
-- TOC entry 788 (class 1259 OID 580454)
-- Name: test_farmer_names; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_farmer_names (
    msisdn character varying(255),
    name character varying(255),
    formated_name character varying(255)
);


ALTER TABLE public.test_farmer_names OWNER TO postgres;

--
-- TOC entry 584 (class 1259 OID 269587)
-- Name: testing_numbers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.testing_numbers (
    id bigint NOT NULL,
    msisdn character varying(15) NOT NULL
);


ALTER TABLE public.testing_numbers OWNER TO postgres;

--
-- TOC entry 585 (class 1259 OID 269590)
-- Name: testing_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.testing_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.testing_numbers_id_seq OWNER TO postgres;

--
-- TOC entry 10456 (class 0 OID 0)
-- Dependencies: 585
-- Name: testing_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.testing_numbers_id_seq OWNED BY public.testing_numbers.id;


--
-- TOC entry 586 (class 1259 OID 269592)
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
-- TOC entry 10458 (class 0 OID 0)
-- Dependencies: 586
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.loan_transactions.id;


--
-- TOC entry 587 (class 1259 OID 269594)
-- Name: trunk_call_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trunk_call_details (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    trunk_name character varying(255) NOT NULL,
    endpoint character varying(255) NOT NULL,
    mask character varying(255) DEFAULT NULL::character varying,
    stasis_name character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    offtime_content_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    validation_query text
);


ALTER TABLE public.trunk_call_details OWNER TO postgres;

--
-- TOC entry 588 (class 1259 OID 269606)
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
-- TOC entry 10461 (class 0 OID 0)
-- Dependencies: 588
-- Name: trunk_call_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trunk_call_details_id_seq OWNED BY public.trunk_call_details.id;


--
-- TOC entry 589 (class 1259 OID 269608)
-- Name: trunk_dialing_timings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trunk_dialing_timings (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    trunk_call_detail_id character varying(255) NOT NULL,
    start_time time(6) without time zone,
    end_time time(6) without time zone,
    week_days character varying(255) DEFAULT NULL::character varying,
    month_days character varying(255) DEFAULT NULL::character varying,
    year_months character varying(255) DEFAULT NULL::character varying,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    seq_order smallint DEFAULT 0 NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.trunk_dialing_timings OWNER TO postgres;

--
-- TOC entry 590 (class 1259 OID 269622)
-- Name: trunk_recording_timings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trunk_recording_timings (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    trunk_call_detail_id character varying(255) NOT NULL,
    start_time time(6) without time zone,
    end_time time(6) without time zone,
    week_days character varying(255) DEFAULT NULL::character varying,
    month_days character varying(255) DEFAULT NULL::character varying,
    year_months character varying(255) DEFAULT NULL::character varying,
    recording_path_id character varying(255) NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    seq_order smallint DEFAULT 0 NOT NULL,
    content_id character varying(255) NOT NULL,
    max_duration_seconds bigint NOT NULL,
    max_silence_seconds bigint NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.trunk_recording_timings OWNER TO postgres;

--
-- TOC entry 591 (class 1259 OID 269636)
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
-- TOC entry 10465 (class 0 OID 0)
-- Dependencies: 591
-- Name: trunk_recording_timings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trunk_recording_timings_id_seq OWNED BY public.trunk_recording_timings.id;


--
-- TOC entry 592 (class 1259 OID 269638)
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
-- TOC entry 10467 (class 0 OID 0)
-- Dependencies: 592
-- Name: trunk_timings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.trunk_timings_id_seq OWNED BY public.trunk_dialing_timings.id;


--
-- TOC entry 593 (class 1259 OID 269640)
-- Name: tts_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tts_records (
    username character varying(255),
    audio_path character varying,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tts_records OWNER TO postgres;

--
-- TOC entry 594 (class 1259 OID 269647)
-- Name: ufone_operator; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ufone_operator (
    msisdn character varying(15)
);


ALTER TABLE public.ufone_operator OWNER TO postgres;

--
-- TOC entry 595 (class 1259 OID 269650)
-- Name: unsub_modes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unsub_modes (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255),
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.unsub_modes OWNER TO postgres;

--
-- TOC entry 596 (class 1259 OID 269658)
-- Name: unsub_request_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.unsub_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.unsub_request_id_seq OWNER TO postgres;

--
-- TOC entry 597 (class 1259 OID 269660)
-- Name: unsub_request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unsub_request (
    id integer DEFAULT nextval('public.unsub_request_id_seq'::regclass) NOT NULL,
    msisdn character varying(255) NOT NULL,
    ref_id integer,
    date timestamp(6) without time zone,
    requested_by character varying(255),
    created_on timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    status boolean,
    unsub_on timestamp(6) without time zone
);


ALTER TABLE public.unsub_request OWNER TO postgres;

--
-- TOC entry 598 (class 1259 OID 269668)
-- Name: unsubscribers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unsubscribers (
    msisdn character varying(15) NOT NULL,
    country_code character varying(5),
    location_id character varying(255),
    first_sub_dt timestamp(6) without time zone,
    last_sub_dt timestamp(6) without time zone,
    last_charge_dt timestamp(6) without time zone,
    grace_expire_dt timestamp(6) without time zone,
    last_signin_dt timestamp(6) without time zone,
    farmer_id character varying(255),
    operator_id character varying(255),
    last_unsub_dt timestamp(6) without time zone,
    unsub_mode character varying(40),
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    is_blocked boolean,
    source character varying,
    is_purged boolean DEFAULT false NOT NULL,
    last_purge_date timestamp(6) without time zone,
    charge_count integer,
    is_host boolean,
    is_charging_enabled boolean DEFAULT true NOT NULL,
    recent_activity_dt timestamp(6) without time zone,
    default_location_enabled boolean DEFAULT true,
    language_id character varying(255),
    dbss_sync_dt timestamp(6) without time zone,
    next_charge_dt timestamp(6) without time zone,
    call_success bigint DEFAULT 0 NOT NULL,
    in_app_enabled boolean,
    obd_enabled boolean,
    sms_enabled boolean,
    category_type character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    lat numeric(8,6),
    lng numeric(8,6),
    partner_service_id character varying(255),
    profiled_by character varying(255),
    profiler_type character varying(255),
    tenant character varying(100) DEFAULT 'global'::character varying NOT NULL,
    unsub_mode_id character varying(255),
    sub_mode_id character varying(255)
);


ALTER TABLE public.unsubscribers OWNER TO postgres;

--
-- TOC entry 599 (class 1259 OID 269680)
-- Name: user_activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_activities (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    action character varying NOT NULL,
    description character varying NOT NULL,
    data character varying NOT NULL,
    "user" character varying NOT NULL,
    user_type character varying NOT NULL,
    create_dt timestamp(6) without time zone NOT NULL,
    update_dt timestamp(6) without time zone,
    table_name character varying NOT NULL,
    role_id character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.user_activities OWNER TO postgres;

--
-- TOC entry 600 (class 1259 OID 269688)
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
-- TOC entry 10476 (class 0 OID 0)
-- Dependencies: 600
-- Name: user_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_activities_id_seq OWNED BY public.user_activities.id;


--
-- TOC entry 823 (class 1259 OID 830747)
-- Name: user_engagement; Type: TABLE; Schema: public; Owner: naqia_dev_rw
--

CREATE TABLE public.user_engagement (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    msisdn character varying(255) NOT NULL,
    advisory_kharif integer DEFAULT 0,
    advisory_rabi integer DEFAULT 0,
    livestock_advisory integer DEFAULT 0,
    product_advisory integer DEFAULT 0,
    weather_alert integer DEFAULT 0,
    ivr_advisory integer DEFAULT 0,
    vms integer DEFAULT 0,
    disaster_alert integer DEFAULT 0,
    digital integer DEFAULT 0,
    create_dt timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_dt timestamp without time zone,
    agri_consultancy integer DEFAULT 0
);


ALTER TABLE public.user_engagement OWNER TO naqia_dev_rw;

--
-- TOC entry 601 (class 1259 OID 269690)
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
-- TOC entry 10479 (class 0 OID 0)
-- Dependencies: 601
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.oauth_users.id;


--
-- TOC entry 602 (class 1259 OID 269692)
-- Name: weather_change_set; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_change_set (
    site_id character varying(255) NOT NULL,
    temp integer,
    min_temp integer,
    max_temp integer,
    condition_id bigint,
    weather_date date NOT NULL,
    weather_time time(6) without time zone,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    lat numeric(8,6),
    lng numeric(8,6),
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    hour integer,
    daily_daypart_name character varying(50),
    phrase32_id integer,
    intra_icon_code integer,
    qualifier_code character varying(50),
    qualifier character varying(255),
    wx_phrase_id integer,
    hourly_icon_code integer,
    qualifier_set integer[],
    narrative_id integer,
    daily_icon_code integer,
    precip_chance integer,
    thunder_category integer,
    qualifier_phrase character varying(255),
    intra_daypart_name character varying(50),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weather_change_set OWNER TO postgres;

--
-- TOC entry 603 (class 1259 OID 269700)
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
-- TOC entry 604 (class 1259 OID 269702)
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
-- TOC entry 10483 (class 0 OID 0)
-- Dependencies: 604
-- Name: weather_change_set_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weather_change_set_id_seq1 OWNED BY public.weather_change_set.id;


--
-- TOC entry 605 (class 1259 OID 269704)
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
-- TOC entry 606 (class 1259 OID 269712)
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
-- TOC entry 607 (class 1259 OID 269714)
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
-- TOC entry 10487 (class 0 OID 0)
-- Dependencies: 607
-- Name: weather_conditions_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weather_conditions_id_seq1 OWNED BY public.weather_conditions.id;


--
-- TOC entry 608 (class 1259 OID 269716)
-- Name: weather_daily; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_daily (
    site_id character varying(255),
    lat numeric(8,6),
    lng numeric(8,6),
    min_temp integer,
    max_temp integer,
    condition_id bigint,
    date date,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    wind_speed bigint,
    humidity bigint,
    sunrise timestamp(6) without time zone,
    sunset timestamp(6) without time zone,
    moonrise timestamp(6) without time zone,
    moonset timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weather_daily OWNER TO postgres;

--
-- TOC entry 609 (class 1259 OID 269725)
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
-- TOC entry 610 (class 1259 OID 269727)
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
-- TOC entry 10491 (class 0 OID 0)
-- Dependencies: 610
-- Name: weather_daily_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weather_daily_id_seq1 OWNED BY public.weather_daily.id;


--
-- TOC entry 611 (class 1259 OID 269729)
-- Name: weather_hourly; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_hourly (
    site_id bigint,
    lat numeric(8,6),
    lng numeric(8,6),
    temp integer,
    condition_id bigint,
    weather_dt timestamp(6) without time zone,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    wind_speed bigint,
    humidity bigint,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weather_hourly OWNER TO postgres;

--
-- TOC entry 612 (class 1259 OID 269737)
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
-- TOC entry 613 (class 1259 OID 269739)
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
-- TOC entry 10495 (class 0 OID 0)
-- Dependencies: 613
-- Name: weather_hourly_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weather_hourly_id_seq1 OWNED BY public.weather_hourly.id;


--
-- TOC entry 614 (class 1259 OID 269741)
-- Name: weather_intraday; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_intraday (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    site_id character varying(255) NOT NULL,
    lat numeric(8,6),
    lng numeric(8,6),
    temp bigint,
    condition_id bigint,
    wind_speed bigint,
    humidity bigint,
    daypart_name character varying,
    weather_dt timestamp(6) without time zone,
    create_dt timestamp(6) without time zone,
    update_dt timestamp(6) without time zone,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weather_intraday OWNER TO postgres;

--
-- TOC entry 615 (class 1259 OID 269749)
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
-- TOC entry 10498 (class 0 OID 0)
-- Dependencies: 615
-- Name: weather_intraday_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weather_intraday_id_seq OWNED BY public.weather_intraday.id;


--
-- TOC entry 616 (class 1259 OID 269751)
-- Name: weather_outlooks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_outlooks (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying NOT NULL,
    video_url character varying NOT NULL,
    start_dt timestamp(6) without time zone NOT NULL,
    end_dt timestamp(6) without time zone NOT NULL,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weather_outlooks OWNER TO postgres;

--
-- TOC entry 617 (class 1259 OID 269759)
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
-- TOC entry 10501 (class 0 OID 0)
-- Dependencies: 617
-- Name: weather_outlook_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weather_outlook_id_seq OWNED BY public.weather_outlooks.id;


--
-- TOC entry 618 (class 1259 OID 269761)
-- Name: weather_raw; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_raw (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    site_id character varying(255),
    daily json,
    intraday json,
    hourly json,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    lat numeric(8,6),
    lng numeric(8,6),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weather_raw OWNER TO postgres;

--
-- TOC entry 619 (class 1259 OID 269770)
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
-- TOC entry 10504 (class 0 OID 0)
-- Dependencies: 619
-- Name: weather_raw_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weather_raw_id_seq OWNED BY public.weather_raw.id;


--
-- TOC entry 620 (class 1259 OID 269772)
-- Name: weather_service_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_service_events (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weather_service_events OWNER TO postgres;

--
-- TOC entry 621 (class 1259 OID 269780)
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
-- TOC entry 10507 (class 0 OID 0)
-- Dependencies: 621
-- Name: weather_service_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weather_service_events_id_seq OWNED BY public.weather_service_events.id;


--
-- TOC entry 622 (class 1259 OID 269782)
-- Name: weather_sms_whitelist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_sms_whitelist (
    msisdn character varying(15)
);


ALTER TABLE public.weather_sms_whitelist OWNER TO postgres;

--
-- TOC entry 623 (class 1259 OID 269785)
-- Name: weather_stations_location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weather_stations_location (
    id character varying DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    name character varying(255),
    type character varying(255),
    station_id character varying(255) NOT NULL,
    shape public.geometry
);


ALTER TABLE public.weather_stations_location OWNER TO postgres;

--
-- TOC entry 822 (class 1259 OID 666239)
-- Name: webview_users; Type: TABLE; Schema: public; Owner: rameez_dev_rw
--

CREATE TABLE public.webview_users (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    msisdn character varying(255) NOT NULL,
    active boolean DEFAULT true,
    created_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP,
    redirect_url character varying(512)
);


ALTER TABLE public.webview_users OWNER TO rameez_dev_rw;

--
-- TOC entry 624 (class 1259 OID 269792)
-- Name: weeds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.weeds (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    "order" integer,
    title character varying(255),
    title_urdu character varying(255),
    content_id character varying(255),
    file_name character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.weeds OWNER TO postgres;

--
-- TOC entry 625 (class 1259 OID 269801)
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
-- TOC entry 10513 (class 0 OID 0)
-- Dependencies: 625
-- Name: weeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.weeds_id_seq OWNED BY public.weeds.id;


--
-- TOC entry 626 (class 1259 OID 269803)
-- Name: welcome_box; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.welcome_box (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    title character varying(255) NOT NULL,
    action_id character varying(255) DEFAULT NULL::character varying,
    action_type character varying(255) NOT NULL,
    file_name character varying(255) DEFAULT NULL::character varying,
    validation_query text,
    seq_order smallint DEFAULT 0 NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    create_dt timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    update_dt timestamp(6) without time zone,
    child_node_uuid character varying,
    parent_node_uuid character varying,
    file_name_query text,
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    app_name character varying(255)
);


ALTER TABLE public.welcome_box OWNER TO postgres;

--
-- TOC entry 627 (class 1259 OID 269817)
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
-- TOC entry 10516 (class 0 OID 0)
-- Dependencies: 627
-- Name: welcome_box_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.welcome_box_id_seq OWNED BY public.welcome_box.id;


--
-- TOC entry 628 (class 1259 OID 269819)
-- Name: wx_phrase_list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wx_phrase_list (
    id character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL,
    wx_phrase_description character varying(255),
    guid character varying(255) DEFAULT uuid_in((md5(((random())::text || (random())::text)))::cstring) NOT NULL
);


ALTER TABLE public.wx_phrase_list OWNER TO postgres;

--
-- TOC entry 629 (class 1259 OID 269827)
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
-- TOC entry 10519 (class 0 OID 0)
-- Dependencies: 629
-- Name: wx_phrase_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wx_phrase_list_id_seq OWNED BY public.wx_phrase_list.id;


--
-- TOC entry 7099 (class 2604 OID 269829)
-- Name: cross_promo_dtmf_sub id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cross_promo_dtmf_sub ALTER COLUMN id SET DEFAULT nextval('public.cross_promo_dtmf_sub_id_seq'::regclass);


--
-- TOC entry 8075 (class 2604 OID 645548)
-- Name: qrp_searches id; Type: DEFAULT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.qrp_searches ALTER COLUMN id SET DEFAULT nextval('public.qrp_searches_id_seq'::regclass);


--
-- TOC entry 7200 (class 2604 OID 269830)
-- Name: stats_notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stats_notifications ALTER COLUMN id SET DEFAULT nextval('public.hourly_stat_receivers_id_seq'::regclass);


--
-- TOC entry 7565 (class 2604 OID 269831)
-- Name: subscriptions subscription_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN subscription_type_id SET DEFAULT nextval('public.subscriptions_subscription_type_id_seq'::regclass);


--
-- TOC entry 7585 (class 2604 OID 269832)
-- Name: testing_numbers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testing_numbers ALTER COLUMN id SET DEFAULT nextval('public.testing_numbers_id_seq'::regclass);


--
-- TOC entry 8143 (class 2606 OID 275076)
-- Name: abiotic_stress abiotic_stress_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.abiotic_stress
    ADD CONSTRAINT abiotic_stress_pkey PRIMARY KEY (id);


--
-- TOC entry 9208 (class 2606 OID 643861)
-- Name: abusive_callers abusive_callers_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.abusive_callers
    ADD CONSTRAINT abusive_callers_pk1 PRIMARY KEY (id);


--
-- TOC entry 8145 (class 2606 OID 275078)
-- Name: actions_types actions_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actions_types
    ADD CONSTRAINT actions_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8147 (class 2606 OID 275080)
-- Name: active_subscriber_range active_subscriber_range_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_subscriber_range
    ADD CONSTRAINT active_subscriber_range_pkey PRIMARY KEY (id);


--
-- TOC entry 8149 (class 2606 OID 323930)
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8389 (class 2606 OID 324272)
-- Name: ivr_activities activity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_activities
    ADD CONSTRAINT activity_pkey PRIMARY KEY (id);


--
-- TOC entry 9029 (class 2606 OID 504935)
-- Name: adoptive_ivr_apps adoptive_ivr_apps_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_ivr_apps
    ADD CONSTRAINT adoptive_ivr_apps_pkey PRIMARY KEY (id);


--
-- TOC entry 8151 (class 2606 OID 275084)
-- Name: adoptive_menu adoptive_menu_1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu
    ADD CONSTRAINT adoptive_menu_1_pkey PRIMARY KEY (id);


--
-- TOC entry 9032 (class 2606 OID 504951)
-- Name: adoptive_menu_api_actions adoptive_menu_api_actions_adoptive_menu_id_action_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_api_actions
    ADD CONSTRAINT adoptive_menu_api_actions_adoptive_menu_id_action_id_key UNIQUE (adoptive_menu_id, action_id);


--
-- TOC entry 9034 (class 2606 OID 509248)
-- Name: adoptive_menu_api_actions adoptive_menu_api_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_api_actions
    ADD CONSTRAINT adoptive_menu_api_actions_pkey PRIMARY KEY (id);


--
-- TOC entry 9044 (class 2606 OID 509257)
-- Name: adoptive_menu_content_nodes adoptive_menu_content_nodes_adoptive_menu_id_content_file_i_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_content_nodes
    ADD CONSTRAINT adoptive_menu_content_nodes_adoptive_menu_id_content_file_i_key UNIQUE (adoptive_menu_id, content_file_id);


--
-- TOC entry 9049 (class 2606 OID 509261)
-- Name: adoptive_menu_crops adoptive_menu_crops_adoptive_menu_id_crop_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_crops
    ADD CONSTRAINT adoptive_menu_crops_adoptive_menu_id_crop_id_key UNIQUE (adoptive_menu_id, crop_id);


--
-- TOC entry 9039 (class 2606 OID 504981)
-- Name: adoptive_menu_campaigns adoptive_menu_events_adoptive_menu_id_event_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_campaigns
    ADD CONSTRAINT adoptive_menu_events_adoptive_menu_id_event_id_key UNIQUE (adoptive_menu_id, campaign_id);


--
-- TOC entry 9041 (class 2606 OID 509228)
-- Name: adoptive_menu_campaigns adoptive_menu_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_campaigns
    ADD CONSTRAINT adoptive_menu_events_pkey PRIMARY KEY (id);


--
-- TOC entry 9053 (class 2606 OID 505076)
-- Name: adoptive_menu_file_name_apis adoptive_menu_file_name_apis_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_file_name_apis
    ADD CONSTRAINT adoptive_menu_file_name_apis_pk1 PRIMARY KEY (id);


--
-- TOC entry 9055 (class 2606 OID 505078)
-- Name: adoptive_menu_file_name_apis adoptive_menu_file_name_apis_uk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_file_name_apis
    ADD CONSTRAINT adoptive_menu_file_name_apis_uk1 UNIQUE (adoptive_menu_id, action_id);


--
-- TOC entry 9058 (class 2606 OID 505103)
-- Name: adoptive_menu_files adoptive_menu_files_adoptive_menu_id_content_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_files
    ADD CONSTRAINT adoptive_menu_files_adoptive_menu_id_content_file_id_key UNIQUE (adoptive_menu_id, content_file_id);


--
-- TOC entry 9060 (class 2606 OID 509263)
-- Name: adoptive_menu_files adoptive_menu_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_files
    ADD CONSTRAINT adoptive_menu_files_pkey PRIMARY KEY (id);


--
-- TOC entry 9047 (class 2606 OID 509255)
-- Name: adoptive_menu_content_nodes adoptive_menu_files_v2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_content_nodes
    ADD CONSTRAINT adoptive_menu_files_v2_pkey PRIMARY KEY (id);


--
-- TOC entry 9063 (class 2606 OID 509272)
-- Name: adoptive_menu_languages adoptive_menu_languages_adoptive_menu_id_language_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_languages
    ADD CONSTRAINT adoptive_menu_languages_adoptive_menu_id_language_id_key UNIQUE (adoptive_menu_id, language_id);


--
-- TOC entry 9067 (class 2606 OID 509276)
-- Name: adoptive_menu_livestocks adoptive_menu_livestocks_adoptive_menu_id_livestock_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_livestocks
    ADD CONSTRAINT adoptive_menu_livestocks_adoptive_menu_id_livestock_id_key UNIQUE (adoptive_menu_id, livestock_id);


--
-- TOC entry 9071 (class 2606 OID 509280)
-- Name: adoptive_menu_locations adoptive_menu_locations_adoptive_menu_id_location_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_locations
    ADD CONSTRAINT adoptive_menu_locations_adoptive_menu_id_location_id_key UNIQUE (adoptive_menu_id, location_id);


--
-- TOC entry 9075 (class 2606 OID 509284)
-- Name: adoptive_menu_machineries adoptive_menu_machineries_adoptive_menu_id_machinery_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_machineries
    ADD CONSTRAINT adoptive_menu_machineries_adoptive_menu_id_machinery_id_key UNIQUE (adoptive_menu_id, machinery_id);


--
-- TOC entry 9101 (class 2606 OID 508402)
-- Name: adoptive_menu_operators adoptive_menu_operators_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_operators
    ADD CONSTRAINT adoptive_menu_operators_pk PRIMARY KEY (id);


--
-- TOC entry 9103 (class 2606 OID 508404)
-- Name: adoptive_menu_operators adoptive_menu_operators_u1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_operators
    ADD CONSTRAINT adoptive_menu_operators_u1 UNIQUE (adoptive_menu_id, operator_id);


--
-- TOC entry 9105 (class 2606 OID 508425)
-- Name: adoptive_menu_profiles adoptive_menu_profiles_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_profiles
    ADD CONSTRAINT adoptive_menu_profiles_pk PRIMARY KEY (id);


--
-- TOC entry 9107 (class 2606 OID 508427)
-- Name: adoptive_menu_profiles adoptive_menu_profiles_u1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_profiles
    ADD CONSTRAINT adoptive_menu_profiles_u1 UNIQUE (adoptive_menu_id, msisdn);


--
-- TOC entry 9079 (class 2606 OID 509288)
-- Name: adoptive_menu_recording_end_files adoptive_menu_recording_end_f_adoptive_menu_id_content_file_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_recording_end_files
    ADD CONSTRAINT adoptive_menu_recording_end_f_adoptive_menu_id_content_file_key UNIQUE (adoptive_menu_id, content_file_id);


--
-- TOC entry 9082 (class 2606 OID 509286)
-- Name: adoptive_menu_recording_end_files adoptive_menu_recording_end_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_recording_end_files
    ADD CONSTRAINT adoptive_menu_recording_end_files_pkey PRIMARY KEY (id);


--
-- TOC entry 9086 (class 2606 OID 505263)
-- Name: adoptive_menu_surveys adoptive_menu_surveys_adoptive_menu_id_survey_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_surveys
    ADD CONSTRAINT adoptive_menu_surveys_adoptive_menu_id_survey_id_key UNIQUE (adoptive_menu_id, survey_id);


--
-- TOC entry 9088 (class 2606 OID 509290)
-- Name: adoptive_menu_surveys adoptive_menu_surveys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_surveys
    ADD CONSTRAINT adoptive_menu_surveys_pkey PRIMARY KEY (id);


--
-- TOC entry 9092 (class 2606 OID 505294)
-- Name: adoptive_menu_trunk_actions adoptive_menu_trunk_actions_adoptive_menu_id_action_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_trunk_actions
    ADD CONSTRAINT adoptive_menu_trunk_actions_adoptive_menu_id_action_id_key UNIQUE (adoptive_menu_id, action_id);


--
-- TOC entry 9094 (class 2606 OID 505296)
-- Name: adoptive_menu_trunk_actions adoptive_menu_trunk_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_trunk_actions
    ADD CONSTRAINT adoptive_menu_trunk_actions_pkey PRIMARY KEY (action_id, adoptive_menu_id);


--
-- TOC entry 9097 (class 2606 OID 505321)
-- Name: adoptive_menu_validation_apis adoptive_menu_validation_apis_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_validation_apis
    ADD CONSTRAINT adoptive_menu_validation_apis_pk1 PRIMARY KEY (id);


--
-- TOC entry 9099 (class 2606 OID 505323)
-- Name: adoptive_menu_validation_apis adoptive_menu_validation_apis_uk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_validation_apis
    ADD CONSTRAINT adoptive_menu_validation_apis_uk1 UNIQUE (adoptive_menu_id, action_id);


--
-- TOC entry 8940 (class 2606 OID 509324)
-- Name: campaign_livestocks advisory_livestock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_livestocks
    ADD CONSTRAINT advisory_livestock_pkey PRIMARY KEY (id);


--
-- TOC entry 8944 (class 2606 OID 509326)
-- Name: campaign_locations advisory_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_locations
    ADD CONSTRAINT advisory_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 8948 (class 2606 OID 509355)
-- Name: campaign_machineries advisory_machineries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_machineries
    ADD CONSTRAINT advisory_machineries_pkey PRIMARY KEY (id);


--
-- TOC entry 8882 (class 2606 OID 374739)
-- Name: campaigns advisory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT advisory_pkey PRIMARY KEY (id);


--
-- TOC entry 9129 (class 2606 OID 546501)
-- Name: advisory_salutations advisory_salutations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisory_salutations
    ADD CONSTRAINT advisory_salutations_pkey PRIMARY KEY (id);


--
-- TOC entry 8936 (class 2606 OID 509322)
-- Name: campaign_languages advisory_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_languages
    ADD CONSTRAINT advisory_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 8169 (class 2606 OID 323960)
-- Name: agents_activity_logs agent_activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_activity_logs
    ADD CONSTRAINT agent_activity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8162 (class 2606 OID 275136)
-- Name: roles agent_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT agent_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 8158 (class 2606 OID 275138)
-- Name: agent_roles agent_roles_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_roles
    ADD CONSTRAINT agent_roles_pkey1 PRIMARY KEY (id);


--
-- TOC entry 8223 (class 2606 OID 275140)
-- Name: cc_agents agents.._copy11_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cc_agents
    ADD CONSTRAINT "agents.._copy11_email_key" UNIQUE (email);


--
-- TOC entry 8802 (class 2606 OID 323895)
-- Name: agents_backup agents_copy1_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_backup
    ADD CONSTRAINT agents_copy1_email_key UNIQUE (email);


--
-- TOC entry 8804 (class 2606 OID 323893)
-- Name: agents_backup agents_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_backup
    ADD CONSTRAINT agents_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8165 (class 2606 OID 323956)
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- TOC entry 8806 (class 2606 OID 323907)
-- Name: agri_businesess_tags agri_business_tags; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agri_businesess_tags
    ADD CONSTRAINT agri_business_tags UNIQUE (title);


--
-- TOC entry 8808 (class 2606 OID 323905)
-- Name: agri_businesess_tags agri_businesses_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agri_businesess_tags
    ADD CONSTRAINT agri_businesses_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 8920 (class 2606 OID 412311)
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- TOC entry 9225 (class 2606 OID 663202)
-- Name: anomalies anomalies_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anomalies
    ADD CONSTRAINT anomalies_pk1 PRIMARY KEY (id);


--
-- TOC entry 9215 (class 2606 OID 647750)
-- Name: anomaly_response anomaly_response_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anomaly_response
    ADD CONSTRAINT anomaly_response_pkey PRIMARY KEY (id);


--
-- TOC entry 8909 (class 2606 OID 406416)
-- Name: api_call_details_updated api_call_details_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_call_details_updated
    ADD CONSTRAINT api_call_details_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8911 (class 2606 OID 406418)
-- Name: api_call_details_updated api_call_details_copy1_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_call_details_updated
    ADD CONSTRAINT api_call_details_copy1_title_key UNIQUE (title);


--
-- TOC entry 8179 (class 2606 OID 275148)
-- Name: api_call_details api_call_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_call_details
    ADD CONSTRAINT api_call_details_pkey PRIMARY KEY (id);


--
-- TOC entry 8181 (class 2606 OID 275150)
-- Name: api_call_details api_call_details_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_call_details
    ADD CONSTRAINT api_call_details_title_key UNIQUE (title);


--
-- TOC entry 8183 (class 2606 OID 275152)
-- Name: api_permissions api_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_permissions
    ADD CONSTRAINT api_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 8185 (class 2606 OID 275154)
-- Name: api_resource_category api_resource_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resource_category
    ADD CONSTRAINT api_resource_category_pkey PRIMARY KEY (id);


--
-- TOC entry 8189 (class 2606 OID 275156)
-- Name: api_resource_permissions api_resource_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resource_permissions
    ADD CONSTRAINT api_resource_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 8193 (class 2606 OID 275158)
-- Name: api_resource_roles api_resource_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resource_roles
    ADD CONSTRAINT api_resource_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 8197 (class 2606 OID 275160)
-- Name: api_resources api_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resources
    ADD CONSTRAINT api_resources_pkey PRIMARY KEY (id);


--
-- TOC entry 8201 (class 2606 OID 275162)
-- Name: application_status application_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_status
    ADD CONSTRAINT application_status_pkey PRIMARY KEY (id);


--
-- TOC entry 8203 (class 2606 OID 275164)
-- Name: badges badges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT badges_pkey PRIMARY KEY (id);


--
-- TOC entry 8810 (class 2606 OID 323915)
-- Name: banners banners_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.banners
    ADD CONSTRAINT banners_pkey PRIMARY KEY (id);


--
-- TOC entry 8205 (class 2606 OID 275166)
-- Name: blacklist blacklist_msisdn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blacklist
    ADD CONSTRAINT blacklist_msisdn_key UNIQUE (msisdn);


--
-- TOC entry 8207 (class 2606 OID 275168)
-- Name: blacklist blacklist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blacklist
    ADD CONSTRAINT blacklist_pkey PRIMARY KEY (id);


--
-- TOC entry 8812 (class 2606 OID 323970)
-- Name: business_categories business_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_categories
    ADD CONSTRAINT business_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 8816 (class 2606 OID 323990)
-- Name: business_media_files business_media_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_media_files
    ADD CONSTRAINT business_media_files_pkey PRIMARY KEY (id);


--
-- TOC entry 8824 (class 2606 OID 324029)
-- Name: contact_person businesses_contact_person_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contact_person
    ADD CONSTRAINT businesses_contact_person_pkey PRIMARY KEY (id);


--
-- TOC entry 8814 (class 2606 OID 323980)
-- Name: business_contact_person businesses_contact_person_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_contact_person
    ADD CONSTRAINT businesses_contact_person_pkey1 PRIMARY KEY (id);


--
-- TOC entry 8820 (class 2606 OID 324017)
-- Name: business businesses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT businesses_pkey PRIMARY KEY (id);


--
-- TOC entry 8818 (class 2606 OID 324000)
-- Name: business_tags businesses_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_tags
    ADD CONSTRAINT businesses_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 9133 (class 2606 OID 559284)
-- Name: buyer_types buyer_types_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buyer_types
    ADD CONSTRAINT buyer_types_pk1 PRIMARY KEY (id);


--
-- TOC entry 9200 (class 2606 OID 640461)
-- Name: buyers buyers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.buyers
    ADD CONSTRAINT buyers_pkey PRIMARY KEY (id);


--
-- TOC entry 8896 (class 2606 OID 389326)
-- Name: call_end_notification call_end_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_end_notification
    ADD CONSTRAINT call_end_notification_pkey PRIMARY KEY (id);


--
-- TOC entry 8209 (class 2606 OID 275170)
-- Name: call_hangup_cause call_hangup_cause_call_uuid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_hangup_cause
    ADD CONSTRAINT call_hangup_cause_call_uuid_key UNIQUE (call_uuid);


--
-- TOC entry 8211 (class 2606 OID 275172)
-- Name: call_hangup_cause call_hangup_cause_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.call_hangup_cause
    ADD CONSTRAINT call_hangup_cause_pkey PRIMARY KEY (id);


--
-- TOC entry 8932 (class 2606 OID 509313)
-- Name: campaign_files campagin_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_files
    ADD CONSTRAINT campagin_files_pkey PRIMARY KEY (id);


--
-- TOC entry 8934 (class 2606 OID 509315)
-- Name: campaign_files campagin_files_uniquekey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_files
    ADD CONSTRAINT campagin_files_uniquekey UNIQUE (campaign_id, content_file_id);


--
-- TOC entry 8922 (class 2606 OID 502727)
-- Name: campaign_categories campaign_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_categories
    ADD CONSTRAINT campaign_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 8924 (class 2606 OID 509292)
-- Name: campaign_crops campaign_crops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_crops
    ADD CONSTRAINT campaign_crops_pkey PRIMARY KEY (id);


--
-- TOC entry 8928 (class 2606 OID 502769)
-- Name: campaign_file_name_apis campaign_file_name_apis_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_file_name_apis
    ADD CONSTRAINT campaign_file_name_apis_pk1 PRIMARY KEY (id);


--
-- TOC entry 8930 (class 2606 OID 502771)
-- Name: campaign_file_name_apis campaign_file_name_apis_uk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_file_name_apis
    ADD CONSTRAINT campaign_file_name_apis_uk1 UNIQUE (campaign_id, action_id);


--
-- TOC entry 8952 (class 2606 OID 509364)
-- Name: campaign_operator campaign_operator_campaign_id_operator_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_operator
    ADD CONSTRAINT campaign_operator_campaign_id_operator_id_key UNIQUE (campaign_id, operator_id);


--
-- TOC entry 8954 (class 2606 OID 509362)
-- Name: campaign_operator campaign_operator_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_operator
    ADD CONSTRAINT campaign_operator_pkey PRIMARY KEY (id);


--
-- TOC entry 8956 (class 2606 OID 502926)
-- Name: campaign_profiles campaign_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_profiles
    ADD CONSTRAINT campaign_profile_pkey PRIMARY KEY (id);


--
-- TOC entry 8959 (class 2606 OID 502942)
-- Name: campaign_promo_data campaign_promo_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_promo_data
    ADD CONSTRAINT campaign_promo_data_pkey PRIMARY KEY (id);


--
-- TOC entry 8962 (class 2606 OID 509368)
-- Name: campaign_recording_end_files campaign_recording_end_files_campaign_id_content_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_recording_end_files
    ADD CONSTRAINT campaign_recording_end_files_campaign_id_content_file_id_key UNIQUE (campaign_id, content_file_id);


--
-- TOC entry 8964 (class 2606 OID 502959)
-- Name: campaign_recording_end_files campaign_recording_end_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_recording_end_files
    ADD CONSTRAINT campaign_recording_end_files_pkey PRIMARY KEY (id);


--
-- TOC entry 8880 (class 2606 OID 371832)
-- Name: campaign_types campaign_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_types
    ADD CONSTRAINT campaign_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8966 (class 2606 OID 502983)
-- Name: campaign_validation_apis campaign_validation_apis_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_validation_apis
    ADD CONSTRAINT campaign_validation_apis_pk1 PRIMARY KEY (id);


--
-- TOC entry 8968 (class 2606 OID 502985)
-- Name: campaign_validation_apis campaign_validation_apis_uk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_validation_apis
    ADD CONSTRAINT campaign_validation_apis_uk1 UNIQUE (campaign_id, action_id);


--
-- TOC entry 8884 (class 2606 OID 374741)
-- Name: campaigns campaigns_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_title_key UNIQUE (title);


--
-- TOC entry 8213 (class 2606 OID 275190)
-- Name: case_categories case_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_categories
    ADD CONSTRAINT case_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 8215 (class 2606 OID 275192)
-- Name: case_media_contents case_media_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_media_contents
    ADD CONSTRAINT case_media_contents_pkey PRIMARY KEY (id);


--
-- TOC entry 8217 (class 2606 OID 275194)
-- Name: case_parameters case_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_parameters
    ADD CONSTRAINT case_parameters_pkey PRIMARY KEY (id);


--
-- TOC entry 8219 (class 2606 OID 275196)
-- Name: case_tags case_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_tags
    ADD CONSTRAINT case_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 8221 (class 2606 OID 275198)
-- Name: cases cases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (id);


--
-- TOC entry 8229 (class 2606 OID 275200)
-- Name: cc_call_end_survey_logs cc_call_end_survey_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cc_call_end_survey_logs
    ADD CONSTRAINT cc_call_end_survey_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8796 (class 2606 OID 323780)
-- Name: cc_outbound_whitelist cc_outbound_whitelist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cc_outbound_whitelist
    ADD CONSTRAINT cc_outbound_whitelist_pkey PRIMARY KEY (msisdn);


--
-- TOC entry 8238 (class 2606 OID 275202)
-- Name: cdr_asterisk cdr_asterisk_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cdr_asterisk
    ADD CONSTRAINT cdr_asterisk_pkey PRIMARY KEY (id);


--
-- TOC entry 8240 (class 2606 OID 275204)
-- Name: clauses clauses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clauses
    ADD CONSTRAINT clauses_pkey PRIMARY KEY (id);


--
-- TOC entry 9127 (class 2606 OID 519710)
-- Name: community_blacklist community_blacklist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_blacklist
    ADD CONSTRAINT community_blacklist_pkey PRIMARY KEY (id);


--
-- TOC entry 8242 (class 2606 OID 502999)
-- Name: content_files content_files_file_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_file_name_key UNIQUE (file_name);


--
-- TOC entry 8244 (class 2606 OID 275208)
-- Name: content_files content_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_pkey PRIMARY KEY (id);


--
-- TOC entry 8246 (class 2606 OID 503001)
-- Name: content_files content_files_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_title_key UNIQUE (title);


--
-- TOC entry 8248 (class 2606 OID 275212)
-- Name: content_folders content_folders_folder_path_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_folders
    ADD CONSTRAINT content_folders_folder_path_key UNIQUE (folder_path);


--
-- TOC entry 8250 (class 2606 OID 275214)
-- Name: content_folders content_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_folders
    ADD CONSTRAINT content_folders_pkey PRIMARY KEY (id);


--
-- TOC entry 8252 (class 2606 OID 275216)
-- Name: content_folders content_folders_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_folders
    ADD CONSTRAINT content_folders_title_key UNIQUE (title);


--
-- TOC entry 8258 (class 2606 OID 275218)
-- Name: crop_calender_crops crop_calender_crops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_crops
    ADD CONSTRAINT crop_calender_crops_pkey PRIMARY KEY (id);


--
-- TOC entry 8260 (class 2606 OID 275220)
-- Name: crop_calender_locations crop_calender_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_locations
    ADD CONSTRAINT crop_calender_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 8254 (class 2606 OID 275222)
-- Name: crop_calender crop_calender_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender
    ADD CONSTRAINT crop_calender_pkey PRIMARY KEY (id);


--
-- TOC entry 8256 (class 2606 OID 275224)
-- Name: crop_calender crop_calender_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender
    ADD CONSTRAINT crop_calender_title_key UNIQUE (title);


--
-- TOC entry 8262 (class 2606 OID 275226)
-- Name: crop_calender_weather_favourable_conditions crop_calender_weather_favourable_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_weather_favourable_conditions
    ADD CONSTRAINT crop_calender_weather_favourable_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 8264 (class 2606 OID 275228)
-- Name: crop_calender_weather_unfavourable_conditions crop_calender_weather_unfavourable_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_weather_unfavourable_conditions
    ADD CONSTRAINT crop_calender_weather_unfavourable_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 8266 (class 2606 OID 275230)
-- Name: crop_diseases crop_diseases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_diseases
    ADD CONSTRAINT crop_diseases_pkey PRIMARY KEY (id);


--
-- TOC entry 8268 (class 2606 OID 275232)
-- Name: growth_stages crop_growth_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.growth_stages
    ADD CONSTRAINT crop_growth_stages_pkey PRIMARY KEY (id);


--
-- TOC entry 8898 (class 2606 OID 390409)
-- Name: crop_season crop_season_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_season
    ADD CONSTRAINT crop_season_pkey PRIMARY KEY (id);


--
-- TOC entry 8278 (class 2606 OID 275234)
-- Name: crops_lightsail crops_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops_lightsail
    ADD CONSTRAINT crops_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8830 (class 2606 OID 324052)
-- Name: crops_backup crops_copy1_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops_backup
    ADD CONSTRAINT crops_copy1_pkey1 PRIMARY KEY (id);


--
-- TOC entry 8826 (class 2606 OID 324040)
-- Name: crops_2023_07_26 crops_copy1_pkey2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops_2023_07_26
    ADD CONSTRAINT crops_copy1_pkey2 PRIMARY KEY (id);


--
-- TOC entry 8280 (class 2606 OID 275236)
-- Name: crops_lightsail crops_copy1_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops_lightsail
    ADD CONSTRAINT crops_copy1_title_key UNIQUE (title);


--
-- TOC entry 8832 (class 2606 OID 324054)
-- Name: crops_backup crops_copy1_title_key1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops_backup
    ADD CONSTRAINT crops_copy1_title_key1 UNIQUE (title);


--
-- TOC entry 8828 (class 2606 OID 324042)
-- Name: crops_2023_07_26 crops_copy1_title_key2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops_2023_07_26
    ADD CONSTRAINT crops_copy1_title_key2 UNIQUE (title);


--
-- TOC entry 8274 (class 2606 OID 275238)
-- Name: crops crops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops
    ADD CONSTRAINT crops_pkey PRIMARY KEY (id);


--
-- TOC entry 8282 (class 2606 OID 275240)
-- Name: cross_promo_dtmf_sub cross_promo_dtmf_sub_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cross_promo_dtmf_sub
    ADD CONSTRAINT cross_promo_dtmf_sub_pkey PRIMARY KEY (id);


--
-- TOC entry 8284 (class 2606 OID 275242)
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- TOC entry 8286 (class 2606 OID 275244)
-- Name: drl_count_ml drl_count_ml_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drl_count_ml
    ADD CONSTRAINT drl_count_ml_pkey PRIMARY KEY (id);


--
-- TOC entry 9190 (class 2606 OID 619693)
-- Name: endpoints_permissions endpoints_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.endpoints_permissions
    ADD CONSTRAINT endpoints_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 9188 (class 2606 OID 619664)
-- Name: endpoints endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.endpoints
    ADD CONSTRAINT endpoints_pkey PRIMARY KEY (id);


--
-- TOC entry 8288 (class 2606 OID 275246)
-- Name: event_types event_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_types
    ADD CONSTRAINT event_types_pkey PRIMARY KEY (id);


--
-- TOC entry 9219 (class 2606 OID 648459)
-- Name: expert_call_requests expert_call_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expert_call_requests
    ADD CONSTRAINT expert_call_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 9227 (class 2606 OID 663212)
-- Name: farm_crop_growth_stage_anomalies farm_crop_growth_stage_anomalies_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crop_growth_stage_anomalies
    ADD CONSTRAINT farm_crop_growth_stage_anomalies_pk PRIMARY KEY (id);


--
-- TOC entry 8292 (class 2606 OID 275251)
-- Name: farm_crop_growth_stages farm_crop_growth_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crop_growth_stages
    ADD CONSTRAINT farm_crop_growth_stages_pkey PRIMARY KEY (id);


--
-- TOC entry 8900 (class 2606 OID 390563)
-- Name: farm_crops_seed_types farm_crops_seed_types_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crops_seed_types
    ADD CONSTRAINT farm_crops_seed_types_pk1 PRIMARY KEY (id);


--
-- TOC entry 8902 (class 2606 OID 390565)
-- Name: farm_crops_seed_types farm_crops_seed_types_uk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crops_seed_types
    ADD CONSTRAINT farm_crops_seed_types_uk1 UNIQUE (farm_crop_id, crop_id, seed_type_id);


--
-- TOC entry 9118 (class 2606 OID 519320)
-- Name: farmcrops farmcrops_new_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmcrops
    ADD CONSTRAINT farmcrops_new_pkey PRIMARY KEY (id);


--
-- TOC entry 8834 (class 2606 OID 324071)
-- Name: farmcrops_old farmcrops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmcrops_old
    ADD CONSTRAINT farmcrops_pkey PRIMARY KEY (id);


--
-- TOC entry 9112 (class 2606 OID 519273)
-- Name: farmcrops_duplicate_record farmcrops_pkey2; Type: CONSTRAINT; Schema: public; Owner: ateebqa_rw
--

ALTER TABLE ONLY public.farmcrops_duplicate_record
    ADD CONSTRAINT farmcrops_pkey2 PRIMARY KEY (id);


--
-- TOC entry 9114 (class 2606 OID 519283)
-- Name: farmcrops_unique_record farmcrops_pkey3; Type: CONSTRAINT; Schema: public; Owner: ateebqa_rw
--

ALTER TABLE ONLY public.farmcrops_unique_record
    ADD CONSTRAINT farmcrops_pkey3 PRIMARY KEY (id);


--
-- TOC entry 9121 (class 2606 OID 519393)
-- Name: farmcrops farmcrops_seed_type_id_crop_id_farm_id_crop_season_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmcrops
    ADD CONSTRAINT farmcrops_seed_type_id_crop_id_farm_id_crop_season_id_key UNIQUE (seed_type_id, crop_id, farm_id, crop_season_id);


--
-- TOC entry 8296 (class 2606 OID 275270)
-- Name: farmer_badge_recommendations farmer_badge_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_badge_recommendations
    ADD CONSTRAINT farmer_badge_recommendations_pkey PRIMARY KEY (id);


--
-- TOC entry 8298 (class 2606 OID 275272)
-- Name: farmer_friends farmer_friends_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_friends
    ADD CONSTRAINT farmer_friends_pkey PRIMARY KEY (farmer_id, friend_id);


--
-- TOC entry 8302 (class 2606 OID 275274)
-- Name: farmer_gender farmer_gender_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_gender
    ADD CONSTRAINT farmer_gender_pkey PRIMARY KEY (id);


--
-- TOC entry 8310 (class 2606 OID 275276)
-- Name: farmer_livestocks farmer_livestocks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestocks
    ADD CONSTRAINT farmer_livestocks_pkey PRIMARY KEY (id);


--
-- TOC entry 8313 (class 2606 OID 275306)
-- Name: farmer_machineries farmer_machineries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_machineries
    ADD CONSTRAINT farmer_machineries_pkey PRIMARY KEY (id);


--
-- TOC entry 8315 (class 2606 OID 275309)
-- Name: farmer_name_change farmer_name_change_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_name_change
    ADD CONSTRAINT farmer_name_change_pkey PRIMARY KEY (msisdn);


--
-- TOC entry 8318 (class 2606 OID 275311)
-- Name: farmer_name_content farmer_name_content_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_name_content
    ADD CONSTRAINT farmer_name_content_pkey PRIMARY KEY (id);


--
-- TOC entry 8836 (class 2606 OID 324088)
-- Name: farmers_copy farmers_copy1_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_copy
    ADD CONSTRAINT farmers_copy1_key_key UNIQUE (key);


--
-- TOC entry 8326 (class 2606 OID 275313)
-- Name: farmers_testing farmers_copy1_key_key1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_testing
    ADD CONSTRAINT farmers_copy1_key_key1 UNIQUE (key);


--
-- TOC entry 8838 (class 2606 OID 324086)
-- Name: farmers_copy farmers_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_copy
    ADD CONSTRAINT farmers_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8328 (class 2606 OID 275315)
-- Name: farmers_testing farmers_copy1_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_testing
    ADD CONSTRAINT farmers_copy1_pkey1 PRIMARY KEY (id);


--
-- TOC entry 9141 (class 2606 OID 563299)
-- Name: farmers_eng_urdu_names farmers_eng_urdu_names_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_eng_urdu_names
    ADD CONSTRAINT farmers_eng_urdu_names_pkey PRIMARY KEY (id);


--
-- TOC entry 8321 (class 2606 OID 275317)
-- Name: farmers farmers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers
    ADD CONSTRAINT farmers_pkey PRIMARY KEY (id);


--
-- TOC entry 8336 (class 2606 OID 275319)
-- Name: farms farms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_pkey PRIMARY KEY (id);


--
-- TOC entry 9146 (class 2606 OID 579414)
-- Name: fav_crops fav_crops_farmer_id_crop_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fav_crops
    ADD CONSTRAINT fav_crops_farmer_id_crop_id_key UNIQUE (farmer_id, crop_id);


--
-- TOC entry 9148 (class 2606 OID 579412)
-- Name: fav_crops fav_crops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fav_crops
    ADD CONSTRAINT fav_crops_pkey PRIMARY KEY (id);


--
-- TOC entry 8340 (class 2606 OID 275321)
-- Name: field_visits field_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.field_visits
    ADD CONSTRAINT field_visits_pkey PRIMARY KEY (id);


--
-- TOC entry 8840 (class 2606 OID 324105)
-- Name: forum_hide_posts_copy1 forum_hide_posts_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_hide_posts_copy1
    ADD CONSTRAINT forum_hide_posts_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8842 (class 2606 OID 324107)
-- Name: forum_hide_posts_copy1 forum_hide_posts_copy1_user_id_hide_post_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_hide_posts_copy1
    ADD CONSTRAINT forum_hide_posts_copy1_user_id_hide_post_id_key UNIQUE (user_id, hide_post_id);


--
-- TOC entry 8342 (class 2606 OID 275323)
-- Name: forum_hide_posts forum_hide_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_hide_posts
    ADD CONSTRAINT forum_hide_posts_pkey PRIMARY KEY (id);


--
-- TOC entry 8844 (class 2606 OID 324117)
-- Name: forum_hide_users_copy1 forum_hide_users_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_hide_users_copy1
    ADD CONSTRAINT forum_hide_users_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8846 (class 2606 OID 324119)
-- Name: forum_hide_users_copy1 forum_hide_users_copy1_user_id_hide_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_hide_users_copy1
    ADD CONSTRAINT forum_hide_users_copy1_user_id_hide_user_id_key UNIQUE (user_id, hide_user_id);


--
-- TOC entry 8346 (class 2606 OID 275325)
-- Name: forum_hide_users forum_hide_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_hide_users
    ADD CONSTRAINT forum_hide_users_pkey PRIMARY KEY (id);


--
-- TOC entry 8848 (class 2606 OID 324130)
-- Name: forum_media_copy1 forum_media_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_media_copy1
    ADD CONSTRAINT forum_media_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8350 (class 2606 OID 275327)
-- Name: forum_media forum_media_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_media
    ADD CONSTRAINT forum_media_pkey PRIMARY KEY (id);


--
-- TOC entry 9110 (class 2606 OID 536084)
-- Name: forum_post_rejection_reasons forum_post_rejection_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_post_rejection_reasons
    ADD CONSTRAINT forum_post_rejection_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 8352 (class 2606 OID 324255)
-- Name: forum_posts forum_posts_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts
    ADD CONSTRAINT forum_posts_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8850 (class 2606 OID 324144)
-- Name: forum_posts_cc forum_posts_copy1_pkey1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_cc
    ADD CONSTRAINT forum_posts_copy1_pkey1 PRIMARY KEY (id);


--
-- TOC entry 8852 (class 2606 OID 324157)
-- Name: forum_posts_rejected_copy1 forum_posts_rejected_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_rejected_copy1
    ADD CONSTRAINT forum_posts_rejected_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8357 (class 2606 OID 275331)
-- Name: forum_posts_rejected forum_posts_rejected_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_rejected
    ADD CONSTRAINT forum_posts_rejected_pkey PRIMARY KEY (id);


--
-- TOC entry 8913 (class 2606 OID 406787)
-- Name: forum_posts_tags forum_posts_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_tags
    ADD CONSTRAINT forum_posts_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 9186 (class 2606 OID 617278)
-- Name: forum_posts_views_shares forum_posts_views_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_views_shares
    ADD CONSTRAINT forum_posts_views_shares_pkey PRIMARY KEY (id);


--
-- TOC entry 8854 (class 2606 OID 324167)
-- Name: forum_report_posts_copy1 forum_report_posts_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_posts_copy1
    ADD CONSTRAINT forum_report_posts_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8856 (class 2606 OID 324169)
-- Name: forum_report_posts_copy1 forum_report_posts_copy1_report_post_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_posts_copy1
    ADD CONSTRAINT forum_report_posts_copy1_report_post_id_user_id_key UNIQUE (report_post_id, user_id);


--
-- TOC entry 8359 (class 2606 OID 275333)
-- Name: forum_report_posts forum_report_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_posts
    ADD CONSTRAINT forum_report_posts_pkey PRIMARY KEY (id);


--
-- TOC entry 8858 (class 2606 OID 324179)
-- Name: forum_report_reason_actions_copy1 forum_report_reason_actions_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_reason_actions_copy1
    ADD CONSTRAINT forum_report_reason_actions_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8363 (class 2606 OID 275335)
-- Name: forum_report_reason_actions forum_report_reason_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_reason_actions
    ADD CONSTRAINT forum_report_reason_actions_pkey PRIMARY KEY (id);


--
-- TOC entry 8860 (class 2606 OID 324189)
-- Name: forum_report_reasons_copy1 forum_report_reasons_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_reasons_copy1
    ADD CONSTRAINT forum_report_reasons_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8365 (class 2606 OID 275337)
-- Name: forum_report_reasons forum_report_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_reasons
    ADD CONSTRAINT forum_report_reasons_pkey PRIMARY KEY (id);


--
-- TOC entry 8862 (class 2606 OID 324199)
-- Name: forum_report_users_copy1 forum_report_users_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_users_copy1
    ADD CONSTRAINT forum_report_users_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8864 (class 2606 OID 324201)
-- Name: forum_report_users_copy1 forum_report_users_copy1_user_id_report_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_users_copy1
    ADD CONSTRAINT forum_report_users_copy1_user_id_report_user_id_key UNIQUE (user_id, report_user_id);


--
-- TOC entry 8367 (class 2606 OID 275339)
-- Name: forum_report_users forum_report_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_users
    ADD CONSTRAINT forum_report_users_pkey PRIMARY KEY (id);


--
-- TOC entry 8866 (class 2606 OID 324213)
-- Name: forum_user_agreements_copy1 forum_user_agreements_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_user_agreements_copy1
    ADD CONSTRAINT forum_user_agreements_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8868 (class 2606 OID 324215)
-- Name: forum_user_agreements_copy1 forum_user_agreements_copy1_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_user_agreements_copy1
    ADD CONSTRAINT forum_user_agreements_copy1_user_id_key UNIQUE (user_id);


--
-- TOC entry 8371 (class 2606 OID 275341)
-- Name: forum_user_agreements forum_user_agreements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_user_agreements
    ADD CONSTRAINT forum_user_agreements_pkey PRIMARY KEY (id);


--
-- TOC entry 8375 (class 2606 OID 275343)
-- Name: he_alerts_data he_alerts_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.he_alerts_data
    ADD CONSTRAINT he_alerts_data_pkey PRIMARY KEY (id);


--
-- TOC entry 8377 (class 2606 OID 275345)
-- Name: he_data he_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.he_data
    ADD CONSTRAINT he_data_pkey PRIMARY KEY (id);


--
-- TOC entry 8379 (class 2606 OID 275347)
-- Name: stats_notifications hourly_stat_receivers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stats_notifications
    ADD CONSTRAINT hourly_stat_receivers_pkey PRIMARY KEY (id);


--
-- TOC entry 8381 (class 2606 OID 275349)
-- Name: in_app_notifications in_app_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.in_app_notifications
    ADD CONSTRAINT in_app_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 8383 (class 2606 OID 275351)
-- Name: incentive_transactions incentive_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incentive_transactions
    ADD CONSTRAINT incentive_transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 8385 (class 2606 OID 275353)
-- Name: incentive_types incentive_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incentive_types
    ADD CONSTRAINT incentive_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8870 (class 2606 OID 324227)
-- Name: interests interests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interests
    ADD CONSTRAINT interests_pkey PRIMARY KEY (id);


--
-- TOC entry 8387 (class 2606 OID 275355)
-- Name: irrigation_sources irrigation_source_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.irrigation_sources
    ADD CONSTRAINT irrigation_source_pkey PRIMARY KEY (id);


--
-- TOC entry 8391 (class 2606 OID 275359)
-- Name: ivr_paths ivr_paths_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_paths
    ADD CONSTRAINT ivr_paths_pkey PRIMARY KEY (id);


--
-- TOC entry 8393 (class 2606 OID 275361)
-- Name: ivr_paths ivr_paths_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_paths
    ADD CONSTRAINT ivr_paths_title_key UNIQUE (title);


--
-- TOC entry 8395 (class 2606 OID 275363)
-- Name: ivr_sessions ivr_sessions_channel_uuid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_sessions
    ADD CONSTRAINT ivr_sessions_channel_uuid_key UNIQUE (channel_uuid);


--
-- TOC entry 8397 (class 2606 OID 275365)
-- Name: ivr_sessions ivr_sessions_msisdn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_sessions
    ADD CONSTRAINT ivr_sessions_msisdn_key UNIQUE (msisdn);


--
-- TOC entry 8399 (class 2606 OID 275367)
-- Name: ivr_sessions ivr_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_sessions
    ADD CONSTRAINT ivr_sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 9172 (class 2606 OID 599068)
-- Name: jazzcash_merchant_accounts jazzcash_merchant_accounts_merchant_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jazzcash_merchant_accounts
    ADD CONSTRAINT jazzcash_merchant_accounts_merchant_id_key UNIQUE (merchant_id);


--
-- TOC entry 9174 (class 2606 OID 599066)
-- Name: jazzcash_merchant_accounts jazzcash_merchant_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jazzcash_merchant_accounts
    ADD CONSTRAINT jazzcash_merchant_accounts_pkey PRIMARY KEY (id);


--
-- TOC entry 9184 (class 2606 OID 606200)
-- Name: jazzcash_onetime_transactions jazzcash_onetime_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jazzcash_onetime_transactions
    ADD CONSTRAINT jazzcash_onetime_transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 9182 (class 2606 OID 599110)
-- Name: jazzcash_recurring_transactions jazzcash_recurring_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jazzcash_recurring_transactions
    ADD CONSTRAINT jazzcash_recurring_transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 9170 (class 2606 OID 598793)
-- Name: jazzcash_user_accounts jazzcash_user_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jazzcash_user_accounts
    ADD CONSTRAINT jazzcash_user_accounts_pkey PRIMARY KEY (id);


--
-- TOC entry 9180 (class 2606 OID 599090)
-- Name: jazzcash_user_wallet_transactions jazzcash_user_wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jazzcash_user_wallet_transactions
    ADD CONSTRAINT jazzcash_user_wallet_transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 9176 (class 2606 OID 599080)
-- Name: jazzcash_user_wallets jazzcash_user_wallets_msisdn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jazzcash_user_wallets
    ADD CONSTRAINT jazzcash_user_wallets_msisdn_key UNIQUE (msisdn);


--
-- TOC entry 9178 (class 2606 OID 599078)
-- Name: jazzcash_user_wallets jazzcash_user_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jazzcash_user_wallets
    ADD CONSTRAINT jazzcash_user_wallets_pkey PRIMARY KEY (id);


--
-- TOC entry 8792 (class 2606 OID 316812)
-- Name: job_executor_stats job_executor_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_executor_stats
    ADD CONSTRAINT job_executor_stats_pkey PRIMARY KEY (id);


--
-- TOC entry 8794 (class 2606 OID 316814)
-- Name: job_executor_stats job_executor_stats_request_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_executor_stats
    ADD CONSTRAINT job_executor_stats_request_id_key UNIQUE (request_id);


--
-- TOC entry 9239 (class 2606 OID 1091004)
-- Name: job_logs_2025_07_24 job_logs_2025_07_24_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_07_24
    ADD CONSTRAINT job_logs_2025_07_24_pkey PRIMARY KEY (id);


--
-- TOC entry 9242 (class 2606 OID 1091260)
-- Name: job_logs_2025_07_25 job_logs_2025_07_25_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_07_25
    ADD CONSTRAINT job_logs_2025_07_25_pkey PRIMARY KEY (id);


--
-- TOC entry 9245 (class 2606 OID 1134160)
-- Name: job_logs_2025_07_26 job_logs_2025_07_26_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_07_26
    ADD CONSTRAINT job_logs_2025_07_26_pkey PRIMARY KEY (id);


--
-- TOC entry 9248 (class 2606 OID 1134433)
-- Name: job_logs_2025_07_27 job_logs_2025_07_27_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_07_27
    ADD CONSTRAINT job_logs_2025_07_27_pkey PRIMARY KEY (id);


--
-- TOC entry 9251 (class 2606 OID 1134699)
-- Name: job_logs_2025_07_28 job_logs_2025_07_28_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_07_28
    ADD CONSTRAINT job_logs_2025_07_28_pkey PRIMARY KEY (id);


--
-- TOC entry 9254 (class 2606 OID 1178351)
-- Name: job_logs_2025_07_29 job_logs_2025_07_29_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_07_29
    ADD CONSTRAINT job_logs_2025_07_29_pkey PRIMARY KEY (id);


--
-- TOC entry 9257 (class 2606 OID 1561217)
-- Name: job_logs_2025_07_30 job_logs_2025_07_30_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_07_30
    ADD CONSTRAINT job_logs_2025_07_30_pkey PRIMARY KEY (id);


--
-- TOC entry 9260 (class 2606 OID 1561801)
-- Name: job_logs_2025_07_31 job_logs_2025_07_31_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_07_31
    ADD CONSTRAINT job_logs_2025_07_31_pkey PRIMARY KEY (id);


--
-- TOC entry 9263 (class 2606 OID 1566041)
-- Name: job_logs_2025_08_13 job_logs_2025_08_13_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_08_13
    ADD CONSTRAINT job_logs_2025_08_13_pkey PRIMARY KEY (id);


--
-- TOC entry 9266 (class 2606 OID 1566383)
-- Name: job_logs_2025_08_14 job_logs_2025_08_14_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_08_14
    ADD CONSTRAINT job_logs_2025_08_14_pkey PRIMARY KEY (id);


--
-- TOC entry 9269 (class 2606 OID 1566783)
-- Name: job_logs_2025_08_15 job_logs_2025_08_15_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_logs_2025_08_15
    ADD CONSTRAINT job_logs_2025_08_15_pkey PRIMARY KEY (id);


--
-- TOC entry 8778 (class 2606 OID 308194)
-- Name: job_operators job_operators_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_operators
    ADD CONSTRAINT job_operators_pkey PRIMARY KEY (id);


--
-- TOC entry 8782 (class 2606 OID 308316)
-- Name: job_state_flow job_state_flow_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_state_flow
    ADD CONSTRAINT job_state_flow_pkey PRIMARY KEY (id);


--
-- TOC entry 8784 (class 2606 OID 308399)
-- Name: job_statuses job_statuses_job_status_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_statuses
    ADD CONSTRAINT job_statuses_job_status_key UNIQUE (job_status);


--
-- TOC entry 8786 (class 2606 OID 308401)
-- Name: job_statuses job_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_statuses
    ADD CONSTRAINT job_statuses_pkey PRIMARY KEY (id);


--
-- TOC entry 8788 (class 2606 OID 308403)
-- Name: job_statuses job_statuses_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_statuses
    ADD CONSTRAINT job_statuses_title_key UNIQUE (title);


--
-- TOC entry 8790 (class 2606 OID 308476)
-- Name: job_testing_msisdns job_testing_msisdns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_testing_msisdns
    ADD CONSTRAINT job_testing_msisdns_pkey PRIMARY KEY (id);


--
-- TOC entry 8774 (class 2606 OID 308067)
-- Name: job_types job_types_job_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_types
    ADD CONSTRAINT job_types_job_type_key UNIQUE (job_type);


--
-- TOC entry 8776 (class 2606 OID 308069)
-- Name: job_types job_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_types
    ADD CONSTRAINT job_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8401 (class 2606 OID 275369)
-- Name: jobs jobs_v2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_v2_pkey PRIMARY KEY (id);


--
-- TOC entry 8403 (class 2606 OID 275371)
-- Name: jobs jobs_v2_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_v2_title_key UNIQUE (title);


--
-- TOC entry 8405 (class 2606 OID 275375)
-- Name: land_topography land_topography_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.land_topography
    ADD CONSTRAINT land_topography_pkey PRIMARY KEY (id);


--
-- TOC entry 8408 (class 2606 OID 275377)
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- TOC entry 8410 (class 2606 OID 275379)
-- Name: livestock_breeds livestock_breeds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_breeds
    ADD CONSTRAINT livestock_breeds_pkey PRIMARY KEY (id);


--
-- TOC entry 8412 (class 2606 OID 275384)
-- Name: livestock_disease livestock_disease_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_disease
    ADD CONSTRAINT livestock_disease_pkey PRIMARY KEY (id);


--
-- TOC entry 9160 (class 2606 OID 598289)
-- Name: livestock_farm_livestocks livestock_farm_livestock_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farm_livestocks
    ADD CONSTRAINT livestock_farm_livestock_pk1 PRIMARY KEY (id);


--
-- TOC entry 8414 (class 2606 OID 275386)
-- Name: livestock_farming_categories livestock_farming_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farming_categories
    ADD CONSTRAINT livestock_farming_category_pkey PRIMARY KEY (id);


--
-- TOC entry 9158 (class 2606 OID 598263)
-- Name: livestock_farms livestock_farms_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farms
    ADD CONSTRAINT livestock_farms_pk1 PRIMARY KEY (id);


--
-- TOC entry 8418 (class 2606 OID 275391)
-- Name: livestock_management livestock_management_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_management
    ADD CONSTRAINT livestock_management_pkey PRIMARY KEY (id);


--
-- TOC entry 8420 (class 2606 OID 275393)
-- Name: livestock_nutrition livestock_nutrition_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_nutrition
    ADD CONSTRAINT livestock_nutrition_pkey PRIMARY KEY (id);


--
-- TOC entry 8422 (class 2606 OID 275396)
-- Name: livestock_purpose livestock_purpose_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_purpose
    ADD CONSTRAINT livestock_purpose_pkey PRIMARY KEY (id);


--
-- TOC entry 8424 (class 2606 OID 275398)
-- Name: livestock_stage livestock_stage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_stage
    ADD CONSTRAINT livestock_stage_pkey PRIMARY KEY (id);


--
-- TOC entry 8304 (class 2606 OID 275400)
-- Name: farmer_livestock_tags livestock_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestock_tags
    ADD CONSTRAINT livestock_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 8427 (class 2606 OID 275402)
-- Name: livestocks livestocks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestocks
    ADD CONSTRAINT livestocks_pkey PRIMARY KEY (id);


--
-- TOC entry 8199 (class 2606 OID 275404)
-- Name: loan_agreements loan_agreements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_agreements
    ADD CONSTRAINT loan_agreements_pkey PRIMARY KEY (id);


--
-- TOC entry 8429 (class 2606 OID 275406)
-- Name: loan_applications loan_application_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_applications
    ADD CONSTRAINT loan_application_pkey PRIMARY KEY (id);


--
-- TOC entry 8431 (class 2606 OID 275408)
-- Name: loan_partners loan_partners_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_partners
    ADD CONSTRAINT loan_partners_pkey PRIMARY KEY (id);


--
-- TOC entry 8433 (class 2606 OID 275410)
-- Name: loan_payment_modes loan_payment_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_payment_modes
    ADD CONSTRAINT loan_payment_modes_pkey PRIMARY KEY (id);


--
-- TOC entry 8435 (class 2606 OID 275412)
-- Name: loan_procurement_docs loan_procurement_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_procurement_docs
    ADD CONSTRAINT loan_procurement_attachments_pkey PRIMARY KEY (id);


--
-- TOC entry 8437 (class 2606 OID 275414)
-- Name: loan_procurements loan_procurements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_procurements
    ADD CONSTRAINT loan_procurements_pkey PRIMARY KEY (id);


--
-- TOC entry 8439 (class 2606 OID 275416)
-- Name: loan_transactions loan_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_transactions
    ADD CONSTRAINT loan_transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 8441 (class 2606 OID 275418)
-- Name: loan_types loan_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_types
    ADD CONSTRAINT loan_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8443 (class 2606 OID 275420)
-- Name: location_crops location_crops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_crops
    ADD CONSTRAINT location_crops_pkey PRIMARY KEY (id);


--
-- TOC entry 8445 (class 2606 OID 275422)
-- Name: location_livestocks location_livestocks_livestock_id_location_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_livestocks
    ADD CONSTRAINT location_livestocks_livestock_id_location_id_key UNIQUE (livestock_id, location_id);


--
-- TOC entry 8447 (class 2606 OID 275424)
-- Name: location_livestocks location_livestocks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_livestocks
    ADD CONSTRAINT location_livestocks_pkey PRIMARY KEY (id);


--
-- TOC entry 8449 (class 2606 OID 275426)
-- Name: location_machineries location_machineries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_machineries
    ADD CONSTRAINT location_machineries_pkey PRIMARY KEY (id);


--
-- TOC entry 9233 (class 2606 OID 875354)
-- Name: locations_copy1 locations_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations_copy1
    ADD CONSTRAINT locations_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8454 (class 2606 OID 275428)
-- Name: locations locations_v2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_v2_pkey PRIMARY KEY (id);


--
-- TOC entry 8456 (class 2606 OID 275430)
-- Name: machineries machineries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machineries
    ADD CONSTRAINT machineries_pkey PRIMARY KEY (id);


--
-- TOC entry 8458 (class 2606 OID 275432)
-- Name: machinery_types machinery_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machinery_types
    ADD CONSTRAINT machinery_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8462 (class 2606 OID 275434)
-- Name: mandi_categories mandi_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_categories
    ADD CONSTRAINT mandi_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 8464 (class 2606 OID 275436)
-- Name: mandi_listing_images mandi_listing_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_listing_images
    ADD CONSTRAINT mandi_listing_images_pkey PRIMARY KEY (id);


--
-- TOC entry 8466 (class 2606 OID 275438)
-- Name: mandi_listing_tags mandi_listing_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_listing_tags
    ADD CONSTRAINT mandi_listing_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 8472 (class 2606 OID 275440)
-- Name: mandi_listings_meta_data mandi_listings_meta_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_listings_meta_data
    ADD CONSTRAINT mandi_listings_meta_data_pkey PRIMARY KEY (id);


--
-- TOC entry 8470 (class 2606 OID 275442)
-- Name: mandi_listings mandi_listings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_listings
    ADD CONSTRAINT mandi_listings_pkey PRIMARY KEY (id);


--
-- TOC entry 8476 (class 2606 OID 275444)
-- Name: mandi_reviews mandi_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_reviews
    ADD CONSTRAINT mandi_reviews_pkey PRIMARY KEY (id);


--
-- TOC entry 8478 (class 2606 OID 275446)
-- Name: master_dncr master_dncr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master_dncr
    ADD CONSTRAINT master_dncr_pkey PRIMARY KEY (msisdn);


--
-- TOC entry 9051 (class 2606 OID 509259)
-- Name: adoptive_menu_crops menu_crops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_crops
    ADD CONSTRAINT menu_crops_pkey PRIMARY KEY (id);


--
-- TOC entry 9069 (class 2606 OID 509274)
-- Name: adoptive_menu_livestocks menu_livestock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_livestocks
    ADD CONSTRAINT menu_livestock_pkey PRIMARY KEY (id);


--
-- TOC entry 9073 (class 2606 OID 509278)
-- Name: adoptive_menu_locations menu_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_locations
    ADD CONSTRAINT menu_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 9077 (class 2606 OID 509282)
-- Name: adoptive_menu_machineries menu_machineries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_machineries
    ADD CONSTRAINT menu_machineries_pkey PRIMARY KEY (id);


--
-- TOC entry 9065 (class 2606 OID 509270)
-- Name: adoptive_menu_languages menu_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_languages
    ADD CONSTRAINT menu_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 8480 (class 2606 OID 275456)
-- Name: mmbl_data mmbl_data_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mmbl_data
    ADD CONSTRAINT mmbl_data_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8482 (class 2606 OID 275458)
-- Name: mmbl_transaction_logs mmbl_transaction_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mmbl_transaction_logs
    ADD CONSTRAINT mmbl_transaction_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8484 (class 2606 OID 324282)
-- Name: mo_sms mo_sms_new_pkey39; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mo_sms
    ADD CONSTRAINT mo_sms_new_pkey39 PRIMARY KEY (id);


--
-- TOC entry 8486 (class 2606 OID 275462)
-- Name: mp_crop_diseases mp_crop_crop_diseases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mp_crop_diseases
    ADD CONSTRAINT mp_crop_crop_diseases_pkey PRIMARY KEY (id);


--
-- TOC entry 8488 (class 2606 OID 275464)
-- Name: mp_livestock_disease mp_livestock_disease_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mp_livestock_disease
    ADD CONSTRAINT mp_livestock_disease_pkey PRIMARY KEY (id);


--
-- TOC entry 8490 (class 2606 OID 275466)
-- Name: mp_livestock_farming_categories mp_livestock_farming_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mp_livestock_farming_categories
    ADD CONSTRAINT mp_livestock_farming_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 8492 (class 2606 OID 275468)
-- Name: narrative_list narrative_list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.narrative_list
    ADD CONSTRAINT narrative_list_pkey PRIMARY KEY (id);


--
-- TOC entry 8494 (class 2606 OID 275470)
-- Name: neighbouring_tehsils neighbouring_tehsils_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.neighbouring_tehsils
    ADD CONSTRAINT neighbouring_tehsils_pkey PRIMARY KEY (id);


--
-- TOC entry 8496 (class 2606 OID 275472)
-- Name: network_tagging network_tagging_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.network_tagging
    ADD CONSTRAINT network_tagging_copy1_pkey PRIMARY KEY (msisdn);


--
-- TOC entry 8498 (class 2606 OID 275474)
-- Name: network_types network_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.network_types
    ADD CONSTRAINT network_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8500 (class 2606 OID 275476)
-- Name: network_types network_types_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.network_types
    ADD CONSTRAINT network_types_title_key UNIQUE (title);


--
-- TOC entry 8231 (class 2606 OID 275478)
-- Name: cc_call_logs new_cc_call_logs_caller_paidwall_id_key37; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cc_call_logs
    ADD CONSTRAINT new_cc_call_logs_caller_paidwall_id_key37 UNIQUE (caller, paidwall_id);


--
-- TOC entry 8234 (class 2606 OID 275480)
-- Name: cc_call_logs new_cc_call_logs_pkey37; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cc_call_logs
    ADD CONSTRAINT new_cc_call_logs_pkey37 PRIMARY KEY (id);


--
-- TOC entry 9202 (class 2606 OID 642073)
-- Name: notification_categories notification_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_categories
    ADD CONSTRAINT notification_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 8502 (class 2606 OID 275482)
-- Name: notification_history notification_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_history
    ADD CONSTRAINT notification_history_pkey PRIMARY KEY (id);


--
-- TOC entry 8504 (class 2606 OID 275484)
-- Name: notification_modes notification_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_modes
    ADD CONSTRAINT notification_modes_pkey PRIMARY KEY (id);


--
-- TOC entry 8506 (class 2606 OID 275486)
-- Name: notification_types notification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_types
    ADD CONSTRAINT notification_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8509 (class 2606 OID 275488)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 8511 (class 2606 OID 275490)
-- Name: nutrient_deficiency nutrient_deficiency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nutrient_deficiency
    ADD CONSTRAINT nutrient_deficiency_pkey PRIMARY KEY (id);


--
-- TOC entry 8513 (class 2606 OID 275492)
-- Name: oauth_access_tokens oauth_access_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_token_pkey PRIMARY KEY (id);


--
-- TOC entry 8515 (class 2606 OID 275494)
-- Name: oauth_authorization_codes oauth_authorization_code_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT oauth_authorization_code_pkey PRIMARY KEY (id);


--
-- TOC entry 8517 (class 2606 OID 275496)
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- TOC entry 8519 (class 2606 OID 275498)
-- Name: oauth_refresh_tokens oauth_refresh_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT oauth_refresh_token_pkey PRIMARY KEY (id);


--
-- TOC entry 8521 (class 2606 OID 275500)
-- Name: oauth_scopes oauth_scopes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_scopes
    ADD CONSTRAINT oauth_scopes_pkey PRIMARY KEY (id);


--
-- TOC entry 8526 (class 2606 OID 275502)
-- Name: oauth_user_client_grants oauth_user_client_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_user_client_grants
    ADD CONSTRAINT oauth_user_client_grants_pkey PRIMARY KEY (id);


--
-- TOC entry 8530 (class 2606 OID 275504)
-- Name: oauth_user_otp oauth_user_otp_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_user_otp
    ADD CONSTRAINT oauth_user_otp_pkey PRIMARY KEY (id);


--
-- TOC entry 8538 (class 2606 OID 275506)
-- Name: obd_activities obd_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.obd_activities
    ADD CONSTRAINT obd_activities_pkey PRIMARY KEY (id);


--
-- TOC entry 8540 (class 2606 OID 275508)
-- Name: occupations occupations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.occupations
    ADD CONSTRAINT occupations_pkey PRIMARY KEY (id);


--
-- TOC entry 8542 (class 2606 OID 275510)
-- Name: operators operators_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operators
    ADD CONSTRAINT operators_pkey PRIMARY KEY (id);


--
-- TOC entry 9198 (class 2606 OID 640447)
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- TOC entry 9192 (class 2606 OID 633442)
-- Name: otp_whitelisted_numbers otp_whitelisted_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_whitelisted_numbers
    ADD CONSTRAINT otp_whitelisted_numbers_pkey PRIMARY KEY (id);


--
-- TOC entry 8546 (class 2606 OID 275512)
-- Name: paidwalls paidwalls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paidwalls
    ADD CONSTRAINT paidwalls_pkey PRIMARY KEY (id);


--
-- TOC entry 8550 (class 2606 OID 275514)
-- Name: partner_procurement partner_procurement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_procurement
    ADD CONSTRAINT partner_procurement_pkey PRIMARY KEY (id);


--
-- TOC entry 8553 (class 2606 OID 275516)
-- Name: partner_services partner_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_services
    ADD CONSTRAINT partner_services_pkey PRIMARY KEY (id);


--
-- TOC entry 8563 (class 2606 OID 324379)
-- Name: partners_msisdn partners_msisdn_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partners_msisdn
    ADD CONSTRAINT partners_msisdn_pkey PRIMARY KEY (partner_id, msisdn);


--
-- TOC entry 8559 (class 2606 OID 275520)
-- Name: partners partners_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_pkey PRIMARY KEY (id);


--
-- TOC entry 8872 (class 2606 OID 324310)
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 8272 (class 2606 OID 275522)
-- Name: crop_insects pests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_insects
    ADD CONSTRAINT pests_pkey PRIMARY KEY (id);


--
-- TOC entry 8565 (class 2606 OID 275524)
-- Name: phrase_32_char_list phrase_32_char_list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.phrase_32_char_list
    ADD CONSTRAINT phrase_32_char_list_pkey PRIMARY KEY (id);


--
-- TOC entry 9150 (class 2606 OID 583719)
-- Name: pin_crops pin_crops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pin_crops
    ADD CONSTRAINT pin_crops_pkey PRIMARY KEY (id);


--
-- TOC entry 9152 (class 2606 OID 583735)
-- Name: pin_farms pin_farms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pin_farms
    ADD CONSTRAINT pin_farms_pkey PRIMARY KEY (id);


--
-- TOC entry 9229 (class 2606 OID 666250)
-- Name: webview_users pk_webview_users; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.webview_users
    ADD CONSTRAINT pk_webview_users PRIMARY KEY (id);


--
-- TOC entry 9217 (class 2606 OID 647757)
-- Name: post_anomaly post_anomaly_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_anomaly
    ADD CONSTRAINT post_anomaly_pkey PRIMARY KEY (id);


--
-- TOC entry 9223 (class 2606 OID 660680)
-- Name: post_status post_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_status
    ADD CONSTRAINT post_status_pkey PRIMARY KEY (id);


--
-- TOC entry 8567 (class 2606 OID 275526)
-- Name: pro_farmer_profile_update pro_farmer_profile_update_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pro_farmer_profile_update
    ADD CONSTRAINT pro_farmer_profile_update_pkey PRIMARY KEY (email, date);


--
-- TOC entry 8569 (class 2606 OID 275528)
-- Name: processed_tehsils processed_tehsils_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processed_tehsils
    ADD CONSTRAINT processed_tehsils_pkey PRIMARY KEY (farmer_id);


--
-- TOC entry 8580 (class 2606 OID 275530)
-- Name: profile_change_set_default profile_change_set_new_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_change_set_default
    ADD CONSTRAINT profile_change_set_new_pkey PRIMARY KEY (id);


--
-- TOC entry 8575 (class 2606 OID 324324)
-- Name: profile_change_set profile_change_set_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_change_set
    ADD CONSTRAINT profile_change_set_pkey PRIMARY KEY (id);


--
-- TOC entry 8582 (class 2606 OID 275534)
-- Name: profile_change_set_stats profile_change_set_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_change_set_stats
    ADD CONSTRAINT profile_change_set_stats_pkey PRIMARY KEY (id);


--
-- TOC entry 8584 (class 2606 OID 275536)
-- Name: profile_change_set_stats profile_change_set_stats_stats_sync_dt_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_change_set_stats
    ADD CONSTRAINT profile_change_set_stats_stats_sync_dt_key UNIQUE (stats_sync_dt);


--
-- TOC entry 8236 (class 2606 OID 275538)
-- Name: cc_msisdn_check_profile profile_levels_pkeey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cc_msisdn_check_profile
    ADD CONSTRAINT profile_levels_pkeey PRIMARY KEY (id);


--
-- TOC entry 8586 (class 2606 OID 275540)
-- Name: profile_levels profile_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_levels
    ADD CONSTRAINT profile_levels_pkey PRIMARY KEY (id);


--
-- TOC entry 8906 (class 2606 OID 405729)
-- Name: profile_stages profile_stages_pkeey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_stages
    ADD CONSTRAINT profile_stages_pkeey PRIMARY KEY (id);


--
-- TOC entry 8800 (class 2606 OID 323872)
-- Name: profiling_nps_survey profiling_nps_survey_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiling_nps_survey
    ADD CONSTRAINT profiling_nps_survey_pkey PRIMARY KEY (id);


--
-- TOC entry 8588 (class 2606 OID 275542)
-- Name: promo_data_count promo_data_count_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promo_data_count
    ADD CONSTRAINT promo_data_count_pkey PRIMARY KEY (id);


--
-- TOC entry 8590 (class 2606 OID 275544)
-- Name: provinces provinces_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provinces
    ADD CONSTRAINT provinces_pkey PRIMARY KEY (id);


--
-- TOC entry 9221 (class 2606 OID 649288)
-- Name: qrp_case_products qrp_case_products_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.qrp_case_products
    ADD CONSTRAINT qrp_case_products_pkey PRIMARY KEY (id);


--
-- TOC entry 9211 (class 2606 OID 649278)
-- Name: qrp_cases qrp_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.qrp_cases
    ADD CONSTRAINT qrp_cases_pkey PRIMARY KEY (id);


--
-- TOC entry 9213 (class 2606 OID 645555)
-- Name: qrp_searches qrp_searches_pkey; Type: CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.qrp_searches
    ADD CONSTRAINT qrp_searches_pkey PRIMARY KEY (id);


--
-- TOC entry 8592 (class 2606 OID 275546)
-- Name: questionair questionair_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questionair
    ADD CONSTRAINT questionair_pkey PRIMARY KEY (id);


--
-- TOC entry 8594 (class 2606 OID 275548)
-- Name: questionair_response questionair_response_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questionair_response
    ADD CONSTRAINT questionair_response_pkey PRIMARY KEY (id);


--
-- TOC entry 8596 (class 2606 OID 275550)
-- Name: queue_position queue_position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.queue_position
    ADD CONSTRAINT queue_position_pkey PRIMARY KEY (id);


--
-- TOC entry 8601 (class 2606 OID 275552)
-- Name: recording_logs recording_logs_new_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recording_logs
    ADD CONSTRAINT recording_logs_new_pkey PRIMARY KEY (id);


--
-- TOC entry 8874 (class 2606 OID 324352)
-- Name: roles_backup roles_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_backup
    ADD CONSTRAINT roles_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8876 (class 2606 OID 324362)
-- Name: roles_permissions roles_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permissions
    ADD CONSTRAINT roles_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 8603 (class 2606 OID 275554)
-- Name: scenarios scenarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_pkey PRIMARY KEY (id);


--
-- TOC entry 8605 (class 2606 OID 275556)
-- Name: scenarios scenarios_scenario_uuid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_scenario_uuid_key UNIQUE (scenario_uuid);


--
-- TOC entry 8607 (class 2606 OID 275558)
-- Name: scenarios scenarios_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_title_key UNIQUE (title);


--
-- TOC entry 8609 (class 2606 OID 275560)
-- Name: seed_types seed_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seed_types
    ADD CONSTRAINT seed_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8611 (class 2606 OID 390553)
-- Name: seed_types seed_types_uk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seed_types
    ADD CONSTRAINT seed_types_uk1 UNIQUE (id, crop_id);


--
-- TOC entry 8618 (class 2606 OID 275562)
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- TOC entry 8524 (class 2606 OID 275564)
-- Name: oauth_sessions session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_sessions
    ADD CONSTRAINT session_pkey PRIMARY KEY (sid);


--
-- TOC entry 9137 (class 2606 OID 559296)
-- Name: shopify_buyers shopify_buyers_msisdn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_buyers
    ADD CONSTRAINT shopify_buyers_msisdn_key UNIQUE (msisdn);


--
-- TOC entry 9139 (class 2606 OID 559294)
-- Name: shopify_buyers shopify_buyers_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_buyers
    ADD CONSTRAINT shopify_buyers_pk1 PRIMARY KEY (id);


--
-- TOC entry 9206 (class 2606 OID 642094)
-- Name: shopify_visitors_interests shopify_visitors_interests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_visitors_interests
    ADD CONSTRAINT shopify_visitors_interests_pkey PRIMARY KEY (id);


--
-- TOC entry 9204 (class 2606 OID 642084)
-- Name: shopify_visitors shopify_visitors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_visitors
    ADD CONSTRAINT shopify_visitors_pkey PRIMARY KEY (id);


--
-- TOC entry 8621 (class 2606 OID 275577)
-- Name: sites sites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- TOC entry 8878 (class 2606 OID 324372)
-- Name: sites_temp sites_tmp_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sites_temp
    ADD CONSTRAINT sites_tmp_pkey PRIMARY KEY (id);


--
-- TOC entry 9131 (class 2606 OID 558217)
-- Name: sms_keys sms_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sms_keys
    ADD CONSTRAINT sms_keys_pkey PRIMARY KEY (id);


--
-- TOC entry 8625 (class 2606 OID 275579)
-- Name: sms_profiling sms_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sms_profiling
    ADD CONSTRAINT sms_menu_pkey PRIMARY KEY (id);


--
-- TOC entry 8627 (class 2606 OID 275581)
-- Name: sms_profiling_activities sms_menu_response_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sms_profiling_activities
    ADD CONSTRAINT sms_menu_response_pkey PRIMARY KEY (id);


--
-- TOC entry 8630 (class 2606 OID 275583)
-- Name: sms_survey_form_status sms_survey_form_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sms_survey_form_status
    ADD CONSTRAINT sms_survey_form_status_pkey PRIMARY KEY (id);


--
-- TOC entry 8632 (class 2606 OID 275585)
-- Name: sms_survey_questions sms_survey_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sms_survey_questions
    ADD CONSTRAINT sms_survey_questions_pkey PRIMARY KEY (id);


--
-- TOC entry 8634 (class 2606 OID 275587)
-- Name: sms_surveyform_params sms_surveyform_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sms_surveyform_params
    ADD CONSTRAINT sms_surveyform_params_pkey PRIMARY KEY (id);


--
-- TOC entry 8636 (class 2606 OID 275589)
-- Name: soil_issues soil_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_issues
    ADD CONSTRAINT soil_issues_pkey PRIMARY KEY (id);


--
-- TOC entry 8638 (class 2606 OID 275591)
-- Name: soil_types soil_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_types
    ADD CONSTRAINT soil_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8642 (class 2606 OID 275593)
-- Name: source_types source_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source_types
    ADD CONSTRAINT source_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8644 (class 2606 OID 275595)
-- Name: sowing_methods sowing_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sowing_methods
    ADD CONSTRAINT sowing_methods_pkey PRIMARY KEY (id);


--
-- TOC entry 8646 (class 2606 OID 275597)
-- Name: sub_modes sub_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sub_modes
    ADD CONSTRAINT sub_modes_pkey PRIMARY KEY (id);


--
-- TOC entry 8649 (class 2606 OID 275599)
-- Name: sub_modes sub_modes_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sub_modes
    ADD CONSTRAINT sub_modes_title_key UNIQUE (title);


--
-- TOC entry 8653 (class 2606 OID 275601)
-- Name: subscriber_base_other_network_tagging subscriber_base_network_tagging_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriber_base_other_network_tagging
    ADD CONSTRAINT subscriber_base_network_tagging_copy1_pkey PRIMARY KEY (id);


--
-- TOC entry 8651 (class 2606 OID 275603)
-- Name: subscriber_base_network_tagging subscriber_base_network_tagging_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriber_base_network_tagging
    ADD CONSTRAINT subscriber_base_network_tagging_pkey PRIMARY KEY (id);


--
-- TOC entry 8665 (class 2606 OID 275605)
-- Name: subscriber_tagging_update subscriber_copy_26_06_2023_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriber_tagging_update
    ADD CONSTRAINT subscriber_copy_26_06_2023_pkey PRIMARY KEY (id);


--
-- TOC entry 8655 (class 2606 OID 275607)
-- Name: subscriber_notification_types subscriber_notification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriber_notification_types
    ADD CONSTRAINT subscriber_notification_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8660 (class 2606 OID 275609)
-- Name: subscriber_roles subscriber_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriber_roles
    ADD CONSTRAINT subscriber_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 8676 (class 2606 OID 275611)
-- Name: subscribers_test subscribers_copy1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_test
    ADD CONSTRAINT subscribers_copy1_pkey PRIMARY KEY (msisdn);


--
-- TOC entry 8678 (class 2606 OID 275613)
-- Name: subscribers_testt subscribers_copy2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_testt
    ADD CONSTRAINT subscribers_copy2_pkey PRIMARY KEY (msisdn);


--
-- TOC entry 8674 (class 2606 OID 275615)
-- Name: subscribers_job_logs subscribers_job_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_job_logs
    ADD CONSTRAINT subscribers_job_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 8671 (class 2606 OID 328354)
-- Name: subscribers subscribers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers
    ADD CONSTRAINT subscribers_pkey PRIMARY KEY (msisdn, tenant);


--
-- TOC entry 8680 (class 2606 OID 275619)
-- Name: subscription_types subscription_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription_types
    ADD CONSTRAINT subscription_types_pkey PRIMARY KEY (id);


--
-- TOC entry 8682 (class 2606 OID 275621)
-- Name: subscription_types subscription_types_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription_types
    ADD CONSTRAINT subscription_types_title_key UNIQUE (title);


--
-- TOC entry 8685 (class 2606 OID 275623)
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- TOC entry 8991 (class 2606 OID 507495)
-- Name: survey_input_files surveeys_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_files
    ADD CONSTRAINT surveeys_files_pkey PRIMARY KEY (id);


--
-- TOC entry 8971 (class 2606 OID 503026)
-- Name: survey_activities survey_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_activities
    ADD CONSTRAINT survey_activities_pkey PRIMARY KEY (id);


--
-- TOC entry 8987 (class 2606 OID 507491)
-- Name: survey_input_api_actions survey_api_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_api_actions
    ADD CONSTRAINT survey_api_actions_pkey PRIMARY KEY (id);


--
-- TOC entry 8989 (class 2606 OID 503137)
-- Name: survey_input_api_actions survey_api_actions_survey_input_id_action_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_api_actions
    ADD CONSTRAINT survey_api_actions_survey_input_id_action_id_key UNIQUE (survey_input_id, action_id);


--
-- TOC entry 8973 (class 2606 OID 503040)
-- Name: survey_categories survey_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_categories
    ADD CONSTRAINT survey_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 8975 (class 2606 OID 507487)
-- Name: survey_crops survey_crops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_crops
    ADD CONSTRAINT survey_crops_pkey PRIMARY KEY (id);


--
-- TOC entry 8977 (class 2606 OID 507485)
-- Name: survey_crops survey_crops_survey_id_crop_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_crops
    ADD CONSTRAINT survey_crops_survey_id_crop_id_key UNIQUE (survey_id, crop_id);


--
-- TOC entry 8979 (class 2606 OID 503081)
-- Name: survey_file_name_apis survey_file_name_apis_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_file_name_apis
    ADD CONSTRAINT survey_file_name_apis_pk1 PRIMARY KEY (id);


--
-- TOC entry 8981 (class 2606 OID 503083)
-- Name: survey_file_name_apis survey_file_name_apis_uk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_file_name_apis
    ADD CONSTRAINT survey_file_name_apis_uk1 UNIQUE (survey_id, action_id);


--
-- TOC entry 8983 (class 2606 OID 507489)
-- Name: survey_files survey_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_files
    ADD CONSTRAINT survey_files_pkey PRIMARY KEY (id);


--
-- TOC entry 8985 (class 2606 OID 503110)
-- Name: survey_files survey_files_survey_id_content_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_files
    ADD CONSTRAINT survey_files_survey_id_content_file_id_key UNIQUE (survey_id, content_file_id);


--
-- TOC entry 8993 (class 2606 OID 507493)
-- Name: survey_input_files survey_input_files_survey_input_id_content_file_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_files
    ADD CONSTRAINT survey_input_files_survey_input_id_content_file_id_key UNIQUE (survey_input_id, content_file_id);


--
-- TOC entry 8995 (class 2606 OID 507497)
-- Name: survey_input_trunk_actions survey_input_trunk_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_trunk_actions
    ADD CONSTRAINT survey_input_trunk_actions_pkey PRIMARY KEY (id);


--
-- TOC entry 8997 (class 2606 OID 503193)
-- Name: survey_input_trunk_actions survey_input_trunk_actions_survey_input_id_action_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_trunk_actions
    ADD CONSTRAINT survey_input_trunk_actions_survey_input_id_action_id_key UNIQUE (survey_input_id, action_id);


--
-- TOC entry 8890 (class 2606 OID 503146)
-- Name: survey_inputs survey_inputs_event_id_input_digit_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_inputs
    ADD CONSTRAINT survey_inputs_event_id_input_digit_key UNIQUE (survey_id, input_digit);


--
-- TOC entry 8892 (class 2606 OID 387632)
-- Name: survey_inputs survey_inputs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_inputs
    ADD CONSTRAINT survey_inputs_pkey PRIMARY KEY (id);


--
-- TOC entry 8999 (class 2606 OID 507499)
-- Name: survey_languages survey_languages_survey_id_language_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_languages
    ADD CONSTRAINT survey_languages_survey_id_language_id_key UNIQUE (survey_id, language_id);


--
-- TOC entry 9003 (class 2606 OID 507505)
-- Name: survey_livestocks survey_livestock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_livestocks
    ADD CONSTRAINT survey_livestock_pkey PRIMARY KEY (id);


--
-- TOC entry 9005 (class 2606 OID 507503)
-- Name: survey_livestocks survey_livestocks_survey_id_livestock_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_livestocks
    ADD CONSTRAINT survey_livestocks_survey_id_livestock_id_key UNIQUE (survey_id, livestock_id);


--
-- TOC entry 9007 (class 2606 OID 507509)
-- Name: survey_locations survey_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_locations
    ADD CONSTRAINT survey_locations_pkey PRIMARY KEY (id);


--
-- TOC entry 9009 (class 2606 OID 507507)
-- Name: survey_locations survey_locations_survey_id_location_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_locations
    ADD CONSTRAINT survey_locations_survey_id_location_id_key UNIQUE (survey_id, location_id);


--
-- TOC entry 9011 (class 2606 OID 507513)
-- Name: survey_machineries survey_machineries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_machineries
    ADD CONSTRAINT survey_machineries_pkey PRIMARY KEY (id);


--
-- TOC entry 9013 (class 2606 OID 507511)
-- Name: survey_machineries survey_machineries_survey_id_machinery_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_machineries
    ADD CONSTRAINT survey_machineries_survey_id_machinery_id_key UNIQUE (survey_id, machinery_id);


--
-- TOC entry 9015 (class 2606 OID 507517)
-- Name: survey_operator survey_operator_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_operator
    ADD CONSTRAINT survey_operator_pkey PRIMARY KEY (id);


--
-- TOC entry 9017 (class 2606 OID 507515)
-- Name: survey_operator survey_operator_survey_id_operator_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_operator
    ADD CONSTRAINT survey_operator_survey_id_operator_id_key UNIQUE (survey_id, operator_id);


--
-- TOC entry 8886 (class 2606 OID 387473)
-- Name: surveys survey_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.surveys
    ADD CONSTRAINT survey_pkey PRIMARY KEY (id);


--
-- TOC entry 9019 (class 2606 OID 503321)
-- Name: survey_profiles survey_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_profiles
    ADD CONSTRAINT survey_profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 9021 (class 2606 OID 503339)
-- Name: survey_promo_data survey_promo_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_promo_data
    ADD CONSTRAINT survey_promo_data_pkey PRIMARY KEY (id);


--
-- TOC entry 9023 (class 2606 OID 503347)
-- Name: survey_questions survey_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_questions
    ADD CONSTRAINT survey_questions_pkey PRIMARY KEY (id);


--
-- TOC entry 9001 (class 2606 OID 507501)
-- Name: survey_languages survey_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_languages
    ADD CONSTRAINT survey_tags_pkey PRIMARY KEY (id);


--
-- TOC entry 8888 (class 2606 OID 387475)
-- Name: surveys survey_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.surveys
    ADD CONSTRAINT survey_title_key UNIQUE (title);


--
-- TOC entry 9025 (class 2606 OID 503359)
-- Name: survey_validation_apis survey_validation_apis_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_validation_apis
    ADD CONSTRAINT survey_validation_apis_pk1 PRIMARY KEY (id);


--
-- TOC entry 9027 (class 2606 OID 503361)
-- Name: survey_validation_apis survey_validation_apis_uk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_validation_apis
    ADD CONSTRAINT survey_validation_apis_uk1 UNIQUE (survey_id, action_id);


--
-- TOC entry 9194 (class 2606 OID 638599)
-- Name: sync_jobs sync_jobs_pk1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sync_jobs
    ADD CONSTRAINT sync_jobs_pk1 PRIMARY KEY (id);


--
-- TOC entry 8691 (class 2606 OID 275669)
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 8693 (class 2606 OID 275671)
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- TOC entry 8697 (class 2606 OID 275673)
-- Name: tehsils tehsils_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tehsils
    ADD CONSTRAINT tehsils_pkey PRIMARY KEY (id);


--
-- TOC entry 8699 (class 2606 OID 275675)
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- TOC entry 8701 (class 2606 OID 275677)
-- Name: terms_of_use terms_of_use_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.terms_of_use
    ADD CONSTRAINT terms_of_use_pkey PRIMARY KEY (id);


--
-- TOC entry 8703 (class 2606 OID 275682)
-- Name: testing_numbers testing_numbers_msisdn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testing_numbers
    ADD CONSTRAINT testing_numbers_msisdn_key UNIQUE (msisdn);


--
-- TOC entry 8705 (class 2606 OID 275687)
-- Name: testing_numbers testing_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testing_numbers
    ADD CONSTRAINT testing_numbers_pkey PRIMARY KEY (id);


--
-- TOC entry 8707 (class 2606 OID 275691)
-- Name: trunk_call_details trunk_call_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trunk_call_details
    ADD CONSTRAINT trunk_call_details_pkey PRIMARY KEY (id);


--
-- TOC entry 8709 (class 2606 OID 275693)
-- Name: trunk_call_details trunk_call_details_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trunk_call_details
    ADD CONSTRAINT trunk_call_details_title_key UNIQUE (title);


--
-- TOC entry 8713 (class 2606 OID 275695)
-- Name: trunk_recording_timings trunk_recording_timings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trunk_recording_timings
    ADD CONSTRAINT trunk_recording_timings_pkey PRIMARY KEY (id);


--
-- TOC entry 8711 (class 2606 OID 275699)
-- Name: trunk_dialing_timings trunk_timings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trunk_dialing_timings
    ADD CONSTRAINT trunk_timings_pkey PRIMARY KEY (id);


--
-- TOC entry 8822 (class 2606 OID 324019)
-- Name: business uniqueTitle; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT "uniqueTitle" UNIQUE (unique_title);


--
-- TOC entry 9124 (class 2606 OID 519541)
-- Name: farmcrops unique_farmcrops; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmcrops
    ADD CONSTRAINT unique_farmcrops UNIQUE (seed_type_id, crop_id, farm_id, crop_season_id);


--
-- TOC entry 8294 (class 2606 OID 516654)
-- Name: farm_crop_growth_stages unique_growth_stage_date_farm_crop; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crop_growth_stages
    ADD CONSTRAINT unique_growth_stage_date_farm_crop UNIQUE (growth_stage_id, date, farm_crop_id);


--
-- TOC entry 8715 (class 2606 OID 275703)
-- Name: unsub_modes unsub_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unsub_modes
    ADD CONSTRAINT unsub_modes_pkey PRIMARY KEY (id);


--
-- TOC entry 8718 (class 2606 OID 275705)
-- Name: unsub_request unsub_request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unsub_request
    ADD CONSTRAINT unsub_request_pkey PRIMARY KEY (id);


--
-- TOC entry 8720 (class 2606 OID 328328)
-- Name: unsubscribers unsubscribers_temp_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unsubscribers
    ADD CONSTRAINT unsubscribers_temp_pkey PRIMARY KEY (msisdn, tenant);


--
-- TOC entry 8167 (class 2606 OID 323958)
-- Name: agents uq_agent_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT uq_agent_email UNIQUE (email);


--
-- TOC entry 8160 (class 2606 OID 275709)
-- Name: agent_roles uq_agent_roles; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_roles
    ADD CONSTRAINT uq_agent_roles UNIQUE (role_id, agent_id);


--
-- TOC entry 8926 (class 2606 OID 502741)
-- Name: campaign_crops uq_campaign_crop; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_crops
    ADD CONSTRAINT uq_campaign_crop UNIQUE (campaign_id, stage_id, crop_id);


--
-- TOC entry 8938 (class 2606 OID 502815)
-- Name: campaign_languages uq_campaign_language; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_languages
    ADD CONSTRAINT uq_campaign_language UNIQUE (campaign_id, language_id);


--
-- TOC entry 8942 (class 2606 OID 502839)
-- Name: campaign_livestocks uq_campaign_livestock; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_livestocks
    ADD CONSTRAINT uq_campaign_livestock UNIQUE (campaign_id, livestock_id, category_id);


--
-- TOC entry 8946 (class 2606 OID 502863)
-- Name: campaign_locations uq_campaign_location; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_locations
    ADD CONSTRAINT uq_campaign_location UNIQUE (campaign_id, location_id);


--
-- TOC entry 8950 (class 2606 OID 502887)
-- Name: campaign_machineries uq_campaign_machinery; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_machineries
    ADD CONSTRAINT uq_campaign_machinery UNIQUE (campaign_id, machinery_id);


--
-- TOC entry 8727 (class 2606 OID 275728)
-- Name: weather_change_set uq_change_set; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_change_set
    ADD CONSTRAINT uq_change_set UNIQUE (site_id, weather_time, weather_date);


--
-- TOC entry 8276 (class 2606 OID 275730)
-- Name: crops uq_crop_title; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops
    ADD CONSTRAINT uq_crop_title UNIQUE (title);


--
-- TOC entry 8306 (class 2606 OID 275732)
-- Name: farmer_livestock_tags uq_farmer_livestock_tag; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestock_tags
    ADD CONSTRAINT uq_farmer_livestock_tag UNIQUE (livestock_id, tag_id);


--
-- TOC entry 8344 (class 2606 OID 275737)
-- Name: forum_hide_posts uq_forum_hide_post; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_hide_posts
    ADD CONSTRAINT uq_forum_hide_post UNIQUE (user_id, hide_post_id);


--
-- TOC entry 8348 (class 2606 OID 275744)
-- Name: forum_hide_users uq_forum_hide_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_hide_users
    ADD CONSTRAINT uq_forum_hide_user UNIQUE (user_id, hide_user_id);


--
-- TOC entry 8361 (class 2606 OID 275751)
-- Name: forum_report_posts uq_forum_report_post; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_posts
    ADD CONSTRAINT uq_forum_report_post UNIQUE (report_post_id, user_id);


--
-- TOC entry 8369 (class 2606 OID 275762)
-- Name: forum_report_users uq_forum_report_users; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_report_users
    ADD CONSTRAINT uq_forum_report_users UNIQUE (user_id, report_user_id);


--
-- TOC entry 8373 (class 2606 OID 275766)
-- Name: forum_user_agreements uq_forum_user_agreement; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_user_agreements
    ADD CONSTRAINT uq_forum_user_agreement UNIQUE (user_id);


--
-- TOC entry 8300 (class 2606 OID 275770)
-- Name: farmer_friends uq_friends; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_friends
    ADD CONSTRAINT uq_friends UNIQUE (farmer_id, friend_id);


--
-- TOC entry 8780 (class 2606 OID 308196)
-- Name: job_operators uq_job_operator; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_operators
    ADD CONSTRAINT uq_job_operator UNIQUE (job_id, operator_id);


--
-- TOC entry 8474 (class 2606 OID 275772)
-- Name: mandi_listings_meta_data uq_listing_meta_data; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_listings_meta_data
    ADD CONSTRAINT uq_listing_meta_data UNIQUE (listing_id, key);


--
-- TOC entry 8468 (class 2606 OID 275774)
-- Name: mandi_listing_tags uq_listing_tag; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_listing_tags
    ADD CONSTRAINT uq_listing_tag UNIQUE (listing_id, tag_id);


--
-- TOC entry 8416 (class 2606 OID 275776)
-- Name: livestock_farming_categories uq_livestock_farming_category_title; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farming_categories
    ADD CONSTRAINT uq_livestock_farming_category_title UNIQUE (title);


--
-- TOC entry 8460 (class 2606 OID 275778)
-- Name: machinery_types uq_machinery_type_title; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machinery_types
    ADD CONSTRAINT uq_machinery_type_title UNIQUE (title);


--
-- TOC entry 8187 (class 2606 OID 275780)
-- Name: api_resource_category uq_resource_category; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resource_category
    ADD CONSTRAINT uq_resource_category UNIQUE (title);


--
-- TOC entry 8191 (class 2606 OID 275782)
-- Name: api_resource_permissions uq_resource_permission; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resource_permissions
    ADD CONSTRAINT uq_resource_permission UNIQUE (resource_id, permission_id);


--
-- TOC entry 8195 (class 2606 OID 275784)
-- Name: api_resource_roles uq_resource_role; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resource_roles
    ADD CONSTRAINT uq_resource_role UNIQUE (role_id, resource_id, permission_id);


--
-- TOC entry 8613 (class 2606 OID 275786)
-- Name: seed_types uq_seed_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seed_types
    ADD CONSTRAINT uq_seed_type UNIQUE (title, crop_id);


--
-- TOC entry 8616 (class 2606 OID 275788)
-- Name: sentiments uq_sentiment; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sentiments
    ADD CONSTRAINT uq_sentiment UNIQUE (creator_id, post_id);


--
-- TOC entry 8755 (class 2606 OID 275790)
-- Name: weather_raw uq_siteId; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_raw
    ADD CONSTRAINT "uq_siteId" UNIQUE (site_id);


--
-- TOC entry 8737 (class 2606 OID 275792)
-- Name: weather_daily uq_site_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_daily
    ADD CONSTRAINT uq_site_date UNIQUE (site_id, date);


--
-- TOC entry 8749 (class 2606 OID 275794)
-- Name: weather_intraday uq_site_intraday_weather_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_intraday
    ADD CONSTRAINT uq_site_intraday_weather_date UNIQUE (site_id, daypart_name, weather_dt);


--
-- TOC entry 8623 (class 2606 OID 275796)
-- Name: sites uq_site_lat_lng; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT uq_site_lat_lng UNIQUE (lat, lng);


--
-- TOC entry 8743 (class 2606 OID 275798)
-- Name: weather_hourly uq_site_weather_dt; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_hourly
    ADD CONSTRAINT uq_site_weather_dt UNIQUE (site_id, weather_dt);


--
-- TOC entry 8640 (class 2606 OID 275804)
-- Name: soil_types uq_soil_types; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_types
    ADD CONSTRAINT uq_soil_types UNIQUE (name);


--
-- TOC entry 8657 (class 2606 OID 275808)
-- Name: subscriber_notification_types uq_subscriber_notification_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriber_notification_types
    ADD CONSTRAINT uq_subscriber_notification_type UNIQUE (notification_type_id, msisdn);


--
-- TOC entry 8663 (class 2606 OID 275810)
-- Name: subscriber_roles uq_subscriber_role; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriber_roles
    ADD CONSTRAINT uq_subscriber_role UNIQUE (msisdn, role_id);


--
-- TOC entry 8688 (class 2606 OID 275812)
-- Name: subscriptions uq_subscriber_subscription; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT uq_subscriber_subscription UNIQUE (msisdn, subscription_type_id);


--
-- TOC entry 8695 (class 2606 OID 275814)
-- Name: tags uq_tag_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT uq_tag_name UNIQUE (name);


--
-- TOC entry 8916 (class 2606 OID 406801)
-- Name: posts_tags uq_tag_title; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts_tags
    ADD CONSTRAINT uq_tag_title UNIQUE (title);


--
-- TOC entry 8918 (class 2606 OID 406803)
-- Name: posts_tags uq_tag_title_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts_tags
    ADD CONSTRAINT uq_tag_title_pkey PRIMARY KEY (id);


--
-- TOC entry 8324 (class 2606 OID 275816)
-- Name: farmers uq_user_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers
    ADD CONSTRAINT uq_user_key UNIQUE (key);


--
-- TOC entry 8532 (class 2606 OID 275818)
-- Name: oauth_user_otp uq_user_otp; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_user_otp
    ADD CONSTRAINT uq_user_otp UNIQUE (user_id);


--
-- TOC entry 8534 (class 2606 OID 275820)
-- Name: oauth_users uq_user_username; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_users
    ADD CONSTRAINT uq_user_username UNIQUE (username);


--
-- TOC entry 8722 (class 2606 OID 275822)
-- Name: user_activities user_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_activities
    ADD CONSTRAINT user_activities_pkey PRIMARY KEY (id);


--
-- TOC entry 8528 (class 2606 OID 1563946)
-- Name: oauth_user_client_grants user_client_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_user_client_grants
    ADD CONSTRAINT user_client_unique UNIQUE (user_id, client_id);


--
-- TOC entry 9231 (class 2606 OID 830762)
-- Name: user_engagement user_engagement_pkey; Type: CONSTRAINT; Schema: public; Owner: naqia_dev_rw
--

ALTER TABLE ONLY public.user_engagement
    ADD CONSTRAINT user_engagement_pkey PRIMARY KEY (id);


--
-- TOC entry 8536 (class 2606 OID 275824)
-- Name: oauth_users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 8729 (class 2606 OID 275826)
-- Name: weather_change_set weather_change_set_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_change_set
    ADD CONSTRAINT weather_change_set_pkey PRIMARY KEY (id);


--
-- TOC entry 8732 (class 2606 OID 275828)
-- Name: weather_conditions weather_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_conditions
    ADD CONSTRAINT weather_conditions_pkey PRIMARY KEY (id);


--
-- TOC entry 8739 (class 2606 OID 275830)
-- Name: weather_daily weather_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_daily
    ADD CONSTRAINT weather_daily_pkey PRIMARY KEY (id);


--
-- TOC entry 8745 (class 2606 OID 275832)
-- Name: weather_hourly weather_hourly_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_hourly
    ADD CONSTRAINT weather_hourly_pkey PRIMARY KEY (id);


--
-- TOC entry 8751 (class 2606 OID 275834)
-- Name: weather_intraday weather_intraday_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_intraday
    ADD CONSTRAINT weather_intraday_pkey PRIMARY KEY (id);


--
-- TOC entry 8753 (class 2606 OID 275836)
-- Name: weather_outlooks weather_outlook_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_outlooks
    ADD CONSTRAINT weather_outlook_pkey PRIMARY KEY (id);


--
-- TOC entry 8757 (class 2606 OID 275838)
-- Name: weather_raw weather_raw_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_raw
    ADD CONSTRAINT weather_raw_pkey PRIMARY KEY (id);


--
-- TOC entry 8759 (class 2606 OID 275840)
-- Name: weather_service_events weather_service_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_service_events
    ADD CONSTRAINT weather_service_events_pkey PRIMARY KEY (id);


--
-- TOC entry 8762 (class 2606 OID 275842)
-- Name: weather_stations_location weather_stations_location_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_stations_location
    ADD CONSTRAINT weather_stations_location_pkey PRIMARY KEY (id);


--
-- TOC entry 8764 (class 2606 OID 275844)
-- Name: weeds weeds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weeds
    ADD CONSTRAINT weeds_pkey PRIMARY KEY (id);


--
-- TOC entry 8768 (class 2606 OID 275846)
-- Name: welcome_box welcome_box_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.welcome_box
    ADD CONSTRAINT welcome_box_pkey PRIMARY KEY (id);


--
-- TOC entry 8770 (class 2606 OID 275848)
-- Name: welcome_box welcome_box_title_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.welcome_box
    ADD CONSTRAINT welcome_box_title_key UNIQUE (title);


--
-- TOC entry 8772 (class 2606 OID 275850)
-- Name: wx_phrase_list wx_phrase_list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wx_phrase_list
    ADD CONSTRAINT wx_phrase_list_pkey PRIMARY KEY (id);


--
-- TOC entry 8522 (class 1259 OID 275851)
-- Name: IDX_session_expire; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_session_expire" ON public.oauth_sessions USING btree (expire);


--
-- TOC entry 8152 (class 1259 OID 504922)
-- Name: adoptive_menu_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_active_idx ON public.adoptive_menu USING btree (active);


--
-- TOC entry 9030 (class 1259 OID 504955)
-- Name: adoptive_menu_api_actions_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_api_actions_active_idx ON public.adoptive_menu_api_actions USING btree (active);


--
-- TOC entry 9035 (class 1259 OID 504956)
-- Name: adoptive_menu_api_actions_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_api_actions_seq_order_idx ON public.adoptive_menu_api_actions USING btree (seq_order);


--
-- TOC entry 8153 (class 1259 OID 504923)
-- Name: adoptive_menu_app_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_app_name_idx ON public.adoptive_menu USING btree (app_name);


--
-- TOC entry 9036 (class 1259 OID 504984)
-- Name: adoptive_menu_campaigns_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_campaigns_active_idx ON public.adoptive_menu_campaigns USING btree (active);


--
-- TOC entry 9037 (class 1259 OID 504986)
-- Name: adoptive_menu_campaigns_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_campaigns_seq_order_idx ON public.adoptive_menu_campaigns USING btree (seq_order);


--
-- TOC entry 8154 (class 1259 OID 504924)
-- Name: adoptive_menu_child_node_uuid_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_child_node_uuid_idx ON public.adoptive_menu USING btree (child_node_uuid);


--
-- TOC entry 9042 (class 1259 OID 505012)
-- Name: adoptive_menu_content_nodes_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_content_nodes_active_idx ON public.adoptive_menu_content_nodes USING btree (active);


--
-- TOC entry 9045 (class 1259 OID 505014)
-- Name: adoptive_menu_content_nodes_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_content_nodes_seq_order_idx ON public.adoptive_menu_content_nodes USING btree (seq_order);


--
-- TOC entry 9056 (class 1259 OID 505106)
-- Name: adoptive_menu_files_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_files_active_idx ON public.adoptive_menu_files USING btree (active);


--
-- TOC entry 9061 (class 1259 OID 505108)
-- Name: adoptive_menu_files_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_files_seq_order_idx ON public.adoptive_menu_files USING btree (seq_order);


--
-- TOC entry 8155 (class 1259 OID 504925)
-- Name: adoptive_menu_parent_node_uuid_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_parent_node_uuid_idx ON public.adoptive_menu USING btree (parent_node_uuid);


--
-- TOC entry 9080 (class 1259 OID 505237)
-- Name: adoptive_menu_recording_end_files_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_recording_end_files_active_idx ON public.adoptive_menu_recording_end_files USING btree (active);


--
-- TOC entry 9083 (class 1259 OID 505238)
-- Name: adoptive_menu_recording_end_files_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_recording_end_files_seq_order_idx ON public.adoptive_menu_recording_end_files USING btree (seq_order);


--
-- TOC entry 8156 (class 1259 OID 504926)
-- Name: adoptive_menu_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_seq_order_idx ON public.adoptive_menu USING btree (seq_order);


--
-- TOC entry 9084 (class 1259 OID 505266)
-- Name: adoptive_menu_surveys_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_surveys_active_idx ON public.adoptive_menu_surveys USING btree (active);


--
-- TOC entry 9089 (class 1259 OID 505267)
-- Name: adoptive_menu_surveys_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_surveys_seq_order_idx ON public.adoptive_menu_surveys USING btree (seq_order);


--
-- TOC entry 9090 (class 1259 OID 505298)
-- Name: adoptive_menu_trunk_actions_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_trunk_actions_active_idx ON public.adoptive_menu_trunk_actions USING btree (active);


--
-- TOC entry 9095 (class 1259 OID 505299)
-- Name: adoptive_menu_trunk_actions_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX adoptive_menu_trunk_actions_seq_order_idx ON public.adoptive_menu_trunk_actions USING btree (seq_order);


--
-- TOC entry 8170 (class 1259 OID 275883)
-- Name: agent_msisdn_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_msisdn_copy1 ON public.agents_activity_logs USING btree (msisdn);


--
-- TOC entry 8171 (class 1259 OID 275884)
-- Name: agent_new_value_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_new_value_copy1 ON public.agents_activity_logs USING btree (new_value);


--
-- TOC entry 8172 (class 1259 OID 275885)
-- Name: agent_old_value_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_old_value_copy1 ON public.agents_activity_logs USING btree (old_value);


--
-- TOC entry 8173 (class 1259 OID 275886)
-- Name: agent_profiled_by_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_profiled_by_copy1 ON public.agents_activity_logs USING btree (profiled_by);


--
-- TOC entry 8174 (class 1259 OID 275887)
-- Name: agent_profiler_type_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agent_profiler_type_copy1 ON public.agents_activity_logs USING btree (profiler_type);


--
-- TOC entry 8175 (class 1259 OID 275888)
-- Name: agents_key_value_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agents_key_value_copy1 ON public.agents_activity_logs USING btree (key_value);


--
-- TOC entry 8176 (class 1259 OID 275889)
-- Name: agents_table_name_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX agents_table_name_copy1 ON public.agents_activity_logs USING btree (table_name);


--
-- TOC entry 8177 (class 1259 OID 275890)
-- Name: api_call_details_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_call_details_active_idx ON public.api_call_details USING btree (active);


--
-- TOC entry 8907 (class 1259 OID 406419)
-- Name: api_call_details_active_idx_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_call_details_active_idx_copy1 ON public.api_call_details_updated USING btree (active);


--
-- TOC entry 8893 (class 1259 OID 389327)
-- Name: call_end_notification_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX call_end_notification_created_at_idx ON public.call_end_notification USING btree (created_at);


--
-- TOC entry 8894 (class 1259 OID 389328)
-- Name: call_end_notification_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX call_end_notification_msisdn_idx ON public.call_end_notification USING btree (msisdn);


--
-- TOC entry 8957 (class 1259 OID 502943)
-- Name: campaign_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX campaign_id ON public.campaign_promo_data USING btree (campaign_id);


--
-- TOC entry 8225 (class 1259 OID 275892)
-- Name: cc_call_end_survey_logs_context_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cc_call_end_survey_logs_context_idx ON public.cc_call_end_survey_logs USING btree (context);


--
-- TOC entry 8226 (class 1259 OID 275893)
-- Name: cc_call_end_survey_logs_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cc_call_end_survey_logs_dt_idx ON public.cc_call_end_survey_logs USING btree (dt);


--
-- TOC entry 8227 (class 1259 OID 275894)
-- Name: cc_call_end_survey_logs_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cc_call_end_survey_logs_msisdn_idx ON public.cc_call_end_survey_logs USING btree (msisdn);


--
-- TOC entry 8289 (class 1259 OID 275895)
-- Name: farm_crop_growth_stages_farm_crop_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farm_crop_growth_stages_farm_crop_id_idx ON public.farm_crop_growth_stages USING btree (farm_crop_id);


--
-- TOC entry 8290 (class 1259 OID 275896)
-- Name: farm_crop_growth_stages_growth_stage_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farm_crop_growth_stages_growth_stage_id_idx ON public.farm_crop_growth_stages USING btree (growth_stage_id);


--
-- TOC entry 9115 (class 1259 OID 519341)
-- Name: farmcrops_new_crop_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farmcrops_new_crop_id_idx ON public.farmcrops USING btree (crop_id);


--
-- TOC entry 9116 (class 1259 OID 519342)
-- Name: farmcrops_new_farm_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farmcrops_new_farm_id_idx ON public.farmcrops USING btree (farm_id);


--
-- TOC entry 9119 (class 1259 OID 519343)
-- Name: farmcrops_new_sowing_method_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farmcrops_new_sowing_method_id_idx ON public.farmcrops USING btree (sowing_method_id);


--
-- TOC entry 9122 (class 1259 OID 602955)
-- Name: farmcrops_seq_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farmcrops_seq_order_idx ON public.farmcrops USING btree (seq_order);


--
-- TOC entry 8307 (class 1259 OID 275901)
-- Name: farmer_livestocks_farmer_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farmer_livestocks_farmer_id_idx ON public.farmer_livestocks USING btree (farmer_id);


--
-- TOC entry 8308 (class 1259 OID 275902)
-- Name: farmer_livestocks_livestock_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farmer_livestocks_livestock_id_idx ON public.farmer_livestocks USING btree (livestock_id);


--
-- TOC entry 8311 (class 1259 OID 275903)
-- Name: farmer_machineries_farmer_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farmer_machineries_farmer_id_idx ON public.farmer_machineries USING btree (farmer_id);


--
-- TOC entry 8316 (class 1259 OID 275904)
-- Name: farmer_name_content_file_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmer_name_content_file_name_idx ON public.farmer_name_content USING btree (file_name);


--
-- TOC entry 8319 (class 1259 OID 275905)
-- Name: farmers_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmers_key_idx ON public.farmers USING btree (key);


--
-- TOC entry 8329 (class 1259 OID 275906)
-- Name: farmers_msisdn_idx_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX farmers_msisdn_idx_copy1 ON public.farmers_testing USING btree (id);


--
-- TOC entry 8322 (class 1259 OID 324253)
-- Name: farmers_profile_level_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farmers_profile_level_id_idx ON public.farmers USING btree (profile_level_id);


--
-- TOC entry 8330 (class 1259 OID 275908)
-- Name: farms_create_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farms_create_dt_idx ON public.farms USING btree (create_dt);


--
-- TOC entry 8331 (class 1259 OID 275909)
-- Name: farms_farmer_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farms_farmer_id_idx ON public.farms USING btree (farmer_id);


--
-- TOC entry 8332 (class 1259 OID 275910)
-- Name: farms_geo_point_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farms_geo_point_idx ON public.farms USING gist (geo_point);


--
-- TOC entry 8333 (class 1259 OID 275911)
-- Name: farms_is_default_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farms_is_default_idx ON public.farms USING btree (is_default);


--
-- TOC entry 8334 (class 1259 OID 275912)
-- Name: farms_location_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farms_location_id_idx ON public.farms USING btree (location_id);


--
-- TOC entry 8337 (class 1259 OID 275913)
-- Name: farms_shape_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farms_shape_idx ON public.farms USING gist (shape);


--
-- TOC entry 8338 (class 1259 OID 275914)
-- Name: farms_soil_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX farms_soil_type_id_idx ON public.farms USING btree (soil_type_id);


--
-- TOC entry 9108 (class 1259 OID 536113)
-- Name: forum_post_rejection_reasons_create_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX forum_post_rejection_reasons_create_dt_idx ON public.forum_post_rejection_reasons USING btree (create_dt);


--
-- TOC entry 8353 (class 1259 OID 538173)
-- Name: forum_posts_create_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX forum_posts_create_dt_idx ON public.forum_posts USING btree (created_at);


--
-- TOC entry 8354 (class 1259 OID 538172)
-- Name: forum_posts_creator_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX forum_posts_creator_id_idx ON public.forum_posts USING btree (creator_id);


--
-- TOC entry 8914 (class 1259 OID 628805)
-- Name: forum_posts_tags_post_tag_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX forum_posts_tags_post_tag_id_idx ON public.forum_posts_tags USING btree (post_tag_id);


--
-- TOC entry 8355 (class 1259 OID 538170)
-- Name: forum_posts_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX forum_posts_type_idx ON public.forum_posts USING btree (type);


--
-- TOC entry 8425 (class 1259 OID 275915)
-- Name: id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX id ON public.livestocks USING btree (id);


--
-- TOC entry 8269 (class 1259 OID 275916)
-- Name: id_p; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX id_p ON public.growth_stages USING btree (parent_id);


--
-- TOC entry 8270 (class 1259 OID 275917)
-- Name: id_unix; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX id_unix ON public.growth_stages USING btree (id);


--
-- TOC entry 8723 (class 1259 OID 275918)
-- Name: idx_change_set_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_change_set_site_id ON public.weather_change_set USING btree (site_id);


--
-- TOC entry 8724 (class 1259 OID 275919)
-- Name: idx_change_set_weather_dt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_change_set_weather_dt ON public.weather_change_set USING btree (weather_date);


--
-- TOC entry 8725 (class 1259 OID 275920)
-- Name: idx_change_set_weather_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_change_set_weather_time ON public.weather_change_set USING btree (weather_time);


--
-- TOC entry 9142 (class 1259 OID 563295)
-- Name: idx_create_dt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_create_dt ON public.farmers_eng_urdu_names USING btree (create_dt);


--
-- TOC entry 8224 (class 1259 OID 275921)
-- Name: idx_msisdn; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_msisdn ON public.cc_agents USING btree (msisdn);


--
-- TOC entry 9209 (class 1259 OID 651522)
-- Name: idx_qrp_cases_farmer_id; Type: INDEX; Schema: public; Owner: rameez_dev_rw
--

CREATE INDEX idx_qrp_cases_farmer_id ON public.qrp_cases USING btree (farmer_id);


--
-- TOC entry 9143 (class 1259 OID 563296)
-- Name: idx_unique_name_en; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_name_en ON public.farmers_eng_urdu_names USING btree (name_en);


--
-- TOC entry 9144 (class 1259 OID 563297)
-- Name: idx_unique_name_ur; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_unique_name_ur ON public.farmers_eng_urdu_names USING btree (name_ur);


--
-- TOC entry 8797 (class 1259 OID 323781)
-- Name: idxmsisdn; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idxmsisdn ON public.cc_outbound_whitelist USING btree (msisdn);


--
-- TOC entry 8730 (class 1259 OID 275922)
-- Name: index_icon_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_icon_code ON public.weather_conditions USING btree (icon_code);


--
-- TOC entry 8733 (class 1259 OID 275923)
-- Name: index_uq_weather_daily; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_uq_weather_daily ON public.weather_daily USING btree (site_id, date);


--
-- TOC entry 8734 (class 1259 OID 275924)
-- Name: index_w_daily_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_w_daily_date ON public.weather_daily USING btree (date);


--
-- TOC entry 8735 (class 1259 OID 275925)
-- Name: index_w_daily_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_w_daily_site_id ON public.weather_daily USING btree (site_id);


--
-- TOC entry 8740 (class 1259 OID 275926)
-- Name: index_w_hourly_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_w_hourly_date ON public.weather_hourly USING btree (weather_dt);


--
-- TOC entry 8741 (class 1259 OID 275927)
-- Name: index_w_hourly_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_w_hourly_site_id ON public.weather_hourly USING btree (site_id);


--
-- TOC entry 8746 (class 1259 OID 275928)
-- Name: index_w_intraday_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_w_intraday_date ON public.weather_intraday USING btree (weather_dt);


--
-- TOC entry 8747 (class 1259 OID 275929)
-- Name: index_w_intraday_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_w_intraday_site_id ON public.weather_intraday USING btree (site_id);


--
-- TOC entry 9237 (class 1259 OID 1091005)
-- Name: job_logs_2025_07_24_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_07_24_job_id_request_id_msisdn_idx ON public.job_logs_2025_07_24 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9240 (class 1259 OID 1091261)
-- Name: job_logs_2025_07_25_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_07_25_job_id_request_id_msisdn_idx ON public.job_logs_2025_07_25 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9243 (class 1259 OID 1134161)
-- Name: job_logs_2025_07_26_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_07_26_job_id_request_id_msisdn_idx ON public.job_logs_2025_07_26 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9246 (class 1259 OID 1134434)
-- Name: job_logs_2025_07_27_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_07_27_job_id_request_id_msisdn_idx ON public.job_logs_2025_07_27 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9249 (class 1259 OID 1134700)
-- Name: job_logs_2025_07_28_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_07_28_job_id_request_id_msisdn_idx ON public.job_logs_2025_07_28 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9252 (class 1259 OID 1178352)
-- Name: job_logs_2025_07_29_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_07_29_job_id_request_id_msisdn_idx ON public.job_logs_2025_07_29 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9255 (class 1259 OID 1561218)
-- Name: job_logs_2025_07_30_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_07_30_job_id_request_id_msisdn_idx ON public.job_logs_2025_07_30 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9258 (class 1259 OID 1561802)
-- Name: job_logs_2025_07_31_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_07_31_job_id_request_id_msisdn_idx ON public.job_logs_2025_07_31 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9261 (class 1259 OID 1566042)
-- Name: job_logs_2025_08_13_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_08_13_job_id_request_id_msisdn_idx ON public.job_logs_2025_08_13 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9264 (class 1259 OID 1566384)
-- Name: job_logs_2025_08_14_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_08_14_job_id_request_id_msisdn_idx ON public.job_logs_2025_08_14 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 9267 (class 1259 OID 1566784)
-- Name: job_logs_2025_08_15_job_id_request_id_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX job_logs_2025_08_15_job_id_request_id_msisdn_idx ON public.job_logs_2025_08_15 USING btree (job_id, request_id, msisdn);


--
-- TOC entry 8406 (class 1259 OID 275930)
-- Name: languages_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX languages_name_idx ON public.languages USING btree (name);


--
-- TOC entry 9161 (class 1259 OID 598320)
-- Name: livestock_farm_livestocks_idk1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farm_livestocks_idk1 ON public.livestock_farm_livestocks USING btree (create_dt);


--
-- TOC entry 9162 (class 1259 OID 598321)
-- Name: livestock_farm_livestocks_idk2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farm_livestocks_idk2 ON public.livestock_farm_livestocks USING btree (livestock_farm_id);


--
-- TOC entry 9163 (class 1259 OID 598322)
-- Name: livestock_farm_livestocks_idk3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farm_livestocks_idk3 ON public.livestock_farm_livestocks USING btree (breed_id);


--
-- TOC entry 9164 (class 1259 OID 598323)
-- Name: livestock_farm_livestocks_idk4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farm_livestocks_idk4 ON public.livestock_farm_livestocks USING btree (stage_id);


--
-- TOC entry 9165 (class 1259 OID 598324)
-- Name: livestock_farm_livestocks_idk5; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farm_livestocks_idk5 ON public.livestock_farm_livestocks USING btree (create_dt);


--
-- TOC entry 9166 (class 1259 OID 598325)
-- Name: livestock_farm_livestocks_idk6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farm_livestocks_idk6 ON public.livestock_farm_livestocks USING btree (purpose_id);


--
-- TOC entry 9167 (class 1259 OID 598326)
-- Name: livestock_farm_livestocks_idk7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farm_livestocks_idk7 ON public.livestock_farm_livestocks USING btree (category_id);


--
-- TOC entry 9168 (class 1259 OID 598327)
-- Name: livestock_farm_livestocks_idk8; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farm_livestocks_idk8 ON public.livestock_farm_livestocks USING btree (livestock_id);


--
-- TOC entry 9153 (class 1259 OID 598274)
-- Name: livestock_farms_idk1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farms_idk1 ON public.livestock_farms USING btree (create_dt);


--
-- TOC entry 9154 (class 1259 OID 598275)
-- Name: livestock_farms_idk2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farms_idk2 ON public.livestock_farms USING btree (farmer_id);


--
-- TOC entry 9155 (class 1259 OID 598276)
-- Name: livestock_farms_idk3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farms_idk3 ON public.livestock_farms USING btree (is_default);


--
-- TOC entry 9156 (class 1259 OID 598277)
-- Name: livestock_farms_idk4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX livestock_farms_idk4 ON public.livestock_farms USING btree (location_id);


--
-- TOC entry 9125 (class 1259 OID 519376)
-- Name: location_id_index; Type: INDEX; Schema: public; Owner: bkkdev_rw
--

CREATE INDEX location_id_index ON public.crop_segregation_material USING btree (location_id);


--
-- TOC entry 8450 (class 1259 OID 275931)
-- Name: locations_geo_point_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX locations_geo_point_idx ON public.locations USING gist (geo_point);


--
-- TOC entry 9234 (class 1259 OID 877690)
-- Name: locations_geo_point_idx_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX locations_geo_point_idx_copy1 ON public.locations_copy1 USING gist (geo_point);


--
-- TOC entry 8451 (class 1259 OID 275932)
-- Name: locations_shape_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX locations_shape_idx ON public.locations USING gist (shape);


--
-- TOC entry 9235 (class 1259 OID 877691)
-- Name: locations_shape_idx_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX locations_shape_idx_copy1 ON public.locations_copy1 USING gist (shape);


--
-- TOC entry 8452 (class 1259 OID 275933)
-- Name: locations_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX locations_type_idx ON public.locations USING btree (type);


--
-- TOC entry 9236 (class 1259 OID 877692)
-- Name: locations_type_idx_copy1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX locations_type_idx_copy1 ON public.locations_copy1 USING btree (type);


--
-- TOC entry 8960 (class 1259 OID 502944)
-- Name: msisdn; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX msisdn ON public.campaign_promo_data USING btree (msisdn);


--
-- TOC entry 8232 (class 1259 OID 275935)
-- Name: new_cc_call_logs_paidwall_id_idx37; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX new_cc_call_logs_paidwall_id_idx37 ON public.cc_call_logs USING btree (paidwall_id);


--
-- TOC entry 8507 (class 1259 OID 275936)
-- Name: notifications_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_msisdn_idx ON public.notifications USING btree (msisdn);


--
-- TOC entry 8543 (class 1259 OID 275937)
-- Name: operators_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX operators_title_idx ON public.operators USING btree (title);


--
-- TOC entry 9195 (class 1259 OID 640448)
-- Name: orders_idk1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX orders_idk1 ON public.orders USING btree (create_dt);


--
-- TOC entry 9196 (class 1259 OID 640449)
-- Name: orders_idk2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX orders_idk2 ON public.orders USING btree (product_list);


--
-- TOC entry 8544 (class 1259 OID 275938)
-- Name: paidwalls_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX paidwalls_active_idx ON public.paidwalls USING btree (active);


--
-- TOC entry 8547 (class 1259 OID 275939)
-- Name: paidwalls_queue_tag_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX paidwalls_queue_tag_idx ON public.paidwalls USING btree (queue_tag);


--
-- TOC entry 8548 (class 1259 OID 275940)
-- Name: paidwalls_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX paidwalls_title_idx ON public.paidwalls USING btree (title);


--
-- TOC entry 8551 (class 1259 OID 275941)
-- Name: partner_services_partner_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partner_services_partner_id_idx ON public.partner_services USING btree (partner_id);


--
-- TOC entry 8554 (class 1259 OID 275942)
-- Name: partner_services_sequence_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partner_services_sequence_order_idx ON public.partner_services USING btree (sequence_order);


--
-- TOC entry 8555 (class 1259 OID 275943)
-- Name: partner_services_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX partner_services_title_idx ON public.partner_services USING btree (title);


--
-- TOC entry 8556 (class 1259 OID 324726)
-- Name: partners_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partners_active_idx ON public.partners USING btree (active);


--
-- TOC entry 8557 (class 1259 OID 324299)
-- Name: partners_end_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partners_end_dt_idx ON public.partners USING btree (end_dt);


--
-- TOC entry 8561 (class 1259 OID 275946)
-- Name: partners_msisdn_partner_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partners_msisdn_partner_id_idx ON public.partners_msisdn USING btree (partner_id);


--
-- TOC entry 8560 (class 1259 OID 324298)
-- Name: partners_start_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partners_start_dt_idx ON public.partners USING btree (start_dt);


--
-- TOC entry 8570 (class 1259 OID 275948)
-- Name: profile_change_set_create_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_change_set_create_dt_idx ON public.profile_change_set USING btree (create_dt);


--
-- TOC entry 8576 (class 1259 OID 275949)
-- Name: profile_change_set_new_column_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_change_set_new_column_key_idx ON public.profile_change_set_default USING btree (column_key);


--
-- TOC entry 8571 (class 1259 OID 275950)
-- Name: profile_change_set_new_column_key_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_change_set_new_column_key_idx1 ON public.profile_change_set USING btree (column_key);


--
-- TOC entry 8577 (class 1259 OID 275951)
-- Name: profile_change_set_new_column_value_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_change_set_new_column_value_idx ON public.profile_change_set_default USING btree (column_value);


--
-- TOC entry 8572 (class 1259 OID 324312)
-- Name: profile_change_set_new_column_value_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_change_set_new_column_value_idx1 ON public.profile_change_set USING btree (column_value);


--
-- TOC entry 8578 (class 1259 OID 275953)
-- Name: profile_change_set_new_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_change_set_new_msisdn_idx ON public.profile_change_set_default USING btree (msisdn);


--
-- TOC entry 8573 (class 1259 OID 275954)
-- Name: profile_change_set_new_msisdn_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_change_set_new_msisdn_idx1 ON public.profile_change_set USING btree (msisdn);


--
-- TOC entry 8903 (class 1259 OID 405730)
-- Name: profile_stages_creat_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_stages_creat_dt_idx ON public.profile_stages USING btree (create_dt);


--
-- TOC entry 8904 (class 1259 OID 405731)
-- Name: profile_stages_msisdn_iid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profile_stages_msisdn_iid ON public.profile_stages USING btree (msisdn);


--
-- TOC entry 8798 (class 1259 OID 324325)
-- Name: profiling_nps_survey_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX profiling_nps_survey_msisdn_idx ON public.profiling_nps_survey USING btree (msisdn);


--
-- TOC entry 8597 (class 1259 OID 275955)
-- Name: recording_logs_new_channel_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX recording_logs_new_channel_id_idx ON public.recording_logs USING btree (channel_id);


--
-- TOC entry 8598 (class 1259 OID 275956)
-- Name: recording_logs_new_context_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX recording_logs_new_context_idx ON public.recording_logs USING btree (context);


--
-- TOC entry 8599 (class 1259 OID 275957)
-- Name: recording_logs_new_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX recording_logs_new_msisdn_idx ON public.recording_logs USING btree (msisdn);


--
-- TOC entry 8163 (class 1259 OID 275958)
-- Name: roles_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX roles_title_idx ON public.roles USING btree (title);


--
-- TOC entry 8614 (class 1259 OID 538174)
-- Name: sentiments_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sentiments_sentiment_idx ON public.sentiments USING btree (sentiment);


--
-- TOC entry 9134 (class 1259 OID 559302)
-- Name: shopify_buyers_first_order_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX shopify_buyers_first_order_dt_idx ON public.shopify_buyers USING btree (first_order_dt);


--
-- TOC entry 9135 (class 1259 OID 559303)
-- Name: shopify_buyers_last_order_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX shopify_buyers_last_order_dt_idx ON public.shopify_buyers USING btree (last_order_dt);


--
-- TOC entry 8619 (class 1259 OID 275959)
-- Name: sites_geom_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sites_geom_idx ON public.sites USING gist (geom);


--
-- TOC entry 8628 (class 1259 OID 275960)
-- Name: sms_profiling_activities_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sms_profiling_activities_msisdn_idx ON public.sms_profiling_activities USING btree (msisdn);


--
-- TOC entry 8647 (class 1259 OID 275961)
-- Name: sub_modes_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sub_modes_title_idx ON public.sub_modes USING btree (title);


--
-- TOC entry 8658 (class 1259 OID 275962)
-- Name: subscriber_roles_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscriber_roles_msisdn_idx ON public.subscriber_roles USING btree (msisdn);


--
-- TOC entry 8661 (class 1259 OID 275963)
-- Name: subscriber_roles_role_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscriber_roles_role_id_idx ON public.subscriber_roles USING btree (role_id);


--
-- TOC entry 8666 (class 1259 OID 591693)
-- Name: subscribers_form_sent_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscribers_form_sent_idx ON public.subscribers USING btree (form_sent);


--
-- TOC entry 8667 (class 1259 OID 275964)
-- Name: subscribers_language_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscribers_language_id_idx ON public.subscribers USING btree (language_id);


--
-- TOC entry 8668 (class 1259 OID 275965)
-- Name: subscribers_last_sub_dt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscribers_last_sub_dt_idx ON public.subscribers USING btree (last_sub_dt);


--
-- TOC entry 8669 (class 1259 OID 275966)
-- Name: subscribers_operator_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscribers_operator_id_idx ON public.subscribers USING btree (operator_id);


--
-- TOC entry 8672 (class 1259 OID 275967)
-- Name: subscribers_sub_mode_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscribers_sub_mode_id_idx ON public.subscribers USING btree (sub_mode_id);


--
-- TOC entry 8683 (class 1259 OID 275968)
-- Name: subscriptions_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscriptions_msisdn_idx ON public.subscriptions USING btree (msisdn);


--
-- TOC entry 8686 (class 1259 OID 275969)
-- Name: subscriptions_subscription_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX subscriptions_subscription_type_id_idx ON public.subscriptions USING btree (subscription_type_id);


--
-- TOC entry 8969 (class 1259 OID 503027)
-- Name: survey_activities_msisdn_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX survey_activities_msisdn_idx ON public.survey_activities USING btree (msisdn);


--
-- TOC entry 8689 (class 1259 OID 275971)
-- Name: system_settings_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX system_settings_key_idx ON public.system_settings USING btree (key);


--
-- TOC entry 8760 (class 1259 OID 275972)
-- Name: unique_Station_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "unique_Station_id" ON public.weather_stations_location USING btree (station_id);


--
-- TOC entry 8716 (class 1259 OID 275973)
-- Name: unsub_modes_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unsub_modes_title_idx ON public.unsub_modes USING btree (title);


--
-- TOC entry 8765 (class 1259 OID 275974)
-- Name: welcome_box_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX welcome_box_active_idx ON public.welcome_box USING btree (active);


--
-- TOC entry 8766 (class 1259 OID 275975)
-- Name: welcome_box_app_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX welcome_box_app_name_idx ON public.welcome_box USING btree (app_name);


--
-- TOC entry 9537 (class 2620 OID 275976)
-- Name: farmers auto_key_gen; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER auto_key_gen AFTER INSERT ON public.farmers FOR EACH ROW EXECUTE FUNCTION public.generate_farmer_uid();


--
-- TOC entry 9538 (class 2620 OID 275977)
-- Name: farmers_testing auto_key_gen; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER auto_key_gen AFTER INSERT ON public.farmers_testing FOR EACH ROW EXECUTE FUNCTION public.generate_farmer_uid();


--
-- TOC entry 9549 (class 2620 OID 389329)
-- Name: call_end_notification call_end_notification_updated_at_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER call_end_notification_updated_at_trigger BEFORE UPDATE ON public.call_end_notification FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 9536 (class 2620 OID 275978)
-- Name: cc_call_logs cc_call_logs_trigger_update_updated_dt; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER cc_call_logs_trigger_update_updated_dt BEFORE UPDATE ON public.cc_call_logs FOR EACH ROW EXECUTE FUNCTION public.update_updated_dt();


--
-- TOC entry 9543 (class 2620 OID 275979)
-- Name: paidwalls paidwalls_trigger_update_updated_dt; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER paidwalls_trigger_update_updated_dt BEFORE UPDATE ON public.paidwalls FOR EACH ROW EXECUTE FUNCTION public.update_updated_dt();


--
-- TOC entry 9535 (class 2620 OID 275980)
-- Name: application_status set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.application_status FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9539 (class 2620 OID 275981)
-- Name: field_visits set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.field_visits FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9540 (class 2620 OID 275982)
-- Name: in_app_notifications set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.in_app_notifications FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9541 (class 2620 OID 275983)
-- Name: loan_applications set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.loan_applications FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9542 (class 2620 OID 275984)
-- Name: loan_types set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.loan_types FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9544 (class 2620 OID 275985)
-- Name: partner_procurement set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.partner_procurement FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9545 (class 2620 OID 275986)
-- Name: partner_services set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.partner_services FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9546 (class 2620 OID 275987)
-- Name: questionair set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.questionair FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9547 (class 2620 OID 275988)
-- Name: questionair_response set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.questionair_response FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9548 (class 2620 OID 275989)
-- Name: services set_timepstamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timepstamp AFTER UPDATE ON public.services FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 9472 (class 2606 OID 509249)
-- Name: adoptive_menu_api_actions adoptive_menu_api_actions_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_api_actions
    ADD CONSTRAINT adoptive_menu_api_actions_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE;


--
-- TOC entry 9473 (class 2606 OID 508655)
-- Name: adoptive_menu_api_actions adoptive_menu_api_actions_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_api_actions
    ADD CONSTRAINT adoptive_menu_api_actions_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9474 (class 2606 OID 508660)
-- Name: adoptive_menu_campaigns adoptive_menu_campaigns_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_campaigns
    ADD CONSTRAINT adoptive_menu_campaigns_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9476 (class 2606 OID 508946)
-- Name: adoptive_menu_content_nodes adoptive_menu_content_nodes_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_content_nodes
    ADD CONSTRAINT adoptive_menu_content_nodes_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9478 (class 2606 OID 508670)
-- Name: adoptive_menu_crops adoptive_menu_crops_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_crops
    ADD CONSTRAINT adoptive_menu_crops_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9475 (class 2606 OID 504992)
-- Name: adoptive_menu_campaigns adoptive_menu_events_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_campaigns
    ADD CONSTRAINT adoptive_menu_events_event_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE;


--
-- TOC entry 9481 (class 2606 OID 505079)
-- Name: adoptive_menu_file_name_apis adoptive_menu_file_name_apis_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_file_name_apis
    ADD CONSTRAINT adoptive_menu_file_name_apis_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9482 (class 2606 OID 505084)
-- Name: adoptive_menu_file_name_apis adoptive_menu_file_name_apis_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_file_name_apis
    ADD CONSTRAINT adoptive_menu_file_name_apis_fk2 FOREIGN KEY (action_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9483 (class 2606 OID 509264)
-- Name: adoptive_menu_files adoptive_menu_files_content_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_files
    ADD CONSTRAINT adoptive_menu_files_content_file_id_fkey FOREIGN KEY (content_file_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9477 (class 2606 OID 505020)
-- Name: adoptive_menu_content_nodes adoptive_menu_files_content_file_v2_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_content_nodes
    ADD CONSTRAINT adoptive_menu_files_content_file_v2_id_fkey FOREIGN KEY (content_file_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9484 (class 2606 OID 508951)
-- Name: adoptive_menu_files adoptive_menu_files_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_files
    ADD CONSTRAINT adoptive_menu_files_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9485 (class 2606 OID 508625)
-- Name: adoptive_menu_languages adoptive_menu_languages_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_languages
    ADD CONSTRAINT adoptive_menu_languages_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9487 (class 2606 OID 508630)
-- Name: adoptive_menu_livestocks adoptive_menu_livestocks_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_livestocks
    ADD CONSTRAINT adoptive_menu_livestocks_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9490 (class 2606 OID 508896)
-- Name: adoptive_menu_locations adoptive_menu_locations_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_locations
    ADD CONSTRAINT adoptive_menu_locations_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9491 (class 2606 OID 508891)
-- Name: adoptive_menu_locations adoptive_menu_locations_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_locations
    ADD CONSTRAINT adoptive_menu_locations_fk2 FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9492 (class 2606 OID 508635)
-- Name: adoptive_menu_machineries adoptive_menu_machineries_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_machineries
    ADD CONSTRAINT adoptive_menu_machineries_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9493 (class 2606 OID 505206)
-- Name: adoptive_menu_machineries adoptive_menu_machineries_machinery_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_machineries
    ADD CONSTRAINT adoptive_menu_machineries_machinery_id_fkey FOREIGN KEY (machinery_id) REFERENCES public.machineries(id) ON UPDATE CASCADE;


--
-- TOC entry 9502 (class 2606 OID 508405)
-- Name: adoptive_menu_operators adoptive_menu_operators_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_operators
    ADD CONSTRAINT adoptive_menu_operators_fk1 FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9503 (class 2606 OID 508410)
-- Name: adoptive_menu_operators adoptive_menu_operators_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_operators
    ADD CONSTRAINT adoptive_menu_operators_fk2 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9504 (class 2606 OID 508665)
-- Name: adoptive_menu_profiles adoptive_menu_profiles_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_profiles
    ADD CONSTRAINT adoptive_menu_profiles_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9494 (class 2606 OID 505244)
-- Name: adoptive_menu_recording_end_files adoptive_menu_recording_end_files_content_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_recording_end_files
    ADD CONSTRAINT adoptive_menu_recording_end_files_content_file_id_fkey FOREIGN KEY (content_file_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9495 (class 2606 OID 508640)
-- Name: adoptive_menu_recording_end_files adoptive_menu_recording_end_files_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_recording_end_files
    ADD CONSTRAINT adoptive_menu_recording_end_files_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9496 (class 2606 OID 508645)
-- Name: adoptive_menu_surveys adoptive_menu_surveys_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_surveys
    ADD CONSTRAINT adoptive_menu_surveys_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9497 (class 2606 OID 505274)
-- Name: adoptive_menu_surveys adoptive_menu_surveys_survey_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_surveys
    ADD CONSTRAINT adoptive_menu_surveys_survey_id_fkey FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9498 (class 2606 OID 505300)
-- Name: adoptive_menu_trunk_actions adoptive_menu_trunk_actions_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_trunk_actions
    ADD CONSTRAINT adoptive_menu_trunk_actions_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.trunk_call_details(id) ON UPDATE CASCADE;


--
-- TOC entry 9499 (class 2606 OID 508650)
-- Name: adoptive_menu_trunk_actions adoptive_menu_trunk_actions_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_trunk_actions
    ADD CONSTRAINT adoptive_menu_trunk_actions_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9500 (class 2606 OID 505324)
-- Name: adoptive_menu_validation_apis adoptive_menu_validation_apis_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_validation_apis
    ADD CONSTRAINT adoptive_menu_validation_apis_fk1 FOREIGN KEY (adoptive_menu_id) REFERENCES public.adoptive_menu(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9501 (class 2606 OID 505329)
-- Name: adoptive_menu_validation_apis adoptive_menu_validation_apis_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_validation_apis
    ADD CONSTRAINT adoptive_menu_validation_apis_fk2 FOREIGN KEY (action_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9432 (class 2606 OID 502840)
-- Name: campaign_livestocks advisory_livestock_id_pkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_livestocks
    ADD CONSTRAINT advisory_livestock_id_pkey FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE;


--
-- TOC entry 9433 (class 2606 OID 502845)
-- Name: campaign_livestocks advisory_pkey_livestock; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_livestocks
    ADD CONSTRAINT advisory_pkey_livestock FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE;


--
-- TOC entry 9434 (class 2606 OID 502864)
-- Name: campaign_locations advisory_pkey_location; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_locations
    ADD CONSTRAINT advisory_pkey_location FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9405 (class 2606 OID 324433)
-- Name: business_tags b_tags; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_tags
    ADD CONSTRAINT b_tags FOREIGN KEY (tag_id) REFERENCES public.agri_businesess_tags(id) ON DELETE RESTRICT;


--
-- TOC entry 9402 (class 2606 OID 324418)
-- Name: business_contact_person business_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_contact_person
    ADD CONSTRAINT business_id FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE RESTRICT;


--
-- TOC entry 9404 (class 2606 OID 324428)
-- Name: business_media_files business_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_media_files
    ADD CONSTRAINT business_id FOREIGN KEY (business_id) REFERENCES public.business(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9406 (class 2606 OID 324438)
-- Name: business_tags business_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_tags
    ADD CONSTRAINT business_id FOREIGN KEY (business_id) REFERENCES public.business(id);


--
-- TOC entry 9426 (class 2606 OID 502772)
-- Name: campaign_file_name_apis campaign_file_name_apis_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_file_name_apis
    ADD CONSTRAINT campaign_file_name_apis_fk1 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9427 (class 2606 OID 502777)
-- Name: campaign_file_name_apis campaign_file_name_apis_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_file_name_apis
    ADD CONSTRAINT campaign_file_name_apis_fk2 FOREIGN KEY (action_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9428 (class 2606 OID 509316)
-- Name: campaign_files campaign_files_content_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_files
    ADD CONSTRAINT campaign_files_content_file_id_fkey FOREIGN KEY (content_file_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9429 (class 2606 OID 502797)
-- Name: campaign_files campaign_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_files
    ADD CONSTRAINT campaign_foreign_key FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9436 (class 2606 OID 509356)
-- Name: campaign_machineries campaign_machineries_machinery_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_machineries
    ADD CONSTRAINT campaign_machineries_machinery_id_fkey FOREIGN KEY (machinery_id) REFERENCES public.machineries(id) ON UPDATE CASCADE;


--
-- TOC entry 9441 (class 2606 OID 502960)
-- Name: campaign_recording_end_files campaign_recording_end_files_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_recording_end_files
    ADD CONSTRAINT campaign_recording_end_files_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9442 (class 2606 OID 502965)
-- Name: campaign_recording_end_files campaign_recording_end_files_content_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_recording_end_files
    ADD CONSTRAINT campaign_recording_end_files_content_file_id_fkey FOREIGN KEY (content_file_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9414 (class 2606 OID 374742)
-- Name: campaigns campaign_type_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaign_type_foreign_key FOREIGN KEY (campaign_type_id) REFERENCES public.campaign_types(id) ON UPDATE CASCADE;


--
-- TOC entry 9443 (class 2606 OID 502986)
-- Name: campaign_validation_apis campaign_validation_apis_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_validation_apis
    ADD CONSTRAINT campaign_validation_apis_fk1 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9444 (class 2606 OID 502991)
-- Name: campaign_validation_apis campaign_validation_apis_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_validation_apis
    ADD CONSTRAINT campaign_validation_apis_fk2 FOREIGN KEY (action_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9415 (class 2606 OID 374747)
-- Name: campaigns campaigns_recording_path_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_recording_path_id_fkey FOREIGN KEY (recording_path_id) REFERENCES public.ivr_paths(id) ON UPDATE CASCADE;


--
-- TOC entry 9440 (class 2606 OID 502927)
-- Name: campaign_profiles campaing_foreign_pkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_profiles
    ADD CONSTRAINT campaing_foreign_pkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE;


--
-- TOC entry 9460 (class 2606 OID 503234)
-- Name: survey_livestocks categroy_id_pkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_livestocks
    ADD CONSTRAINT categroy_id_pkey FOREIGN KEY (category_id) REFERENCES public.livestock_farming_categories(id) ON UPDATE CASCADE;


--
-- TOC entry 9488 (class 2606 OID 505155)
-- Name: adoptive_menu_livestocks categroy_id_pkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_livestocks
    ADD CONSTRAINT categroy_id_pkey FOREIGN KEY (category_id) REFERENCES public.livestock_farming_categories(id) ON UPDATE CASCADE;


--
-- TOC entry 9281 (class 2606 OID 276125)
-- Name: cc_call_logs cc_call_logs_copy2_paidwall_id_fkey_20231012; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cc_call_logs
    ADD CONSTRAINT cc_call_logs_copy2_paidwall_id_fkey_20231012 FOREIGN KEY (paidwall_id) REFERENCES public.paidwalls(id) ON UPDATE CASCADE;


--
-- TOC entry 9403 (class 2606 OID 324423)
-- Name: business_contact_person contact_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_contact_person
    ADD CONSTRAINT contact_id FOREIGN KEY (contact_person_id) REFERENCES public.contact_person(id) ON DELETE RESTRICT;


--
-- TOC entry 9283 (class 2606 OID 503002)
-- Name: content_files content_files_folder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.content_folders(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9284 (class 2606 OID 503007)
-- Name: content_files content_files_folder_path_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_folder_path_fkey FOREIGN KEY (folder_path) REFERENCES public.content_folders(folder_path) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9416 (class 2606 OID 374752)
-- Name: campaigns content_id_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT content_id_foreign_key FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9285 (class 2606 OID 276150)
-- Name: crop_calender crop_calender_crops_crop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender
    ADD CONSTRAINT crop_calender_crops_crop_id_fkey FOREIGN KEY (id) REFERENCES public.crops(id) ON UPDATE CASCADE;


--
-- TOC entry 9288 (class 2606 OID 276155)
-- Name: crop_calender_crops crop_calender_crops_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_crops
    ADD CONSTRAINT crop_calender_crops_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE;


--
-- TOC entry 9286 (class 2606 OID 276160)
-- Name: crop_calender crop_calender_land_topography_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender
    ADD CONSTRAINT crop_calender_land_topography_id_fkey FOREIGN KEY (land_topography_id) REFERENCES public.land_topography(id) ON UPDATE CASCADE;


--
-- TOC entry 9289 (class 2606 OID 276165)
-- Name: crop_calender_locations crop_calender_locations_crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_locations
    ADD CONSTRAINT crop_calender_locations_crop_calender_id_fkey FOREIGN KEY (crop_calender_id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE;


--
-- TOC entry 9287 (class 2606 OID 276170)
-- Name: crop_calender crop_calender_sowing_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender
    ADD CONSTRAINT crop_calender_sowing_method_id_fkey FOREIGN KEY (sowing_method_id) REFERENCES public.sowing_methods(id) ON UPDATE CASCADE;


--
-- TOC entry 9290 (class 2606 OID 276175)
-- Name: crop_calender_weather_unfavourable_conditions crop_calender_weather_unfavourable_condit_crop_calender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crop_calender_weather_unfavourable_conditions
    ADD CONSTRAINT crop_calender_weather_unfavourable_condit_crop_calender_id_fkey FOREIGN KEY (id) REFERENCES public.crop_calender(id) ON UPDATE CASCADE;


--
-- TOC entry 9408 (class 2606 OID 324233)
-- Name: crops_2023_07_26 crops_copy1_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops_2023_07_26
    ADD CONSTRAINT crops_copy1_content_id_fkey FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9525 (class 2606 OID 619699)
-- Name: endpoints_permissions endpoints_permissions_endpoint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.endpoints_permissions
    ADD CONSTRAINT endpoints_permissions_endpoint_id_fkey FOREIGN KEY (endpoint_id) REFERENCES public.endpoints(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9526 (class 2606 OID 619694)
-- Name: endpoints_permissions endpoints_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.endpoints_permissions
    ADD CONSTRAINT endpoints_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9531 (class 2606 OID 663213)
-- Name: farm_crop_growth_stage_anomalies farm_crop_growth_stage_anomalies_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crop_growth_stage_anomalies
    ADD CONSTRAINT farm_crop_growth_stage_anomalies_fk1 FOREIGN KEY (farm_crop_growth_stage_id) REFERENCES public.farm_crop_growth_stages(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9532 (class 2606 OID 663218)
-- Name: farm_crop_growth_stage_anomalies farm_crop_growth_stage_anomalies_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crop_growth_stage_anomalies
    ADD CONSTRAINT farm_crop_growth_stage_anomalies_fk2 FOREIGN KEY (anomaly_id) REFERENCES public.anomalies(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9420 (class 2606 OID 390571)
-- Name: farm_crops_seed_types farm_crops_seed_types_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crops_seed_types
    ADD CONSTRAINT farm_crops_seed_types_fk1 FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9421 (class 2606 OID 519354)
-- Name: farm_crops_seed_types farm_crops_seed_types_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crops_seed_types
    ADD CONSTRAINT farm_crops_seed_types_fk2 FOREIGN KEY (farm_crop_id) REFERENCES public.farmcrops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9422 (class 2606 OID 390576)
-- Name: farm_crops_seed_types farm_crops_seed_types_fk3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crops_seed_types
    ADD CONSTRAINT farm_crops_seed_types_fk3 FOREIGN KEY (seed_type_id, crop_id) REFERENCES public.seed_types(id, crop_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9505 (class 2606 OID 519321)
-- Name: farmcrops farmcrops_farm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmcrops
    ADD CONSTRAINT farmcrops_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9409 (class 2606 OID 324238)
-- Name: farmer_interest farmerId; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_interest
    ADD CONSTRAINT "farmerId" FOREIGN KEY (farmer_id) REFERENCES public.farmers(id) ON UPDATE CASCADE;


--
-- TOC entry 9509 (class 2606 OID 519711)
-- Name: community_blacklist farmer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_blacklist
    ADD CONSTRAINT farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES public.farmers(id);


--
-- TOC entry 9298 (class 2606 OID 276180)
-- Name: farmer_livestocks farmer_livestocks_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestocks
    ADD CONSTRAINT farmer_livestocks_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.livestock_farming_categories(id) ON UPDATE CASCADE;


--
-- TOC entry 9307 (class 2606 OID 276185)
-- Name: farmers_testing farmers_copy1_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_testing
    ADD CONSTRAINT farmers_copy1_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE;


--
-- TOC entry 9308 (class 2606 OID 276195)
-- Name: farmers_testing farmers_copy1_occupation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_testing
    ADD CONSTRAINT farmers_copy1_occupation_id_fkey FOREIGN KEY (occupation_id) REFERENCES public.occupations(id) ON UPDATE CASCADE;


--
-- TOC entry 9309 (class 2606 OID 276200)
-- Name: farmers_testing farmers_copy1_profile_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers_testing
    ADD CONSTRAINT farmers_copy1_profile_level_id_fkey FOREIGN KEY (profile_level_id) REFERENCES public.profile_levels(id);


--
-- TOC entry 9511 (class 2606 OID 579420)
-- Name: fav_crops fav_crops_crop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fav_crops
    ADD CONSTRAINT fav_crops_crop_id_fkey FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON DELETE CASCADE;


--
-- TOC entry 9512 (class 2606 OID 579415)
-- Name: fav_crops fav_crops_farmer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fav_crops
    ADD CONSTRAINT fav_crops_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES public.farmers(id) ON DELETE CASCADE;


--
-- TOC entry 9506 (class 2606 OID 519326)
-- Name: farmcrops fk_crop_season; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmcrops
    ADD CONSTRAINT fk_crop_season FOREIGN KEY (crop_season_id) REFERENCES public.crop_season(id);


--
-- TOC entry 9438 (class 2606 OID 502903)
-- Name: campaign_operator fk_operators; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_operator
    ADD CONSTRAINT fk_operators FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9467 (class 2606 OID 503298)
-- Name: survey_operator fk_operators; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_operator
    ADD CONSTRAINT fk_operators FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE;


--
-- TOC entry 9468 (class 2606 OID 503303)
-- Name: survey_operator fk_operators_survey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_operator
    ADD CONSTRAINT fk_operators_survey FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9530 (class 2606 OID 649289)
-- Name: qrp_case_products fk_qrp_case; Type: FK CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.qrp_case_products
    ADD CONSTRAINT fk_qrp_case FOREIGN KEY (qrp_case_id) REFERENCES public.qrp_cases(id);


--
-- TOC entry 9533 (class 2606 OID 666251)
-- Name: webview_users fk_webview_users_msisdn; Type: FK CONSTRAINT; Schema: public; Owner: rameez_dev_rw
--

ALTER TABLE ONLY public.webview_users
    ADD CONSTRAINT fk_webview_users_msisdn FOREIGN KEY (msisdn) REFERENCES public.farmers(id);


--
-- TOC entry 9479 (class 2606 OID 505038)
-- Name: adoptive_menu_crops foreign_menu_pkey_growth_stages; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_crops
    ADD CONSTRAINT foreign_menu_pkey_growth_stages FOREIGN KEY (stage_id) REFERENCES public.growth_stages(id) ON UPDATE CASCADE;


--
-- TOC entry 9423 (class 2606 OID 502742)
-- Name: campaign_crops foreign_pkey_growth_stages; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_crops
    ADD CONSTRAINT foreign_pkey_growth_stages FOREIGN KEY (stage_id) REFERENCES public.growth_stages(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9445 (class 2606 OID 503054)
-- Name: survey_crops foreign_survey_pkey_growth_stages; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_crops
    ADD CONSTRAINT foreign_survey_pkey_growth_stages FOREIGN KEY (stage_id) REFERENCES public.growth_stages(id) ON UPDATE CASCADE;


--
-- TOC entry 9411 (class 2606 OID 324248)
-- Name: forum_posts_rejected_copy1 forum_posts_rejected_copy1_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_rejected_copy1
    ADD CONSTRAINT forum_posts_rejected_copy1_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.forum_posts_rejected(id) ON UPDATE CASCADE;


--
-- TOC entry 9315 (class 2606 OID 538175)
-- Name: forum_posts_rejected forum_posts_rejected_reason_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_rejected
    ADD CONSTRAINT forum_posts_rejected_reason_id_fk FOREIGN KEY (reason_id) REFERENCES public.forum_post_rejection_reasons(id);


--
-- TOC entry 9524 (class 2606 OID 617279)
-- Name: forum_posts_views_shares forum_posts_views_shares_forum_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_views_shares
    ADD CONSTRAINT forum_posts_views_shares_forum_post_id_fkey FOREIGN KEY (forum_post_id) REFERENCES public.forum_posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9410 (class 2606 OID 324243)
-- Name: farmer_interest interestId; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_interest
    ADD CONSTRAINT "interestId" FOREIGN KEY (interest_id) REFERENCES public.interests(id) ON UPDATE CASCADE;


--
-- TOC entry 9399 (class 2606 OID 324770)
-- Name: job_executor_stats job_executor_stats_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_executor_stats
    ADD CONSTRAINT job_executor_stats_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON UPDATE CASCADE;


--
-- TOC entry 9396 (class 2606 OID 324578)
-- Name: job_state_flow job_state_flow_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_state_flow
    ADD CONSTRAINT job_state_flow_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.job_statuses(id) ON UPDATE CASCADE;


--
-- TOC entry 9398 (class 2606 OID 308477)
-- Name: job_testing_msisdns job_testing_msisdns_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_testing_msisdns
    ADD CONSTRAINT job_testing_msisdns_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE RESTRICT;


--
-- TOC entry 9321 (class 2606 OID 324588)
-- Name: jobs jobs_v2_job_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_v2_job_status_id_fkey FOREIGN KEY (job_status_id) REFERENCES public.job_statuses(id) ON UPDATE CASCADE;


--
-- TOC entry 9322 (class 2606 OID 324593)
-- Name: jobs jobs_v2_job_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_v2_job_type_id_fkey FOREIGN KEY (job_type_id) REFERENCES public.job_types(id) ON UPDATE CASCADE;


--
-- TOC entry 9270 (class 2606 OID 324762)
-- Name: agent_roles key_agent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_roles
    ADD CONSTRAINT key_agent_id FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9318 (class 2606 OID 324533)
-- Name: ivr_activities key_api_call_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_activities
    ADD CONSTRAINT key_api_call_id FOREIGN KEY (api_call_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9274 (class 2606 OID 276235)
-- Name: loan_agreements key_application_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_agreements
    ADD CONSTRAINT key_application_id FOREIGN KEY (application_id) REFERENCES public.loan_applications(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9299 (class 2606 OID 276240)
-- Name: farmer_livestocks key_breed_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestocks
    ADD CONSTRAINT key_breed_id FOREIGN KEY (breed_id) REFERENCES public.livestock_breeds(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9424 (class 2606 OID 502747)
-- Name: campaign_crops key_campaign_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_crops
    ADD CONSTRAINT key_campaign_id FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9439 (class 2606 OID 502908)
-- Name: campaign_operator key_campaign_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_operator
    ADD CONSTRAINT key_campaign_id FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9277 (class 2606 OID 276265)
-- Name: case_media_contents key_case_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_media_contents
    ADD CONSTRAINT key_case_id FOREIGN KEY (case_id) REFERENCES public.cases(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9278 (class 2606 OID 276270)
-- Name: case_parameters key_case_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_parameters
    ADD CONSTRAINT key_case_id FOREIGN KEY (case_id) REFERENCES public.cases(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9279 (class 2606 OID 276275)
-- Name: case_tags key_case_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_tags
    ADD CONSTRAINT key_case_id FOREIGN KEY (case_id) REFERENCES public.cases(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9347 (class 2606 OID 276280)
-- Name: mandi_listings key_category_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_listings
    ADD CONSTRAINT key_category_id FOREIGN KEY (category_id) REFERENCES public.mandi_categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9323 (class 2606 OID 276285)
-- Name: land_topography key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.land_topography
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9324 (class 2606 OID 276290)
-- Name: languages key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9325 (class 2606 OID 276295)
-- Name: livestock_breeds key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_breeds
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9327 (class 2606 OID 276300)
-- Name: livestock_disease key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_disease
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9329 (class 2606 OID 276305)
-- Name: livestock_farming_categories key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farming_categories
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9330 (class 2606 OID 276310)
-- Name: livestock_management key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_management
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9331 (class 2606 OID 276315)
-- Name: livestock_nutrition key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_nutrition
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9332 (class 2606 OID 276320)
-- Name: livestock_purpose key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_purpose
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9333 (class 2606 OID 276325)
-- Name: livestock_stage key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_stage
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9335 (class 2606 OID 276330)
-- Name: livestocks key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestocks
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9343 (class 2606 OID 276335)
-- Name: machineries key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machineries
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9345 (class 2606 OID 276340)
-- Name: machinery_types key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machinery_types
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9356 (class 2606 OID 276345)
-- Name: nutrient_deficiency key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nutrient_deficiency
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9357 (class 2606 OID 276350)
-- Name: occupations key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.occupations
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9362 (class 2606 OID 276355)
-- Name: seed_types key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seed_types
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9364 (class 2606 OID 276360)
-- Name: soil_issues key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_issues
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9365 (class 2606 OID 276365)
-- Name: soil_types key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soil_types
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9366 (class 2606 OID 276370)
-- Name: sowing_methods key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sowing_methods
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9383 (class 2606 OID 276375)
-- Name: trunk_recording_timings key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trunk_recording_timings
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9393 (class 2606 OID 276380)
-- Name: weeds key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weeds
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9292 (class 2606 OID 276385)
-- Name: crops key_content_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.crops
    ADD CONSTRAINT key_content_id FOREIGN KEY (content_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9350 (class 2606 OID 276390)
-- Name: mp_crop_diseases key_crop_disease_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mp_crop_diseases
    ADD CONSTRAINT key_crop_disease_id FOREIGN KEY (crop_disease_id) REFERENCES public.crop_diseases(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9351 (class 2606 OID 276395)
-- Name: mp_crop_diseases key_crop_growth_stage_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mp_crop_diseases
    ADD CONSTRAINT key_crop_growth_stage_id FOREIGN KEY (crop_growth_stage_id) REFERENCES public.growth_stages(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9336 (class 2606 OID 276405)
-- Name: location_crops key_crop_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_crops
    ADD CONSTRAINT key_crop_id FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9352 (class 2606 OID 276410)
-- Name: mp_crop_diseases key_crop_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mp_crop_diseases
    ADD CONSTRAINT key_crop_id FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9363 (class 2606 OID 276415)
-- Name: seed_types key_crop_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seed_types
    ADD CONSTRAINT key_crop_id FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9425 (class 2606 OID 502752)
-- Name: campaign_crops key_crop_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_crops
    ADD CONSTRAINT key_crop_id FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9446 (class 2606 OID 503059)
-- Name: survey_crops key_crop_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_crops
    ADD CONSTRAINT key_crop_id FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON UPDATE CASCADE;


--
-- TOC entry 9507 (class 2606 OID 519331)
-- Name: farmcrops key_crop_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmcrops
    ADD CONSTRAINT key_crop_id FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9381 (class 2606 OID 276430)
-- Name: tehsils key_district_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tehsils
    ADD CONSTRAINT key_district_id FOREIGN KEY (district_id) REFERENCES public.districts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9319 (class 2606 OID 324538)
-- Name: ivr_activities key_event_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_activities
    ADD CONSTRAINT key_event_id FOREIGN KEY (event_id) REFERENCES public.event_types(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9294 (class 2606 OID 519349)
-- Name: farm_crop_growth_stages key_farm_crop_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crop_growth_stages
    ADD CONSTRAINT key_farm_crop_id FOREIGN KEY (farm_crop_id) REFERENCES public.farmcrops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9360 (class 2606 OID 276440)
-- Name: questionair_response key_farmer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questionair_response
    ADD CONSTRAINT key_farmer_id FOREIGN KEY (farmer_id) REFERENCES public.farmers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9310 (class 2606 OID 877710)
-- Name: farms key_farms_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT key_farms_location_id FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9295 (class 2606 OID 330591)
-- Name: farm_crop_growth_stages key_growth_stage_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farm_crop_growth_stages
    ADD CONSTRAINT key_growth_stage_id FOREIGN KEY (growth_stage_id) REFERENCES public.growth_stages(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9317 (class 2606 OID 276455)
-- Name: incentive_transactions key_incentive_type_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incentive_transactions
    ADD CONSTRAINT key_incentive_type_id FOREIGN KEY (incentive_type_id) REFERENCES public.incentive_types(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9311 (class 2606 OID 324508)
-- Name: farms key_irrigation_source_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT key_irrigation_source_id FOREIGN KEY (irrigation_source_id) REFERENCES public.irrigation_sources(id) ON UPDATE CASCADE;


--
-- TOC entry 9394 (class 2606 OID 324785)
-- Name: job_operators key_job_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_operators
    ADD CONSTRAINT key_job_id FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9400 (class 2606 OID 316830)
-- Name: job_executor_stats key_job_type_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_executor_stats
    ADD CONSTRAINT key_job_type_id FOREIGN KEY (job_type_id) REFERENCES public.job_types(id) ON UPDATE CASCADE;


--
-- TOC entry 9312 (class 2606 OID 324513)
-- Name: farms key_land_topography_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT key_land_topography_id FOREIGN KEY (land_topography_id) REFERENCES public.land_topography(id) ON UPDATE CASCADE;


--
-- TOC entry 9367 (class 2606 OID 276470)
-- Name: subscribers key_language_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers
    ADD CONSTRAINT key_language_id FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE;


--
-- TOC entry 9386 (class 2606 OID 276480)
-- Name: unsubscribers key_language_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unsubscribers
    ADD CONSTRAINT key_language_id FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE;


--
-- TOC entry 9304 (class 2606 OID 324493)
-- Name: farmers key_language_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers
    ADD CONSTRAINT key_language_id FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE;


--
-- TOC entry 9348 (class 2606 OID 276485)
-- Name: mandi_listings_meta_data key_listing_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_listings_meta_data
    ADD CONSTRAINT key_listing_id FOREIGN KEY (listing_id) REFERENCES public.mandi_listings(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9349 (class 2606 OID 276490)
-- Name: mandi_reviews key_listing_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_reviews
    ADD CONSTRAINT key_listing_id FOREIGN KEY (listing_id) REFERENCES public.mandi_listings(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9326 (class 2606 OID 276495)
-- Name: livestock_breeds key_livestock_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_breeds
    ADD CONSTRAINT key_livestock_id FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9328 (class 2606 OID 276500)
-- Name: livestock_disease key_livestock_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_disease
    ADD CONSTRAINT key_livestock_id FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9334 (class 2606 OID 276505)
-- Name: livestock_stage key_livestock_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_stage
    ADD CONSTRAINT key_livestock_id FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9353 (class 2606 OID 276510)
-- Name: mp_livestock_farming_categories key_livestock_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mp_livestock_farming_categories
    ADD CONSTRAINT key_livestock_id FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9300 (class 2606 OID 276515)
-- Name: farmer_livestocks key_livestock_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestocks
    ADD CONSTRAINT key_livestock_id FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9296 (class 2606 OID 324757)
-- Name: farmer_livestock_tags key_livestock_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestock_tags
    ADD CONSTRAINT key_livestock_id FOREIGN KEY (livestock_id) REFERENCES public.farmer_livestocks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9282 (class 2606 OID 276520)
-- Name: clauses key_loan_agreement_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clauses
    ADD CONSTRAINT key_loan_agreement_id FOREIGN KEY (loan_agreement_id) REFERENCES public.loan_agreements(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9337 (class 2606 OID 877715)
-- Name: location_crops key_location_crops_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_crops
    ADD CONSTRAINT key_location_crops_location_id FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9368 (class 2606 OID 276525)
-- Name: subscribers key_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers
    ADD CONSTRAINT key_location_id FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9340 (class 2606 OID 276540)
-- Name: location_machineries key_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_machineries
    ADD CONSTRAINT key_location_id FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9354 (class 2606 OID 276545)
-- Name: neighbouring_tehsils key_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.neighbouring_tehsils
    ADD CONSTRAINT key_location_id FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9387 (class 2606 OID 276550)
-- Name: unsubscribers key_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unsubscribers
    ADD CONSTRAINT key_location_id FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9305 (class 2606 OID 877705)
-- Name: farmers key_location_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers
    ADD CONSTRAINT key_location_id FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9341 (class 2606 OID 276555)
-- Name: location_machineries key_machinery_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_machineries
    ADD CONSTRAINT key_machinery_id FOREIGN KEY (machinery_id) REFERENCES public.machineries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9303 (class 2606 OID 276560)
-- Name: farmer_machineries key_machinery_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_machineries
    ADD CONSTRAINT key_machinery_id FOREIGN KEY (machinery_id) REFERENCES public.machineries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9355 (class 2606 OID 276565)
-- Name: notifications key_notification_mode_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT key_notification_mode_id FOREIGN KEY (notification_mode_id) REFERENCES public.notification_modes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9306 (class 2606 OID 324503)
-- Name: farmers key_occupation_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmers
    ADD CONSTRAINT key_occupation_id FOREIGN KEY (occupation_id) REFERENCES public.occupations(id) ON UPDATE CASCADE;


--
-- TOC entry 9369 (class 2606 OID 276575)
-- Name: subscribers key_operator_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers
    ADD CONSTRAINT key_operator_id FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE;


--
-- TOC entry 9388 (class 2606 OID 276585)
-- Name: unsubscribers key_operator_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unsubscribers
    ADD CONSTRAINT key_operator_id FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE;


--
-- TOC entry 9395 (class 2606 OID 308202)
-- Name: job_operators key_operator_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_operators
    ADD CONSTRAINT key_operator_id FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9418 (class 2606 OID 387476)
-- Name: surveys key_operator_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.surveys
    ADD CONSTRAINT key_operator_id FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9276 (class 2606 OID 276595)
-- Name: case_categories key_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_categories
    ADD CONSTRAINT key_parent_id FOREIGN KEY (parent_id) REFERENCES public.case_categories(id) ON UPDATE CASCADE;


--
-- TOC entry 9291 (class 2606 OID 276605)
-- Name: growth_stages key_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.growth_stages
    ADD CONSTRAINT key_parent_id FOREIGN KEY (parent_id) REFERENCES public.growth_stages(id) ON UPDATE CASCADE;


--
-- TOC entry 9346 (class 2606 OID 276610)
-- Name: mandi_categories key_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mandi_categories
    ADD CONSTRAINT key_parent_id FOREIGN KEY (parent_id) REFERENCES public.mandi_categories(id) ON UPDATE CASCADE;


--
-- TOC entry 9316 (class 2606 OID 276615)
-- Name: forum_posts_rejected key_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forum_posts_rejected
    ADD CONSTRAINT key_parent_id FOREIGN KEY (parent_id) REFERENCES public.forum_posts_rejected(id) ON UPDATE CASCADE;


--
-- TOC entry 9397 (class 2606 OID 324583)
-- Name: job_state_flow key_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_state_flow
    ADD CONSTRAINT key_parent_id FOREIGN KEY (parent_id) REFERENCES public.job_statuses(id) ON UPDATE CASCADE;


--
-- TOC entry 9342 (class 2606 OID 1043700)
-- Name: locations key_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT key_parent_id FOREIGN KEY (parent_id) REFERENCES public.locations(id);


--
-- TOC entry 9272 (class 2606 OID 276630)
-- Name: api_resource_permissions key_permisions_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resource_permissions
    ADD CONSTRAINT key_permisions_id FOREIGN KEY (permission_id) REFERENCES public.api_permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9293 (class 2606 OID 276640)
-- Name: districts key_province_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT key_province_id FOREIGN KEY (province_id) REFERENCES public.provinces(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9301 (class 2606 OID 276645)
-- Name: farmer_livestocks key_purpose_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestocks
    ADD CONSTRAINT key_purpose_id FOREIGN KEY (purpose_id) REFERENCES public.livestock_purpose(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9361 (class 2606 OID 276650)
-- Name: questionair_response key_question_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questionair_response
    ADD CONSTRAINT key_question_id FOREIGN KEY (question_id) REFERENCES public.questionair(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9384 (class 2606 OID 276655)
-- Name: trunk_recording_timings key_recording_path_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trunk_recording_timings
    ADD CONSTRAINT key_recording_path_id FOREIGN KEY (recording_path_id) REFERENCES public.ivr_paths(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9273 (class 2606 OID 276660)
-- Name: api_resource_permissions key_resource_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_resource_permissions
    ADD CONSTRAINT key_resource_id FOREIGN KEY (resource_id) REFERENCES public.api_resources(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9271 (class 2606 OID 276665)
-- Name: agent_roles key_roles_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_roles
    ADD CONSTRAINT key_roles_id FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9392 (class 2606 OID 276675)
-- Name: weather_raw key_site_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_raw
    ADD CONSTRAINT key_site_id FOREIGN KEY (site_id) REFERENCES public.sites(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9313 (class 2606 OID 324523)
-- Name: farms key_soil_issue_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT key_soil_issue_id FOREIGN KEY (soil_issue_id) REFERENCES public.soil_issues(id) ON UPDATE CASCADE;


--
-- TOC entry 9314 (class 2606 OID 324528)
-- Name: farms key_soil_type_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT key_soil_type_id FOREIGN KEY (soil_type_id) REFERENCES public.soil_types(id) ON UPDATE CASCADE;


--
-- TOC entry 9508 (class 2606 OID 519336)
-- Name: farmcrops key_sowing_method_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmcrops
    ADD CONSTRAINT key_sowing_method_id FOREIGN KEY (sowing_method_id) REFERENCES public.sowing_methods(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9302 (class 2606 OID 276695)
-- Name: farmer_livestocks key_stage_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestocks
    ADD CONSTRAINT key_stage_id FOREIGN KEY (stage_id) REFERENCES public.livestock_stage(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9280 (class 2606 OID 276720)
-- Name: case_tags key_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_tags
    ADD CONSTRAINT key_tag_id FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9297 (class 2606 OID 276725)
-- Name: farmer_livestock_tags key_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.farmer_livestock_tags
    ADD CONSTRAINT key_tag_id FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9320 (class 2606 OID 324543)
-- Name: ivr_activities key_trunk_call_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ivr_activities
    ADD CONSTRAINT key_trunk_call_id FOREIGN KEY (trunk_call_id) REFERENCES public.trunk_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9275 (class 2606 OID 276730)
-- Name: loan_agreements key_type_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loan_agreements
    ADD CONSTRAINT key_type_id FOREIGN KEY (type_id) REFERENCES public.loan_types(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9518 (class 2606 OID 598290)
-- Name: livestock_farm_livestocks livestock_farm_livestock_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farm_livestocks
    ADD CONSTRAINT livestock_farm_livestock_fk1 FOREIGN KEY (category_id) REFERENCES public.livestock_farming_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9519 (class 2606 OID 598295)
-- Name: livestock_farm_livestocks livestock_farm_livestocks_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farm_livestocks
    ADD CONSTRAINT livestock_farm_livestocks_fk2 FOREIGN KEY (breed_id) REFERENCES public.livestock_breeds(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9520 (class 2606 OID 598300)
-- Name: livestock_farm_livestocks livestock_farm_livestocks_fk3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farm_livestocks
    ADD CONSTRAINT livestock_farm_livestocks_fk3 FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9521 (class 2606 OID 598305)
-- Name: livestock_farm_livestocks livestock_farm_livestocks_fk4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farm_livestocks
    ADD CONSTRAINT livestock_farm_livestocks_fk4 FOREIGN KEY (purpose_id) REFERENCES public.livestock_purpose(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9522 (class 2606 OID 598310)
-- Name: livestock_farm_livestocks livestock_farm_livestocks_fk5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farm_livestocks
    ADD CONSTRAINT livestock_farm_livestocks_fk5 FOREIGN KEY (stage_id) REFERENCES public.livestock_stage(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9523 (class 2606 OID 598315)
-- Name: livestock_farm_livestocks livestock_farm_livestocks_fk6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farm_livestocks
    ADD CONSTRAINT livestock_farm_livestocks_fk6 FOREIGN KEY (livestock_farm_id) REFERENCES public.livestock_farms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9516 (class 2606 OID 598264)
-- Name: livestock_farms livestock_farms_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farms
    ADD CONSTRAINT livestock_farms_fk1 FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9517 (class 2606 OID 598269)
-- Name: livestock_farms livestock_farms_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livestock_farms
    ADD CONSTRAINT livestock_farms_fk2 FOREIGN KEY (farmer_id) REFERENCES public.farmers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9338 (class 2606 OID 276740)
-- Name: location_livestocks location_livestocks_livestock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_livestocks
    ADD CONSTRAINT location_livestocks_livestock_id_fkey FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE;


--
-- TOC entry 9339 (class 2606 OID 276745)
-- Name: location_livestocks location_livestocks_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_livestocks
    ADD CONSTRAINT location_livestocks_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9534 (class 2606 OID 875355)
-- Name: locations_copy1 locations_copy1_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations_copy1
    ADD CONSTRAINT locations_copy1_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9435 (class 2606 OID 502869)
-- Name: campaign_locations locations_pkey_advisory; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_locations
    ADD CONSTRAINT locations_pkey_advisory FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9463 (class 2606 OID 503261)
-- Name: survey_locations locations_pkey_survey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_locations
    ADD CONSTRAINT locations_pkey_survey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9344 (class 2606 OID 276760)
-- Name: machineries machinery_type_id_key; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machineries
    ADD CONSTRAINT machinery_type_id_key FOREIGN KEY (machinery_type_id) REFERENCES public.machinery_types(id) ON UPDATE CASCADE;


--
-- TOC entry 9489 (class 2606 OID 505160)
-- Name: adoptive_menu_livestocks menu_livestock_id_pkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_livestocks
    ADD CONSTRAINT menu_livestock_id_pkey FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE;


--
-- TOC entry 9401 (class 2606 OID 324413)
-- Name: business_categories parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_categories
    ADD CONSTRAINT parent_id FOREIGN KEY (parent_id) REFERENCES public.business_categories(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 9359 (class 2606 OID 276785)
-- Name: partners_msisdn partner_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partners_msisdn
    ADD CONSTRAINT partner_id FOREIGN KEY (partner_id) REFERENCES public.partners(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 9358 (class 2606 OID 324790)
-- Name: partner_services partner_services_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_services
    ADD CONSTRAINT partner_services_service_id_fkey FOREIGN KEY (id) REFERENCES public.services(id) ON UPDATE CASCADE;


--
-- TOC entry 9412 (class 2606 OID 324795)
-- Name: roles_permissions permission_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permissions
    ADD CONSTRAINT permission_id FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9513 (class 2606 OID 583720)
-- Name: pin_crops pin_crops_farmer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pin_crops
    ADD CONSTRAINT pin_crops_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES public.farmers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9514 (class 2606 OID 583741)
-- Name: pin_farms pin_farms_farm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pin_farms
    ADD CONSTRAINT pin_farms_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9515 (class 2606 OID 583736)
-- Name: pin_farms pin_farms_pin_crop_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pin_farms
    ADD CONSTRAINT pin_farms_pin_crop_id_fkey FOREIGN KEY (pin_crop_id) REFERENCES public.pin_crops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9430 (class 2606 OID 502816)
-- Name: campaign_languages pkey_advisory_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_languages
    ADD CONSTRAINT pkey_advisory_id FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9437 (class 2606 OID 502888)
-- Name: campaign_machineries pkey_advisory_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_machineries
    ADD CONSTRAINT pkey_advisory_id FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON UPDATE CASCADE;


--
-- TOC entry 9480 (class 2606 OID 505043)
-- Name: adoptive_menu_crops pkey_crop_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_crops
    ADD CONSTRAINT pkey_crop_id FOREIGN KEY (crop_id) REFERENCES public.crops(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9431 (class 2606 OID 502821)
-- Name: campaign_languages pkey_language_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaign_languages
    ADD CONSTRAINT pkey_language_id FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9458 (class 2606 OID 503211)
-- Name: survey_languages pkey_language_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_languages
    ADD CONSTRAINT pkey_language_id FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE;


--
-- TOC entry 9486 (class 2606 OID 505132)
-- Name: adoptive_menu_languages pkey_language_menu_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.adoptive_menu_languages
    ADD CONSTRAINT pkey_language_menu_id FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE;


--
-- TOC entry 9459 (class 2606 OID 503216)
-- Name: survey_languages pkey_survey_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_languages
    ADD CONSTRAINT pkey_survey_id FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9465 (class 2606 OID 503283)
-- Name: survey_machineries pkey_survey_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_machineries
    ADD CONSTRAINT pkey_survey_id FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9447 (class 2606 OID 503064)
-- Name: survey_crops pkey_survey_relation_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_crops
    ADD CONSTRAINT pkey_survey_relation_id FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9528 (class 2606 OID 647763)
-- Name: post_anomaly post_anomaly_anomaly_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_anomaly
    ADD CONSTRAINT post_anomaly_anomaly_id_fkey FOREIGN KEY (anomaly_id) REFERENCES public.anomaly_response(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9529 (class 2606 OID 647758)
-- Name: post_anomaly post_anomaly_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_anomaly
    ADD CONSTRAINT post_anomaly_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.forum_posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9413 (class 2606 OID 324608)
-- Name: roles_permissions role_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permissions
    ADD CONSTRAINT role_id FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9417 (class 2606 OID 546502)
-- Name: campaigns salutation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT salutation_id_fkey FOREIGN KEY (salutation_id) REFERENCES public.advisory_salutations(id);


--
-- TOC entry 9510 (class 2606 OID 559297)
-- Name: shopify_buyers shopify_buyers_buyer_type_id_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_buyers
    ADD CONSTRAINT shopify_buyers_buyer_type_id_fk1 FOREIGN KEY (buyer_type_id) REFERENCES public.buyer_types(id);


--
-- TOC entry 9527 (class 2606 OID 642095)
-- Name: shopify_visitors_interests shopify_visitors_interests_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_visitors_interests
    ADD CONSTRAINT shopify_visitors_interests_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.shopify_visitors(id) ON DELETE CASCADE;


--
-- TOC entry 9407 (class 2606 OID 324228)
-- Name: business subcategory_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT subcategory_id FOREIGN KEY (subcategory_id) REFERENCES public.business_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9372 (class 2606 OID 276855)
-- Name: subscribers_test subscribers_copy1_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_test
    ADD CONSTRAINT subscribers_copy1_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE;


--
-- TOC entry 9373 (class 2606 OID 276860)
-- Name: subscribers_test subscribers_copy1_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_test
    ADD CONSTRAINT subscribers_copy1_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9374 (class 2606 OID 276865)
-- Name: subscribers_test subscribers_copy1_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_test
    ADD CONSTRAINT subscribers_copy1_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE;


--
-- TOC entry 9375 (class 2606 OID 276870)
-- Name: subscribers_test subscribers_copy1_sub_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_test
    ADD CONSTRAINT subscribers_copy1_sub_mode_id_fkey FOREIGN KEY (sub_mode_id) REFERENCES public.sub_modes(id) ON UPDATE CASCADE;


--
-- TOC entry 9376 (class 2606 OID 276875)
-- Name: subscribers_testt subscribers_copy2_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_testt
    ADD CONSTRAINT subscribers_copy2_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.languages(id) ON UPDATE CASCADE;


--
-- TOC entry 9377 (class 2606 OID 276880)
-- Name: subscribers_testt subscribers_copy2_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_testt
    ADD CONSTRAINT subscribers_copy2_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON UPDATE CASCADE;


--
-- TOC entry 9378 (class 2606 OID 276885)
-- Name: subscribers_testt subscribers_copy2_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_testt
    ADD CONSTRAINT subscribers_copy2_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.operators(id) ON UPDATE CASCADE;


--
-- TOC entry 9379 (class 2606 OID 276890)
-- Name: subscribers_testt subscribers_copy2_sub_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_testt
    ADD CONSTRAINT subscribers_copy2_sub_mode_id_fkey FOREIGN KEY (sub_mode_id) REFERENCES public.sub_modes(id) ON UPDATE CASCADE;


--
-- TOC entry 9370 (class 2606 OID 276895)
-- Name: subscribers_job_logs subscribers_job_logs_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_job_logs
    ADD CONSTRAINT subscribers_job_logs_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON UPDATE CASCADE;


--
-- TOC entry 9371 (class 2606 OID 316865)
-- Name: subscribers_job_logs subscribers_job_logs_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers_job_logs
    ADD CONSTRAINT subscribers_job_logs_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.job_executor_stats(request_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 9380 (class 2606 OID 276900)
-- Name: subscriptions subscriptions_subscription_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_subscription_type_id_fkey FOREIGN KEY (subscription_type_id) REFERENCES public.subscription_types(id) ON UPDATE CASCADE;


--
-- TOC entry 9454 (class 2606 OID 503167)
-- Name: survey_input_files surveeys_file_id_foreing_key; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_files
    ADD CONSTRAINT surveeys_file_id_foreing_key FOREIGN KEY (content_file_id) REFERENCES public.content_files(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9455 (class 2606 OID 503172)
-- Name: survey_input_files surveeys_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_files
    ADD CONSTRAINT surveeys_foreign_key FOREIGN KEY (survey_input_id) REFERENCES public.survey_inputs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9452 (class 2606 OID 503138)
-- Name: survey_input_api_actions survey_api_actions_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_api_actions
    ADD CONSTRAINT survey_api_actions_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9448 (class 2606 OID 503084)
-- Name: survey_file_name_apis survey_file_name_apis_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_file_name_apis
    ADD CONSTRAINT survey_file_name_apis_fk1 FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9449 (class 2606 OID 503089)
-- Name: survey_file_name_apis survey_file_name_apis_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_file_name_apis
    ADD CONSTRAINT survey_file_name_apis_fk2 FOREIGN KEY (action_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9450 (class 2606 OID 503111)
-- Name: survey_files survey_files_content_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_files
    ADD CONSTRAINT survey_files_content_file_id_fkey FOREIGN KEY (content_file_id) REFERENCES public.content_files(id) ON UPDATE CASCADE;


--
-- TOC entry 9451 (class 2606 OID 503116)
-- Name: survey_files survey_files_survey_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_files
    ADD CONSTRAINT survey_files_survey_id_fkey FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9453 (class 2606 OID 509679)
-- Name: survey_input_api_actions survey_input_api_actions_survey_input_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_api_actions
    ADD CONSTRAINT survey_input_api_actions_survey_input_id_fkey FOREIGN KEY (survey_input_id) REFERENCES public.survey_inputs(id) ON UPDATE CASCADE;


--
-- TOC entry 9456 (class 2606 OID 503194)
-- Name: survey_input_trunk_actions survey_input_trunk_actions_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_trunk_actions
    ADD CONSTRAINT survey_input_trunk_actions_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.trunk_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9457 (class 2606 OID 509759)
-- Name: survey_input_trunk_actions survey_input_trunk_actions_survey_input_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_input_trunk_actions
    ADD CONSTRAINT survey_input_trunk_actions_survey_input_id_fkey FOREIGN KEY (survey_input_id) REFERENCES public.survey_inputs(id) ON UPDATE CASCADE;


--
-- TOC entry 9419 (class 2606 OID 503147)
-- Name: survey_inputs survey_inputs_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_inputs
    ADD CONSTRAINT survey_inputs_event_id_fkey FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9461 (class 2606 OID 503239)
-- Name: survey_livestocks survey_livestock_id_pkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_livestocks
    ADD CONSTRAINT survey_livestock_id_pkey FOREIGN KEY (livestock_id) REFERENCES public.livestocks(id) ON UPDATE CASCADE;


--
-- TOC entry 9466 (class 2606 OID 509789)
-- Name: survey_machineries survey_machineries_machinery_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_machineries
    ADD CONSTRAINT survey_machineries_machinery_id_fkey FOREIGN KEY (machinery_id) REFERENCES public.machineries(id) ON UPDATE CASCADE;


--
-- TOC entry 9462 (class 2606 OID 503244)
-- Name: survey_livestocks survey_pkey_livestock; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_livestocks
    ADD CONSTRAINT survey_pkey_livestock FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9464 (class 2606 OID 503266)
-- Name: survey_locations survey_pkey_location; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_locations
    ADD CONSTRAINT survey_pkey_location FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9469 (class 2606 OID 503322)
-- Name: survey_profiles survey_profiles_foreign_pkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_profiles
    ADD CONSTRAINT survey_profiles_foreign_pkey FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE;


--
-- TOC entry 9470 (class 2606 OID 503362)
-- Name: survey_validation_apis survey_validation_apis_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_validation_apis
    ADD CONSTRAINT survey_validation_apis_fk1 FOREIGN KEY (survey_id) REFERENCES public.surveys(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9471 (class 2606 OID 503367)
-- Name: survey_validation_apis survey_validation_apis_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.survey_validation_apis
    ADD CONSTRAINT survey_validation_apis_fk2 FOREIGN KEY (action_id) REFERENCES public.api_call_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 9385 (class 2606 OID 276975)
-- Name: trunk_recording_timings trunk_recording_timings_trunk_call_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trunk_recording_timings
    ADD CONSTRAINT trunk_recording_timings_trunk_call_detail_id_fkey FOREIGN KEY (trunk_call_detail_id) REFERENCES public.trunk_call_details(id) ON UPDATE CASCADE;


--
-- TOC entry 9382 (class 2606 OID 276980)
-- Name: trunk_dialing_timings trunk_timings_trunk_call_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trunk_dialing_timings
    ADD CONSTRAINT trunk_timings_trunk_call_detail_id_fkey FOREIGN KEY (trunk_call_detail_id) REFERENCES public.trunk_call_details(id) ON UPDATE CASCADE;


--
-- TOC entry 9389 (class 2606 OID 276985)
-- Name: weather_change_set weather_change_set_narrative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_change_set
    ADD CONSTRAINT weather_change_set_narrative_id_fkey FOREIGN KEY (id) REFERENCES public.narrative_list(id) ON UPDATE CASCADE;


--
-- TOC entry 9390 (class 2606 OID 276990)
-- Name: weather_change_set weather_change_set_phrase32_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_change_set
    ADD CONSTRAINT weather_change_set_phrase32_id_fkey FOREIGN KEY (id) REFERENCES public.phrase_32_char_list(id) ON UPDATE CASCADE;


--
-- TOC entry 9391 (class 2606 OID 276995)
-- Name: weather_change_set weather_change_set_wx_phrase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.weather_change_set
    ADD CONSTRAINT weather_change_set_wx_phrase_id_fkey FOREIGN KEY (id) REFERENCES public.wx_phrase_list(id) ON UPDATE CASCADE;


--
-- TOC entry 9687 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO ateebqa_rw;
GRANT USAGE ON SCHEMA public TO ahsanprod_rw;
GRANT ALL ON SCHEMA public TO naqia_dev_rw;
GRANT USAGE ON SCHEMA public TO haider_qa;


--
-- TOC entry 9691 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE "KP_Data_Swabi_msisdns"; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."KP_Data_Swabi_msisdns" TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."KP_Data_Swabi_msisdns" TO naqia_dev_rw;
GRANT SELECT ON TABLE public."KP_Data_Swabi_msisdns" TO haider_qa;


--
-- TOC entry 9692 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE abiotic_stress; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.abiotic_stress TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.abiotic_stress TO naqia_dev_rw;
GRANT SELECT ON TABLE public.abiotic_stress TO haider_qa;


--
-- TOC entry 9694 (class 0 OID 0)
-- Dependencies: 212
-- Name: SEQUENCE abiotic_stress_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.abiotic_stress_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.abiotic_stress_id_seq TO naqia_dev_rw;


--
-- TOC entry 9695 (class 0 OID 0)
-- Dependencies: 809
-- Name: TABLE abusive_callers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.abusive_callers TO haider_qa;


--
-- TOC entry 9696 (class 0 OID 0)
-- Dependencies: 213
-- Name: TABLE actions_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.actions_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.actions_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.actions_types TO haider_qa;


--
-- TOC entry 9698 (class 0 OID 0)
-- Dependencies: 214
-- Name: SEQUENCE actions_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.actions_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.actions_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 9699 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE active_subscriber_range; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.active_subscriber_range TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.active_subscriber_range TO naqia_dev_rw;
GRANT SELECT ON TABLE public.active_subscriber_range TO haider_qa;


--
-- TOC entry 9701 (class 0 OID 0)
-- Dependencies: 216
-- Name: SEQUENCE active_subscriber_range_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.active_subscriber_range_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.active_subscriber_range_id_seq TO naqia_dev_rw;


--
-- TOC entry 9702 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE actively_engaged_users_bkk_cc; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.actively_engaged_users_bkk_cc TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.actively_engaged_users_bkk_cc TO naqia_dev_rw;
GRANT SELECT ON TABLE public.actively_engaged_users_bkk_cc TO haider_qa;


--
-- TOC entry 9703 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE activity_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.activity_logs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.activity_logs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.activity_logs TO haider_qa;


--
-- TOC entry 9704 (class 0 OID 0)
-- Dependencies: 744
-- Name: TABLE adoptive_ivr_apps; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_ivr_apps TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_ivr_apps TO haider_qa;


--
-- TOC entry 9705 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE adoptive_menu; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu TO haider_qa;


--
-- TOC entry 9706 (class 0 OID 0)
-- Dependencies: 745
-- Name: TABLE adoptive_menu_api_actions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_api_actions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_api_actions TO haider_qa;


--
-- TOC entry 9708 (class 0 OID 0)
-- Dependencies: 746
-- Name: SEQUENCE adoptive_menu_api_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_api_actions_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.adoptive_menu_api_actions_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.adoptive_menu_api_actions_id_seq TO naqia_dev_rw;


--
-- TOC entry 9709 (class 0 OID 0)
-- Dependencies: 747
-- Name: TABLE adoptive_menu_campaigns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_campaigns TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_campaigns TO haider_qa;


--
-- TOC entry 9710 (class 0 OID 0)
-- Dependencies: 749
-- Name: TABLE adoptive_menu_content_nodes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_content_nodes TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_content_nodes TO haider_qa;


--
-- TOC entry 9712 (class 0 OID 0)
-- Dependencies: 750
-- Name: SEQUENCE adoptive_menu_content_nodes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_content_nodes_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.adoptive_menu_content_nodes_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.adoptive_menu_content_nodes_id_seq TO naqia_dev_rw;


--
-- TOC entry 9713 (class 0 OID 0)
-- Dependencies: 751
-- Name: TABLE adoptive_menu_crops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_crops TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_crops TO haider_qa;


--
-- TOC entry 9715 (class 0 OID 0)
-- Dependencies: 748
-- Name: SEQUENCE adoptive_menu_events_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_events_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.adoptive_menu_events_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.adoptive_menu_events_id_seq TO naqia_dev_rw;


--
-- TOC entry 9716 (class 0 OID 0)
-- Dependencies: 753
-- Name: TABLE adoptive_menu_file_name_apis; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_file_name_apis TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_file_name_apis TO haider_qa;


--
-- TOC entry 9717 (class 0 OID 0)
-- Dependencies: 754
-- Name: TABLE adoptive_menu_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_files TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_files TO haider_qa;


--
-- TOC entry 9719 (class 0 OID 0)
-- Dependencies: 755
-- Name: SEQUENCE adoptive_menu_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_files_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.adoptive_menu_files_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.adoptive_menu_files_id_seq TO naqia_dev_rw;


--
-- TOC entry 9721 (class 0 OID 0)
-- Dependencies: 743
-- Name: SEQUENCE adoptive_menu_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.adoptive_menu_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.adoptive_menu_id_seq TO naqia_dev_rw;


--
-- TOC entry 9722 (class 0 OID 0)
-- Dependencies: 756
-- Name: TABLE adoptive_menu_languages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_languages TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_languages TO haider_qa;


--
-- TOC entry 9723 (class 0 OID 0)
-- Dependencies: 758
-- Name: TABLE adoptive_menu_livestocks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_livestocks TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_livestocks TO haider_qa;


--
-- TOC entry 9724 (class 0 OID 0)
-- Dependencies: 760
-- Name: TABLE adoptive_menu_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_locations TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_locations TO haider_qa;


--
-- TOC entry 9725 (class 0 OID 0)
-- Dependencies: 762
-- Name: TABLE adoptive_menu_machineries; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_machineries TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_machineries TO haider_qa;


--
-- TOC entry 9726 (class 0 OID 0)
-- Dependencies: 771
-- Name: TABLE adoptive_menu_operators; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_operators TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_operators TO haider_qa;


--
-- TOC entry 9727 (class 0 OID 0)
-- Dependencies: 772
-- Name: TABLE adoptive_menu_profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_profiles TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_profiles TO haider_qa;


--
-- TOC entry 9728 (class 0 OID 0)
-- Dependencies: 764
-- Name: TABLE adoptive_menu_recording_end_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_recording_end_files TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_recording_end_files TO haider_qa;


--
-- TOC entry 9730 (class 0 OID 0)
-- Dependencies: 765
-- Name: SEQUENCE adoptive_menu_recording_end_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_recording_end_files_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.adoptive_menu_recording_end_files_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.adoptive_menu_recording_end_files_id_seq TO naqia_dev_rw;


--
-- TOC entry 9731 (class 0 OID 0)
-- Dependencies: 766
-- Name: TABLE adoptive_menu_surveys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_surveys TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_surveys TO haider_qa;


--
-- TOC entry 9733 (class 0 OID 0)
-- Dependencies: 767
-- Name: SEQUENCE adoptive_menu_surveys_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_surveys_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.adoptive_menu_surveys_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.adoptive_menu_surveys_id_seq TO naqia_dev_rw;


--
-- TOC entry 9734 (class 0 OID 0)
-- Dependencies: 768
-- Name: TABLE adoptive_menu_trunk_actions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_trunk_actions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_trunk_actions TO haider_qa;


--
-- TOC entry 9736 (class 0 OID 0)
-- Dependencies: 769
-- Name: SEQUENCE adoptive_menu_trunk_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.adoptive_menu_trunk_actions_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.adoptive_menu_trunk_actions_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.adoptive_menu_trunk_actions_id_seq TO naqia_dev_rw;


--
-- TOC entry 9737 (class 0 OID 0)
-- Dependencies: 770
-- Name: TABLE adoptive_menu_validation_apis; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adoptive_menu_validation_apis TO naqia_dev_rw;
GRANT SELECT ON TABLE public.adoptive_menu_validation_apis TO haider_qa;


--
-- TOC entry 9738 (class 0 OID 0)
-- Dependencies: 690
-- Name: TABLE campaign_crops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_crops TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_crops TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_crops TO haider_qa;


--
-- TOC entry 9740 (class 0 OID 0)
-- Dependencies: 691
-- Name: SEQUENCE advisory_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.advisory_crops_id_seq TO naqia_dev_rw;


--
-- TOC entry 9741 (class 0 OID 0)
-- Dependencies: 676
-- Name: TABLE campaigns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaigns TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaigns TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaigns TO haider_qa;


--
-- TOC entry 9743 (class 0 OID 0)
-- Dependencies: 677
-- Name: SEQUENCE advisory_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.advisory_id_seq TO naqia_dev_rw;


--
-- TOC entry 9744 (class 0 OID 0)
-- Dependencies: 697
-- Name: TABLE campaign_livestocks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_livestocks TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_livestocks TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_livestocks TO haider_qa;


--
-- TOC entry 9746 (class 0 OID 0)
-- Dependencies: 698
-- Name: SEQUENCE advisory_livestock_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.advisory_livestock_id_seq TO naqia_dev_rw;


--
-- TOC entry 9747 (class 0 OID 0)
-- Dependencies: 699
-- Name: TABLE campaign_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_locations TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_locations TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_locations TO haider_qa;


--
-- TOC entry 9749 (class 0 OID 0)
-- Dependencies: 700
-- Name: SEQUENCE advisory_locations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.advisory_locations_id_seq TO naqia_dev_rw;


--
-- TOC entry 9750 (class 0 OID 0)
-- Dependencies: 701
-- Name: TABLE campaign_machineries; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_machineries TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_machineries TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_machineries TO haider_qa;


--
-- TOC entry 9752 (class 0 OID 0)
-- Dependencies: 702
-- Name: SEQUENCE advisory_machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.advisory_machineries_id_seq TO naqia_dev_rw;


--
-- TOC entry 9753 (class 0 OID 0)
-- Dependencies: 780
-- Name: TABLE advisory_salutations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.advisory_salutations TO naqia_dev_rw;
GRANT SELECT ON TABLE public.advisory_salutations TO haider_qa;


--
-- TOC entry 9754 (class 0 OID 0)
-- Dependencies: 695
-- Name: TABLE campaign_languages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_languages TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_languages TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_languages TO haider_qa;


--
-- TOC entry 9756 (class 0 OID 0)
-- Dependencies: 696
-- Name: SEQUENCE advisory_tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.advisory_tags_id_seq TO naqia_dev_rw;


--
-- TOC entry 9757 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE agent_roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agent_roles TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agent_roles TO naqia_dev_rw;
GRANT SELECT ON TABLE public.agent_roles TO haider_qa;


--
-- TOC entry 9758 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.roles TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.roles TO naqia_dev_rw;
GRANT SELECT ON TABLE public.roles TO haider_qa;


--
-- TOC entry 9760 (class 0 OID 0)
-- Dependencies: 222
-- Name: SEQUENCE agent_roles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.agent_roles_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.agent_roles_id_seq TO naqia_dev_rw;


--
-- TOC entry 9762 (class 0 OID 0)
-- Dependencies: 223
-- Name: SEQUENCE agent_roles_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.agent_roles_id_seq1 TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.agent_roles_id_seq1 TO naqia_dev_rw;


--
-- TOC entry 9763 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE agents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents TO naqia_dev_rw;
GRANT SELECT ON TABLE public.agents TO haider_qa;


--
-- TOC entry 9764 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE agents_activity_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents_activity_logs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents_activity_logs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.agents_activity_logs TO haider_qa;


--
-- TOC entry 9765 (class 0 OID 0)
-- Dependencies: 226
-- Name: SEQUENCE agents_activity_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.agents_activity_logs_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.agents_activity_logs_id_seq TO naqia_dev_rw;


--
-- TOC entry 9766 (class 0 OID 0)
-- Dependencies: 639
-- Name: TABLE agents_backup; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents_backup TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents_backup TO naqia_dev_rw;
GRANT SELECT ON TABLE public.agents_backup TO haider_qa;


--
-- TOC entry 9767 (class 0 OID 0)
-- Dependencies: 646
-- Name: TABLE agents_removed_20230607; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents_removed_20230607 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents_removed_20230607 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.agents_removed_20230607 TO haider_qa;


--
-- TOC entry 9768 (class 0 OID 0)
-- Dependencies: 640
-- Name: TABLE agri_businesess_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agri_businesess_tags TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agri_businesess_tags TO naqia_dev_rw;
GRANT SELECT ON TABLE public.agri_businesess_tags TO haider_qa;


--
-- TOC entry 9769 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE ahmed_base; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ahmed_base TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ahmed_base TO naqia_dev_rw;
GRANT SELECT ON TABLE public.ahmed_base TO haider_qa;


--
-- TOC entry 9770 (class 0 OID 0)
-- Dependencies: 688
-- Name: TABLE alerts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.alerts TO naqia_dev_rw;
GRANT SELECT ON TABLE public.alerts TO haider_qa;


--
-- TOC entry 9771 (class 0 OID 0)
-- Dependencies: 820
-- Name: TABLE anomalies; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.anomalies TO haider_qa;


--
-- TOC entry 9772 (class 0 OID 0)
-- Dependencies: 813
-- Name: TABLE anomaly_response; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.anomaly_response TO haider_qa;


--
-- TOC entry 9773 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE api_call_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_call_details TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_call_details TO naqia_dev_rw;
GRANT SELECT ON TABLE public.api_call_details TO haider_qa;


--
-- TOC entry 9775 (class 0 OID 0)
-- Dependencies: 229
-- Name: SEQUENCE api_call_details_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_call_details_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.api_call_details_id_seq TO naqia_dev_rw;


--
-- TOC entry 9776 (class 0 OID 0)
-- Dependencies: 685
-- Name: TABLE api_call_details_updated; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_call_details_updated TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_call_details_updated TO naqia_dev_rw;
GRANT SELECT ON TABLE public.api_call_details_updated TO haider_qa;


--
-- TOC entry 9777 (class 0 OID 0)
-- Dependencies: 230
-- Name: SEQUENCE api_methods_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_methods_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.api_methods_id_seq TO naqia_dev_rw;


--
-- TOC entry 9778 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE api_permissions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_permissions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_permissions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.api_permissions TO haider_qa;


--
-- TOC entry 9780 (class 0 OID 0)
-- Dependencies: 232
-- Name: SEQUENCE api_permissions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_permissions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.api_permissions_id_seq TO naqia_dev_rw;


--
-- TOC entry 9781 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE api_resource_category; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_resource_category TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_resource_category TO naqia_dev_rw;
GRANT SELECT ON TABLE public.api_resource_category TO haider_qa;


--
-- TOC entry 9783 (class 0 OID 0)
-- Dependencies: 234
-- Name: SEQUENCE api_resource_category_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_resource_category_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.api_resource_category_id_seq TO naqia_dev_rw;


--
-- TOC entry 9784 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE api_resource_permissions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_resource_permissions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_resource_permissions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.api_resource_permissions TO haider_qa;


--
-- TOC entry 9786 (class 0 OID 0)
-- Dependencies: 236
-- Name: SEQUENCE api_resource_permissions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_resource_permissions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.api_resource_permissions_id_seq TO naqia_dev_rw;


--
-- TOC entry 9787 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE api_resource_roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_resource_roles TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_resource_roles TO naqia_dev_rw;
GRANT SELECT ON TABLE public.api_resource_roles TO haider_qa;


--
-- TOC entry 9789 (class 0 OID 0)
-- Dependencies: 238
-- Name: SEQUENCE api_resource_roles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_resource_roles_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.api_resource_roles_id_seq TO naqia_dev_rw;


--
-- TOC entry 9790 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE api_resources; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_resources TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.api_resources TO naqia_dev_rw;
GRANT SELECT ON TABLE public.api_resources TO haider_qa;


--
-- TOC entry 9792 (class 0 OID 0)
-- Dependencies: 240
-- Name: SEQUENCE api_resources_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.api_resources_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.api_resources_id_seq TO naqia_dev_rw;


--
-- TOC entry 9793 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE loan_agreements; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_agreements TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_agreements TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_agreements TO haider_qa;


--
-- TOC entry 9795 (class 0 OID 0)
-- Dependencies: 242
-- Name: SEQUENCE application_docs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.application_docs_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.application_docs_id_seq TO naqia_dev_rw;


--
-- TOC entry 9796 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE application_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.application_status TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.application_status TO naqia_dev_rw;
GRANT SELECT ON TABLE public.application_status TO haider_qa;


--
-- TOC entry 9798 (class 0 OID 0)
-- Dependencies: 244
-- Name: SEQUENCE application_status_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.application_status_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.application_status_id_seq TO naqia_dev_rw;


--
-- TOC entry 9799 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE badges; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.badges TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.badges TO naqia_dev_rw;
GRANT SELECT ON TABLE public.badges TO haider_qa;


--
-- TOC entry 9801 (class 0 OID 0)
-- Dependencies: 246
-- Name: SEQUENCE badges_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.badges_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.badges_id_seq TO naqia_dev_rw;


--
-- TOC entry 9802 (class 0 OID 0)
-- Dependencies: 641
-- Name: TABLE banners; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.banners TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.banners TO naqia_dev_rw;
GRANT SELECT ON TABLE public.banners TO haider_qa;


--
-- TOC entry 9803 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE bkk_wrong_charging; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.bkk_wrong_charging TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.bkk_wrong_charging TO naqia_dev_rw;
GRANT SELECT ON TABLE public.bkk_wrong_charging TO haider_qa;


--
-- TOC entry 9804 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE blacklist; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.blacklist TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.blacklist TO naqia_dev_rw;
GRANT SELECT ON TABLE public.blacklist TO haider_qa;


--
-- TOC entry 9806 (class 0 OID 0)
-- Dependencies: 249
-- Name: SEQUENCE blacklist_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.blacklist_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.blacklist_id_seq TO naqia_dev_rw;


--
-- TOC entry 9807 (class 0 OID 0)
-- Dependencies: 647
-- Name: TABLE business; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business TO naqia_dev_rw;
GRANT SELECT ON TABLE public.business TO haider_qa;


--
-- TOC entry 9808 (class 0 OID 0)
-- Dependencies: 642
-- Name: TABLE business_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business_categories TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business_categories TO naqia_dev_rw;
GRANT SELECT ON TABLE public.business_categories TO haider_qa;


--
-- TOC entry 9809 (class 0 OID 0)
-- Dependencies: 643
-- Name: TABLE business_contact_person; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business_contact_person TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business_contact_person TO naqia_dev_rw;
GRANT SELECT ON TABLE public.business_contact_person TO haider_qa;


--
-- TOC entry 9810 (class 0 OID 0)
-- Dependencies: 644
-- Name: TABLE business_media_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business_media_files TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business_media_files TO naqia_dev_rw;
GRANT SELECT ON TABLE public.business_media_files TO haider_qa;


--
-- TOC entry 9811 (class 0 OID 0)
-- Dependencies: 645
-- Name: TABLE business_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business_tags TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.business_tags TO naqia_dev_rw;
GRANT SELECT ON TABLE public.business_tags TO haider_qa;


--
-- TOC entry 9812 (class 0 OID 0)
-- Dependencies: 782
-- Name: TABLE buyer_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.buyer_types TO haider_qa;


--
-- TOC entry 9813 (class 0 OID 0)
-- Dependencies: 805
-- Name: TABLE buyers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.buyers TO haider_qa;


--
-- TOC entry 9814 (class 0 OID 0)
-- Dependencies: 681
-- Name: TABLE call_end_notification; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.call_end_notification TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.call_end_notification TO naqia_dev_rw;
GRANT SELECT ON TABLE public.call_end_notification TO haider_qa;


--
-- TOC entry 9815 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE call_hangup_cause; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.call_hangup_cause TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.call_hangup_cause TO naqia_dev_rw;
GRANT SELECT ON TABLE public.call_hangup_cause TO haider_qa;


--
-- TOC entry 9816 (class 0 OID 0)
-- Dependencies: 689
-- Name: TABLE campaign_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_categories TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_categories TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_categories TO haider_qa;


--
-- TOC entry 9817 (class 0 OID 0)
-- Dependencies: 251
-- Name: SEQUENCE campaign_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_categories_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.campaign_categories_id_seq TO naqia_dev_rw;


--
-- TOC entry 9818 (class 0 OID 0)
-- Dependencies: 692
-- Name: TABLE campaign_file_name_apis; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_file_name_apis TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_file_name_apis TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_file_name_apis TO haider_qa;


--
-- TOC entry 9819 (class 0 OID 0)
-- Dependencies: 693
-- Name: TABLE campaign_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_files TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_files TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_files TO haider_qa;


--
-- TOC entry 9821 (class 0 OID 0)
-- Dependencies: 694
-- Name: SEQUENCE campaign_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.campaign_files_id_seq TO naqia_dev_rw;


--
-- TOC entry 9822 (class 0 OID 0)
-- Dependencies: 703
-- Name: TABLE campaign_operator; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_operator TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_operator TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_operator TO haider_qa;


--
-- TOC entry 9823 (class 0 OID 0)
-- Dependencies: 252
-- Name: SEQUENCE campaign_operator_a_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_operator_a_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.campaign_operator_a_seq TO naqia_dev_rw;


--
-- TOC entry 9824 (class 0 OID 0)
-- Dependencies: 704
-- Name: TABLE campaign_profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_profiles TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_profiles TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_profiles TO haider_qa;


--
-- TOC entry 9826 (class 0 OID 0)
-- Dependencies: 705
-- Name: SEQUENCE campaign_profiles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.campaign_profiles_id_seq TO naqia_dev_rw;


--
-- TOC entry 9827 (class 0 OID 0)
-- Dependencies: 706
-- Name: TABLE campaign_promo_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_promo_data TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_promo_data TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_promo_data TO haider_qa;


--
-- TOC entry 9828 (class 0 OID 0)
-- Dependencies: 253
-- Name: SEQUENCE campaign_promo_data_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.campaign_promo_data_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.campaign_promo_data_id_seq TO naqia_dev_rw;


--
-- TOC entry 9829 (class 0 OID 0)
-- Dependencies: 707
-- Name: TABLE campaign_recording_end_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_recording_end_files TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_recording_end_files TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_recording_end_files TO haider_qa;


--
-- TOC entry 9831 (class 0 OID 0)
-- Dependencies: 708
-- Name: SEQUENCE campaign_recording_end_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.campaign_recording_end_files_id_seq TO naqia_dev_rw;


--
-- TOC entry 9832 (class 0 OID 0)
-- Dependencies: 675
-- Name: TABLE campaign_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_types TO haider_qa;


--
-- TOC entry 9834 (class 0 OID 0)
-- Dependencies: 709
-- Name: SEQUENCE campaign_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.campaign_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 9835 (class 0 OID 0)
-- Dependencies: 710
-- Name: TABLE campaign_validation_apis; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_validation_apis TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.campaign_validation_apis TO naqia_dev_rw;
GRANT SELECT ON TABLE public.campaign_validation_apis TO haider_qa;


--
-- TOC entry 9836 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE case_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.case_categories TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.case_categories TO naqia_dev_rw;
GRANT SELECT ON TABLE public.case_categories TO haider_qa;


--
-- TOC entry 9838 (class 0 OID 0)
-- Dependencies: 255
-- Name: SEQUENCE case_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.case_categories_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.case_categories_id_seq TO naqia_dev_rw;


--
-- TOC entry 9839 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE case_media_contents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.case_media_contents TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.case_media_contents TO naqia_dev_rw;
GRANT SELECT ON TABLE public.case_media_contents TO haider_qa;


--
-- TOC entry 9841 (class 0 OID 0)
-- Dependencies: 257
-- Name: SEQUENCE case_media_contents_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.case_media_contents_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.case_media_contents_id_seq TO naqia_dev_rw;


--
-- TOC entry 9842 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE case_parameters; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.case_parameters TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.case_parameters TO naqia_dev_rw;
GRANT SELECT ON TABLE public.case_parameters TO haider_qa;


--
-- TOC entry 9844 (class 0 OID 0)
-- Dependencies: 259
-- Name: SEQUENCE case_parameters_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.case_parameters_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.case_parameters_id_seq TO naqia_dev_rw;


--
-- TOC entry 9845 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE case_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.case_tags TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.case_tags TO naqia_dev_rw;
GRANT SELECT ON TABLE public.case_tags TO haider_qa;


--
-- TOC entry 9847 (class 0 OID 0)
-- Dependencies: 261
-- Name: SEQUENCE case_tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.case_tags_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.case_tags_id_seq TO naqia_dev_rw;


--
-- TOC entry 9848 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE cases; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cases TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cases TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cases TO haider_qa;


--
-- TOC entry 9850 (class 0 OID 0)
-- Dependencies: 263
-- Name: SEQUENCE cases_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.cases_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.cases_id_seq TO naqia_dev_rw;


--
-- TOC entry 9851 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE cc_agents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_agents TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_agents TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cc_agents TO haider_qa;


--
-- TOC entry 9852 (class 0 OID 0)
-- Dependencies: 265
-- Name: TABLE cc_call_end_survey_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_call_end_survey_logs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_call_end_survey_logs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cc_call_end_survey_logs TO haider_qa;


--
-- TOC entry 9853 (class 0 OID 0)
-- Dependencies: 266
-- Name: TABLE cc_call_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_call_logs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_call_logs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cc_call_logs TO haider_qa;


--
-- TOC entry 9854 (class 0 OID 0)
-- Dependencies: 817
-- Name: TABLE cc_engaged_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.cc_engaged_users TO haider_qa;


--
-- TOC entry 9855 (class 0 OID 0)
-- Dependencies: 267
-- Name: TABLE cc_msisdn_check_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_msisdn_check_profile TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_msisdn_check_profile TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cc_msisdn_check_profile TO haider_qa;


--
-- TOC entry 9856 (class 0 OID 0)
-- Dependencies: 637
-- Name: TABLE cc_outbound_whitelist; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_outbound_whitelist TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cc_outbound_whitelist TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cc_outbound_whitelist TO haider_qa;


--
-- TOC entry 9857 (class 0 OID 0)
-- Dependencies: 268
-- Name: TABLE cdr; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cdr TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cdr TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cdr TO haider_qa;


--
-- TOC entry 9858 (class 0 OID 0)
-- Dependencies: 269
-- Name: TABLE cdr_asterisk; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cdr_asterisk TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cdr_asterisk TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cdr_asterisk TO haider_qa;


--
-- TOC entry 9860 (class 0 OID 0)
-- Dependencies: 270
-- Name: SEQUENCE cdr_asterisk_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.cdr_asterisk_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.cdr_asterisk_id_seq TO naqia_dev_rw;


--
-- TOC entry 9861 (class 0 OID 0)
-- Dependencies: 271
-- Name: TABLE chashma_operator_tagg; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.chashma_operator_tagg TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.chashma_operator_tagg TO naqia_dev_rw;
GRANT SELECT ON TABLE public.chashma_operator_tagg TO haider_qa;


--
-- TOC entry 9862 (class 0 OID 0)
-- Dependencies: 272
-- Name: TABLE chasmha_operator_check; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.chasmha_operator_check TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.chasmha_operator_check TO naqia_dev_rw;
GRANT SELECT ON TABLE public.chasmha_operator_check TO haider_qa;


--
-- TOC entry 9863 (class 0 OID 0)
-- Dependencies: 273
-- Name: TABLE clauses; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.clauses TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.clauses TO naqia_dev_rw;
GRANT SELECT ON TABLE public.clauses TO haider_qa;


--
-- TOC entry 9865 (class 0 OID 0)
-- Dependencies: 274
-- Name: SEQUENCE clauses_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.clauses_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.clauses_id_seq TO naqia_dev_rw;


--
-- TOC entry 9866 (class 0 OID 0)
-- Dependencies: 779
-- Name: TABLE community_blacklist; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.community_blacklist TO naqia_dev_rw;
GRANT SELECT ON TABLE public.community_blacklist TO haider_qa;


--
-- TOC entry 9867 (class 0 OID 0)
-- Dependencies: 648
-- Name: TABLE contact_person; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.contact_person TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.contact_person TO naqia_dev_rw;
GRANT SELECT ON TABLE public.contact_person TO haider_qa;


--
-- TOC entry 9868 (class 0 OID 0)
-- Dependencies: 275
-- Name: TABLE content_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.content_files TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.content_files TO naqia_dev_rw;
GRANT SELECT ON TABLE public.content_files TO haider_qa;


--
-- TOC entry 9870 (class 0 OID 0)
-- Dependencies: 711
-- Name: SEQUENCE content_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.content_files_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.content_files_id_seq TO naqia_dev_rw;


--
-- TOC entry 9871 (class 0 OID 0)
-- Dependencies: 276
-- Name: TABLE content_folders; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.content_folders TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.content_folders TO naqia_dev_rw;
GRANT SELECT ON TABLE public.content_folders TO haider_qa;


--
-- TOC entry 9873 (class 0 OID 0)
-- Dependencies: 277
-- Name: SEQUENCE content_folders_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.content_folders_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.content_folders_id_seq TO naqia_dev_rw;


--
-- TOC entry 9874 (class 0 OID 0)
-- Dependencies: 278
-- Name: TABLE crop_calender; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_calender TO haider_qa;


--
-- TOC entry 9875 (class 0 OID 0)
-- Dependencies: 279
-- Name: TABLE crop_calender_crops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender_crops TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender_crops TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_calender_crops TO haider_qa;


--
-- TOC entry 9877 (class 0 OID 0)
-- Dependencies: 280
-- Name: SEQUENCE crop_calender_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_crops_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.crop_calender_crops_id_seq TO naqia_dev_rw;


--
-- TOC entry 9879 (class 0 OID 0)
-- Dependencies: 281
-- Name: SEQUENCE crop_calender_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.crop_calender_id_seq TO naqia_dev_rw;


--
-- TOC entry 9880 (class 0 OID 0)
-- Dependencies: 282
-- Name: TABLE crop_calender_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender_locations TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender_locations TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_calender_locations TO haider_qa;


--
-- TOC entry 9882 (class 0 OID 0)
-- Dependencies: 283
-- Name: SEQUENCE crop_calender_locations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_locations_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.crop_calender_locations_id_seq TO naqia_dev_rw;


--
-- TOC entry 9883 (class 0 OID 0)
-- Dependencies: 284
-- Name: TABLE crop_calender_weather_favourable_conditions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender_weather_favourable_conditions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender_weather_favourable_conditions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_calender_weather_favourable_conditions TO haider_qa;


--
-- TOC entry 9885 (class 0 OID 0)
-- Dependencies: 285
-- Name: SEQUENCE crop_calender_weather_favourable_conditions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_weather_favourable_conditions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.crop_calender_weather_favourable_conditions_id_seq TO naqia_dev_rw;


--
-- TOC entry 9886 (class 0 OID 0)
-- Dependencies: 286
-- Name: TABLE crop_calender_weather_unfavourable_conditions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender_weather_unfavourable_conditions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_calender_weather_unfavourable_conditions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_calender_weather_unfavourable_conditions TO haider_qa;


--
-- TOC entry 9888 (class 0 OID 0)
-- Dependencies: 287
-- Name: SEQUENCE crop_calender_weather_unfavourable_conditions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_calender_weather_unfavourable_conditions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.crop_calender_weather_unfavourable_conditions_id_seq TO naqia_dev_rw;


--
-- TOC entry 9889 (class 0 OID 0)
-- Dependencies: 288
-- Name: TABLE crop_diseases; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_diseases TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_diseases TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_diseases TO haider_qa;


--
-- TOC entry 9891 (class 0 OID 0)
-- Dependencies: 289
-- Name: SEQUENCE crop_diseases_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_diseases_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.crop_diseases_id_seq TO naqia_dev_rw;


--
-- TOC entry 9892 (class 0 OID 0)
-- Dependencies: 290
-- Name: TABLE growth_stages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.growth_stages TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.growth_stages TO naqia_dev_rw;
GRANT SELECT ON TABLE public.growth_stages TO haider_qa;


--
-- TOC entry 9894 (class 0 OID 0)
-- Dependencies: 291
-- Name: SEQUENCE crop_growth_stages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crop_growth_stages_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.crop_growth_stages_id_seq TO naqia_dev_rw;


--
-- TOC entry 9895 (class 0 OID 0)
-- Dependencies: 292
-- Name: TABLE crop_insects; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_insects TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_insects TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_insects TO haider_qa;


--
-- TOC entry 9896 (class 0 OID 0)
-- Dependencies: 682
-- Name: TABLE crop_season; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_season TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_season TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_season TO haider_qa;


--
-- TOC entry 9897 (class 0 OID 0)
-- Dependencies: 295
-- Name: TABLE crops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crops TO haider_qa;


--
-- TOC entry 9898 (class 0 OID 0)
-- Dependencies: 777
-- Name: TABLE farmcrops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmcrops TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmcrops TO haider_qa;


--
-- TOC entry 9899 (class 0 OID 0)
-- Dependencies: 322
-- Name: TABLE farmers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers TO ahsanprod_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmers TO haider_qa;


--
-- TOC entry 9900 (class 0 OID 0)
-- Dependencies: 324
-- Name: TABLE farms; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farms TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farms TO ahsanprod_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farms TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farms TO haider_qa;


--
-- TOC entry 9901 (class 0 OID 0)
-- Dependencies: 418
-- Name: TABLE locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.locations TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.locations TO naqia_dev_rw;
GRANT SELECT ON TABLE public.locations TO haider_qa;


--
-- TOC entry 9902 (class 0 OID 0)
-- Dependencies: 778
-- Name: TABLE crop_segregation_material; Type: ACL; Schema: public; Owner: bkkdev_rw
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_segregation_material TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_segregation_material TO haider_qa;


--
-- TOC entry 9903 (class 0 OID 0)
-- Dependencies: 293
-- Name: TABLE crop_testing; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_testing TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_testing TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_testing TO haider_qa;


--
-- TOC entry 9904 (class 0 OID 0)
-- Dependencies: 294
-- Name: TABLE crop_variety_ml; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_variety_ml TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crop_variety_ml TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crop_variety_ml TO haider_qa;


--
-- TOC entry 9905 (class 0 OID 0)
-- Dependencies: 649
-- Name: TABLE crops_2023_07_26; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops_2023_07_26 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops_2023_07_26 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crops_2023_07_26 TO haider_qa;


--
-- TOC entry 9906 (class 0 OID 0)
-- Dependencies: 650
-- Name: TABLE crops_backup; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops_backup TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops_backup TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crops_backup TO haider_qa;


--
-- TOC entry 9907 (class 0 OID 0)
-- Dependencies: 296
-- Name: TABLE crops_data_ml; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops_data_ml TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops_data_ml TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crops_data_ml TO haider_qa;


--
-- TOC entry 9909 (class 0 OID 0)
-- Dependencies: 297
-- Name: SEQUENCE crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.crops_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.crops_id_seq TO naqia_dev_rw;


--
-- TOC entry 9910 (class 0 OID 0)
-- Dependencies: 298
-- Name: TABLE crops_lightsail; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops_lightsail TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.crops_lightsail TO naqia_dev_rw;
GRANT SELECT ON TABLE public.crops_lightsail TO haider_qa;


--
-- TOC entry 9911 (class 0 OID 0)
-- Dependencies: 299
-- Name: TABLE "cross_promo_DTMF_subs "; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."cross_promo_DTMF_subs " TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."cross_promo_DTMF_subs " TO naqia_dev_rw;
GRANT SELECT ON TABLE public."cross_promo_DTMF_subs " TO haider_qa;


--
-- TOC entry 9912 (class 0 OID 0)
-- Dependencies: 300
-- Name: TABLE cross_promo_dtmf_sub; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cross_promo_dtmf_sub TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.cross_promo_dtmf_sub TO naqia_dev_rw;
GRANT SELECT ON TABLE public.cross_promo_dtmf_sub TO haider_qa;


--
-- TOC entry 9914 (class 0 OID 0)
-- Dependencies: 301
-- Name: SEQUENCE cross_promo_dtmf_sub_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.cross_promo_dtmf_sub_id_seq TO naqia_dev_rw;


--
-- TOC entry 9915 (class 0 OID 0)
-- Dependencies: 302
-- Name: TABLE csm_farmcrops_garaj; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.csm_farmcrops_garaj TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.csm_farmcrops_garaj TO naqia_dev_rw;
GRANT SELECT ON TABLE public.csm_farmcrops_garaj TO haider_qa;


--
-- TOC entry 9916 (class 0 OID 0)
-- Dependencies: 303
-- Name: TABLE csm_farmers_garaj; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.csm_farmers_garaj TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.csm_farmers_garaj TO naqia_dev_rw;
GRANT SELECT ON TABLE public.csm_farmers_garaj TO haider_qa;


--
-- TOC entry 9917 (class 0 OID 0)
-- Dependencies: 304
-- Name: TABLE csm_farms_garaj; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.csm_farms_garaj TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.csm_farms_garaj TO naqia_dev_rw;
GRANT SELECT ON TABLE public.csm_farms_garaj TO haider_qa;


--
-- TOC entry 9918 (class 0 OID 0)
-- Dependencies: 305
-- Name: TABLE csm_subscribers_garaj; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.csm_subscribers_garaj TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.csm_subscribers_garaj TO naqia_dev_rw;
GRANT SELECT ON TABLE public.csm_subscribers_garaj TO haider_qa;


--
-- TOC entry 9919 (class 0 OID 0)
-- Dependencies: 306
-- Name: TABLE districts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.districts TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.districts TO naqia_dev_rw;
GRANT SELECT ON TABLE public.districts TO haider_qa;


--
-- TOC entry 9920 (class 0 OID 0)
-- Dependencies: 307
-- Name: TABLE drl_count_ml; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.drl_count_ml TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.drl_count_ml TO naqia_dev_rw;
GRANT SELECT ON TABLE public.drl_count_ml TO haider_qa;


--
-- TOC entry 9921 (class 0 OID 0)
-- Dependencies: 308
-- Name: TABLE drl_unprocessed_filename_ml; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.drl_unprocessed_filename_ml TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.drl_unprocessed_filename_ml TO naqia_dev_rw;
GRANT SELECT ON TABLE public.drl_unprocessed_filename_ml TO haider_qa;


--
-- TOC entry 9922 (class 0 OID 0)
-- Dependencies: 800
-- Name: TABLE endpoints; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.endpoints TO haider_qa;


--
-- TOC entry 9923 (class 0 OID 0)
-- Dependencies: 801
-- Name: TABLE endpoints_permissions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.endpoints_permissions TO haider_qa;


--
-- TOC entry 9924 (class 0 OID 0)
-- Dependencies: 818
-- Name: TABLE engaged_user; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.engaged_user TO haider_qa;


--
-- TOC entry 9925 (class 0 OID 0)
-- Dependencies: 309
-- Name: TABLE event_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.event_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.event_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.event_types TO haider_qa;


--
-- TOC entry 9926 (class 0 OID 0)
-- Dependencies: 815
-- Name: TABLE expert_call_requests; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.expert_call_requests TO haider_qa;


--
-- TOC entry 9927 (class 0 OID 0)
-- Dependencies: 821
-- Name: TABLE farm_crop_growth_stage_anomalies; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farm_crop_growth_stage_anomalies TO haider_qa;


--
-- TOC entry 9928 (class 0 OID 0)
-- Dependencies: 310
-- Name: TABLE farm_crop_growth_stages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farm_crop_growth_stages TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farm_crop_growth_stages TO ahsanprod_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farm_crop_growth_stages TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farm_crop_growth_stages TO haider_qa;


--
-- TOC entry 9929 (class 0 OID 0)
-- Dependencies: 773
-- Name: TABLE farm_crop_growth_stages_duplicate_record; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farm_crop_growth_stages_duplicate_record TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farm_crop_growth_stages_duplicate_record TO haider_qa;


--
-- TOC entry 9930 (class 0 OID 0)
-- Dependencies: 683
-- Name: TABLE farm_crops_seed_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farm_crops_seed_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farm_crops_seed_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farm_crops_seed_types TO haider_qa;


--
-- TOC entry 9931 (class 0 OID 0)
-- Dependencies: 651
-- Name: TABLE farmcrops_backup; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmcrops_backup TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmcrops_backup TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmcrops_backup TO haider_qa;


--
-- TOC entry 9932 (class 0 OID 0)
-- Dependencies: 775
-- Name: TABLE farmcrops_duplicate_record; Type: ACL; Schema: public; Owner: ateebqa_rw
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmcrops_duplicate_record TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmcrops_duplicate_record TO haider_qa;


--
-- TOC entry 9933 (class 0 OID 0)
-- Dependencies: 652
-- Name: TABLE farmcrops_old; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmcrops_old TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmcrops_old TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmcrops_old TO haider_qa;


--
-- TOC entry 9934 (class 0 OID 0)
-- Dependencies: 776
-- Name: TABLE farmcrops_unique_record; Type: ACL; Schema: public; Owner: ateebqa_rw
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmcrops_unique_record TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmcrops_unique_record TO haider_qa;


--
-- TOC entry 9935 (class 0 OID 0)
-- Dependencies: 311
-- Name: TABLE farme_land_final; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farme_land_final TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farme_land_final TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farme_land_final TO haider_qa;


--
-- TOC entry 9936 (class 0 OID 0)
-- Dependencies: 312
-- Name: TABLE farmer_badge_recommendations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_badge_recommendations TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_badge_recommendations TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_badge_recommendations TO haider_qa;


--
-- TOC entry 9938 (class 0 OID 0)
-- Dependencies: 313
-- Name: SEQUENCE farmer_badge_recommendations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.farmer_badge_recommendations_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.farmer_badge_recommendations_id_seq TO naqia_dev_rw;


--
-- TOC entry 9939 (class 0 OID 0)
-- Dependencies: 314
-- Name: TABLE farmer_friends; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_friends TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_friends TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_friends TO haider_qa;


--
-- TOC entry 9940 (class 0 OID 0)
-- Dependencies: 315
-- Name: TABLE farmer_gender; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_gender TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_gender TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_gender TO haider_qa;


--
-- TOC entry 9941 (class 0 OID 0)
-- Dependencies: 653
-- Name: TABLE farmer_interest; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_interest TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_interest TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_interest TO haider_qa;


--
-- TOC entry 9942 (class 0 OID 0)
-- Dependencies: 316
-- Name: TABLE farmer_livestock_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_livestock_tags TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_livestock_tags TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_livestock_tags TO haider_qa;


--
-- TOC entry 9943 (class 0 OID 0)
-- Dependencies: 317
-- Name: TABLE farmer_livestocks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_livestocks TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_livestocks TO ahsanprod_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_livestocks TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_livestocks TO haider_qa;


--
-- TOC entry 9944 (class 0 OID 0)
-- Dependencies: 318
-- Name: TABLE farmer_machineries; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_machineries TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_machineries TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_machineries TO haider_qa;


--
-- TOC entry 9945 (class 0 OID 0)
-- Dependencies: 319
-- Name: TABLE farmer_name_change; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_name_change TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_name_change TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_name_change TO haider_qa;


--
-- TOC entry 9946 (class 0 OID 0)
-- Dependencies: 320
-- Name: TABLE farmer_name_content; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_name_content TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_name_content TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_name_content TO haider_qa;


--
-- TOC entry 9947 (class 0 OID 0)
-- Dependencies: 321
-- Name: TABLE farmer_names_ml; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_names_ml TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmer_names_ml TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmer_names_ml TO haider_qa;


--
-- TOC entry 9948 (class 0 OID 0)
-- Dependencies: 787
-- Name: TABLE farmer_updated_names; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmer_updated_names TO haider_qa;


--
-- TOC entry 9949 (class 0 OID 0)
-- Dependencies: 654
-- Name: TABLE farmers_copy; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers_copy TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers_copy TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmers_copy TO haider_qa;


--
-- TOC entry 9950 (class 0 OID 0)
-- Dependencies: 784
-- Name: TABLE farmers_eng_urdu_names; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.farmers_eng_urdu_names TO haider_qa;


--
-- TOC entry 9951 (class 0 OID 0)
-- Dependencies: 655
-- Name: TABLE farmers_old; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers_old TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers_old TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmers_old TO haider_qa;


--
-- TOC entry 9952 (class 0 OID 0)
-- Dependencies: 323
-- Name: TABLE farmers_testing; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers_testing TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farmers_testing TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farmers_testing TO haider_qa;


--
-- TOC entry 9953 (class 0 OID 0)
-- Dependencies: 325
-- Name: TABLE farms_final; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farms_final TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farms_final TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farms_final TO haider_qa;


--
-- TOC entry 9954 (class 0 OID 0)
-- Dependencies: 326
-- Name: TABLE farms_tagg; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farms_tagg TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.farms_tagg TO naqia_dev_rw;
GRANT SELECT ON TABLE public.farms_tagg TO haider_qa;


--
-- TOC entry 9955 (class 0 OID 0)
-- Dependencies: 786
-- Name: TABLE fav_crops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.fav_crops TO haider_qa;


--
-- TOC entry 9956 (class 0 OID 0)
-- Dependencies: 327
-- Name: TABLE field_visits; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.field_visits TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.field_visits TO naqia_dev_rw;
GRANT SELECT ON TABLE public.field_visits TO haider_qa;


--
-- TOC entry 9958 (class 0 OID 0)
-- Dependencies: 328
-- Name: SEQUENCE field_visits_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.field_visits_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.field_visits_id_seq TO naqia_dev_rw;


--
-- TOC entry 9959 (class 0 OID 0)
-- Dependencies: 329
-- Name: TABLE final_names; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.final_names TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.final_names TO naqia_dev_rw;
GRANT SELECT ON TABLE public.final_names TO haider_qa;


--
-- TOC entry 9960 (class 0 OID 0)
-- Dependencies: 330
-- Name: TABLE final_names1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.final_names1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.final_names1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.final_names1 TO haider_qa;


--
-- TOC entry 9961 (class 0 OID 0)
-- Dependencies: 331
-- Name: TABLE forum_hide_posts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_hide_posts TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_hide_posts TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_hide_posts TO haider_qa;


--
-- TOC entry 9962 (class 0 OID 0)
-- Dependencies: 656
-- Name: TABLE forum_hide_posts_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_hide_posts_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_hide_posts_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_hide_posts_copy1 TO haider_qa;


--
-- TOC entry 9964 (class 0 OID 0)
-- Dependencies: 332
-- Name: SEQUENCE forum_hide_posts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_hide_posts_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_hide_posts_id_seq TO naqia_dev_rw;


--
-- TOC entry 9965 (class 0 OID 0)
-- Dependencies: 333
-- Name: TABLE forum_hide_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_hide_users TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_hide_users TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_hide_users TO haider_qa;


--
-- TOC entry 9966 (class 0 OID 0)
-- Dependencies: 657
-- Name: TABLE forum_hide_users_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_hide_users_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_hide_users_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_hide_users_copy1 TO haider_qa;


--
-- TOC entry 9968 (class 0 OID 0)
-- Dependencies: 334
-- Name: SEQUENCE forum_hide_users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_hide_users_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_hide_users_id_seq TO naqia_dev_rw;


--
-- TOC entry 9969 (class 0 OID 0)
-- Dependencies: 335
-- Name: TABLE forum_media; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_media TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_media TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_media TO haider_qa;


--
-- TOC entry 9970 (class 0 OID 0)
-- Dependencies: 658
-- Name: TABLE forum_media_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_media_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_media_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_media_copy1 TO haider_qa;


--
-- TOC entry 9972 (class 0 OID 0)
-- Dependencies: 336
-- Name: SEQUENCE forum_media_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_media_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_media_id_seq TO naqia_dev_rw;


--
-- TOC entry 9973 (class 0 OID 0)
-- Dependencies: 774
-- Name: TABLE forum_post_rejection_reasons; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_post_rejection_reasons TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_post_rejection_reasons TO haider_qa;


--
-- TOC entry 9974 (class 0 OID 0)
-- Dependencies: 337
-- Name: TABLE forum_posts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_posts TO haider_qa;


--
-- TOC entry 9975 (class 0 OID 0)
-- Dependencies: 659
-- Name: TABLE forum_posts_cc; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts_cc TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts_cc TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_posts_cc TO haider_qa;


--
-- TOC entry 9977 (class 0 OID 0)
-- Dependencies: 338
-- Name: SEQUENCE forum_posts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_posts_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_posts_id_seq TO naqia_dev_rw;


--
-- TOC entry 9978 (class 0 OID 0)
-- Dependencies: 339
-- Name: TABLE forum_posts_rejected; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts_rejected TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts_rejected TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_posts_rejected TO haider_qa;


--
-- TOC entry 9979 (class 0 OID 0)
-- Dependencies: 660
-- Name: TABLE forum_posts_rejected_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts_rejected_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts_rejected_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_posts_rejected_copy1 TO haider_qa;


--
-- TOC entry 9980 (class 0 OID 0)
-- Dependencies: 686
-- Name: TABLE forum_posts_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts_tags TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_posts_tags TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_posts_tags TO haider_qa;


--
-- TOC entry 9981 (class 0 OID 0)
-- Dependencies: 799
-- Name: TABLE forum_posts_views_shares; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.forum_posts_views_shares TO haider_qa;


--
-- TOC entry 9982 (class 0 OID 0)
-- Dependencies: 340
-- Name: TABLE forum_report_posts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_posts TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_posts TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_report_posts TO haider_qa;


--
-- TOC entry 9983 (class 0 OID 0)
-- Dependencies: 661
-- Name: TABLE forum_report_posts_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_posts_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_posts_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_report_posts_copy1 TO haider_qa;


--
-- TOC entry 9985 (class 0 OID 0)
-- Dependencies: 341
-- Name: SEQUENCE forum_report_posts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_report_posts_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_report_posts_id_seq TO naqia_dev_rw;


--
-- TOC entry 9986 (class 0 OID 0)
-- Dependencies: 342
-- Name: TABLE forum_report_reason_actions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_reason_actions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_reason_actions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_report_reason_actions TO haider_qa;


--
-- TOC entry 9987 (class 0 OID 0)
-- Dependencies: 662
-- Name: TABLE forum_report_reason_actions_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_reason_actions_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_reason_actions_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_report_reason_actions_copy1 TO haider_qa;


--
-- TOC entry 9989 (class 0 OID 0)
-- Dependencies: 343
-- Name: SEQUENCE forum_report_reason_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_report_reason_actions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_report_reason_actions_id_seq TO naqia_dev_rw;


--
-- TOC entry 9990 (class 0 OID 0)
-- Dependencies: 344
-- Name: TABLE forum_report_reasons; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_reasons TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_reasons TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_report_reasons TO haider_qa;


--
-- TOC entry 9991 (class 0 OID 0)
-- Dependencies: 663
-- Name: TABLE forum_report_reasons_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_reasons_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_reasons_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_report_reasons_copy1 TO haider_qa;


--
-- TOC entry 9993 (class 0 OID 0)
-- Dependencies: 345
-- Name: SEQUENCE forum_report_reasons_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_report_reasons_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_report_reasons_id_seq TO naqia_dev_rw;


--
-- TOC entry 9994 (class 0 OID 0)
-- Dependencies: 346
-- Name: TABLE forum_report_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_users TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_users TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_report_users TO haider_qa;


--
-- TOC entry 9995 (class 0 OID 0)
-- Dependencies: 664
-- Name: TABLE forum_report_users_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_users_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_report_users_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_report_users_copy1 TO haider_qa;


--
-- TOC entry 9997 (class 0 OID 0)
-- Dependencies: 347
-- Name: SEQUENCE forum_report_users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_report_users_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_report_users_id_seq TO naqia_dev_rw;


--
-- TOC entry 9998 (class 0 OID 0)
-- Dependencies: 348
-- Name: TABLE forum_user_agreements; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_user_agreements TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_user_agreements TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_user_agreements TO haider_qa;


--
-- TOC entry 9999 (class 0 OID 0)
-- Dependencies: 665
-- Name: TABLE forum_user_agreements_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_user_agreements_copy1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.forum_user_agreements_copy1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.forum_user_agreements_copy1 TO haider_qa;


--
-- TOC entry 10000 (class 0 OID 0)
-- Dependencies: 349
-- Name: SEQUENCE forum_user_agreements_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.forum_user_agreements_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.forum_user_agreements_id_seq TO naqia_dev_rw;


--
-- TOC entry 10001 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE geography_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.geography_columns TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.geography_columns TO naqia_dev_rw;
GRANT SELECT ON TABLE public.geography_columns TO haider_qa;


--
-- TOC entry 10002 (class 0 OID 0)
-- Dependencies: 209
-- Name: TABLE geometry_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.geometry_columns TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.geometry_columns TO naqia_dev_rw;
GRANT SELECT ON TABLE public.geometry_columns TO haider_qa;


--
-- TOC entry 10003 (class 0 OID 0)
-- Dependencies: 350
-- Name: TABLE gmlc_check; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.gmlc_check TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.gmlc_check TO naqia_dev_rw;
GRANT SELECT ON TABLE public.gmlc_check TO haider_qa;


--
-- TOC entry 10004 (class 0 OID 0)
-- Dependencies: 666
-- Name: TABLE gsma_advisory_2022_02_22; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.gsma_advisory_2022_02_22 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.gsma_advisory_2022_02_22 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.gsma_advisory_2022_02_22 TO haider_qa;


--
-- TOC entry 10005 (class 0 OID 0)
-- Dependencies: 351
-- Name: TABLE gsma_base_advisory; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.gsma_base_advisory TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.gsma_base_advisory TO naqia_dev_rw;
GRANT SELECT ON TABLE public.gsma_base_advisory TO haider_qa;


--
-- TOC entry 10006 (class 0 OID 0)
-- Dependencies: 352
-- Name: TABLE haseeb_testing_profile; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.haseeb_testing_profile TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.haseeb_testing_profile TO naqia_dev_rw;
GRANT SELECT ON TABLE public.haseeb_testing_profile TO haider_qa;


--
-- TOC entry 10007 (class 0 OID 0)
-- Dependencies: 353
-- Name: TABLE he_alerts_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.he_alerts_data TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.he_alerts_data TO naqia_dev_rw;
GRANT SELECT ON TABLE public.he_alerts_data TO haider_qa;


--
-- TOC entry 10008 (class 0 OID 0)
-- Dependencies: 354
-- Name: TABLE he_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.he_data TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.he_data TO naqia_dev_rw;
GRANT SELECT ON TABLE public.he_data TO haider_qa;


--
-- TOC entry 10018 (class 0 OID 0)
-- Dependencies: 355
-- Name: TABLE stats_notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.stats_notifications TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.stats_notifications TO naqia_dev_rw;
GRANT SELECT ON TABLE public.stats_notifications TO haider_qa;


--
-- TOC entry 10020 (class 0 OID 0)
-- Dependencies: 356
-- Name: SEQUENCE hourly_stat_receivers_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.hourly_stat_receivers_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.hourly_stat_receivers_id_seq TO naqia_dev_rw;


--
-- TOC entry 10021 (class 0 OID 0)
-- Dependencies: 357
-- Name: TABLE in_app_notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.in_app_notifications TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.in_app_notifications TO naqia_dev_rw;
GRANT SELECT ON TABLE public.in_app_notifications TO haider_qa;


--
-- TOC entry 10023 (class 0 OID 0)
-- Dependencies: 358
-- Name: SEQUENCE in_app_notifications_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.in_app_notifications_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.in_app_notifications_id_seq TO naqia_dev_rw;


--
-- TOC entry 10024 (class 0 OID 0)
-- Dependencies: 359
-- Name: TABLE incentive_transactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.incentive_transactions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.incentive_transactions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.incentive_transactions TO haider_qa;


--
-- TOC entry 10026 (class 0 OID 0)
-- Dependencies: 360
-- Name: SEQUENCE incentive_transactions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.incentive_transactions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.incentive_transactions_id_seq TO naqia_dev_rw;


--
-- TOC entry 10027 (class 0 OID 0)
-- Dependencies: 361
-- Name: TABLE incentive_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.incentive_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.incentive_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.incentive_types TO haider_qa;


--
-- TOC entry 10029 (class 0 OID 0)
-- Dependencies: 362
-- Name: SEQUENCE incentive_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.incentive_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.incentive_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10030 (class 0 OID 0)
-- Dependencies: 667
-- Name: TABLE interests; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.interests TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.interests TO naqia_dev_rw;
GRANT SELECT ON TABLE public.interests TO haider_qa;


--
-- TOC entry 10031 (class 0 OID 0)
-- Dependencies: 363
-- Name: TABLE irrigation_sources; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.irrigation_sources TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.irrigation_sources TO naqia_dev_rw;
GRANT SELECT ON TABLE public.irrigation_sources TO haider_qa;


--
-- TOC entry 10033 (class 0 OID 0)
-- Dependencies: 364
-- Name: SEQUENCE irrigation_source_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.irrigation_source_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.irrigation_source_id_seq TO naqia_dev_rw;


--
-- TOC entry 10034 (class 0 OID 0)
-- Dependencies: 365
-- Name: TABLE isl_weather_subs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.isl_weather_subs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.isl_weather_subs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.isl_weather_subs TO haider_qa;


--
-- TOC entry 10035 (class 0 OID 0)
-- Dependencies: 366
-- Name: TABLE ivr_activities; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ivr_activities TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ivr_activities TO naqia_dev_rw;
GRANT SELECT ON TABLE public.ivr_activities TO haider_qa;


--
-- TOC entry 10036 (class 0 OID 0)
-- Dependencies: 367
-- Name: TABLE ivr_paths; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ivr_paths TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ivr_paths TO naqia_dev_rw;
GRANT SELECT ON TABLE public.ivr_paths TO haider_qa;


--
-- TOC entry 10038 (class 0 OID 0)
-- Dependencies: 368
-- Name: SEQUENCE ivr_paths_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.ivr_paths_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.ivr_paths_id_seq TO naqia_dev_rw;


--
-- TOC entry 10039 (class 0 OID 0)
-- Dependencies: 369
-- Name: TABLE ivr_sessions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ivr_sessions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ivr_sessions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.ivr_sessions TO haider_qa;


--
-- TOC entry 10041 (class 0 OID 0)
-- Dependencies: 370
-- Name: SEQUENCE ivr_sessions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.ivr_sessions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.ivr_sessions_id_seq TO naqia_dev_rw;


--
-- TOC entry 10042 (class 0 OID 0)
-- Dependencies: 371
-- Name: TABLE jazz_op_check; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.jazz_op_check TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.jazz_op_check TO naqia_dev_rw;
GRANT SELECT ON TABLE public.jazz_op_check TO haider_qa;


--
-- TOC entry 10043 (class 0 OID 0)
-- Dependencies: 372
-- Name: TABLE jazz_other; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.jazz_other TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.jazz_other TO naqia_dev_rw;
GRANT SELECT ON TABLE public.jazz_other TO haider_qa;


--
-- TOC entry 10044 (class 0 OID 0)
-- Dependencies: 794
-- Name: TABLE jazzcash_merchant_accounts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.jazzcash_merchant_accounts TO haider_qa;


--
-- TOC entry 10045 (class 0 OID 0)
-- Dependencies: 798
-- Name: TABLE jazzcash_onetime_transactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.jazzcash_onetime_transactions TO haider_qa;


--
-- TOC entry 10046 (class 0 OID 0)
-- Dependencies: 797
-- Name: TABLE jazzcash_recurring_transactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.jazzcash_recurring_transactions TO haider_qa;


--
-- TOC entry 10047 (class 0 OID 0)
-- Dependencies: 793
-- Name: TABLE jazzcash_user_accounts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.jazzcash_user_accounts TO haider_qa;


--
-- TOC entry 10048 (class 0 OID 0)
-- Dependencies: 796
-- Name: TABLE jazzcash_user_wallet_transactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.jazzcash_user_wallet_transactions TO haider_qa;


--
-- TOC entry 10049 (class 0 OID 0)
-- Dependencies: 795
-- Name: TABLE jazzcash_user_wallets; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.jazzcash_user_wallets TO haider_qa;


--
-- TOC entry 10050 (class 0 OID 0)
-- Dependencies: 636
-- Name: TABLE job_executor_stats; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_executor_stats TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_executor_stats TO naqia_dev_rw;
GRANT SELECT ON TABLE public.job_executor_stats TO haider_qa;


--
-- TOC entry 10051 (class 0 OID 0)
-- Dependencies: 828
-- Name: TABLE job_logs_2025_07_24; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_07_24 TO haider_qa;


--
-- TOC entry 10052 (class 0 OID 0)
-- Dependencies: 829
-- Name: TABLE job_logs_2025_07_25; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_07_25 TO haider_qa;


--
-- TOC entry 10053 (class 0 OID 0)
-- Dependencies: 830
-- Name: TABLE job_logs_2025_07_26; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_07_26 TO haider_qa;


--
-- TOC entry 10054 (class 0 OID 0)
-- Dependencies: 831
-- Name: TABLE job_logs_2025_07_27; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_07_27 TO haider_qa;


--
-- TOC entry 10055 (class 0 OID 0)
-- Dependencies: 832
-- Name: TABLE job_logs_2025_07_28; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_07_28 TO haider_qa;


--
-- TOC entry 10056 (class 0 OID 0)
-- Dependencies: 833
-- Name: TABLE job_logs_2025_07_29; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_07_29 TO haider_qa;


--
-- TOC entry 10057 (class 0 OID 0)
-- Dependencies: 834
-- Name: TABLE job_logs_2025_07_30; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_07_30 TO haider_qa;


--
-- TOC entry 10058 (class 0 OID 0)
-- Dependencies: 835
-- Name: TABLE job_logs_2025_07_31; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_07_31 TO haider_qa;


--
-- TOC entry 10059 (class 0 OID 0)
-- Dependencies: 837
-- Name: TABLE job_logs_2025_08_13; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_08_13 TO haider_qa;


--
-- TOC entry 10060 (class 0 OID 0)
-- Dependencies: 838
-- Name: TABLE job_logs_2025_08_14; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_08_14 TO haider_qa;


--
-- TOC entry 10061 (class 0 OID 0)
-- Dependencies: 839
-- Name: TABLE job_logs_2025_08_15; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.job_logs_2025_08_15 TO haider_qa;


--
-- TOC entry 10062 (class 0 OID 0)
-- Dependencies: 631
-- Name: TABLE job_operators; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_operators TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_operators TO naqia_dev_rw;
GRANT SELECT ON TABLE public.job_operators TO haider_qa;


--
-- TOC entry 10063 (class 0 OID 0)
-- Dependencies: 632
-- Name: TABLE job_state_flow; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_state_flow TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_state_flow TO naqia_dev_rw;
GRANT SELECT ON TABLE public.job_state_flow TO haider_qa;


--
-- TOC entry 10065 (class 0 OID 0)
-- Dependencies: 633
-- Name: SEQUENCE job_state_flow_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.job_state_flow_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.job_state_flow_id_seq TO naqia_dev_rw;


--
-- TOC entry 10066 (class 0 OID 0)
-- Dependencies: 634
-- Name: TABLE job_statuses; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_statuses TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_statuses TO naqia_dev_rw;
GRANT SELECT ON TABLE public.job_statuses TO haider_qa;


--
-- TOC entry 10067 (class 0 OID 0)
-- Dependencies: 635
-- Name: TABLE job_testing_msisdns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_testing_msisdns TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_testing_msisdns TO naqia_dev_rw;
GRANT SELECT ON TABLE public.job_testing_msisdns TO haider_qa;


--
-- TOC entry 10068 (class 0 OID 0)
-- Dependencies: 630
-- Name: TABLE job_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.job_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.job_types TO haider_qa;


--
-- TOC entry 10069 (class 0 OID 0)
-- Dependencies: 373
-- Name: TABLE jobs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.jobs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.jobs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.jobs TO haider_qa;


--
-- TOC entry 10070 (class 0 OID 0)
-- Dependencies: 374
-- Name: SEQUENCE jobs_v2_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.jobs_v2_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.jobs_v2_id_seq TO naqia_dev_rw;


--
-- TOC entry 10071 (class 0 OID 0)
-- Dependencies: 826
-- Name: TABLE khasra; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.khasra TO haider_qa;


--
-- TOC entry 10072 (class 0 OID 0)
-- Dependencies: 375
-- Name: TABLE land_topography; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.land_topography TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.land_topography TO naqia_dev_rw;
GRANT SELECT ON TABLE public.land_topography TO haider_qa;


--
-- TOC entry 10074 (class 0 OID 0)
-- Dependencies: 376
-- Name: SEQUENCE land_topography_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.land_topography_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.land_topography_id_seq TO naqia_dev_rw;


--
-- TOC entry 10075 (class 0 OID 0)
-- Dependencies: 377
-- Name: TABLE languages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.languages TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.languages TO naqia_dev_rw;
GRANT SELECT ON TABLE public.languages TO haider_qa;


--
-- TOC entry 10077 (class 0 OID 0)
-- Dependencies: 378
-- Name: SEQUENCE languages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.languages_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.languages_id_seq TO naqia_dev_rw;


--
-- TOC entry 10078 (class 0 OID 0)
-- Dependencies: 379
-- Name: TABLE livestock_breeds; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_breeds TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_breeds TO naqia_dev_rw;
GRANT SELECT ON TABLE public.livestock_breeds TO haider_qa;


--
-- TOC entry 10080 (class 0 OID 0)
-- Dependencies: 380
-- Name: SEQUENCE livestock_breeds__id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_breeds__id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestock_breeds__id_seq TO naqia_dev_rw;


--
-- TOC entry 10081 (class 0 OID 0)
-- Dependencies: 381
-- Name: TABLE livestock_disease; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_disease TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_disease TO naqia_dev_rw;
GRANT SELECT ON TABLE public.livestock_disease TO haider_qa;


--
-- TOC entry 10083 (class 0 OID 0)
-- Dependencies: 382
-- Name: SEQUENCE livestock_disease_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_disease_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestock_disease_id_seq TO naqia_dev_rw;


--
-- TOC entry 10084 (class 0 OID 0)
-- Dependencies: 792
-- Name: TABLE livestock_farm_livestocks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.livestock_farm_livestocks TO haider_qa;


--
-- TOC entry 10085 (class 0 OID 0)
-- Dependencies: 383
-- Name: TABLE livestock_farming_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_farming_categories TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_farming_categories TO naqia_dev_rw;
GRANT SELECT ON TABLE public.livestock_farming_categories TO haider_qa;


--
-- TOC entry 10087 (class 0 OID 0)
-- Dependencies: 384
-- Name: SEQUENCE livestock_farming_category_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_farming_category_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestock_farming_category_id_seq TO naqia_dev_rw;


--
-- TOC entry 10088 (class 0 OID 0)
-- Dependencies: 791
-- Name: TABLE livestock_farms; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.livestock_farms TO haider_qa;


--
-- TOC entry 10089 (class 0 OID 0)
-- Dependencies: 385
-- Name: TABLE livestock_management; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_management TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_management TO naqia_dev_rw;
GRANT SELECT ON TABLE public.livestock_management TO haider_qa;


--
-- TOC entry 10091 (class 0 OID 0)
-- Dependencies: 386
-- Name: SEQUENCE livestock_management_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_management_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestock_management_id_seq TO naqia_dev_rw;


--
-- TOC entry 10092 (class 0 OID 0)
-- Dependencies: 387
-- Name: TABLE livestock_nutrition; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_nutrition TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_nutrition TO naqia_dev_rw;
GRANT SELECT ON TABLE public.livestock_nutrition TO haider_qa;


--
-- TOC entry 10094 (class 0 OID 0)
-- Dependencies: 388
-- Name: SEQUENCE livestock_nutrition_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_nutrition_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestock_nutrition_id_seq TO naqia_dev_rw;


--
-- TOC entry 10095 (class 0 OID 0)
-- Dependencies: 389
-- Name: TABLE livestock_purpose; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_purpose TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_purpose TO naqia_dev_rw;
GRANT SELECT ON TABLE public.livestock_purpose TO haider_qa;


--
-- TOC entry 10097 (class 0 OID 0)
-- Dependencies: 390
-- Name: SEQUENCE livestock_purpose_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_purpose_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestock_purpose_id_seq TO naqia_dev_rw;


--
-- TOC entry 10098 (class 0 OID 0)
-- Dependencies: 391
-- Name: TABLE livestock_stage; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_stage TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestock_stage TO naqia_dev_rw;
GRANT SELECT ON TABLE public.livestock_stage TO haider_qa;


--
-- TOC entry 10100 (class 0 OID 0)
-- Dependencies: 392
-- Name: SEQUENCE livestock_stage_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_stage_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestock_stage_id_seq TO naqia_dev_rw;


--
-- TOC entry 10102 (class 0 OID 0)
-- Dependencies: 393
-- Name: SEQUENCE livestock_tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestock_tags_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestock_tags_id_seq TO naqia_dev_rw;


--
-- TOC entry 10103 (class 0 OID 0)
-- Dependencies: 394
-- Name: TABLE livestocks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestocks TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.livestocks TO naqia_dev_rw;
GRANT SELECT ON TABLE public.livestocks TO haider_qa;


--
-- TOC entry 10105 (class 0 OID 0)
-- Dependencies: 395
-- Name: SEQUENCE livestocks_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.livestocks_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.livestocks_id_seq TO naqia_dev_rw;


--
-- TOC entry 10106 (class 0 OID 0)
-- Dependencies: 396
-- Name: TABLE loan_agreement_docs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_agreement_docs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_agreement_docs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_agreement_docs TO haider_qa;


--
-- TOC entry 10107 (class 0 OID 0)
-- Dependencies: 397
-- Name: SEQUENCE loan_agreement_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_agreement_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.loan_agreement_id_seq TO naqia_dev_rw;


--
-- TOC entry 10108 (class 0 OID 0)
-- Dependencies: 398
-- Name: TABLE loan_applications; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_applications TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_applications TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_applications TO haider_qa;


--
-- TOC entry 10110 (class 0 OID 0)
-- Dependencies: 399
-- Name: SEQUENCE loan_application_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_application_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.loan_application_id_seq TO naqia_dev_rw;


--
-- TOC entry 10111 (class 0 OID 0)
-- Dependencies: 400
-- Name: TABLE loan_partners; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_partners TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_partners TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_partners TO haider_qa;


--
-- TOC entry 10113 (class 0 OID 0)
-- Dependencies: 401
-- Name: SEQUENCE loan_partners_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_partners_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.loan_partners_id_seq TO naqia_dev_rw;


--
-- TOC entry 10114 (class 0 OID 0)
-- Dependencies: 402
-- Name: TABLE loan_payment_modes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_payment_modes TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_payment_modes TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_payment_modes TO haider_qa;


--
-- TOC entry 10116 (class 0 OID 0)
-- Dependencies: 403
-- Name: SEQUENCE loan_payment_modes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_payment_modes_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.loan_payment_modes_id_seq TO naqia_dev_rw;


--
-- TOC entry 10117 (class 0 OID 0)
-- Dependencies: 404
-- Name: TABLE loan_procurement_docs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_procurement_docs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_procurement_docs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_procurement_docs TO haider_qa;


--
-- TOC entry 10119 (class 0 OID 0)
-- Dependencies: 405
-- Name: SEQUENCE loan_procurement_attachments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_procurement_attachments_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.loan_procurement_attachments_id_seq TO naqia_dev_rw;


--
-- TOC entry 10120 (class 0 OID 0)
-- Dependencies: 406
-- Name: TABLE loan_procurements; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_procurements TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_procurements TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_procurements TO haider_qa;


--
-- TOC entry 10122 (class 0 OID 0)
-- Dependencies: 407
-- Name: SEQUENCE loan_procurements_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_procurements_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.loan_procurements_id_seq TO naqia_dev_rw;


--
-- TOC entry 10123 (class 0 OID 0)
-- Dependencies: 408
-- Name: TABLE loan_transactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_transactions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_transactions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_transactions TO haider_qa;


--
-- TOC entry 10124 (class 0 OID 0)
-- Dependencies: 409
-- Name: TABLE loan_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.loan_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.loan_types TO haider_qa;


--
-- TOC entry 10126 (class 0 OID 0)
-- Dependencies: 410
-- Name: SEQUENCE loan_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.loan_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.loan_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10127 (class 0 OID 0)
-- Dependencies: 411
-- Name: TABLE location_crops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.location_crops TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.location_crops TO naqia_dev_rw;
GRANT SELECT ON TABLE public.location_crops TO haider_qa;


--
-- TOC entry 10129 (class 0 OID 0)
-- Dependencies: 412
-- Name: SEQUENCE location_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.location_crops_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.location_crops_id_seq TO naqia_dev_rw;


--
-- TOC entry 10130 (class 0 OID 0)
-- Dependencies: 413
-- Name: TABLE location_livestocks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.location_livestocks TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.location_livestocks TO naqia_dev_rw;
GRANT SELECT ON TABLE public.location_livestocks TO haider_qa;


--
-- TOC entry 10132 (class 0 OID 0)
-- Dependencies: 414
-- Name: SEQUENCE location_livestocks_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.location_livestocks_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.location_livestocks_id_seq TO naqia_dev_rw;


--
-- TOC entry 10133 (class 0 OID 0)
-- Dependencies: 415
-- Name: TABLE location_machineries; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.location_machineries TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.location_machineries TO naqia_dev_rw;
GRANT SELECT ON TABLE public.location_machineries TO haider_qa;


--
-- TOC entry 10135 (class 0 OID 0)
-- Dependencies: 416
-- Name: SEQUENCE location_machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.location_machineries_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.location_machineries_id_seq TO naqia_dev_rw;


--
-- TOC entry 10136 (class 0 OID 0)
-- Dependencies: 668
-- Name: TABLE location_temp; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.location_temp TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.location_temp TO naqia_dev_rw;
GRANT SELECT ON TABLE public.location_temp TO haider_qa;


--
-- TOC entry 10137 (class 0 OID 0)
-- Dependencies: 417
-- Name: SEQUENCE location_v2_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.location_v2_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.location_v2_id_seq TO naqia_dev_rw;


--
-- TOC entry 10138 (class 0 OID 0)
-- Dependencies: 827
-- Name: TABLE locations_copy1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.locations_copy1 TO haider_qa;


--
-- TOC entry 10139 (class 0 OID 0)
-- Dependencies: 419
-- Name: TABLE machineries; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.machineries TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.machineries TO naqia_dev_rw;
GRANT SELECT ON TABLE public.machineries TO haider_qa;


--
-- TOC entry 10141 (class 0 OID 0)
-- Dependencies: 420
-- Name: SEQUENCE machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.machineries_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.machineries_id_seq TO naqia_dev_rw;


--
-- TOC entry 10142 (class 0 OID 0)
-- Dependencies: 421
-- Name: TABLE machinery_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.machinery_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.machinery_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.machinery_types TO haider_qa;


--
-- TOC entry 10144 (class 0 OID 0)
-- Dependencies: 422
-- Name: SEQUENCE machinery_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.machinery_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.machinery_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10145 (class 0 OID 0)
-- Dependencies: 423
-- Name: TABLE mandi_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_categories TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_categories TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mandi_categories TO haider_qa;


--
-- TOC entry 10147 (class 0 OID 0)
-- Dependencies: 424
-- Name: SEQUENCE mandi_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_categories_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mandi_categories_id_seq TO naqia_dev_rw;


--
-- TOC entry 10148 (class 0 OID 0)
-- Dependencies: 425
-- Name: TABLE mandi_listing_images; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_listing_images TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_listing_images TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mandi_listing_images TO haider_qa;


--
-- TOC entry 10150 (class 0 OID 0)
-- Dependencies: 426
-- Name: SEQUENCE mandi_listing_images_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_listing_images_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mandi_listing_images_id_seq TO naqia_dev_rw;


--
-- TOC entry 10151 (class 0 OID 0)
-- Dependencies: 427
-- Name: TABLE mandi_listing_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_listing_tags TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_listing_tags TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mandi_listing_tags TO haider_qa;


--
-- TOC entry 10153 (class 0 OID 0)
-- Dependencies: 428
-- Name: SEQUENCE mandi_listing_tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_listing_tags_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mandi_listing_tags_id_seq TO naqia_dev_rw;


--
-- TOC entry 10154 (class 0 OID 0)
-- Dependencies: 429
-- Name: TABLE mandi_listings; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_listings TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_listings TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mandi_listings TO haider_qa;


--
-- TOC entry 10156 (class 0 OID 0)
-- Dependencies: 430
-- Name: SEQUENCE mandi_listings_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_listings_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mandi_listings_id_seq TO naqia_dev_rw;


--
-- TOC entry 10157 (class 0 OID 0)
-- Dependencies: 431
-- Name: TABLE mandi_listings_meta_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_listings_meta_data TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_listings_meta_data TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mandi_listings_meta_data TO haider_qa;


--
-- TOC entry 10159 (class 0 OID 0)
-- Dependencies: 432
-- Name: SEQUENCE mandi_listings_meta_data_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_listings_meta_data_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mandi_listings_meta_data_id_seq TO naqia_dev_rw;


--
-- TOC entry 10160 (class 0 OID 0)
-- Dependencies: 433
-- Name: TABLE mandi_reviews; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_reviews TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mandi_reviews TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mandi_reviews TO haider_qa;


--
-- TOC entry 10162 (class 0 OID 0)
-- Dependencies: 434
-- Name: SEQUENCE mandi_reviews_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mandi_reviews_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mandi_reviews_id_seq TO naqia_dev_rw;


--
-- TOC entry 10163 (class 0 OID 0)
-- Dependencies: 435
-- Name: TABLE master_dncr; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.master_dncr TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.master_dncr TO naqia_dev_rw;
GRANT SELECT ON TABLE public.master_dncr TO haider_qa;


--
-- TOC entry 10165 (class 0 OID 0)
-- Dependencies: 752
-- Name: SEQUENCE menu_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_crops_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.menu_crops_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.menu_crops_id_seq TO naqia_dev_rw;


--
-- TOC entry 10167 (class 0 OID 0)
-- Dependencies: 757
-- Name: SEQUENCE menu_languages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_languages_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.menu_languages_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.menu_languages_id_seq TO naqia_dev_rw;


--
-- TOC entry 10169 (class 0 OID 0)
-- Dependencies: 759
-- Name: SEQUENCE menu_livestocks_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_livestocks_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.menu_livestocks_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.menu_livestocks_id_seq TO naqia_dev_rw;


--
-- TOC entry 10171 (class 0 OID 0)
-- Dependencies: 761
-- Name: SEQUENCE menu_locations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_locations_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.menu_locations_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.menu_locations_id_seq TO naqia_dev_rw;


--
-- TOC entry 10173 (class 0 OID 0)
-- Dependencies: 763
-- Name: SEQUENCE menu_machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.menu_machineries_id_seq TO bkkdev_rw;
GRANT USAGE ON SEQUENCE public.menu_machineries_id_seq TO ateebqa_rw;
GRANT SELECT,USAGE ON SEQUENCE public.menu_machineries_id_seq TO naqia_dev_rw;


--
-- TOC entry 10174 (class 0 OID 0)
-- Dependencies: 436
-- Name: TABLE mmbl_base; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_base TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_base TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mmbl_base TO haider_qa;


--
-- TOC entry 10175 (class 0 OID 0)
-- Dependencies: 437
-- Name: TABLE mmbl_base_alisufi; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_base_alisufi TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_base_alisufi TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mmbl_base_alisufi TO haider_qa;


--
-- TOC entry 10176 (class 0 OID 0)
-- Dependencies: 438
-- Name: TABLE mmbl_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_data TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_data TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mmbl_data TO haider_qa;


--
-- TOC entry 10177 (class 0 OID 0)
-- Dependencies: 439
-- Name: TABLE mmbl_incorrect_tagging; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_incorrect_tagging TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_incorrect_tagging TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mmbl_incorrect_tagging TO haider_qa;


--
-- TOC entry 10178 (class 0 OID 0)
-- Dependencies: 440
-- Name: TABLE mmbl_test; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_test TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_test TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mmbl_test TO haider_qa;


--
-- TOC entry 10179 (class 0 OID 0)
-- Dependencies: 441
-- Name: TABLE mmbl_transaction_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_transaction_logs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mmbl_transaction_logs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mmbl_transaction_logs TO haider_qa;


--
-- TOC entry 10181 (class 0 OID 0)
-- Dependencies: 442
-- Name: SEQUENCE mmbl_transaction_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mmbl_transaction_logs_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mmbl_transaction_logs_id_seq TO naqia_dev_rw;


--
-- TOC entry 10182 (class 0 OID 0)
-- Dependencies: 443
-- Name: TABLE mo_sms; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mo_sms TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mo_sms TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mo_sms TO haider_qa;


--
-- TOC entry 10183 (class 0 OID 0)
-- Dependencies: 825
-- Name: TABLE mouza; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.mouza TO haider_qa;


--
-- TOC entry 10184 (class 0 OID 0)
-- Dependencies: 444
-- Name: TABLE mp_crop_diseases; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mp_crop_diseases TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mp_crop_diseases TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mp_crop_diseases TO haider_qa;


--
-- TOC entry 10186 (class 0 OID 0)
-- Dependencies: 445
-- Name: SEQUENCE mp_crop_crop_diseases_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mp_crop_crop_diseases_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mp_crop_crop_diseases_id_seq TO naqia_dev_rw;


--
-- TOC entry 10187 (class 0 OID 0)
-- Dependencies: 446
-- Name: TABLE mp_livestock_disease; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mp_livestock_disease TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mp_livestock_disease TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mp_livestock_disease TO haider_qa;


--
-- TOC entry 10189 (class 0 OID 0)
-- Dependencies: 447
-- Name: SEQUENCE mp_livestock_disease_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mp_livestock_disease_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mp_livestock_disease_id_seq TO naqia_dev_rw;


--
-- TOC entry 10190 (class 0 OID 0)
-- Dependencies: 448
-- Name: TABLE mp_livestock_farming_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mp_livestock_farming_categories TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mp_livestock_farming_categories TO naqia_dev_rw;
GRANT SELECT ON TABLE public.mp_livestock_farming_categories TO haider_qa;


--
-- TOC entry 10192 (class 0 OID 0)
-- Dependencies: 449
-- Name: SEQUENCE mp_livestock_farming_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.mp_livestock_farming_categories_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.mp_livestock_farming_categories_id_seq TO naqia_dev_rw;


--
-- TOC entry 10193 (class 0 OID 0)
-- Dependencies: 450
-- Name: TABLE msisdn_tagged_as_csm1; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.msisdn_tagged_as_csm1 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.msisdn_tagged_as_csm1 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.msisdn_tagged_as_csm1 TO haider_qa;


--
-- TOC entry 10194 (class 0 OID 0)
-- Dependencies: 451
-- Name: TABLE msisdn_tagged_as_csm2; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.msisdn_tagged_as_csm2 TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.msisdn_tagged_as_csm2 TO naqia_dev_rw;
GRANT SELECT ON TABLE public.msisdn_tagged_as_csm2 TO haider_qa;


--
-- TOC entry 10195 (class 0 OID 0)
-- Dependencies: 452
-- Name: SEQUENCE my_sequence; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.my_sequence TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.my_sequence TO naqia_dev_rw;


--
-- TOC entry 10196 (class 0 OID 0)
-- Dependencies: 453
-- Name: TABLE name_suggestions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.name_suggestions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.name_suggestions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.name_suggestions TO haider_qa;


--
-- TOC entry 10197 (class 0 OID 0)
-- Dependencies: 454
-- Name: TABLE narrative_list; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.narrative_list TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.narrative_list TO naqia_dev_rw;
GRANT SELECT ON TABLE public.narrative_list TO haider_qa;


--
-- TOC entry 10199 (class 0 OID 0)
-- Dependencies: 455
-- Name: SEQUENCE narrative_list_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.narrative_list_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.narrative_list_id_seq TO naqia_dev_rw;


--
-- TOC entry 10200 (class 0 OID 0)
-- Dependencies: 456
-- Name: TABLE neighbouring_tehsils; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.neighbouring_tehsils TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.neighbouring_tehsils TO naqia_dev_rw;
GRANT SELECT ON TABLE public.neighbouring_tehsils TO haider_qa;


--
-- TOC entry 10201 (class 0 OID 0)
-- Dependencies: 457
-- Name: TABLE network_tagging; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.network_tagging TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.network_tagging TO naqia_dev_rw;
GRANT SELECT ON TABLE public.network_tagging TO haider_qa;


--
-- TOC entry 10202 (class 0 OID 0)
-- Dependencies: 458
-- Name: TABLE network_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.network_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.network_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.network_types TO haider_qa;


--
-- TOC entry 10204 (class 0 OID 0)
-- Dependencies: 459
-- Name: SEQUENCE network_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.network_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.network_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10205 (class 0 OID 0)
-- Dependencies: 806
-- Name: TABLE notification_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.notification_categories TO haider_qa;


--
-- TOC entry 10206 (class 0 OID 0)
-- Dependencies: 460
-- Name: TABLE notification_history; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notification_history TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notification_history TO naqia_dev_rw;
GRANT SELECT ON TABLE public.notification_history TO haider_qa;


--
-- TOC entry 10208 (class 0 OID 0)
-- Dependencies: 461
-- Name: SEQUENCE notification_history_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.notification_history_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.notification_history_id_seq TO naqia_dev_rw;


--
-- TOC entry 10209 (class 0 OID 0)
-- Dependencies: 462
-- Name: TABLE notification_modes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notification_modes TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notification_modes TO naqia_dev_rw;
GRANT SELECT ON TABLE public.notification_modes TO haider_qa;


--
-- TOC entry 10211 (class 0 OID 0)
-- Dependencies: 463
-- Name: SEQUENCE notification_modes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.notification_modes_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.notification_modes_id_seq TO naqia_dev_rw;


--
-- TOC entry 10212 (class 0 OID 0)
-- Dependencies: 464
-- Name: TABLE notification_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notification_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notification_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.notification_types TO haider_qa;


--
-- TOC entry 10214 (class 0 OID 0)
-- Dependencies: 465
-- Name: SEQUENCE notification_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.notification_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.notification_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10215 (class 0 OID 0)
-- Dependencies: 466
-- Name: TABLE notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notifications TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.notifications TO naqia_dev_rw;
GRANT SELECT ON TABLE public.notifications TO haider_qa;


--
-- TOC entry 10217 (class 0 OID 0)
-- Dependencies: 467
-- Name: SEQUENCE notifications_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.notifications_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.notifications_id_seq TO naqia_dev_rw;


--
-- TOC entry 10218 (class 0 OID 0)
-- Dependencies: 468
-- Name: TABLE nutrient_deficiency; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.nutrient_deficiency TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.nutrient_deficiency TO naqia_dev_rw;
GRANT SELECT ON TABLE public.nutrient_deficiency TO haider_qa;


--
-- TOC entry 10220 (class 0 OID 0)
-- Dependencies: 469
-- Name: SEQUENCE nutrient_deficiency_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.nutrient_deficiency_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.nutrient_deficiency_id_seq TO naqia_dev_rw;


--
-- TOC entry 10221 (class 0 OID 0)
-- Dependencies: 470
-- Name: TABLE oauth_access_tokens; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_access_tokens TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_access_tokens TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_access_tokens TO haider_qa;


--
-- TOC entry 10223 (class 0 OID 0)
-- Dependencies: 471
-- Name: SEQUENCE oauth_access_token_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_access_token_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.oauth_access_token_id_seq TO naqia_dev_rw;


--
-- TOC entry 10224 (class 0 OID 0)
-- Dependencies: 472
-- Name: TABLE oauth_authorization_codes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_authorization_codes TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_authorization_codes TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_authorization_codes TO haider_qa;


--
-- TOC entry 10226 (class 0 OID 0)
-- Dependencies: 473
-- Name: SEQUENCE oauth_authorization_code_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_authorization_code_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.oauth_authorization_code_id_seq TO naqia_dev_rw;


--
-- TOC entry 10227 (class 0 OID 0)
-- Dependencies: 474
-- Name: TABLE oauth_clients; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_clients TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_clients TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_clients TO haider_qa;


--
-- TOC entry 10229 (class 0 OID 0)
-- Dependencies: 475
-- Name: SEQUENCE oauth_clients_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_clients_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.oauth_clients_id_seq TO naqia_dev_rw;


--
-- TOC entry 10230 (class 0 OID 0)
-- Dependencies: 476
-- Name: TABLE oauth_refresh_tokens; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_refresh_tokens TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_refresh_tokens TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_refresh_tokens TO haider_qa;


--
-- TOC entry 10232 (class 0 OID 0)
-- Dependencies: 477
-- Name: SEQUENCE oauth_refresh_token_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_refresh_token_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.oauth_refresh_token_id_seq TO naqia_dev_rw;


--
-- TOC entry 10233 (class 0 OID 0)
-- Dependencies: 478
-- Name: TABLE oauth_scopes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_scopes TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_scopes TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_scopes TO haider_qa;


--
-- TOC entry 10235 (class 0 OID 0)
-- Dependencies: 479
-- Name: SEQUENCE oauth_scopes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_scopes_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.oauth_scopes_id_seq TO naqia_dev_rw;


--
-- TOC entry 10236 (class 0 OID 0)
-- Dependencies: 480
-- Name: TABLE oauth_sessions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_sessions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_sessions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_sessions TO haider_qa;


--
-- TOC entry 10237 (class 0 OID 0)
-- Dependencies: 481
-- Name: TABLE oauth_user_client_grants; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_user_client_grants TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_user_client_grants TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_user_client_grants TO haider_qa;


--
-- TOC entry 10239 (class 0 OID 0)
-- Dependencies: 482
-- Name: SEQUENCE oauth_user_client_grants_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_user_client_grants_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.oauth_user_client_grants_id_seq TO naqia_dev_rw;


--
-- TOC entry 10240 (class 0 OID 0)
-- Dependencies: 483
-- Name: TABLE oauth_user_otp; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_user_otp TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_user_otp TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_user_otp TO haider_qa;


--
-- TOC entry 10242 (class 0 OID 0)
-- Dependencies: 484
-- Name: SEQUENCE oauth_user_otp_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.oauth_user_otp_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.oauth_user_otp_id_seq TO naqia_dev_rw;


--
-- TOC entry 10243 (class 0 OID 0)
-- Dependencies: 485
-- Name: TABLE oauth_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_users TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.oauth_users TO naqia_dev_rw;
GRANT SELECT ON TABLE public.oauth_users TO haider_qa;


--
-- TOC entry 10244 (class 0 OID 0)
-- Dependencies: 486
-- Name: TABLE obd_activities; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.obd_activities TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.obd_activities TO naqia_dev_rw;
GRANT SELECT ON TABLE public.obd_activities TO haider_qa;


--
-- TOC entry 10245 (class 0 OID 0)
-- Dependencies: 487
-- Name: TABLE occupations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.occupations TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.occupations TO naqia_dev_rw;
GRANT SELECT ON TABLE public.occupations TO haider_qa;


--
-- TOC entry 10247 (class 0 OID 0)
-- Dependencies: 488
-- Name: SEQUENCE occupations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.occupations_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.occupations_id_seq TO naqia_dev_rw;


--
-- TOC entry 10248 (class 0 OID 0)
-- Dependencies: 489
-- Name: TABLE operator_check; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.operator_check TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.operator_check TO naqia_dev_rw;
GRANT SELECT ON TABLE public.operator_check TO haider_qa;


--
-- TOC entry 10249 (class 0 OID 0)
-- Dependencies: 490
-- Name: TABLE operators; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.operators TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.operators TO naqia_dev_rw;
GRANT SELECT ON TABLE public.operators TO haider_qa;


--
-- TOC entry 10251 (class 0 OID 0)
-- Dependencies: 491
-- Name: SEQUENCE operators_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.operators_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.operators_id_seq TO naqia_dev_rw;


--
-- TOC entry 10252 (class 0 OID 0)
-- Dependencies: 804
-- Name: TABLE orders; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.orders TO haider_qa;


--
-- TOC entry 10253 (class 0 OID 0)
-- Dependencies: 836
-- Name: TABLE otp; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.otp TO haider_qa;


--
-- TOC entry 10254 (class 0 OID 0)
-- Dependencies: 802
-- Name: TABLE otp_whitelisted_numbers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.otp_whitelisted_numbers TO haider_qa;


--
-- TOC entry 10255 (class 0 OID 0)
-- Dependencies: 492
-- Name: TABLE paidwalls; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.paidwalls TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.paidwalls TO naqia_dev_rw;
GRANT SELECT ON TABLE public.paidwalls TO haider_qa;


--
-- TOC entry 10256 (class 0 OID 0)
-- Dependencies: 493
-- Name: TABLE partner_procurement; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partner_procurement TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partner_procurement TO naqia_dev_rw;
GRANT SELECT ON TABLE public.partner_procurement TO haider_qa;


--
-- TOC entry 10258 (class 0 OID 0)
-- Dependencies: 494
-- Name: SEQUENCE partner_procurement_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.partner_procurement_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.partner_procurement_id_seq TO naqia_dev_rw;


--
-- TOC entry 10259 (class 0 OID 0)
-- Dependencies: 495
-- Name: TABLE partner_services; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partner_services TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partner_services TO naqia_dev_rw;
GRANT SELECT ON TABLE public.partner_services TO haider_qa;


--
-- TOC entry 10261 (class 0 OID 0)
-- Dependencies: 496
-- Name: SEQUENCE partner_services_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.partner_services_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.partner_services_id_seq TO naqia_dev_rw;


--
-- TOC entry 10262 (class 0 OID 0)
-- Dependencies: 497
-- Name: TABLE partners; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partners TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partners TO naqia_dev_rw;
GRANT SELECT ON TABLE public.partners TO haider_qa;


--
-- TOC entry 10263 (class 0 OID 0)
-- Dependencies: 498
-- Name: TABLE partners_msisdn; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partners_msisdn TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partners_msisdn TO naqia_dev_rw;
GRANT SELECT ON TABLE public.partners_msisdn TO haider_qa;


--
-- TOC entry 10264 (class 0 OID 0)
-- Dependencies: 669
-- Name: TABLE permissions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.permissions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.permissions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.permissions TO haider_qa;


--
-- TOC entry 10266 (class 0 OID 0)
-- Dependencies: 499
-- Name: SEQUENCE pests_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.pests_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.pests_id_seq TO naqia_dev_rw;


--
-- TOC entry 10267 (class 0 OID 0)
-- Dependencies: 500
-- Name: TABLE phrase_32_char_list; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.phrase_32_char_list TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.phrase_32_char_list TO naqia_dev_rw;
GRANT SELECT ON TABLE public.phrase_32_char_list TO haider_qa;


--
-- TOC entry 10269 (class 0 OID 0)
-- Dependencies: 501
-- Name: SEQUENCE phrase_32_char_list_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.phrase_32_char_list_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.phrase_32_char_list_id_seq TO naqia_dev_rw;


--
-- TOC entry 10270 (class 0 OID 0)
-- Dependencies: 789
-- Name: TABLE pin_crops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.pin_crops TO haider_qa;


--
-- TOC entry 10271 (class 0 OID 0)
-- Dependencies: 790
-- Name: TABLE pin_farms; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.pin_farms TO haider_qa;


--
-- TOC entry 10272 (class 0 OID 0)
-- Dependencies: 502
-- Name: TABLE pivot_exapmle; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pivot_exapmle TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pivot_exapmle TO naqia_dev_rw;
GRANT SELECT ON TABLE public.pivot_exapmle TO haider_qa;


--
-- TOC entry 10273 (class 0 OID 0)
-- Dependencies: 503
-- Name: TABLE player; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.player TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.player TO naqia_dev_rw;
GRANT SELECT ON TABLE public.player TO haider_qa;


--
-- TOC entry 10275 (class 0 OID 0)
-- Dependencies: 504
-- Name: SEQUENCE player_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.player_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.player_id_seq TO naqia_dev_rw;


--
-- TOC entry 10276 (class 0 OID 0)
-- Dependencies: 814
-- Name: TABLE post_anomaly; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.post_anomaly TO haider_qa;


--
-- TOC entry 10277 (class 0 OID 0)
-- Dependencies: 819
-- Name: TABLE post_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.post_status TO haider_qa;


--
-- TOC entry 10278 (class 0 OID 0)
-- Dependencies: 687
-- Name: TABLE posts_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.posts_tags TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.posts_tags TO naqia_dev_rw;
GRANT SELECT ON TABLE public.posts_tags TO haider_qa;


--
-- TOC entry 10279 (class 0 OID 0)
-- Dependencies: 505
-- Name: TABLE pro_farmer_profile_update; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pro_farmer_profile_update TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.pro_farmer_profile_update TO naqia_dev_rw;
GRANT SELECT ON TABLE public.pro_farmer_profile_update TO haider_qa;


--
-- TOC entry 10280 (class 0 OID 0)
-- Dependencies: 506
-- Name: TABLE process_partners; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.process_partners TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.process_partners TO naqia_dev_rw;
GRANT SELECT ON TABLE public.process_partners TO haider_qa;


--
-- TOC entry 10281 (class 0 OID 0)
-- Dependencies: 507
-- Name: TABLE processed_tehsils; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.processed_tehsils TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.processed_tehsils TO naqia_dev_rw;
GRANT SELECT ON TABLE public.processed_tehsils TO haider_qa;


--
-- TOC entry 10292 (class 0 OID 0)
-- Dependencies: 508
-- Name: TABLE profile_change_set; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_change_set TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_change_set TO naqia_dev_rw;
GRANT SELECT ON TABLE public.profile_change_set TO haider_qa;


--
-- TOC entry 10293 (class 0 OID 0)
-- Dependencies: 509
-- Name: TABLE profile_change_set_default; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_change_set_default TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_change_set_default TO naqia_dev_rw;
GRANT SELECT ON TABLE public.profile_change_set_default TO haider_qa;


--
-- TOC entry 10294 (class 0 OID 0)
-- Dependencies: 510
-- Name: TABLE profile_change_set_stats; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_change_set_stats TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_change_set_stats TO naqia_dev_rw;
GRANT SELECT ON TABLE public.profile_change_set_stats TO haider_qa;


--
-- TOC entry 10295 (class 0 OID 0)
-- Dependencies: 511
-- Name: TABLE profile_levels; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_levels TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_levels TO naqia_dev_rw;
GRANT SELECT ON TABLE public.profile_levels TO haider_qa;


--
-- TOC entry 10296 (class 0 OID 0)
-- Dependencies: 684
-- Name: TABLE profile_stages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_stages TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_stages TO naqia_dev_rw;
GRANT SELECT ON TABLE public.profile_stages TO haider_qa;


--
-- TOC entry 10297 (class 0 OID 0)
-- Dependencies: 512
-- Name: TABLE profile_stages_testing; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_stages_testing TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profile_stages_testing TO naqia_dev_rw;
GRANT SELECT ON TABLE public.profile_stages_testing TO haider_qa;


--
-- TOC entry 10298 (class 0 OID 0)
-- Dependencies: 638
-- Name: TABLE profiling_nps_survey; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profiling_nps_survey TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profiling_nps_survey TO naqia_dev_rw;
GRANT SELECT ON TABLE public.profiling_nps_survey TO haider_qa;


--
-- TOC entry 10299 (class 0 OID 0)
-- Dependencies: 513
-- Name: TABLE promo_data_count; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.promo_data_count TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.promo_data_count TO naqia_dev_rw;
GRANT SELECT ON TABLE public.promo_data_count TO haider_qa;


--
-- TOC entry 10300 (class 0 OID 0)
-- Dependencies: 514
-- Name: TABLE province; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.province TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.province TO naqia_dev_rw;
GRANT SELECT ON TABLE public.province TO haider_qa;


--
-- TOC entry 10301 (class 0 OID 0)
-- Dependencies: 515
-- Name: TABLE provinces; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.provinces TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.provinces TO naqia_dev_rw;
GRANT SELECT ON TABLE public.provinces TO haider_qa;


--
-- TOC entry 10302 (class 0 OID 0)
-- Dependencies: 824
-- Name: TABLE punjab_agri_profiled_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.punjab_agri_profiled_users TO haider_qa;


--
-- TOC entry 10303 (class 0 OID 0)
-- Dependencies: 816
-- Name: TABLE qrp_case_products; Type: ACL; Schema: public; Owner: rameez_dev_rw
--

GRANT SELECT ON TABLE public.qrp_case_products TO haider_qa;


--
-- TOC entry 10304 (class 0 OID 0)
-- Dependencies: 810
-- Name: TABLE qrp_cases; Type: ACL; Schema: public; Owner: rameez_dev_rw
--

GRANT SELECT ON TABLE public.qrp_cases TO haider_qa;


--
-- TOC entry 10305 (class 0 OID 0)
-- Dependencies: 812
-- Name: TABLE qrp_searches; Type: ACL; Schema: public; Owner: rameez_dev_rw
--

GRANT SELECT ON TABLE public.qrp_searches TO haider_qa;


--
-- TOC entry 10307 (class 0 OID 0)
-- Dependencies: 516
-- Name: TABLE questionair; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.questionair TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.questionair TO naqia_dev_rw;
GRANT SELECT ON TABLE public.questionair TO haider_qa;


--
-- TOC entry 10309 (class 0 OID 0)
-- Dependencies: 517
-- Name: SEQUENCE questionair_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.questionair_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.questionair_id_seq TO naqia_dev_rw;


--
-- TOC entry 10310 (class 0 OID 0)
-- Dependencies: 518
-- Name: TABLE questionair_response; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.questionair_response TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.questionair_response TO naqia_dev_rw;
GRANT SELECT ON TABLE public.questionair_response TO haider_qa;


--
-- TOC entry 10312 (class 0 OID 0)
-- Dependencies: 519
-- Name: SEQUENCE questionair_response_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.questionair_response_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.questionair_response_id_seq TO naqia_dev_rw;


--
-- TOC entry 10313 (class 0 OID 0)
-- Dependencies: 520
-- Name: TABLE queue_position; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.queue_position TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.queue_position TO naqia_dev_rw;
GRANT SELECT ON TABLE public.queue_position TO haider_qa;


--
-- TOC entry 10314 (class 0 OID 0)
-- Dependencies: 521
-- Name: SEQUENCE queue_position_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.queue_position_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.queue_position_id_seq TO naqia_dev_rw;


--
-- TOC entry 10315 (class 0 OID 0)
-- Dependencies: 522
-- Name: TABLE reapagro_promts; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reapagro_promts TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reapagro_promts TO naqia_dev_rw;
GRANT SELECT ON TABLE public.reapagro_promts TO haider_qa;


--
-- TOC entry 10316 (class 0 OID 0)
-- Dependencies: 523
-- Name: TABLE recording_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.recording_logs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.recording_logs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.recording_logs TO haider_qa;


--
-- TOC entry 10317 (class 0 OID 0)
-- Dependencies: 524
-- Name: TABLE remove_from_partners; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.remove_from_partners TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.remove_from_partners TO naqia_dev_rw;
GRANT SELECT ON TABLE public.remove_from_partners TO haider_qa;


--
-- TOC entry 10318 (class 0 OID 0)
-- Dependencies: 670
-- Name: TABLE roles_backup; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.roles_backup TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.roles_backup TO naqia_dev_rw;
GRANT SELECT ON TABLE public.roles_backup TO haider_qa;


--
-- TOC entry 10319 (class 0 OID 0)
-- Dependencies: 671
-- Name: TABLE roles_permissions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.roles_permissions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.roles_permissions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.roles_permissions TO haider_qa;


--
-- TOC entry 10320 (class 0 OID 0)
-- Dependencies: 525
-- Name: TABLE scenarios; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.scenarios TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.scenarios TO naqia_dev_rw;
GRANT SELECT ON TABLE public.scenarios TO haider_qa;


--
-- TOC entry 10322 (class 0 OID 0)
-- Dependencies: 526
-- Name: SEQUENCE scenarios_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.scenarios_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.scenarios_id_seq TO naqia_dev_rw;


--
-- TOC entry 10323 (class 0 OID 0)
-- Dependencies: 527
-- Name: TABLE seed_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.seed_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.seed_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.seed_types TO haider_qa;


--
-- TOC entry 10325 (class 0 OID 0)
-- Dependencies: 528
-- Name: SEQUENCE seed_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.seed_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.seed_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10326 (class 0 OID 0)
-- Dependencies: 529
-- Name: TABLE sentiments; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sentiments TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sentiments TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sentiments TO haider_qa;


--
-- TOC entry 10328 (class 0 OID 0)
-- Dependencies: 530
-- Name: SEQUENCE sentiments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sentiments_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.sentiments_id_seq TO naqia_dev_rw;


--
-- TOC entry 10329 (class 0 OID 0)
-- Dependencies: 531
-- Name: TABLE services; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.services TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.services TO naqia_dev_rw;
GRANT SELECT ON TABLE public.services TO haider_qa;


--
-- TOC entry 10331 (class 0 OID 0)
-- Dependencies: 532
-- Name: SEQUENCE services_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.services_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.services_id_seq TO naqia_dev_rw;


--
-- TOC entry 10332 (class 0 OID 0)
-- Dependencies: 783
-- Name: TABLE shopify_buyers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.shopify_buyers TO haider_qa;


--
-- TOC entry 10333 (class 0 OID 0)
-- Dependencies: 807
-- Name: TABLE shopify_visitors; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.shopify_visitors TO haider_qa;


--
-- TOC entry 10334 (class 0 OID 0)
-- Dependencies: 808
-- Name: TABLE shopify_visitors_interests; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.shopify_visitors_interests TO haider_qa;


--
-- TOC entry 10335 (class 0 OID 0)
-- Dependencies: 533
-- Name: TABLE sites; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sites TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sites TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sites TO haider_qa;


--
-- TOC entry 10336 (class 0 OID 0)
-- Dependencies: 534
-- Name: SEQUENCE sites_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sites_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.sites_id_seq TO naqia_dev_rw;


--
-- TOC entry 10338 (class 0 OID 0)
-- Dependencies: 535
-- Name: SEQUENCE sites_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sites_id_seq1 TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.sites_id_seq1 TO naqia_dev_rw;


--
-- TOC entry 10339 (class 0 OID 0)
-- Dependencies: 672
-- Name: TABLE sites_temp; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sites_temp TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sites_temp TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sites_temp TO haider_qa;


--
-- TOC entry 10340 (class 0 OID 0)
-- Dependencies: 781
-- Name: TABLE sms_keys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_keys TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sms_keys TO haider_qa;


--
-- TOC entry 10341 (class 0 OID 0)
-- Dependencies: 536
-- Name: TABLE sms_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_logs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_logs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sms_logs TO haider_qa;


--
-- TOC entry 10342 (class 0 OID 0)
-- Dependencies: 537
-- Name: TABLE sms_profiling; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_profiling TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_profiling TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sms_profiling TO haider_qa;


--
-- TOC entry 10343 (class 0 OID 0)
-- Dependencies: 538
-- Name: TABLE sms_profiling_activities; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_profiling_activities TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_profiling_activities TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sms_profiling_activities TO haider_qa;


--
-- TOC entry 10344 (class 0 OID 0)
-- Dependencies: 539
-- Name: TABLE sms_survey_form_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_survey_form_status TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_survey_form_status TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sms_survey_form_status TO haider_qa;


--
-- TOC entry 10345 (class 0 OID 0)
-- Dependencies: 540
-- Name: TABLE sms_survey_question_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_survey_question_log TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_survey_question_log TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sms_survey_question_log TO haider_qa;


--
-- TOC entry 10346 (class 0 OID 0)
-- Dependencies: 541
-- Name: TABLE sms_survey_questions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_survey_questions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_survey_questions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sms_survey_questions TO haider_qa;


--
-- TOC entry 10347 (class 0 OID 0)
-- Dependencies: 542
-- Name: TABLE sms_surveyform_params; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_surveyform_params TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sms_surveyform_params TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sms_surveyform_params TO haider_qa;


--
-- TOC entry 10348 (class 0 OID 0)
-- Dependencies: 543
-- Name: TABLE soil_issues; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.soil_issues TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.soil_issues TO naqia_dev_rw;
GRANT SELECT ON TABLE public.soil_issues TO haider_qa;


--
-- TOC entry 10350 (class 0 OID 0)
-- Dependencies: 544
-- Name: SEQUENCE soil_issues_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.soil_issues_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.soil_issues_id_seq TO naqia_dev_rw;


--
-- TOC entry 10351 (class 0 OID 0)
-- Dependencies: 545
-- Name: TABLE soil_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.soil_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.soil_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.soil_types TO haider_qa;


--
-- TOC entry 10353 (class 0 OID 0)
-- Dependencies: 546
-- Name: SEQUENCE soil_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.soil_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.soil_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10354 (class 0 OID 0)
-- Dependencies: 547
-- Name: TABLE source_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.source_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.source_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.source_types TO haider_qa;


--
-- TOC entry 10356 (class 0 OID 0)
-- Dependencies: 548
-- Name: SEQUENCE source_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.source_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.source_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10357 (class 0 OID 0)
-- Dependencies: 549
-- Name: TABLE sowing_methods; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sowing_methods TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sowing_methods TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sowing_methods TO haider_qa;


--
-- TOC entry 10359 (class 0 OID 0)
-- Dependencies: 550
-- Name: SEQUENCE sowing_methods_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sowing_methods_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.sowing_methods_id_seq TO naqia_dev_rw;


--
-- TOC entry 10360 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE spatial_ref_sys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.spatial_ref_sys TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.spatial_ref_sys TO naqia_dev_rw;
GRANT SELECT ON TABLE public.spatial_ref_sys TO haider_qa;


--
-- TOC entry 10361 (class 0 OID 0)
-- Dependencies: 551
-- Name: TABLE stats_notifications_replica; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.stats_notifications_replica TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.stats_notifications_replica TO naqia_dev_rw;
GRANT SELECT ON TABLE public.stats_notifications_replica TO haider_qa;


--
-- TOC entry 10362 (class 0 OID 0)
-- Dependencies: 552
-- Name: TABLE sub_dbss_sync_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sub_dbss_sync_log TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sub_dbss_sync_log TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sub_dbss_sync_log TO haider_qa;


--
-- TOC entry 10363 (class 0 OID 0)
-- Dependencies: 553
-- Name: TABLE sub_modes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sub_modes TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.sub_modes TO naqia_dev_rw;
GRANT SELECT ON TABLE public.sub_modes TO haider_qa;


--
-- TOC entry 10365 (class 0 OID 0)
-- Dependencies: 554
-- Name: SEQUENCE sub_modes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.sub_modes_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.sub_modes_id_seq TO naqia_dev_rw;


--
-- TOC entry 10366 (class 0 OID 0)
-- Dependencies: 555
-- Name: SEQUENCE subscriber_base_network_tagging_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriber_base_network_tagging_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.subscriber_base_network_tagging_id_seq TO naqia_dev_rw;


--
-- TOC entry 10367 (class 0 OID 0)
-- Dependencies: 556
-- Name: TABLE subscriber_base_network_tagging; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_base_network_tagging TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_base_network_tagging TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscriber_base_network_tagging TO haider_qa;


--
-- TOC entry 10368 (class 0 OID 0)
-- Dependencies: 557
-- Name: TABLE subscriber_base_other_network_tagging; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_base_other_network_tagging TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_base_other_network_tagging TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscriber_base_other_network_tagging TO haider_qa;


--
-- TOC entry 10369 (class 0 OID 0)
-- Dependencies: 558
-- Name: SEQUENCE subscriber_base_other_network_tagging_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriber_base_other_network_tagging_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.subscriber_base_other_network_tagging_id_seq TO naqia_dev_rw;


--
-- TOC entry 10370 (class 0 OID 0)
-- Dependencies: 559
-- Name: TABLE subscriber_notification_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_notification_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_notification_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscriber_notification_types TO haider_qa;


--
-- TOC entry 10372 (class 0 OID 0)
-- Dependencies: 560
-- Name: SEQUENCE subscriber_notification_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriber_notification_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.subscriber_notification_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10373 (class 0 OID 0)
-- Dependencies: 561
-- Name: TABLE subscriber_roles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_roles TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_roles TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscriber_roles TO haider_qa;


--
-- TOC entry 10375 (class 0 OID 0)
-- Dependencies: 562
-- Name: SEQUENCE subscriber_roles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriber_roles_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.subscriber_roles_id_seq TO naqia_dev_rw;


--
-- TOC entry 10376 (class 0 OID 0)
-- Dependencies: 563
-- Name: TABLE subscriber_tagging_update; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_tagging_update TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriber_tagging_update TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscriber_tagging_update TO haider_qa;


--
-- TOC entry 10377 (class 0 OID 0)
-- Dependencies: 564
-- Name: TABLE subscribers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers TO ahsanprod_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscribers TO haider_qa;


--
-- TOC entry 10378 (class 0 OID 0)
-- Dependencies: 565
-- Name: TABLE subscribers_job_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers_job_logs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers_job_logs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscribers_job_logs TO haider_qa;


--
-- TOC entry 10380 (class 0 OID 0)
-- Dependencies: 566
-- Name: SEQUENCE subscribers_job_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscribers_job_logs_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.subscribers_job_logs_id_seq TO naqia_dev_rw;


--
-- TOC entry 10381 (class 0 OID 0)
-- Dependencies: 567
-- Name: TABLE subscribers_test; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers_test TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers_test TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscribers_test TO haider_qa;


--
-- TOC entry 10382 (class 0 OID 0)
-- Dependencies: 568
-- Name: TABLE subscribers_testt; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers_testt TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscribers_testt TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscribers_testt TO haider_qa;


--
-- TOC entry 10383 (class 0 OID 0)
-- Dependencies: 569
-- Name: TABLE subscription_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscription_types TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscription_types TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscription_types TO haider_qa;


--
-- TOC entry 10385 (class 0 OID 0)
-- Dependencies: 570
-- Name: SEQUENCE subscription_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscription_types_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.subscription_types_id_seq TO naqia_dev_rw;


--
-- TOC entry 10386 (class 0 OID 0)
-- Dependencies: 571
-- Name: TABLE subscriptions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriptions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.subscriptions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.subscriptions TO haider_qa;


--
-- TOC entry 10388 (class 0 OID 0)
-- Dependencies: 572
-- Name: SEQUENCE subscriptions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriptions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.subscriptions_id_seq TO naqia_dev_rw;


--
-- TOC entry 10390 (class 0 OID 0)
-- Dependencies: 573
-- Name: SEQUENCE subscriptions_subscription_type_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.subscriptions_subscription_type_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.subscriptions_subscription_type_id_seq TO naqia_dev_rw;


--
-- TOC entry 10391 (class 0 OID 0)
-- Dependencies: 712
-- Name: TABLE survey_activities; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_activities TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_activities TO ahsanprod_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_activities TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_activities TO haider_qa;


--
-- TOC entry 10393 (class 0 OID 0)
-- Dependencies: 713
-- Name: SEQUENCE survey_activities_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_activities_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.survey_activities_id_seq TO naqia_dev_rw;


--
-- TOC entry 10394 (class 0 OID 0)
-- Dependencies: 721
-- Name: TABLE survey_input_api_actions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_input_api_actions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_input_api_actions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_input_api_actions TO haider_qa;


--
-- TOC entry 10396 (class 0 OID 0)
-- Dependencies: 722
-- Name: SEQUENCE survey_api_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_api_actions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.survey_api_actions_id_seq TO naqia_dev_rw;


--
-- TOC entry 10397 (class 0 OID 0)
-- Dependencies: 714
-- Name: TABLE survey_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_categories TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_categories TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_categories TO haider_qa;


--
-- TOC entry 10399 (class 0 OID 0)
-- Dependencies: 715
-- Name: SEQUENCE survey_categories_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_categories_id_seq TO naqia_dev_rw;


--
-- TOC entry 10400 (class 0 OID 0)
-- Dependencies: 716
-- Name: TABLE survey_crops; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_crops TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_crops TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_crops TO haider_qa;


--
-- TOC entry 10402 (class 0 OID 0)
-- Dependencies: 717
-- Name: SEQUENCE survey_crops_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_crops_id_seq TO naqia_dev_rw;


--
-- TOC entry 10403 (class 0 OID 0)
-- Dependencies: 718
-- Name: TABLE survey_file_name_apis; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_file_name_apis TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_file_name_apis TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_file_name_apis TO haider_qa;


--
-- TOC entry 10404 (class 0 OID 0)
-- Dependencies: 719
-- Name: TABLE survey_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_files TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_files TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_files TO haider_qa;


--
-- TOC entry 10406 (class 0 OID 0)
-- Dependencies: 720
-- Name: SEQUENCE survey_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_files_id_seq TO naqia_dev_rw;


--
-- TOC entry 10407 (class 0 OID 0)
-- Dependencies: 678
-- Name: TABLE surveys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.surveys TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.surveys TO naqia_dev_rw;
GRANT SELECT ON TABLE public.surveys TO haider_qa;


--
-- TOC entry 10409 (class 0 OID 0)
-- Dependencies: 679
-- Name: SEQUENCE survey_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_id_seq TO naqia_dev_rw;


--
-- TOC entry 10410 (class 0 OID 0)
-- Dependencies: 724
-- Name: TABLE survey_input_files; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_input_files TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_input_files TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_input_files TO haider_qa;


--
-- TOC entry 10412 (class 0 OID 0)
-- Dependencies: 725
-- Name: SEQUENCE survey_input_files_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_input_files_id_seq TO naqia_dev_rw;


--
-- TOC entry 10413 (class 0 OID 0)
-- Dependencies: 726
-- Name: TABLE survey_input_trunk_actions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_input_trunk_actions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_input_trunk_actions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_input_trunk_actions TO haider_qa;


--
-- TOC entry 10415 (class 0 OID 0)
-- Dependencies: 727
-- Name: SEQUENCE survey_input_trunk_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_input_trunk_actions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.survey_input_trunk_actions_id_seq TO naqia_dev_rw;


--
-- TOC entry 10416 (class 0 OID 0)
-- Dependencies: 680
-- Name: TABLE survey_inputs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_inputs TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_inputs TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_inputs TO haider_qa;


--
-- TOC entry 10418 (class 0 OID 0)
-- Dependencies: 723
-- Name: SEQUENCE survey_inputs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_inputs_id_seq TO naqia_dev_rw;


--
-- TOC entry 10419 (class 0 OID 0)
-- Dependencies: 728
-- Name: TABLE survey_languages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_languages TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_languages TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_languages TO haider_qa;


--
-- TOC entry 10421 (class 0 OID 0)
-- Dependencies: 729
-- Name: SEQUENCE survey_languages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_languages_id_seq TO naqia_dev_rw;


--
-- TOC entry 10422 (class 0 OID 0)
-- Dependencies: 730
-- Name: TABLE survey_livestocks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_livestocks TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_livestocks TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_livestocks TO haider_qa;


--
-- TOC entry 10424 (class 0 OID 0)
-- Dependencies: 731
-- Name: SEQUENCE survey_livestocks_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_livestocks_id_seq TO naqia_dev_rw;


--
-- TOC entry 10425 (class 0 OID 0)
-- Dependencies: 732
-- Name: TABLE survey_locations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_locations TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_locations TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_locations TO haider_qa;


--
-- TOC entry 10427 (class 0 OID 0)
-- Dependencies: 733
-- Name: SEQUENCE survey_locations_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_locations_id_seq TO naqia_dev_rw;


--
-- TOC entry 10428 (class 0 OID 0)
-- Dependencies: 734
-- Name: TABLE survey_machineries; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_machineries TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_machineries TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_machineries TO haider_qa;


--
-- TOC entry 10430 (class 0 OID 0)
-- Dependencies: 735
-- Name: SEQUENCE survey_machineries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_machineries_id_seq TO naqia_dev_rw;


--
-- TOC entry 10431 (class 0 OID 0)
-- Dependencies: 736
-- Name: TABLE survey_operator; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_operator TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_operator TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_operator TO haider_qa;


--
-- TOC entry 10432 (class 0 OID 0)
-- Dependencies: 574
-- Name: SEQUENCE survey_operator_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_operator_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.survey_operator_id_seq TO naqia_dev_rw;


--
-- TOC entry 10433 (class 0 OID 0)
-- Dependencies: 737
-- Name: TABLE survey_profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_profiles TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_profiles TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_profiles TO haider_qa;


--
-- TOC entry 10435 (class 0 OID 0)
-- Dependencies: 738
-- Name: SEQUENCE survey_profiles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.survey_profiles_id_seq TO naqia_dev_rw;


--
-- TOC entry 10436 (class 0 OID 0)
-- Dependencies: 739
-- Name: TABLE survey_promo_data; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_promo_data TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_promo_data TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_promo_data TO haider_qa;


--
-- TOC entry 10438 (class 0 OID 0)
-- Dependencies: 740
-- Name: SEQUENCE survey_promo_data_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.survey_promo_data_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.survey_promo_data_id_seq TO naqia_dev_rw;


--
-- TOC entry 10439 (class 0 OID 0)
-- Dependencies: 741
-- Name: TABLE survey_questions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_questions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_questions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_questions TO haider_qa;


--
-- TOC entry 10440 (class 0 OID 0)
-- Dependencies: 742
-- Name: TABLE survey_validation_apis; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_validation_apis TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.survey_validation_apis TO naqia_dev_rw;
GRANT SELECT ON TABLE public.survey_validation_apis TO haider_qa;


--
-- TOC entry 10441 (class 0 OID 0)
-- Dependencies: 803
-- Name: TABLE sync_jobs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.sync_jobs TO haider_qa;


--
-- TOC entry 10442 (class 0 OID 0)
-- Dependencies: 575
-- Name: TABLE system_settings; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.system_settings TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.system_settings TO naqia_dev_rw;
GRANT SELECT ON TABLE public.system_settings TO haider_qa;


--
-- TOC entry 10443 (class 0 OID 0)
-- Dependencies: 576
-- Name: TABLE system_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.system_users TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.system_users TO naqia_dev_rw;
GRANT SELECT ON TABLE public.system_users TO haider_qa;


--
-- TOC entry 10444 (class 0 OID 0)
-- Dependencies: 577
-- Name: TABLE tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tags TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tags TO naqia_dev_rw;
GRANT SELECT ON TABLE public.tags TO haider_qa;


--
-- TOC entry 10446 (class 0 OID 0)
-- Dependencies: 578
-- Name: SEQUENCE tags_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.tags_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.tags_id_seq TO naqia_dev_rw;


--
-- TOC entry 10447 (class 0 OID 0)
-- Dependencies: 579
-- Name: TABLE tehsil_data_ml; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tehsil_data_ml TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tehsil_data_ml TO naqia_dev_rw;
GRANT SELECT ON TABLE public.tehsil_data_ml TO haider_qa;


--
-- TOC entry 10448 (class 0 OID 0)
-- Dependencies: 673
-- Name: TABLE tehsil_temp; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tehsil_temp TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tehsil_temp TO naqia_dev_rw;
GRANT SELECT ON TABLE public.tehsil_temp TO haider_qa;


--
-- TOC entry 10449 (class 0 OID 0)
-- Dependencies: 580
-- Name: TABLE tehsils; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tehsils TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tehsils TO naqia_dev_rw;
GRANT SELECT ON TABLE public.tehsils TO haider_qa;


--
-- TOC entry 10450 (class 0 OID 0)
-- Dependencies: 674
-- Name: TABLE temp; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.temp TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.temp TO naqia_dev_rw;
GRANT SELECT ON TABLE public.temp TO haider_qa;


--
-- TOC entry 10451 (class 0 OID 0)
-- Dependencies: 581
-- Name: TABLE tenants; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tenants TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tenants TO naqia_dev_rw;
GRANT SELECT ON TABLE public.tenants TO haider_qa;


--
-- TOC entry 10452 (class 0 OID 0)
-- Dependencies: 582
-- Name: TABLE terms_of_use; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.terms_of_use TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.terms_of_use TO naqia_dev_rw;
GRANT SELECT ON TABLE public.terms_of_use TO haider_qa;


--
-- TOC entry 10453 (class 0 OID 0)
-- Dependencies: 583
-- Name: SEQUENCE terms_of_use_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.terms_of_use_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.terms_of_use_id_seq TO naqia_dev_rw;


--
-- TOC entry 10454 (class 0 OID 0)
-- Dependencies: 788
-- Name: TABLE test_farmer_names; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.test_farmer_names TO haider_qa;


--
-- TOC entry 10455 (class 0 OID 0)
-- Dependencies: 584
-- Name: TABLE testing_numbers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.testing_numbers TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.testing_numbers TO naqia_dev_rw;
GRANT SELECT ON TABLE public.testing_numbers TO haider_qa;


--
-- TOC entry 10457 (class 0 OID 0)
-- Dependencies: 585
-- Name: SEQUENCE testing_numbers_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.testing_numbers_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.testing_numbers_id_seq TO naqia_dev_rw;


--
-- TOC entry 10459 (class 0 OID 0)
-- Dependencies: 586
-- Name: SEQUENCE transactions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.transactions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.transactions_id_seq TO naqia_dev_rw;


--
-- TOC entry 10460 (class 0 OID 0)
-- Dependencies: 587
-- Name: TABLE trunk_call_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.trunk_call_details TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.trunk_call_details TO naqia_dev_rw;
GRANT SELECT ON TABLE public.trunk_call_details TO haider_qa;


--
-- TOC entry 10462 (class 0 OID 0)
-- Dependencies: 588
-- Name: SEQUENCE trunk_call_details_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.trunk_call_details_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.trunk_call_details_id_seq TO naqia_dev_rw;


--
-- TOC entry 10463 (class 0 OID 0)
-- Dependencies: 589
-- Name: TABLE trunk_dialing_timings; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.trunk_dialing_timings TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.trunk_dialing_timings TO naqia_dev_rw;
GRANT SELECT ON TABLE public.trunk_dialing_timings TO haider_qa;


--
-- TOC entry 10464 (class 0 OID 0)
-- Dependencies: 590
-- Name: TABLE trunk_recording_timings; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.trunk_recording_timings TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.trunk_recording_timings TO naqia_dev_rw;
GRANT SELECT ON TABLE public.trunk_recording_timings TO haider_qa;


--
-- TOC entry 10466 (class 0 OID 0)
-- Dependencies: 591
-- Name: SEQUENCE trunk_recording_timings_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.trunk_recording_timings_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.trunk_recording_timings_id_seq TO naqia_dev_rw;


--
-- TOC entry 10468 (class 0 OID 0)
-- Dependencies: 592
-- Name: SEQUENCE trunk_timings_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.trunk_timings_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.trunk_timings_id_seq TO naqia_dev_rw;


--
-- TOC entry 10469 (class 0 OID 0)
-- Dependencies: 593
-- Name: TABLE tts_records; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tts_records TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tts_records TO naqia_dev_rw;
GRANT SELECT ON TABLE public.tts_records TO haider_qa;


--
-- TOC entry 10470 (class 0 OID 0)
-- Dependencies: 594
-- Name: TABLE ufone_operator; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ufone_operator TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.ufone_operator TO naqia_dev_rw;
GRANT SELECT ON TABLE public.ufone_operator TO haider_qa;


--
-- TOC entry 10471 (class 0 OID 0)
-- Dependencies: 595
-- Name: TABLE unsub_modes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.unsub_modes TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.unsub_modes TO naqia_dev_rw;
GRANT SELECT ON TABLE public.unsub_modes TO haider_qa;


--
-- TOC entry 10472 (class 0 OID 0)
-- Dependencies: 596
-- Name: SEQUENCE unsub_request_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.unsub_request_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.unsub_request_id_seq TO naqia_dev_rw;


--
-- TOC entry 10473 (class 0 OID 0)
-- Dependencies: 597
-- Name: TABLE unsub_request; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.unsub_request TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.unsub_request TO naqia_dev_rw;
GRANT SELECT ON TABLE public.unsub_request TO haider_qa;


--
-- TOC entry 10474 (class 0 OID 0)
-- Dependencies: 598
-- Name: TABLE unsubscribers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.unsubscribers TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.unsubscribers TO naqia_dev_rw;
GRANT SELECT ON TABLE public.unsubscribers TO haider_qa;


--
-- TOC entry 10475 (class 0 OID 0)
-- Dependencies: 599
-- Name: TABLE user_activities; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_activities TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_activities TO naqia_dev_rw;
GRANT SELECT ON TABLE public.user_activities TO haider_qa;


--
-- TOC entry 10477 (class 0 OID 0)
-- Dependencies: 600
-- Name: SEQUENCE user_activities_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.user_activities_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.user_activities_id_seq TO naqia_dev_rw;


--
-- TOC entry 10478 (class 0 OID 0)
-- Dependencies: 823
-- Name: TABLE user_engagement; Type: ACL; Schema: public; Owner: naqia_dev_rw
--

GRANT SELECT ON TABLE public.user_engagement TO haider_qa;


--
-- TOC entry 10480 (class 0 OID 0)
-- Dependencies: 601
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.users_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.users_id_seq TO naqia_dev_rw;


--
-- TOC entry 10481 (class 0 OID 0)
-- Dependencies: 602
-- Name: TABLE weather_change_set; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_change_set TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_change_set TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_change_set TO haider_qa;


--
-- TOC entry 10482 (class 0 OID 0)
-- Dependencies: 603
-- Name: SEQUENCE weather_change_set_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_change_set_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_change_set_id_seq TO naqia_dev_rw;


--
-- TOC entry 10484 (class 0 OID 0)
-- Dependencies: 604
-- Name: SEQUENCE weather_change_set_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_change_set_id_seq1 TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_change_set_id_seq1 TO naqia_dev_rw;


--
-- TOC entry 10485 (class 0 OID 0)
-- Dependencies: 605
-- Name: TABLE weather_conditions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_conditions TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_conditions TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_conditions TO haider_qa;


--
-- TOC entry 10486 (class 0 OID 0)
-- Dependencies: 606
-- Name: SEQUENCE weather_conditions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_conditions_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_conditions_id_seq TO naqia_dev_rw;


--
-- TOC entry 10488 (class 0 OID 0)
-- Dependencies: 607
-- Name: SEQUENCE weather_conditions_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_conditions_id_seq1 TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_conditions_id_seq1 TO naqia_dev_rw;


--
-- TOC entry 10489 (class 0 OID 0)
-- Dependencies: 608
-- Name: TABLE weather_daily; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_daily TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_daily TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_daily TO haider_qa;


--
-- TOC entry 10490 (class 0 OID 0)
-- Dependencies: 609
-- Name: SEQUENCE weather_daily_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_daily_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_daily_id_seq TO naqia_dev_rw;


--
-- TOC entry 10492 (class 0 OID 0)
-- Dependencies: 610
-- Name: SEQUENCE weather_daily_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_daily_id_seq1 TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_daily_id_seq1 TO naqia_dev_rw;


--
-- TOC entry 10493 (class 0 OID 0)
-- Dependencies: 611
-- Name: TABLE weather_hourly; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_hourly TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_hourly TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_hourly TO haider_qa;


--
-- TOC entry 10494 (class 0 OID 0)
-- Dependencies: 612
-- Name: SEQUENCE weather_hourly_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_hourly_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_hourly_id_seq TO naqia_dev_rw;


--
-- TOC entry 10496 (class 0 OID 0)
-- Dependencies: 613
-- Name: SEQUENCE weather_hourly_id_seq1; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_hourly_id_seq1 TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_hourly_id_seq1 TO naqia_dev_rw;


--
-- TOC entry 10497 (class 0 OID 0)
-- Dependencies: 614
-- Name: TABLE weather_intraday; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_intraday TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_intraday TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_intraday TO haider_qa;


--
-- TOC entry 10499 (class 0 OID 0)
-- Dependencies: 615
-- Name: SEQUENCE weather_intraday_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_intraday_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_intraday_id_seq TO naqia_dev_rw;


--
-- TOC entry 10500 (class 0 OID 0)
-- Dependencies: 616
-- Name: TABLE weather_outlooks; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_outlooks TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_outlooks TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_outlooks TO haider_qa;


--
-- TOC entry 10502 (class 0 OID 0)
-- Dependencies: 617
-- Name: SEQUENCE weather_outlook_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_outlook_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_outlook_id_seq TO naqia_dev_rw;


--
-- TOC entry 10503 (class 0 OID 0)
-- Dependencies: 618
-- Name: TABLE weather_raw; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_raw TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_raw TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_raw TO haider_qa;


--
-- TOC entry 10505 (class 0 OID 0)
-- Dependencies: 619
-- Name: SEQUENCE weather_raw_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_raw_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_raw_id_seq TO naqia_dev_rw;


--
-- TOC entry 10506 (class 0 OID 0)
-- Dependencies: 620
-- Name: TABLE weather_service_events; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_service_events TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_service_events TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_service_events TO haider_qa;


--
-- TOC entry 10508 (class 0 OID 0)
-- Dependencies: 621
-- Name: SEQUENCE weather_service_events_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weather_service_events_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weather_service_events_id_seq TO naqia_dev_rw;


--
-- TOC entry 10509 (class 0 OID 0)
-- Dependencies: 622
-- Name: TABLE weather_sms_whitelist; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_sms_whitelist TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_sms_whitelist TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_sms_whitelist TO haider_qa;


--
-- TOC entry 10510 (class 0 OID 0)
-- Dependencies: 623
-- Name: TABLE weather_stations_location; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_stations_location TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weather_stations_location TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weather_stations_location TO haider_qa;


--
-- TOC entry 10511 (class 0 OID 0)
-- Dependencies: 822
-- Name: TABLE webview_users; Type: ACL; Schema: public; Owner: rameez_dev_rw
--

GRANT SELECT ON TABLE public.webview_users TO haider_qa;


--
-- TOC entry 10512 (class 0 OID 0)
-- Dependencies: 624
-- Name: TABLE weeds; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weeds TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.weeds TO naqia_dev_rw;
GRANT SELECT ON TABLE public.weeds TO haider_qa;


--
-- TOC entry 10514 (class 0 OID 0)
-- Dependencies: 625
-- Name: SEQUENCE weeds_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.weeds_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.weeds_id_seq TO naqia_dev_rw;


--
-- TOC entry 10515 (class 0 OID 0)
-- Dependencies: 626
-- Name: TABLE welcome_box; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.welcome_box TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.welcome_box TO naqia_dev_rw;
GRANT SELECT ON TABLE public.welcome_box TO haider_qa;


--
-- TOC entry 10517 (class 0 OID 0)
-- Dependencies: 627
-- Name: SEQUENCE welcome_box_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.welcome_box_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.welcome_box_id_seq TO naqia_dev_rw;


--
-- TOC entry 10518 (class 0 OID 0)
-- Dependencies: 628
-- Name: TABLE wx_phrase_list; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wx_phrase_list TO ateebqa_rw;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.wx_phrase_list TO naqia_dev_rw;
GRANT SELECT ON TABLE public.wx_phrase_list TO haider_qa;


--
-- TOC entry 10520 (class 0 OID 0)
-- Dependencies: 629
-- Name: SEQUENCE wx_phrase_list_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.wx_phrase_list_id_seq TO bkkdev_rw;
GRANT SELECT,USAGE ON SEQUENCE public.wx_phrase_list_id_seq TO naqia_dev_rw;


--
-- TOC entry 5125 (class 826 OID 1564250)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO haider_qa;


-- Completed on 2025-08-15 12:00:59

--
-- PostgreSQL database dump complete
--

