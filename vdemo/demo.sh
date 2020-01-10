shopt -s expand_aliases
source ./kalias.source


#Fill data
kmysql <data.sql
sleep 1

#Materialize Product table to Customer as a lookup table
echo "************ Materializing Product table ************"
kvtctl ApplyVSchema -vschema="$(cat new_customer.json)" customer
sleep 1
kvtctl Materialize "$(cat mat_product.json)"
sleep 1
kvtctl ApplyRoutingRules -rules='{"rules": [{"fromTable":"product", "toTables":["product.product", "customer.product"]}]}'
sleep 1
kvtctl GetRoutingRules


#Materialize Customer Orders to Merchant Orders with a different sharding key
echo "************ Materializing Orders table ************"
kvtctl ApplyVSchema -vschema="$(cat new_merchant.json)" merchant
sleep 1
kvtctl Materialize "$(cat mat_orders.json)"
sleep 1
kvtctl ApplyRoutingRules -rules='{"rules": [{"fromTable":"orders", "toTables":["customer.orders", "merchant.orders"]}]}'
sleep 1
kvtctl GetRoutingRules

#Migrate Customer Orders to Merchant Orders
kvtctl MigrateReads -tablet_type=rdonly merchant.mat_orders
kvtctl MigrateReads -tablet_type=replica merchant.mat_orders
kvtctl MigrateWrites merchant.mat_orders


echo Demo Done



#vtgate link 		: http://localhost:15001/debug/status
#Tablet links
#Product Tablet 	: http://localhost:15100/debug/status
#Customer Tablet -80 	: http://localhost:15200/debug/status
#Customer Tablet 80- 	: http://localhost:15300/debug/status
#Merchant Tablet -80 	: http://localhost:15400/debug/status
#Merchant Tablet 80- 	: http://localhost:15500/debug/status

#app/run.py		: http://localhost:8000

