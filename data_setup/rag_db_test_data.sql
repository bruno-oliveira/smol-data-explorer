\c rag_db

INSERT INTO public.query_examples (question, query)
VALUES ('What is the current market value of each portfolio, including the portfolio name and institution name?',
        'WITH latest_prices AS (
        SELECT instrument_id,
               closing_price,
               ROW_NUMBER() OVER (PARTITION BY instrument_id ORDER BY price_date DESC) as rn
        FROM market_prices
    )
    SELECT
        p.name as portfolio_name,
        fi.name as institution_name,
        SUM(ph.quantity * lp.closing_price) as current_market_value
    FROM portfolios p
    JOIN financial_institutions fi ON p.institution_id = fi.id
    JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
    JOIN latest_prices lp ON ph.instrument_id = lp.instrument_id
    WHERE lp.rn = 1
    GROUP BY p.name, fi.name
    ORDER BY current_market_value DESC;'),
       ('Show me all pending corporate actions and their impact on portfolio holdings',
        'WITH portfolio_exposure AS (
        SELECT
            ca.id as action_id,
            p.name as portfolio_name,
            i.symbol,
            ca.action_type,
            ca.payment_date,
            ph.quantity,
            CASE
                WHEN ca.action_type = ''SPLIT'' THEN ph.quantity * ca.ratio
                WHEN ca.action_type = ''DIVIDEND'' THEN ph.quantity * ca.amount
                ELSE 0
            END as expected_impact
        FROM corporate_actions ca
        JOIN instruments i ON ca.instrument_id = i.id
        JOIN portfolio_holdings ph ON i.id = ph.instrument_id
        JOIN portfolios p ON ph.portfolio_id = p.id
        WHERE ca.status = ''PENDING''
    )
    SELECT * FROM portfolio_exposure
    ORDER BY payment_date;'),
       ('Which portfolios are currently violating their compliance rules?',
        'WITH portfolio_concentrations AS (
        SELECT
            p.id as portfolio_id,
            p.name as portfolio_name,
            i.symbol,
            i.asset_class,
            (ph.quantity * mp.closing_price) /
            SUM(ph.quantity * mp.closing_price) OVER (PARTITION BY p.id) * 100 as concentration
        FROM portfolios p
        JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
        JOIN instruments i ON ph.instrument_id = i.id
        JOIN market_prices mp ON i.id = mp.instrument_id
        WHERE mp.price_date = (SELECT MAX(price_date) FROM market_prices)
    )
    SELECT
        pc.portfolio_name,
        cr.rule_type,
        cr.threshold_value as limit_value,
        pc.symbol,
        pc.concentration as current_value,
        (pc.concentration - cr.threshold_value) as breach_amount
    FROM portfolio_concentrations pc
    JOIN compliance_rules cr ON pc.portfolio_id = cr.portfolio_id
    WHERE
        cr.active = true
        AND pc.concentration > cr.threshold_value
    ORDER BY breach_amount DESC;'),
       ('Calculate year-to-date performance for each portfolio with risk metrics',
        'WITH ytd_returns AS (
        SELECT
            p.name as portfolio_name,
            p.risk_profile,
            MAX(pm.ytd_return) as ytd_return,
            jsonb_array_elements(pm.risk_metrics::jsonb) as risk_metric
        FROM portfolios p
        JOIN performance_metrics pm ON p.id = pm.portfolio_id
        WHERE EXTRACT(YEAR FROM pm.calculation_date) = EXTRACT(YEAR FROM CURRENT_DATE)
        GROUP BY p.name, p.risk_profile, pm.risk_metrics
    )
    SELECT
        portfolio_name,
        risk_profile,
        ytd_return,
        risk_metric->''sharpe_ratio'' as sharpe_ratio,
        risk_metric->''volatility'' as volatility,
        risk_metric->''beta'' as beta
    FROM ytd_returns
    ORDER BY ytd_return DESC;'),
       ('Show portfolios that need rebalancing based on their target allocations',
        'WITH current_allocations AS (
        SELECT
            p.id as portfolio_id,
            p.name as portfolio_name,
            i.asset_class,
            SUM(ph.quantity * mp.closing_price) /
            SUM(SUM(ph.quantity * mp.closing_price)) OVER (PARTITION BY p.id) * 100 as current_allocation
        FROM portfolios p
        JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
        JOIN instruments i ON ph.instrument_id = i.id
        JOIN market_prices mp ON i.id = mp.instrument_id
        WHERE mp.price_date = (SELECT MAX(price_date) FROM market_prices)
        GROUP BY p.id, p.name, i.asset_class
    )
    SELECT
        ca.portfolio_name,
        ca.asset_class,
        rs.target_allocation->>(ca.asset_class::text) as target_pct,
        ca.current_allocation as current_pct,
        ABS(ca.current_allocation - (rs.target_allocation->>(ca.asset_class::text))::numeric) as deviation
    FROM current_allocations ca
    JOIN rebalancing_schedules rs ON ca.portfolio_id = rs.portfolio_id
    WHERE ABS(ca.current_allocation - (rs.target_allocation->>(ca.asset_class::text))::numeric) > rs.tolerance_band
    ORDER BY deviation DESC;'),
       ('List all portfolios and their risk profiles',
        'SELECT name, risk_profile, target_return
         FROM portfolios
         ORDER BY name;'),
       ('Show me the total number of instruments by asset class',
        'SELECT asset_class, COUNT(*) as instrument_count
         FROM instruments
         GROUP BY asset_class
         ORDER BY instrument_count DESC;'),
       ('What are the latest prices for all instruments?',
        'SELECT i.symbol, i.name, mp.closing_price, mp.price_date
         FROM instruments i
         JOIN market_prices mp ON i.id = mp.instrument_id
         WHERE mp.price_date = (SELECT MAX(price_date) FROM market_prices);'),
       ('Which institution has the highest credit rating?',
        'SELECT name, credit_rating, country_code
         FROM financial_institutions
         ORDER BY credit_rating ASC
         LIMIT 1;'),
       ('List all dividend payments received in 2024',
        'SELECT
            p.name as portfolio_name,
            i.symbol,
            t.price as dividend_amount,
            t.transaction_date
         FROM transactions t
         JOIN portfolios p ON t.portfolio_id = p.id
         JOIN instruments i ON t.instrument_id = i.id
         WHERE t.transaction_type = ''DIVIDEND''
         AND EXTRACT(YEAR FROM t.transaction_date) = 2024
         ORDER BY t.transaction_date DESC;'),
       ('Show me all US-based financial institutions',
        'SELECT name, credit_rating
         FROM financial_institutions
         WHERE country_code = ''US''
         ORDER BY name;'),
       ('What is the total transaction count by type?',
        'SELECT
            transaction_type,
            COUNT(*) as transaction_count
         FROM transactions
         GROUP BY transaction_type
         ORDER BY transaction_count DESC;'),
       ('Which instruments have no transactions?',
        'SELECT i.symbol, i.name, i.asset_class
         FROM instruments i
         LEFT JOIN transactions t ON i.id = t.instrument_id
         WHERE t.id IS NULL;'),
       ('Show the average daily trading volume for each equity',
        'SELECT
            i.symbol,
            AVG(mp.volume) as avg_daily_volume,
            MIN(mp.volume) as min_volume,
            MAX(mp.volume) as max_volume
         FROM instruments i
         JOIN market_prices mp ON i.id = mp.instrument_id
         WHERE i.asset_class = ''EQUITY''
         GROUP BY i.symbol
         ORDER BY avg_daily_volume DESC;'),
       ('List portfolios with their total number of holdings',
        'SELECT
            p.name as portfolio_name,
            COUNT(ph.instrument_id) as number_of_holdings
         FROM portfolios p
         LEFT JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
         GROUP BY p.name
         ORDER BY number_of_holdings DESC;'),
       ('Find instruments with price increases over the last 5 days',
        'WITH price_change AS (
            SELECT
                instrument_id,
                first_value(closing_price) OVER (PARTITION BY instrument_id ORDER BY price_date DESC) as latest_price,
                first_value(closing_price) OVER (PARTITION BY instrument_id ORDER BY price_date ASC) as oldest_price
            FROM market_prices
            WHERE price_date >= CURRENT_DATE - INTERVAL ''5 days''
        )
        SELECT
            i.symbol,
            i.name,
            pc.oldest_price,
            pc.latest_price,
            ((pc.latest_price - pc.oldest_price) / pc.oldest_price * 100)::DECIMAL(5,2) as price_change_pct
        FROM price_change pc
        JOIN instruments i ON pc.instrument_id = i.id
        WHERE pc.latest_price > pc.oldest_price
        ORDER BY price_change_pct DESC;'),
       ('Show me all fixed income instruments and their issuers',
        'SELECT
            i.symbol,
            i.name,
            fi.name as issuer_name,
            fi.credit_rating as issuer_rating
         FROM instruments i
         LEFT JOIN financial_institutions fi ON i.issuer_id = fi.id
         WHERE i.asset_class = ''FIXED_INCOME''
         ORDER BY fi.credit_rating, i.symbol;');