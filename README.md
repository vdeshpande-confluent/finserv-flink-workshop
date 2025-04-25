# Confluent Cloud - Flink SQL Finserv Workshop

Imagine you’re working in the financial services industry. You want to get an overview of your users' financial behaviors, track their investments, and assess the overall health of your portfolio. With Confluent Cloud as the backbone of your data, you can leverage Confluent Flink SQL for ad-hoc analysis and real-time insights into your financial transactions and user behavior!

To get the most out of this workshop, please read this [Guide to Flink SQL: An In-Depth Exploration](https://www.confluent.io/blog/getting-started-with-apache-flink-sql/). If you need a refresher on the basics of Kafka, we highly recommend our [Kafka Fundamentals Workshop](https://www.confluent.io/resources/online-talk/fundamentals-workshop-apache-kafka-101/).

In this workshop, we will build a Financial Services Data Pipeline with Flink SQL on Confluent Cloud. We’ll process financial transactions in real-time, provide insights, and track key metrics like account balances and transaction summaries. Below is an architecture diagram for the FinServ pipeline:

![image](terraform/img/Flink_Hands-on_Workshop_FinServ.png)

## Required Confluent Cloud Resources
This hands-on workshop consists of two labs (see below), which require Confluent Cloud infrastructure to be provisioned before starting the workshop. You can either set up the resources manually by following this [guide](prereq.md) or automate the provisioning using Terraform with this [guide](terraform/README.md).

If you prefer, you can deploy the complete finished workshop using Terraform. Please follow the [guide](terraform-complete/README.md) for an automated setup.

## Workshop Labs
  * [Lab 1](lab1.md): Financial Data Processing, Aggregations, Time Windows
  * [Lab 2](lab2.md): Joins, Data Enrichment, and Transaction Analysis

Together, the labs will design a real-time financial insights engine within Flink SQL. Below is a mapping of dynamic tables and topics used throughout the workshop.

![image](terraform/img/flink_sql_diagram_finserv.png)

## Optional: Complete Workshop Setup with Terraform
You can deploy the entire finished workshop using Terraform. Please follow the [guide](terraform-complete/README.md) to set up a fully functional financial insights pipeline. The only manual setup required is the notification system.

## Notification Client
You can find the Python Notification client in this [guide](notification_client.md).

## Costs of this Confluent Cloud - Flink SQL FinServ Workshop
The lab execution costs are minimal. We estimate the cost to be less than $10 for a few hours of testing. If you create the cluster a day before, we recommend pausing all connectors when not in use to save costs.

