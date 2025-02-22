--
-- PostgreSQL database dump
--

-- Dumped from database version 15.12 (Debian 15.12-1.pgdg120+1)
-- Dumped by pg_dump version 15.10 (Postgres.app)

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
-- Name: action_status; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.action_status AS ENUM (
    'PENDING',
    'PROCESSED',
    'CANCELLED'
);


ALTER TYPE public.action_status OWNER TO admin;

--
-- Name: asset_class; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.asset_class AS ENUM (
    'EQUITY',
    'FIXED_INCOME',
    'REAL_ESTATE',
    'COMMODITY',
    'CASH'
);


ALTER TYPE public.asset_class OWNER TO admin;

--
-- Name: corporate_action_type; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.corporate_action_type AS ENUM (
    'SPLIT',
    'REVERSE_SPLIT',
    'DIVIDEND',
    'MERGER',
    'SPINOFF',
    'RIGHTS_ISSUE'
);


ALTER TYPE public.corporate_action_type OWNER TO admin;

--
-- Name: rebalance_frequency; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.rebalance_frequency AS ENUM (
    'MONTHLY',
    'QUARTERLY',
    'SEMI_ANNUAL',
    'ANNUAL'
);


ALTER TYPE public.rebalance_frequency OWNER TO admin;

--
-- Name: risk_rating; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.risk_rating AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH'
);


ALTER TYPE public.risk_rating OWNER TO admin;

--
-- Name: rule_type; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.rule_type AS ENUM (
    'CONCENTRATION',
    'ASSET_CLASS',
    'CURRENCY',
    'CREDIT_RATING'
);


ALTER TYPE public.rule_type OWNER TO admin;

--
-- Name: transaction_type; Type: TYPE; Schema: public; Owner: admin
--

CREATE TYPE public.transaction_type AS ENUM (
    'BUY',
    'SELL',
    'DIVIDEND',
    'INTEREST',
    'FEE'
);


ALTER TYPE public.transaction_type OWNER TO admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: compliance_rules; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.compliance_rules (
    id integer NOT NULL,
    portfolio_id integer,
    rule_type public.rule_type NOT NULL,
    threshold_value numeric(10,2) NOT NULL,
    active boolean DEFAULT true,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_checked_at timestamp with time zone
);


ALTER TABLE public.compliance_rules OWNER TO admin;

--
-- Name: compliance_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.compliance_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.compliance_rules_id_seq OWNER TO admin;

--
-- Name: compliance_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.compliance_rules_id_seq OWNED BY public.compliance_rules.id;


--
-- Name: corporate_actions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.corporate_actions (
    id integer NOT NULL,
    instrument_id integer,
    action_type public.corporate_action_type NOT NULL,
    announcement_date timestamp with time zone NOT NULL,
    record_date timestamp with time zone,
    payment_date timestamp with time zone,
    ratio numeric(10,4),
    amount numeric(10,4),
    currency_code character(3),
    status public.action_status DEFAULT 'PENDING'::public.action_status,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    processed_at timestamp with time zone
);


ALTER TABLE public.corporate_actions OWNER TO admin;

--
-- Name: corporate_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.corporate_actions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.corporate_actions_id_seq OWNER TO admin;

--
-- Name: corporate_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.corporate_actions_id_seq OWNED BY public.corporate_actions.id;


