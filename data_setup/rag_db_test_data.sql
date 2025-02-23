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
         ORDER BY fi.credit_rating, i.symbol;'),
-- Risk Analysis
(
    'Calculate the volatility of daily returns for each portfolio in the last month',
    'WITH daily_returns AS (
        SELECT
            portfolio_id,
            calculation_date,
            daily_return,
            AVG(daily_return) OVER (PARTITION BY portfolio_id) as avg_return
        FROM performance_metrics
        WHERE calculation_date >= CURRENT_DATE - INTERVAL ''1 month''
    )
    SELECT
        p.name as portfolio_name,
        SQRT(AVG(POW(daily_return - avg_return, 2))) as volatility,
        AVG(daily_return) as average_return
    FROM daily_returns dr
    JOIN portfolios p ON dr.portfolio_id = p.id
    GROUP BY p.name
    ORDER BY volatility DESC;'
),
(
    'Show correlation between portfolio returns in the last quarter',
    'WITH daily_returns AS (
        SELECT
            portfolio_id,
            calculation_date,
            daily_return
        FROM performance_metrics
        WHERE calculation_date >= CURRENT_DATE - INTERVAL ''3 months''
    )
    SELECT
        p1.name as portfolio_1,
        p2.name as portfolio_2,
        CORR(dr1.daily_return, dr2.daily_return) as return_correlation
    FROM daily_returns dr1
    JOIN daily_returns dr2 ON dr1.calculation_date = dr2.calculation_date
    JOIN portfolios p1 ON dr1.portfolio_id = p1.id
    JOIN portfolios p2 ON dr2.portfolio_id = p2.id
    WHERE p1.id < p2.id
    GROUP BY p1.name, p2.name
    HAVING CORR(dr1.daily_return, dr2.daily_return) IS NOT NULL
    ORDER BY return_correlation DESC;'
),

-- Performance Attribution
(
    'Calculate contribution to return by asset class for each portfolio',
    'WITH portfolio_returns AS (
        SELECT
            p.id as portfolio_id,
            p.name as portfolio_name,
            i.asset_class,
            SUM(ph.quantity * (mp_latest.closing_price - mp_prev.closing_price)) /
            SUM(ph.quantity * mp_prev.closing_price) * 100 as asset_class_return
        FROM portfolios p
        JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
        JOIN instruments i ON ph.instrument_id = i.id
        JOIN market_prices mp_latest ON i.id = mp_latest.instrument_id
        JOIN market_prices mp_prev ON i.id = mp_prev.instrument_id
        WHERE mp_latest.price_date = CURRENT_DATE
        AND mp_prev.price_date = CURRENT_DATE - INTERVAL ''1 month''
        GROUP BY p.id, p.name, i.asset_class
    )
    SELECT
        portfolio_name,
        asset_class,
        asset_class_return,
        SUM(asset_class_return) OVER (PARTITION BY portfolio_name) as total_portfolio_return
    FROM portfolio_returns
    ORDER BY portfolio_name, asset_class_return DESC;'
),
(
    'Identify best and worst performing instruments in each portfolio',
    'WITH instrument_returns AS (
        SELECT
            p.name as portfolio_name,
            i.symbol,
            i.name as instrument_name,
            ((mp_latest.closing_price - mp_prev.closing_price) / mp_prev.closing_price * 100)::DECIMAL(5,2) as return_pct,
            ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY ((mp_latest.closing_price - mp_prev.closing_price) / mp_prev.closing_price) DESC) as top_rank,
            ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY ((mp_latest.closing_price - mp_prev.closing_price) / mp_prev.closing_price) ASC) as bottom_rank
        FROM portfolios p
        JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
        JOIN instruments i ON ph.instrument_id = i.id
        JOIN market_prices mp_latest ON i.id = mp_latest.instrument_id
        JOIN market_prices mp_prev ON i.id = mp_prev.instrument_id
        WHERE mp_latest.price_date = CURRENT_DATE
        AND mp_prev.price_date = CURRENT_DATE - INTERVAL ''1 month''
    )
    SELECT
        portfolio_name,
        symbol,
        instrument_name,
        return_pct,
        CASE WHEN top_rank = 1 THEN ''Best'' ELSE ''Worst'' END as performance_type
    FROM instrument_returns
    WHERE top_rank = 1 OR bottom_rank = 1
    ORDER BY portfolio_name, return_pct DESC;'
),

