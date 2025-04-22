Got it — you're absolutely right. We should **first perform the temporal join** of `stock_orders` with `stock_prices` to fetch the **price at the time of the order**, and then **derive holdings and valuations** from that enriched data (not from current prices). Let's refactor **Lab 2** with this logic as the foundation.

---

## 📘 Lab 2: Real-Time Portfolio Analytics from Trades (Refactored)

---

### 🧾 Use Case Overview

In this lab, we:
- Enrich trade orders with stock price at the time of order.
- Build a holdings table from historical trade activity.
- Track portfolio valuations based on executed prices (not live).
- Build trade leaderboards and exposure analytics.

---

## 🧱 Step 1: Temporal Join to Get Executed Price per Trade

```sql
CREATE VIEW enriched_orders AS
SELECT
  o.order_id,
  o.user_id,
  o.symbol,
  o.type,
  o.quantity,
  p.price AS executed_price,
  o.quantity * p.price AS trade_value,
  o.order_time
FROM stock_orders AS o
JOIN stock_prices FOR SYSTEM_TIME AS OF o.order_time AS p
ON o.symbol = p.symbol;
```

> This gives us the **executed price** for each trade using a **temporal join**.

---

## 💼 Step 2: Derive User Holdings (from executed trades)

```sql
CREATE VIEW user_holdings AS
SELECT
  user_id,
  symbol,
  SUM(CASE WHEN type = 'BUY' THEN quantity ELSE -quantity END) AS total_quantity
FROM enriched_orders
GROUP BY user_id, symbol;
```

> This computes net position per user per stock.

---

## 💰 Step 3: Portfolio Valuation (Based on Executed Prices)

```sql
CREATE VIEW portfolio_valuation AS
SELECT
  user_id,
  symbol,
  total_quantity,
  AVG(executed_price) AS avg_price,
  total_quantity * AVG(executed_price) AS portfolio_value
FROM (
  SELECT
    user_id,
    symbol,
    type,
    quantity,
    executed_price
  FROM enriched_orders
) t
JOIN user_holdings h
ON t.user_id = h.user_id AND t.symbol = h.symbol
GROUP BY t.user_id, t.symbol, h.total_quantity;
```

> This approximates portfolio value based on average executed price (not live mark-to-market).

---

## 🚨 Step 4: Risk Exposure

```sql
CREATE VIEW high_exposure_users AS
SELECT
  user_id,
  SUM(portfolio_value) AS total_portfolio_value
FROM portfolio_valuation
GROUP BY user_id
HAVING SUM(portfolio_value) > 100000;  -- example threshold
```

---

## 🏆 Step 5: Trader Leaderboard

```sql
CREATE VIEW top_traders AS
SELECT
  user_id,
  COUNT(order_id) AS trade_count,
  SUM(trade_value) AS total_trade_value
FROM enriched_orders
GROUP BY user_id
ORDER BY total_trade_value DESC
LIMIT 10;
```

---

## ⏱️ Step 6: Symbol-Wise Trade Activity (Hourly)

```sql
CREATE VIEW hourly_symbol_activity AS
SELECT
  symbol,
  TUMBLE_START(order_time, INTERVAL '1' HOUR) AS window_start,
  SUM(quantity) AS total_volume,
  SUM(trade_value) AS traded_value
FROM enriched_orders
GROUP BY symbol, TUMBLE(order_time, INTERVAL '1' HOUR);
```

---

## ✅ Summary

| Stage | Action |
|-------|--------|
| Step 1 | Temporal join `stock_orders` + `stock_prices` to get `executed_price` |
| Step 2 | Calculate net `user_holdings` |
| Step 3 | Estimate `portfolio_valuation` based on execution history |
| Step 4 | Identify `high_exposure_users` |
| Step 5 | Rank `top_traders` by trade value |
| Step 6 | Analyze trade volume by symbol and time window |

---

Let me know if you'd like this as an updated `lab2.md`, or want to move on to **Lab 3** (Fraud, PII alerting, compliance signals).
