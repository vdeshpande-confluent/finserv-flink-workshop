![image](terraform/img/confluent-logo-300-2.png)
# Lab 2
Finishing Lab 1 is required for Lab 2. If you have not completed it, go back to [Lab 1](lab1.md).


[1. Flink Joins](lab2.md#1-flink-joins)

[2. Understand Timestamps](lab2.md#2-understand-timestamps)

[3. Understand Joins](lab2.md#3-understand-joins)

[4. Data Enrichment](lab2.md#4-data-enrichment)

[5. Loyalty Levels Calculation](lab2.md#5-loyalty-levels-calculation)

[6. Promotions Calculation](lab2.md#6-promotions-calculation)



## 1. Flink Joins

Flink SQL supports complex and flexible join operations over dynamic tables. There are a number of different types of joins to account for the wide variety of semantics that queries may require.
By default, the order of joins is not optimized. Tables are joined in the order in which they are specified in the FROM clause.

You can find more information about Flink SQL Joins [here.](https://docs.confluent.io/cloud/current/flink/reference/queries/joins.html)

### 2. Understand Timestamps
Let's first look at our data records and their timestamps. Open the Flink SQL workspace.

If you left the Flink SQL Workspace or refreshed the page, `catalog` and `database` dropdowns are reset. Make sure they are selected again. 

![image](terraform/img/catalog-and-database-dropdown.png)

Find all user records for one user_id and display the timestamps from when the events were ingested in the `user_profiles` Kafka topic.
```
SELECT user_id,$rowtime 
FROM user_profiles  
WHERE user_id = 'User9';
```
NOTE: Check the timestamps from when the user records were generated.

Find all stock_orders for one customer and display the timestamps from when the events were ingested in the `stock_orders` Kafka topic.
```
SELECT order_id ,$rowtime
FROM stock_orders
WHERE user_id = 'User9';
```
NOTE: Check the timestamps when the orders were generated. This is important for the join operations we will do next.

Find all stock prices for one symbol and display the timestamps from when the events were ingested in the `stock_prices` Kafka topic.
```
SELECT symbol,$rowtime 
FROM stock_prices  
WHERE symbol = 'GOOG';
```
### 3. Understand Joins
Now, we can look at the different types of joins available. 
We will join `stock_orders` records and `stock_prices` records.

Join stock orders with non-keyed stock prices records (Regular Join). Joining unbounded data streams requires Time-To-Live configuration:
```
SELECT /*+ STATE_TTL('sp'='6h', 'so'='2d') */  
order_id, so.`$rowtime`, so.symbol
FROM stock_orders as so
INNER JOIN stock_prices as sp
ON so.symbol = sp.symbol
WHERE so.symbol  = 'GOOG';
```
NOTE: Look at the number of rows returned for each order. There are many duplicates! Ideally we just want one correct price attached for every order.

Joining infinite data streams can cause your state to grow indefinitely. Look at Time-to-live to limit the state size [here.](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/best-practices.html#implement-state-time-to-live-ttl)
TTL Hints configuraiton examples [More info here.](https://docs.confluent.io/cloud/current/flink/reference/statements/hints.html)

Join orders with non-keyed prices records in some time windows (Interval Join):
Check if there is a stock price record that was created within 10 minutes after the order was created. Did price changed after/before placing the order?
```
SELECT order_id, so.`$rowtime` AS order_time, sp.`$rowtime` AS price_change_record_time , so.symbol
FROM stock_orders as so
INNER JOIN stock_prices as sp
ON so.symbol = sp.symbol
WHERE order_id = 955 AND
  so.`$rowtime` BETWEEN sp.`$rowtime` - INTERVAL '10' MINUTES AND sp.`$rowtime`;
```

Join orders with keyed stock price records (Regular Join with Keyed Table):
```
SELECT order_id, so.`$rowtime`,symbol,user_id,side,quantity,order_type
FROM stock_orders as so
INNER JOIN stock_prices_keyed as spk
ON so.symbol = spk.symbol
WHERE so.order_id = 955;
```
NOTE: Look at the number of rows returned. There are no duplicates! This is because we have only one price record for each symbol.

Join orders with keyed stock price records at the time when order was created (Temporal Join with Keyed Table):
```
SELECT
  o.order_id,
  o.user_id,
  o.symbol,
  o.quantity,
  p.price AS executed_price,
  o.quantity * p.price AS trade_value FROM stock_orders AS o
JOIN stock_prices_keyed FOR SYSTEM_TIME AS OF o.`$rowtime` AS p
ON o.symbol = p.symbol;
```
NOTE 1: There might be empty result set if keyed customers tables was created after the order records were ingested in the stock_orders topic. 

NOTE 2: You can find more information about Temporal Joins with Flink SQL [here.](https://docs.confluent.io/cloud/current/flink/reference/queries/joins.html#temporal-joins)

### 4. Data Enrichment
We can store the result of a join in a new table. 
We will join data from: User Profile , Order, Prices tables together in a single SQL statement.

Create a new table for `Stock Orders <-> Users Profile <-> Stock Prices` join result:
```
CREATE TABLE stock_price_data_product AS  
SELECT
  o.order_id,
  o.user_id,
  u.name AS user_name,
  u.email AS user_email,
  u.phone AS user_phone,
  o.symbol,
  o.quantity,
  p.price AS executed_price,
  o.quantity * p.price AS trade_value
FROM stock_orders AS o
JOIN stock_prices_keyed FOR SYSTEM_TIME AS OF o.`$rowtime` AS p
  ON o.symbol = p.symbol
JOIN user_profiles_keyed FOR SYSTEM_TIME AS OF o.`$rowtime` AS u
  ON o.user_id = u.user_id;
```

Verify that the data was joined successfully. 
```
SELECT * FROM stock_price_data_productt;
```

###💼 5. Derive User Holdings (from executed trades) 

Now we are ready to calculate net position per user per stock.

Let's see :
```
SELECT
  user_id,
  symbol,
  SUM(CASE WHEN `type` = 'BUY' THEN quantity ELSE -quantity END) AS total_quantity,
  SUM(CASE WHEN `type` = 'BUY' THEN trade_value ELSE -trade_value END) AS total_investment 
FROM stock_price_data_product
GROUP BY user_id, symbol;
```

Prepare the table for user holdings:
```
CREATE TABLE user_holdings(
  user_id STRING,
  symbol STRING,
  total_quantity INTEGER,
  total_investment INTEGER, 
  PRIMARY KEY (user_id,symbol) NOT ENFORCED
);
```

Now you can calculate loyalty levels and store the results in the new table.
```
INSERT INTO user_holdings
SELECT
  user_id,
  symbol,
  SUM(CASE WHEN `type` = 'BUY' THEN quantity ELSE -quantity END) AS total_quantity,
  SUM(CASE WHEN `type` = 'BUY' THEN trade_value ELSE -trade_value END) AS total_investment 
FROM stock_price_data_product
GROUP BY user_id, symbol;
```

Verify your results:
```
SELECT * FROM user_holdings;
```

###🏆 6. Trader Leaderboard 

Let's find out if top traders.
```
CREATE TABLE top_traders AS
SELECT
  user_id,
  COUNT(order_id) AS trade_count,
  SUM(trade_value) AS total_trade_value
FROM stock_price_data_productt
GROUP BY user_id
ORDER BY total_trade_value DESC
LIMIT 10;
 ```


###⏱️ 7.Symbol-Wise Trade Activity (Hourly)

```sql
CREATE TABLE hourly_symbol_activity AS
SELECT
  symbol,
  window_start,
  SUM(quantity) AS total_volume,
  SUM(trade_value) AS traded_value
FROM TABLE(
  TUMBLE(TABLE stock_price_data_productt, DESCRIPTOR(order_time), INTERVAL '1' HOUR)
)
GROUP BY symbol, window_start;
```

All data products are created now and events are in motion. Visit the brand new data portal to get all information you need and query the data. Give it a try!

![image](terraform/img/dataportal.png)

## End of Lab2.

# If you don't need your infrastructure anymore, do not forget to delete the resources!
