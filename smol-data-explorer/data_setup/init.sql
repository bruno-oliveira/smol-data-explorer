CREATE TYPE asset_class AS ENUM ('EQUITY', 'FIXED_INCOME', 'REAL_ESTATE', 'COMMODITY', 'CASH');
CREATE TYPE transaction_type AS ENUM ('BUY', 'SELL', 'DIVIDEND', 'INTEREST', 'FEE');
CREATE TYPE risk_rating AS ENUM ('LOW', 'MEDIUM', 'HIGH');

-- Entities

CREATE TABLE financial_institutions (
                                        id SERIAL PRIMARY KEY,
                                        name VARCHAR(100) NOT NULL,
                                        country_code CHAR(2) NOT NULL,
                                        credit_rating VARCHAR(10),
                                        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE portfolios (
                            id SERIAL PRIMARY KEY,
                            name VARCHAR(100) NOT NULL,
                            institution_id INTEGER REFERENCES financial_institutions(id),
                            risk_profile risk_rating NOT NULL,
                            target_return DECIMAL(5,2),
                            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE instruments (
                             id SERIAL PRIMARY KEY,
                             symbol VARCHAR(20) NOT NULL,
                             name VARCHAR(100) NOT NULL,
                             asset_class asset_class NOT NULL,
                             issuer_id INTEGER REFERENCES financial_institutions(id),
                             currency_code CHAR(3) NOT NULL,
                             risk_rating risk_rating NOT NULL,
                             created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                             UNIQUE(symbol)
);

CREATE TABLE portfolio_holdings (
                                    portfolio_id INTEGER REFERENCES portfolios(id),
                                    instrument_id INTEGER REFERENCES instruments(id),
                                    quantity DECIMAL(15,6) NOT NULL,
                                    average_cost DECIMAL(15,2) NOT NULL,
                                    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                    PRIMARY KEY (portfolio_id, instrument_id)
);

CREATE TABLE transactions (
                              id SERIAL PRIMARY KEY,
                              portfolio_id INTEGER REFERENCES portfolios(id),
                              instrument_id INTEGER REFERENCES instruments(id),
                              transaction_type transaction_type NOT NULL,
                              quantity DECIMAL(15,6),
                              price DECIMAL(15,2),
                              transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
                              created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE market_prices (
                               instrument_id INTEGER REFERENCES instruments(id),
                               price_date DATE NOT NULL,
                               closing_price DECIMAL(15,2) NOT NULL,
                               volume BIGINT,
                               created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                               PRIMARY KEY (instrument_id, price_date)
);

CREATE TABLE performance_metrics (
                                     portfolio_id INTEGER REFERENCES portfolios(id),
                                     calculation_date DATE NOT NULL,
                                     total_value DECIMAL(15,2) NOT NULL,
                                     daily_return DECIMAL(8,4),
                                     ytd_return DECIMAL(8,4),
                                     risk_metrics JSONB,
                                     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                     PRIMARY KEY (portfolio_id, calculation_date)
);

-- Indexes for better query performance
CREATE INDEX idx_transactions_portfolio ON transactions(portfolio_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_market_prices_date ON market_prices(price_date);
CREATE INDEX idx_performance_date ON performance_metrics(calculation_date);

-- New ENUMs
CREATE TYPE rule_type AS ENUM ('CONCENTRATION', 'ASSET_CLASS', 'CURRENCY', 'CREDIT_RATING');
CREATE TYPE rebalance_frequency AS ENUM ('MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL');
CREATE TYPE corporate_action_type AS ENUM ('SPLIT', 'REVERSE_SPLIT', 'DIVIDEND', 'MERGER', 'SPINOFF', 'RIGHTS_ISSUE');
CREATE TYPE action_status AS ENUM ('PENDING', 'PROCESSED', 'CANCELLED');

-- New Tables
CREATE TABLE compliance_rules (
                                  id SERIAL PRIMARY KEY,
                                  portfolio_id INTEGER REFERENCES portfolios(id),
                                  rule_type rule_type NOT NULL,
                                  threshold_value DECIMAL(10,2) NOT NULL,
                                  active BOOLEAN DEFAULT true,
                                  description TEXT,
                                  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                  last_checked_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE rebalancing_schedules (
                                       id SERIAL PRIMARY KEY,
                                       portfolio_id INTEGER REFERENCES portfolios(id),
                                       target_allocation JSONB NOT NULL,
                                       tolerance_band DECIMAL(5,2) NOT NULL,
                                       frequency rebalance_frequency NOT NULL,
                                       last_rebalance_date TIMESTAMP WITH TIME ZONE,
                                       next_rebalance_date TIMESTAMP WITH TIME ZONE,
                                       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                       CONSTRAINT valid_tolerance CHECK (tolerance_band BETWEEN 0 AND 100)
);

CREATE TABLE corporate_actions (
                                   id SERIAL PRIMARY KEY,
                                   instrument_id INTEGER REFERENCES instruments(id),
                                   action_type corporate_action_type NOT NULL,
                                   announcement_date TIMESTAMP WITH TIME ZONE NOT NULL,
                                   record_date TIMESTAMP WITH TIME ZONE,
                                   payment_date TIMESTAMP WITH TIME ZONE,
                                   ratio DECIMAL(10,4),
                                   amount DECIMAL(10,4),
                                   currency_code CHAR(3),
                                   status action_status DEFAULT 'PENDING',
                                   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                   processed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for better query performance
CREATE INDEX idx_compliance_portfolio ON compliance_rules(portfolio_id);
CREATE INDEX idx_compliance_active ON compliance_rules(active);
CREATE INDEX idx_rebalancing_portfolio ON rebalancing_schedules(portfolio_id);
CREATE INDEX idx_rebalancing_next_date ON rebalancing_schedules(next_rebalance_date);
CREATE INDEX idx_corporate_actions_instrument ON corporate_actions(instrument_id);
CREATE INDEX idx_corporate_actions_dates ON corporate_actions(record_date, payment_date);
CREATE INDEX idx_corporate_actions_status ON corporate_actions(status);