-- Trading Activity
(
    'Show total trading volume by portfolio in the last week',
    'SELECT
        p.name as portfolio_name,
        COUNT(*) as trade_count,
        SUM(CASE WHEN t.transaction_type = ''BUY'' THEN t.quantity * t.price ELSE 0 END) as total_buys,
        SUM(CASE WHEN t.transaction_type = ''SELL'' THEN t.quantity * t.price ELSE 0 END) as total_sells
    FROM portfolios p
    JOIN transactions t ON p.id = t.portfolio_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL ''7 days''
    GROUP BY p.name
    ORDER BY trade_count DESC;'
),
(
    'List largest individual trades by value',
    'SELECT
        p.name as portfolio_name,
        i.symbol,
        t.transaction_type,
        t.quantity,
        t.price,
        (t.quantity * t.price) as total_value,
        t.transaction_date
    FROM transactions t
    JOIN portfolios p ON t.portfolio_id = p.id
    JOIN instruments i ON t.instrument_id = i.id
    WHERE t.transaction_type IN (''BUY'', ''SELL'')
    ORDER BY (t.quantity * t.price) DESC
    LIMIT 10;'
),

-- Portfolio Allocation
(
    'Show current sector allocation versus targets',
    'WITH current_allocation AS (
        SELECT
            p.id as portfolio_id,
            p.name as portfolio_name,
            i.asset_class,
            (SUM(ph.quantity * mp.closing_price) / SUM(SUM(ph.quantity * mp.closing_price)) OVER (PARTITION BY p.id)) * 100 as current_pct
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
        ca.current_pct::DECIMAL(5,2) as current_allocation,
        (rs.target_allocation->>(ca.asset_class::text))::DECIMAL(5,2) as target_allocation,
        (ca.current_pct - (rs.target_allocation->>(ca.asset_class::text))::DECIMAL)::DECIMAL(5,2) as allocation_difference
    FROM current_allocation ca
    JOIN rebalancing_schedules rs ON ca.portfolio_id = rs.portfolio_id
    ORDER BY ca.portfolio_name, allocation_difference DESC;'
),
(
    'Calculate portfolio diversification metrics',
    'WITH holding_weights AS (
        SELECT
            p.id as portfolio_id,
            p.name as portfolio_name,
            COUNT(DISTINCT i.asset_class) as asset_class_count,
            COUNT(DISTINCT i.id) as instrument_count,
            MAX((ph.quantity * mp.closing_price) / SUM(ph.quantity * mp.closing_price) OVER (PARTITION BY p.id) * 100) as largest_position_pct
        FROM portfolios p
        JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
        JOIN instruments i ON ph.instrument_id = i.id
        JOIN market_prices mp ON i.id = mp.instrument_id
        WHERE mp.price_date = (SELECT MAX(price_date) FROM market_prices)
        GROUP BY p.id, p.name
    )
    SELECT
        portfolio_name,
        asset_class_count,
        instrument_count,
        largest_position_pct::DECIMAL(5,2) as largest_position_pct,
        (100.0 / instrument_count)::DECIMAL(5,2) as theoretical_equal_weight
    FROM holding_weights
    ORDER BY largest_position_pct ASC;'
),