--
-- Name: financial_institutions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.financial_institutions (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    country_code character(2) NOT NULL,
    credit_rating character varying(10),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.financial_institutions OWNER TO admin;

--
-- Name: financial_institutions_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.financial_institutions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.financial_institutions_id_seq OWNER TO admin;

--
-- Name: financial_institutions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.financial_institutions_id_seq OWNED BY public.financial_institutions.id;


--
-- Name: instruments; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.instruments (
    id integer NOT NULL,
    symbol character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    asset_class public.asset_class NOT NULL,
    issuer_id integer,
    currency_code character(3) NOT NULL,
    risk_rating public.risk_rating NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.instruments OWNER TO admin;

--
-- Name: instruments_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.instruments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.instruments_id_seq OWNER TO admin;

--
-- Name: instruments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.instruments_id_seq OWNED BY public.instruments.id;


--
-- Name: market_prices; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.market_prices (
    instrument_id integer NOT NULL,
    price_date date NOT NULL,
    closing_price numeric(15,2) NOT NULL,
    volume bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.market_prices OWNER TO admin;

--
-- Name: performance_metrics; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.performance_metrics (
    portfolio_id integer NOT NULL,
    calculation_date date NOT NULL,
    total_value numeric(15,2) NOT NULL,
    daily_return numeric(8,4),
    ytd_return numeric(8,4),
    risk_metrics jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.performance_metrics OWNER TO admin;

--
-- Name: portfolio_holdings; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.portfolio_holdings (
    portfolio_id integer NOT NULL,
    instrument_id integer NOT NULL,
    quantity numeric(15,6) NOT NULL,
    average_cost numeric(15,2) NOT NULL,
    last_updated timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.portfolio_holdings OWNER TO admin;

--
-- Name: portfolios; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.portfolios (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    institution_id integer,
    risk_profile public.risk_rating NOT NULL,
    target_return numeric(5,2),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.portfolios OWNER TO admin;

--
-- Name: portfolios_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.portfolios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.portfolios_id_seq OWNER TO admin;

--
-- Name: portfolios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.portfolios_id_seq OWNED BY public.portfolios.id;


--
-- Name: rebalancing_schedules; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.rebalancing_schedules (
    id integer NOT NULL,
    portfolio_id integer,
    target_allocation jsonb NOT NULL,
    tolerance_band numeric(5,2) NOT NULL,
    frequency public.rebalance_frequency NOT NULL,
    last_rebalance_date timestamp with time zone,
    next_rebalance_date timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_tolerance CHECK (((tolerance_band >= (0)::numeric) AND (tolerance_band <= (100)::numeric)))
);


ALTER TABLE public.rebalancing_schedules OWNER TO admin;

--
-- Name: rebalancing_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.rebalancing_schedules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rebalancing_schedules_id_seq OWNER TO admin;

--
-- Name: rebalancing_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.rebalancing_schedules_id_seq OWNED BY public.rebalancing_schedules.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.transactions (
    id integer NOT NULL,
    portfolio_id integer,
    instrument_id integer,
    transaction_type public.transaction_type NOT NULL,
    quantity numeric(15,6),
    price numeric(15,2),
    transaction_date timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.transactions OWNER TO admin;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transactions_id_seq OWNER TO admin;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: compliance_rules id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.compliance_rules ALTER COLUMN id SET DEFAULT nextval('public.compliance_rules_id_seq'::regclass);


--
-- Name: corporate_actions id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.corporate_actions ALTER COLUMN id SET DEFAULT nextval('public.corporate_actions_id_seq'::regclass);


--
-- Name: financial_institutions id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.financial_institutions ALTER COLUMN id SET DEFAULT nextval('public.financial_institutions_id_seq'::regclass);


--
-- Name: instruments id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.instruments ALTER COLUMN id SET DEFAULT nextval('public.instruments_id_seq'::regclass);


--
-- Name: portfolios id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.portfolios ALTER COLUMN id SET DEFAULT nextval('public.portfolios_id_seq'::regclass);


--
-- Name: rebalancing_schedules id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.rebalancing_schedules ALTER COLUMN id SET DEFAULT nextval('public.rebalancing_schedules_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: compliance_rules compliance_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.compliance_rules
    ADD CONSTRAINT compliance_rules_pkey PRIMARY KEY (id);


--
-- Name: corporate_actions corporate_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.corporate_actions
    ADD CONSTRAINT corporate_actions_pkey PRIMARY KEY (id);


--
-- Name: financial_institutions financial_institutions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.financial_institutions
    ADD CONSTRAINT financial_institutions_pkey PRIMARY KEY (id);


--
-- Name: instruments instruments_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.instruments
    ADD CONSTRAINT instruments_pkey PRIMARY KEY (id);


--
-- Name: instruments instruments_symbol_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.instruments
    ADD CONSTRAINT instruments_symbol_key UNIQUE (symbol);


--
-- Name: market_prices market_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.market_prices
    ADD CONSTRAINT market_prices_pkey PRIMARY KEY (instrument_id, price_date);


--
-- Name: performance_metrics performance_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.performance_metrics
    ADD CONSTRAINT performance_metrics_pkey PRIMARY KEY (portfolio_id, calculation_date);


--
-- Name: portfolio_holdings portfolio_holdings_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.portfolio_holdings
    ADD CONSTRAINT portfolio_holdings_pkey PRIMARY KEY (portfolio_id, instrument_id);


--
-- Name: portfolios portfolios_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT portfolios_pkey PRIMARY KEY (id);


--
-- Name: rebalancing_schedules rebalancing_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.rebalancing_schedules
    ADD CONSTRAINT rebalancing_schedules_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: idx_compliance_active; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_compliance_active ON public.compliance_rules USING btree (active);


--
-- Name: idx_compliance_portfolio; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_compliance_portfolio ON public.compliance_rules USING btree (portfolio_id);


--
-- Name: idx_corporate_actions_dates; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_corporate_actions_dates ON public.corporate_actions USING btree (record_date, payment_date);


--
-- Name: idx_corporate_actions_instrument; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_corporate_actions_instrument ON public.corporate_actions USING btree (instrument_id);


--
-- Name: idx_corporate_actions_status; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_corporate_actions_status ON public.corporate_actions USING btree (status);


--
-- Name: idx_market_prices_date; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_market_prices_date ON public.market_prices USING btree (price_date);


--
-- Name: idx_performance_date; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_performance_date ON public.performance_metrics USING btree (calculation_date);


--
-- Name: idx_rebalancing_next_date; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_rebalancing_next_date ON public.rebalancing_schedules USING btree (next_rebalance_date);


--
-- Name: idx_rebalancing_portfolio; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_rebalancing_portfolio ON public.rebalancing_schedules USING btree (portfolio_id);


--
-- Name: idx_transactions_date; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_transactions_date ON public.transactions USING btree (transaction_date);


--
-- Name: idx_transactions_portfolio; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_transactions_portfolio ON public.transactions USING btree (portfolio_id);


--
-- Name: compliance_rules compliance_rules_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.compliance_rules
    ADD CONSTRAINT compliance_rules_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(id);


--
-- Name: corporate_actions corporate_actions_instrument_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.corporate_actions
    ADD CONSTRAINT corporate_actions_instrument_id_fkey FOREIGN KEY (instrument_id) REFERENCES public.instruments(id);


--
-- Name: instruments instruments_issuer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.instruments
    ADD CONSTRAINT instruments_issuer_id_fkey FOREIGN KEY (issuer_id) REFERENCES public.financial_institutions(id);


--
-- Name: market_prices market_prices_instrument_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.market_prices
    ADD CONSTRAINT market_prices_instrument_id_fkey FOREIGN KEY (instrument_id) REFERENCES public.instruments(id);


--
-- Name: performance_metrics performance_metrics_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.performance_metrics
    ADD CONSTRAINT performance_metrics_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(id);


--
-- Name: portfolio_holdings portfolio_holdings_instrument_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.portfolio_holdings
    ADD CONSTRAINT portfolio_holdings_instrument_id_fkey FOREIGN KEY (instrument_id) REFERENCES public.instruments(id);


--
-- Name: portfolio_holdings portfolio_holdings_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.portfolio_holdings
    ADD CONSTRAINT portfolio_holdings_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(id);


--
-- Name: portfolios portfolios_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT portfolios_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.financial_institutions(id);


--
-- Name: rebalancing_schedules rebalancing_schedules_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.rebalancing_schedules
    ADD CONSTRAINT rebalancing_schedules_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(id);


--
-- Name: transactions transactions_instrument_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_instrument_id_fkey FOREIGN KEY (instrument_id) REFERENCES public.instruments(id);


--
-- Name: transactions transactions_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(id);


--
-- PostgreSQL database dump complete
--

