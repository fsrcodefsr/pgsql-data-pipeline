--
-- PostgreSQL database dump
--

-- Dumped from database version 15.7 (Debian 15.7-1.pgdg120+1)
-- Dumped by pg_dump version 15.7 (Debian 15.7-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpython3u; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpython3u WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpython3u; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpython3u IS 'PL/Python3U untrusted procedural language';


--
-- Name: generate_address_xml(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.generate_address_xml() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    xml_data TEXT;
BEGIN
    xml_data := 
        '<root xmlns="http://example.com/root" xmlns:addresses="http://example.com/addresses">' ||
        '<addresses:address>' ||
        '<addresses:id>' || NEW.id || '</addresses:id>' ||
        '<addresses:user_id>' || NEW.user_id || '</addresses:user_id>' ||
        '<addresses:street>' || NEW.street || '</addresses:street>' ||
        '<addresses:city>' || NEW.city || '</addresses:city>' ||
        '<addresses:state>' || NEW.state || '</addresses:state>' ||
        '<addresses:postal_code>' || NEW.postal_code || '</addresses:postal_code>' ||
        '</addresses:address>' ||
        '</root>';

    PERFORM send_post_request(xml_data);

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.generate_address_xml() OWNER TO "user";

--
-- Name: generate_order_xml(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.generate_order_xml() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    xml_data TEXT;
BEGIN
    xml_data := 
        '<root xmlns="http://example.com/root" xmlns:orders="http://example.com/orders">' ||
        '<orders:order>' ||
        '<orders:id>' || NEW.id || '</orders:id>' ||
        '<orders:user_id>' || NEW.user_id || '</orders:user_id>' ||
        '<orders:order_date>' || NEW.order_date || '</orders:order_date>' ||
        '<orders:total_amount>' || NEW.total_amount || '</orders:total_amount>' ||
        '</orders:order>' ||
        '</root>';

    PERFORM send_post_request(xml_data);

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.generate_order_xml() OWNER TO "user";

--
-- Name: generate_user_xml(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.generate_user_xml() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    xml_data TEXT;
BEGIN
    xml_data := 
        '<root xmlns="http://example.com/root" xmlns:users="http://example.com/users">' ||
        '<users:user>' ||
        '<users:id>' || NEW.id || '</users:id>' ||
        '<users:username>' || NEW.username || '</users:username>' ||
        '<users:email>' || NEW.email || '</users:email>' ||
        '<users:password_hash>' || NEW.password_hash || '</users:password_hash>' ||
        '</users:user>' ||
        '</root>';

    PERFORM send_post_request(xml_data);

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.generate_user_xml() OWNER TO "user";

--
-- Name: notify_address_changes(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.notify_address_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    payload JSON;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        payload := json_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME,
            'old', row_to_json(OLD)
        );
        OLD.deleted_at := CURRENT_TIMESTAMP;
        RETURN OLD;
    ELSE
        payload := json_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME,
            'new', row_to_json(NEW)
        );
        IF (TG_OP = 'INSERT') THEN
            NEW.created_at := CURRENT_TIMESTAMP;
        ELSE
            NEW.updated_at := CURRENT_TIMESTAMP;
        END IF;
        PERFORM pg_notify('table_changes', payload::text);
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.notify_address_changes() OWNER TO "user";

--
-- Name: notify_order_changes(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.notify_order_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    payload JSON;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        payload := json_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME,
            'old', row_to_json(OLD)
        );
        OLD.deleted_at := CURRENT_TIMESTAMP;
        RETURN OLD;
    ELSE
        payload := json_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME,
            'new', row_to_json(NEW)
        );
        IF (TG_OP = 'INSERT') THEN
            NEW.created_at := CURRENT_TIMESTAMP;
        ELSE
            NEW.updated_at := CURRENT_TIMESTAMP;
        END IF;
        PERFORM pg_notify('table_changes', payload::text);
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.notify_order_changes() OWNER TO "user";

--
-- Name: notify_user_changes(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.notify_user_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    payload JSON;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        payload := json_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME,
            'old', row_to_json(OLD)
        );
        OLD.deleted_at := CURRENT_TIMESTAMP;
        RETURN OLD;
    ELSE
        payload := json_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME,
            'new', row_to_json(NEW)
        );
        IF (TG_OP = 'INSERT') THEN
            NEW.created_at := CURRENT_TIMESTAMP;
        ELSE
            NEW.updated_at := CURRENT_TIMESTAMP;
        END IF;
        PERFORM pg_notify('table_changes', payload::text);
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.notify_user_changes() OWNER TO "user";

--
-- Name: send_post_request(text); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.send_post_request(xml_data text) RETURNS void
    LANGUAGE plpython3u
    AS $$
import urllib.request

url = 'http://localhost:5000/update'
data = xml_data.encode('utf-8')
headers = {'Content-Type': 'application/xml'}

req = urllib.request.Request(url, data=data, headers=headers, method='POST')

try:
    with urllib.request.urlopen(req) as response:
        response_text = response.read().decode('utf-8')
        plpy.info(response_text)
except Exception as e:
    plpy.error(str(e))
$$;


ALTER FUNCTION public.send_post_request(xml_data text) OWNER TO "user";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.addresses (
    id integer NOT NULL,
    user_id integer,
    street character varying(255),
    city character varying(100),
    state character varying(50),
    postal_code character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    transmitted_at timestamp without time zone
);


ALTER TABLE public.addresses OWNER TO "user";

--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.addresses_id_seq OWNER TO "user";

--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    user_id integer,
    order_date date,
    total_amount numeric(10,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    transmitted_at timestamp without time zone
);


ALTER TABLE public.orders OWNER TO "user";

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orders_id_seq OWNER TO "user";

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(100),
    email character varying(255),
    password_hash character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    transmitted_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO "user";

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO "user";

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: addresses id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.addresses (id, user_id, street, city, state, postal_code, created_at, updated_at, deleted_at, transmitted_at) FROM stdin;
1	1	123 Main St	Anytown	CA	12345	2024-06-06 10:53:26.040732	\N	\N	\N
2	2	456 Elm St	Othertown	NY	67890	2024-06-06 10:53:26.040732	\N	\N	\N
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.orders (id, user_id, order_date, total_amount, created_at, updated_at, deleted_at, transmitted_at) FROM stdin;
1	1	2024-06-01	100.00	2024-06-06 10:53:26.047886	\N	\N	\N
2	1	2024-06-02	150.00	2024-06-06 10:53:26.047886	\N	\N	\N
3	2	2024-06-03	200.00	2024-06-06 10:53:26.047886	\N	\N	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.users (id, username, email, password_hash, created_at, updated_at, deleted_at, transmitted_at) FROM stdin;
1	user1	user1@example.com	hashed_password_1	2024-06-06 10:53:26.026333	\N	\N	\N
2	user2	user2@example.com	hashed_password_2	2024-06-06 10:53:26.026333	\N	\N	\N
\.


--
-- Name: addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.addresses_id_seq', 2, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.orders_id_seq', 3, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: addresses address_changes; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER address_changes BEFORE INSERT OR DELETE OR UPDATE ON public.addresses FOR EACH ROW EXECUTE FUNCTION public.notify_address_changes();


--
-- Name: orders order_changes; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER order_changes BEFORE INSERT OR DELETE OR UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.notify_order_changes();


--
-- Name: users user_changes; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER user_changes BEFORE INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.notify_user_changes();


--
-- Name: addresses addresses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