-- Compliance Monitoring
(
    'List all compliance breaches in the last month',
    'WITH holding_concentrations AS (
        SELECT
            p.id as portfolio_id,
            p.name as portfolio_name,
            i.id as instrument_id,
            i.symbol,
            i.asset_class,
            (ph.quantity * mp.closing_price) / SUM(ph.quantity * mp.closing_price) OVER (PARTITION BY p.id) * 100 as concentration
        FROM portfolios p
        JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
        JOIN instruments i ON ph.instrument_id = i.id
        JOIN market_prices mp ON i.id = mp.instrument_id
        WHERE mp.price_date = (SELECT MAX(price_date) FROM market_prices)
    )
    SELECT
        hc.portfolio_name,
        hc.symbol,
        hc.asset_class,
        cr.rule_type,
        cr.threshold_value as limit_value,
        hc.concentration::DECIMAL(5,2) as current_value,
        (hc.concentration - cr.threshold_value)::DECIMAL(5,2) as breach_amount
    FROM holding_concentrations hc
    JOIN compliance_rules cr ON hc.portfolio_id = cr.portfolio_id
    WHERE cr.active = true
    AND hc.concentration > cr.threshold_value
    ORDER BY breach_amount DESC;'
),
(
    'Show portfolios approaching compliance limits',
    'WITH holding_metrics AS (
        SELECT
            p.id as portfolio_id,
            p.name as portfolio_name,
            i.asset_class,
            (ph.quantity * mp.closing_price) / SUM(ph.quantity * mp.closing_price) OVER (PARTITION BY p.id) * 100 as concentration
        FROM portfolios p
        JOIN portfolio_holdings ph ON p.id = ph.portfolio_id
        JOIN instruments i ON ph.instrument_id = i.id
        JOIN market_prices mp ON i.id = mp.instrument_id
        WHERE mp.price_date = (SELECT MAX(price_date) FROM market_prices)
        GROUP BY p.id, p.name, i.asset_class
    )
    SELECT
        hm.portfolio_name,
        hm.asset_class,
        cr.rule_type,
        cr.threshold_value as limit_value,
        hm.concentration::DECIMAL(5,2) as current_value,
        (cr.threshold_value - hm.concentration)::DECIMAL(5,2) as buffer_remaining
    FROM holding_metrics hm
    JOIN compliance_rules cr ON hm.portfolio_id = cr.portfolio_id
    WHERE cr.active = true
    AND (cr.threshold_value - hm.concentration) < 5
    AND hm.concentration < cr.threshold_value
    ORDER BY buffer_remaining ASC;'
),

-- Generic Queries
(
    'List all instruments with their latest prices and 30-day price change',
    'WITH price_changes AS (
        SELECT
            instrument_id,
            first_value(closing_price) OVER (PARTITION BY instrument_id ORDER BY price_date DESC) as current_price,
            first_value(closing_price) OVER (PARTITION BY instrument_id ORDER BY price_date ASC) as old_price
        FROM market_prices
        WHERE price_date >= CURRENT_DATE - INTERVAL ''30 days''
    )
    SELECT
        i.symbol,
        i.name,
        i.asset_class,
        pc.current_price,
        ((pc.current_price - pc.old_price) / pc.old_price * 100)::DECIMAL(5,2) as price_change_pct
    FROM instruments i
    LEFT JOIN price_changes pc ON i.id = pc.instrument_id
    ORDER BY price_change_pct DESC NULLS LAST;'
),
(
    'Summarize portfolio metrics by institution',
    'SELECT
        fi.name as institution_name,
        COUNT(DISTINCT p.id) as portfolio_count,
        AVG(pm.ytd_return)::DECIMAL(5,2) as avg_ytd_return,
        SUM(pm.total_value) as total_aum
    FROM financial_institutions fi
    JOIN portfolios p ON fi.id = p.institution_id
    JOIN performance_metrics pm ON p.id = pm.portfolio_id
    WHERE pm.calculation_date = (SELECT MAX(calculation_date) FROM performance_metrics)
    GROUP BY fi.name
    ORDER BY total_aum DESC;'
),
(
    'Show recent activity summary across all portfolios',
    'SELECT
        DATE_TRUNC(''day'', t.transaction_date) as activity_date,
        COUNT(*) as total_transactions,
        COUNT(DISTINCT t.portfolio_id) as portfolios_traded,
        COUNT(DISTINCT t.instrument_id) as instruments_traded,
        SUM(CASE WHEN t.transaction_type = ''BUY'' THEN 1 ELSE 0 END) as buy_count,
        SUM(CASE WHEN t.transaction_type = ''SELL'' THEN 1 ELSE 0 END) as sell_count
    FROM transactions t
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL ''7 days''
    GROUP BY DATE_TRUNC(''day'', t.transaction_date)
    ORDER BY activity_date DESC;'
);