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