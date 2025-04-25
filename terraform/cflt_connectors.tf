# --------------------------------------------------------
# Service Accounts (Connectors)
# --------------------------------------------------------
resource "confluent_service_account" "connectors" {
  display_name = "connectors-${random_id.id.hex}"
  description  = local.description
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Access Control List (ACL)
# --------------------------------------------------------
# Allow the service account to perform operations on the topics
resource "confluent_kafka_acl" "connectors_source_create_topic_demo" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "CREATE"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_cluster_key.id
    secret = confluent_api_key.app_manager_kafka_cluster_key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_source_write_topic_demo" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "WRITE"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_cluster_key.id
    secret = confluent_api_key.app_manager_kafka_cluster_key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_acl" "connectors_source_read_topic_demo" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "READ"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_cluster_key.id
    secret = confluent_api_key.app_manager_kafka_cluster_key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Create Kafka Topics
# --------------------------------------------------------
resource "confluent_kafka_topic" "stock_prices" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  topic_name       = "stock_prices"
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_cluster_key.id
    secret = confluent_api_key.app_manager_kafka_cluster_key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_topic" "stock_orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  topic_name       = "stock_orders"
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_cluster_key.id
    secret = confluent_api_key.app_manager_kafka_cluster_key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_topic" "user_profiles" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  topic_name       = "user_profiles"
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_cluster_key.id
    secret = confluent_api_key.app_manager_kafka_cluster_key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Create Connectors for DataGen
# --------------------------------------------------------

# Datagen for stock_prices
resource "confluent_connector" "datagen_stock_prices" {
  environment {
    id = confluent_environment.cc_handson_env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  config_sensitive = {}
  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "datagen-stock-prices-${random_id.id.hex}"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.connectors.id
    "kafka.topic"              = confluent_kafka_topic.stock_prices.topic_name
    "output.data.format"       = "AVRO"
    "schema.string"            = "{\"namespace\":\"finserv\",\"name\":\"StockPrices\",\"doc\":\"Defines a hypothetical stock price update.\",\"type\":\"record\",\"fields\":[{\"name\":\"symbol\",\"doc\":\"Stock symbol\",\"type\":{\"type\":\"string\",\"arg.properties\":{\"options\":[\"AAPL\",\"GOOG\",\"AMZN\",\"MSFT\",\"TSLA\",\"META\"]}}},{\"name\":\"price\",\"doc\":\"Latest stock price in pennies\",\"type\":{\"type\":\"int\",\"arg.properties\":{\"range\":{\"min\":100,\"max\":50000}}}},{\"name\":\"timestamp\",\"doc\":\"Timestamp of the price update (epoch ms)\",\"type\":\"long\"}]}"

    "tasks.max"    = "1"
    "max.interval" = "500"
  }
  depends_on = [
    confluent_kafka_acl.connectors_source_create_topic_demo,
    confluent_kafka_acl.connectors_source_write_topic_demo,
    confluent_kafka_acl.connectors_source_read_topic_demo
  ]
  lifecycle {
    prevent_destroy = false
  }
}

# Datagen for stock_orders
resource "confluent_connector" "datagen_stock_orders" {
  environment {
    id = confluent_environment.cc_handson_env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  config_sensitive = {}
  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "datagen-stock-orders-${random_id.id.hex}"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.connectors.id
    "kafka.topic"              = confluent_kafka_topic.stock_orders.topic_name
    "output.data.format"       = "AVRO"
    "schema.string"            = "{\"namespace\":\"finserv\",\"name\":\"StockOrders\",\"doc\":\"Defines a hypothetical stock order with sequential order ID and relevant order details.\",\"type\":\"record\",\"fields\":[{\"name\":\"order_id\",\"doc\":\"Sequential order ID starting from 0\",\"type\":{\"type\":\"int\",\"arg.properties\":{\"iteration\":{\"start\":0}}}},{\"name\":\"user_id\",\"doc\":\"User placing the order\",\"type\":{\"type\":\"string\",\"arg.properties\":{\"options\":[\"User1\",\"User2\",\"User3\",\"User4\",\"User5\",\"User6\",\"User7\",\"User8\",\"User9\",\"User10\",\"User11\",\"User12\",\"User13\",\"User14\",\"User15\",\"User16\",\"User17\",\"User18\",\"User19\",\"User20\",\"User21\",\"User22\",\"User23\",\"User24\",\"User25\",\"User26\",\"User27\",\"User28\",\"User29\",\"User30\"]}}},{\"name\":\"side\",\"doc\":\"Order side (BUY, SELL, SHORT)\",\"type\":{\"type\":\"string\",\"arg.properties\":{\"options\":[\"BUY\",\"SELL\",\"SHORT\"]}}},{\"name\":\"quantity\",\"doc\":\"Number of shares\",\"type\":{\"type\":\"int\",\"arg.properties\":{\"range\":{\"min\":1,\"max\":10000}}}},{\"name\":\"symbol\",\"doc\":\"Stock symbol being ordered\",\"type\":{\"type\":\"string\",\"arg.properties\":{\"options\":[\"AAPL\",\"GOOG\",\"AMZN\",\"MSFT\",\"TSLA\",\"META\"]}}},{\"name\":\"order_type\",\"doc\":\"How the order to be executed in the market\",\"type\":{\"type\":\"string\",\"arg.properties\":{\"options\":[\"LIMIT\",\"MARKET\",\"STOP\"]}}}]}"
    "tasks.max"                = "1"
    "max.interval"             = "500"
  }
  depends_on = [
    confluent_kafka_acl.connectors_source_create_topic_demo,
    confluent_kafka_acl.connectors_source_write_topic_demo,
    confluent_kafka_acl.connectors_source_read_topic_demo
  ]
  lifecycle {
    prevent_destroy = false
  }
}

# Datagen for user_profiles
resource "confluent_connector" "datagen_user_profiles" {
  environment {
    id = confluent_environment.cc_handson_env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cc_kafka_cluster.id
  }
  config_sensitive = {}
  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "datagen-user-profiles-${random_id.id.hex}"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.connectors.id
    "kafka.topic"              = confluent_kafka_topic.user_profiles.topic_name
    "output.data.format"       = "AVRO"
    "schema.string"            = "{\"namespace\":\"finserv\",\"name\":\"UserProfiles\",\"type\":\"record\",\"fields\":[{\"name\":\"user_id\",\"type\":\"string\"},{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"email\",\"type\":\"string\"},{\"name\":\"phone\",\"type\":\"string\"},{\"name\":\"ssn\",\"type\":\"string\"}],\"arg.properties\":{\"options\":[{\"user_id\":\"User1\",\"name\":\"Alice Johnson\",\"email\":\"alice.j@example.com\",\"phone\":\"+1-800-555-0001\",\"ssn\":\"123-45-6781\"},{\"user_id\":\"User2\",\"name\":\"Bob Smith\",\"email\":\"bob.smith@example.com\",\"phone\":\"+1-800-555-0002\",\"ssn\":\"123-45-6782\"},{\"user_id\":\"User3\",\"name\":\"Clara Adams\",\"email\":\"clara.adams@example.com\",\"phone\":\"+1-800-555-0003\",\"ssn\":\"123-45-6783\"},{\"user_id\":\"User4\",\"name\":\"David Lee\",\"email\":\"david.lee@example.com\",\"phone\":\"+1-800-555-0004\",\"ssn\":\"123-45-6784\"},{\"user_id\":\"User5\",\"name\":\"Evelyn Brown\",\"email\":\"evelyn.brown@example.com\",\"phone\":\"+1-800-555-0005\",\"ssn\":\"123-45-6785\"},{\"user_id\":\"User6\",\"name\":\"Frank Green\",\"email\":\"frank.green@example.com\",\"phone\":\"+1-800-555-0006\",\"ssn\":\"123-45-6786\"},{\"user_id\":\"User7\",\"name\":\"Grace Martin\",\"email\":\"grace.martin@example.com\",\"phone\":\"+1-800-555-0007\",\"ssn\":\"123-45-6787\"},{\"user_id\":\"User8\",\"name\":\"Henry Wilson\",\"email\":\"henry.wilson@example.com\",\"phone\":\"+1-800-555-0008\",\"ssn\":\"123-45-6788\"},{\"user_id\":\"User9\",\"name\":\"Ivy Clark\",\"email\":\"ivy.clark@example.com\",\"phone\":\"+1-800-555-0009\",\"ssn\":\"123-45-6789\"},{\"user_id\":\"User10\",\"name\":\"Jack White\",\"email\":\"jack.white@example.com\",\"phone\":\"+1-800-555-0010\",\"ssn\":\"123-45-6790\"},{\"user_id\":\"User11\",\"name\":\"Kara Hall\",\"email\":\"kara.hall@example.com\",\"phone\":\"+1-800-555-0011\",\"ssn\":\"123-45-6791\"},{\"user_id\":\"User12\",\"name\":\"Leo Scott\",\"email\":\"leo.scott@example.com\",\"phone\":\"+1-800-555-0012\",\"ssn\":\"123-45-6792\"},{\"user_id\":\"User13\",\"name\":\"Mia Young\",\"email\":\"mia.young@example.com\",\"phone\":\"+1-800-555-0013\",\"ssn\":\"123-45-6793\"},{\"user_id\":\"User14\",\"name\":\"Noah King\",\"email\":\"noah.king@example.com\",\"phone\":\"+1-800-555-0014\",\"ssn\":\"123-45-6794\"},{\"user_id\":\"User15\",\"name\":\"Olivia Wright\",\"email\":\"olivia.wright@example.com\",\"phone\":\"+1-800-555-0015\",\"ssn\":\"123-45-6795\"},{\"user_id\":\"User16\",\"name\":\"Paul Lopez\",\"email\":\"paul.lopez@example.com\",\"phone\":\"+1-800-555-0016\",\"ssn\":\"123-45-6796\"},{\"user_id\":\"User17\",\"name\":\"Quinn Hill\",\"email\":\"quinn.hill@example.com\",\"phone\":\"+1-800-555-0017\",\"ssn\":\"123-45-6797\"},{\"user_id\":\"User18\",\"name\":\"Rachel Allen\",\"email\":\"rachel.allen@example.com\",\"phone\":\"+1-800-555-0018\",\"ssn\":\"123-45-6798\"},{\"user_id\":\"User19\",\"name\":\"Samuel Baker\",\"email\":\"samuel.baker@example.com\",\"phone\":\"+1-800-555-0019\",\"ssn\":\"123-45-6799\"},{\"user_id\":\"User20\",\"name\":\"Tina Campbell\",\"email\":\"tina.campbell@example.com\",\"phone\":\"+1-800-555-0020\",\"ssn\":\"123-45-6800\"},{\"user_id\":\"User21\",\"name\":\"Uma Foster\",\"email\":\"uma.foster@example.com\",\"phone\":\"+1-800-555-0021\",\"ssn\":\"123-45-6801\"},{\"user_id\":\"User22\",\"name\":\"Victor Hayes\",\"email\":\"victor.hayes@example.com\",\"phone\":\"+1-800-555-0022\",\"ssn\":\"123-45-6802\"},{\"user_id\":\"User23\",\"name\":\"Wendy James\",\"email\":\"wendy.james@example.com\",\"phone\":\"+1-800-555-0023\",\"ssn\":\"123-45-6803\"},{\"user_id\":\"User24\",\"name\":\"Xavier Lewis\",\"email\":\"xavier.lewis@example.com\",\"phone\":\"+1-800-555-0024\",\"ssn\":\"123-45-6804\"},{\"user_id\":\"User25\",\"name\":\"Yara Mitchell\",\"email\":\"yara.mitchell@example.com\",\"phone\":\"+1-800-555-0025\",\"ssn\":\"123-45-6805\"},{\"user_id\":\"User26\",\"name\":\"Zane Nelson\",\"email\":\"zane.nelson@example.com\",\"phone\":\"+1-800-555-0026\",\"ssn\":\"123-45-6806\"},{\"user_id\":\"User27\",\"name\":\"Abby Owens\",\"email\":\"abby.owens@example.com\",\"phone\":\"+1-800-555-0027\",\"ssn\":\"123-45-6807\"},{\"user_id\":\"User28\",\"name\":\"Ben Peterson\",\"email\":\"ben.peterson@example.com\",\"phone\":\"+1-800-555-0028\",\"ssn\":\"123-45-6808\"},{\"user_id\":\"User29\",\"name\":\"Cindy Reed\",\"email\":\"cindy.reed@example.com\",\"phone\":\"+1-800-555-0029\",\"ssn\":\"123-45-6809\"},{\"user_id\":\"User30\",\"name\":\"Danielle Stone\",\"email\":\"danielle.stone@example.com\",\"phone\":\"+1-800-555-0030\",\"ssn\":\"123-45-6810\"}]}}"

    "tasks.max"    = "1"
    "max.interval" = "500"
  }
  depends_on = [
    confluent_kafka_acl.connectors_source_create_topic_demo,
    confluent_kafka_acl.connectors_source_write_topic_demo,
    confluent_kafka_acl.connectors_source_read_topic_demo
  ]
  lifecycle {
    prevent_destroy = false
  }
}
