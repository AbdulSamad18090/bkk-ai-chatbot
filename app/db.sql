--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

-- Started on 2025-08-12 16:15:27

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
-- TOC entry 871 (class 1247 OID 16549)
-- Name: appointment_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.appointment_status AS ENUM (
    'scheduled',
    'completed',
    'cancelled',
    'pending'
);


ALTER TYPE public.appointment_status OWNER TO postgres;

--
-- TOC entry 853 (class 1247 OID 16456)
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'doctor',
    'patient'
);


ALTER TYPE public.user_role OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 16527)
-- Name: appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    patient_id uuid NOT NULL,
    doctor_id uuid NOT NULL,
    reason text NOT NULL,
    status public.appointment_status DEFAULT 'scheduled'::public.appointment_status,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    appointment_at timestamp without time zone NOT NULL
);


ALTER TABLE public.appointments OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16657)
-- Name: chats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chats (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sender_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    message text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    is_read boolean DEFAULT false,
    appointment_id uuid NOT NULL
);


ALTER TABLE public.chats OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16493)
-- Name: doctor_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctor_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    profile_image text,
    bio character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    specialization text,
    university text,
    experience integer,
    address text,
    phone_number text,
    medical_license text,
    graduation_year integer
);


ALTER TABLE public.doctor_profiles OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16510)
-- Name: patient_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    profile_image text,
    problem text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    age integer,
    blood_group text,
    phone_number text,
    emergency_contact text,
    address text
);


ALTER TABLE public.patient_profiles OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16562)
-- Name: ratings_reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ratings_reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doctor_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    rating integer NOT NULL,
    review text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ratings_reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.ratings_reviews OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16624)
-- Name: slots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.slots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doctor_id uuid NOT NULL,
    is_booked boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    slot_date date NOT NULL,
    title text NOT NULL,
    start_time text NOT NULL,
    end_time text NOT NULL
);


ALTER TABLE public.slots OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16475)
-- Name: tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    access_token text,
    refresh_token text NOT NULL,
    is_valid boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tokens OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16461)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password text NOT NULL,
    role public.user_role DEFAULT 'patient'::public.user_role NOT NULL,
    revoked boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;


--
-- TOC entry 4822 (class 2606 OID 16537)
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- TOC entry 4832 (class 2606 OID 16666)
-- Name: chats chats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT chats_pkey PRIMARY KEY (id);


--
-- TOC entry 4814 (class 2606 OID 16502)
-- Name: doctor_profiles doctor_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_profiles
    ADD CONSTRAINT doctor_profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 4816 (class 2606 OID 16504)
-- Name: doctor_profiles doctor_profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_profiles
    ADD CONSTRAINT doctor_profiles_user_id_key UNIQUE (user_id);


--
-- TOC entry 4806 (class 2606 OID 16470)
-- Name: users email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT email UNIQUE (email) INCLUDE (email);


--
-- TOC entry 4818 (class 2606 OID 16519)
-- Name: patient_profiles patient_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_profiles
    ADD CONSTRAINT patient_profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 4820 (class 2606 OID 16521)
-- Name: patient_profiles patient_profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_profiles
    ADD CONSTRAINT patient_profiles_user_id_key UNIQUE (user_id);


--
-- TOC entry 4826 (class 2606 OID 16574)
-- Name: ratings_reviews ratings_reviews_doctor_id_patient_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings_reviews
    ADD CONSTRAINT ratings_reviews_doctor_id_patient_id_key UNIQUE (doctor_id, patient_id);


--
-- TOC entry 4828 (class 2606 OID 16572)
-- Name: ratings_reviews ratings_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings_reviews
    ADD CONSTRAINT ratings_reviews_pkey PRIMARY KEY (id);


--
-- TOC entry 4830 (class 2606 OID 16633)
-- Name: slots slots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slots
    ADD CONSTRAINT slots_pkey PRIMARY KEY (id);


--
-- TOC entry 4810 (class 2606 OID 16485)
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 4824 (class 2606 OID 16623)
-- Name: appointments unique_appointment_at; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT unique_appointment_at UNIQUE (appointment_at);


--
-- TOC entry 4812 (class 2606 OID 16492)
-- Name: tokens user_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT user_id UNIQUE (user_id) INCLUDE (user_id);


--
-- TOC entry 4808 (class 2606 OID 16468)
-- Name: users users_p_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_p_key PRIMARY KEY (id);


--
-- TOC entry 4841 (class 2606 OID 16677)
-- Name: chats fk_appointment; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT fk_appointment FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE CASCADE NOT VALID;


--
-- TOC entry 4836 (class 2606 OID 16543)
-- Name: appointments fk_doctor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT fk_doctor FOREIGN KEY (doctor_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4838 (class 2606 OID 16575)
-- Name: ratings_reviews fk_doctor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings_reviews
    ADD CONSTRAINT fk_doctor FOREIGN KEY (doctor_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4840 (class 2606 OID 16634)
-- Name: slots fk_doctor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.slots
    ADD CONSTRAINT fk_doctor FOREIGN KEY (doctor_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4837 (class 2606 OID 16538)
-- Name: appointments fk_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT fk_patient FOREIGN KEY (patient_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4839 (class 2606 OID 16580)
-- Name: ratings_reviews fk_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings_reviews
    ADD CONSTRAINT fk_patient FOREIGN KEY (patient_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4842 (class 2606 OID 16672)
-- Name: chats fk_receiver; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT fk_receiver FOREIGN KEY (receiver_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4843 (class 2606 OID 16667)
-- Name: chats fk_sender; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT fk_sender FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4833 (class 2606 OID 16486)
-- Name: tokens fk_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4834 (class 2606 OID 16505)
-- Name: doctor_profiles fk_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctor_profiles
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 4835 (class 2606 OID 16522)
-- Name: patient_profiles fk_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_profiles
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2025-08-12 16:15:27

--
-- PostgreSQL database dump complete
--

