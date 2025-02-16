-- Insert Financial Institutions
INSERT INTO financial_institutions (name, country_code, credit_rating) VALUES
('Goldman Sachs', 'US', 'A+'),
('JP Morgan', 'US', 'AA-'),
('Deutsche Bank', 'DE', 'BBB+'),
('UBS', 'CH', 'A+');

-- Insert Portfolios
INSERT INTO portfolios (name, institution_id, risk_profile, target_return) VALUES
                                                                               ('Conservative Growth', 1, 'LOW', 5.50),
                                                                               ('Aggressive Growth', 1, 'HIGH', 12.75),
                                                                               ('Balanced Income', 2, 'MEDIUM', 8.25);

-- Insert Instruments
INSERT INTO instruments (symbol, name, asset_class, issuer_id, currency_code, risk_rating) VALUES
                                                                                               ('AAPL', 'Apple Inc.', 'EQUITY', NULL, 'USD', 'MEDIUM'),
                                                                                               ('MSFT', 'Microsoft Corporation', 'EQUITY', NULL, 'USD', 'MEDIUM'),
                                                                                               ('T-BILL-3M', '3-Month Treasury Bill', 'FIXED_INCOME', 1, 'USD', 'LOW'),
                                                                                               ('GOLD-ETF', 'Gold ETF', 'COMMODITY', 2, 'USD', 'HIGH'),
                                                                                               ('REIT-01', 'Commercial REIT', 'REAL_ESTATE', 3, 'USD', 'MEDIUM');

-- Insert Portfolio Holdings
INSERT INTO portfolio_holdings (portfolio_id, instrument_id, quantity, average_cost) VALUES
                                                                                         (1, 1, 100.00, 150.25),
                                                                                         (1, 3, 1000.00, 98.50),
                                                                                         (2, 2, 150.00, 285.75),
                                                                                         (2, 4, 50.00, 175.25),
                                                                                         (3, 1, 75.00, 148.50),
                                                                                         (3, 5, 200.00, 95.25);

-- Insert Transactions
INSERT INTO transactions (portfolio_id, instrument_id, transaction_type, quantity, price, transaction_date) VALUES
                                                                                                                (1, 1, 'BUY', 100.00, 150.25, '2024-01-15 10:30:00'),
                                                                                                                (1, 3, 'BUY', 1000.00, 98.50, '2024-01-16 11:45:00'),
                                                                                                                (2, 2, 'BUY', 150.00, 285.75, '2024-01-17 09:15:00'),
                                                                                                                (2, 4, 'BUY', 50.00, 175.25, '2024-01-18 14:20:00'),
                                                                                                                (3, 1, 'BUY', 75.00, 148.50, '2024-01-19 15:30:00'),
                                                                                                                (3, 5, 'BUY', 200.00, 95.25, '2024-01-20 10:10:00'),
                                                                                                                (1, 1, 'DIVIDEND', NULL, 0.75, '2024-02-01 00:00:00');

-- Insert Market Prices (last 5 days of data)
INSERT INTO market_prices (instrument_id, price_date, closing_price, volume) VALUES
                                                                                 (1, '2024-02-10', 155.75, 1250000),
                                                                                 (1, '2024-02-11', 157.25, 1150000),
                                                                                 (1, '2024-02-12', 156.50, 1350000),
                                                                                 (1, '2024-02-13', 158.75, 1450000),
                                                                                 (1, '2024-02-14', 159.25, 1550000),
                                                                                 (2, '2024-02-10', 290.25, 850000),
                                                                                 (2, '2024-02-11', 292.75, 950000),
                                                                                 (2, '2024-02-12', 291.50, 900000),
                                                                                 (2, '2024-02-13', 294.25, 1050000),
                                                                                 (2, '2024-02-14', 295.75, 1150000);

-- Insert Performance Metrics
INSERT INTO performance_metrics (portfolio_id, calculation_date, total_value, daily_return, ytd_return, risk_metrics) VALUES
                                                                                                                          (1, '2024-02-14', 185250.00, 0.85, 5.25, '{"sharpe_ratio": 1.25, "volatility": 0.12, "beta": 0.85}'),
                                                                                                                          (2, '2024-02-14', 275500.00, 1.25, 8.75, '{"sharpe_ratio": 1.85, "volatility": 0.22, "beta": 1.35}'),
                                                                                                                          (3, '2024-02-14', 225750.00, 0.95, 6.50, '{"sharpe_ratio": 1.45, "volatility": 0.15, "beta": 0.95}');