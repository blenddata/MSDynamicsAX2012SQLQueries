### Microsoft Dynamics AX 2012 SQL Server Queries
 
**Procurement and sourcing**

**Purchase orders**

*In some cases, Purchase orders prices do not match Trade agreements prices, so we will be able to detect this fault using this query.*

* Step 1: Trade agreements prices: 
	- [x] Fetch all purchase prices from trade agreements: `Done`

* Step 2: Purchase order lines: 
	- [x] Uniquify all items by ITEMID and ACCOUNTINGDATE: `Done`

* Step 3: Join Trade agreement price and Items : 
	- [x] Every item has 3 prices including purchase price, site price, base price (ACCOUNTINGDATE range). : `Done`

* Step 4: Purchase order : 
	- [x] Compare each purchase line price with site or base price (must be equal) : `Done`