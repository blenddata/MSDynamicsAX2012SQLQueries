### Microsoft Dynamics AX 2012 SQL Server Queries
 
**Procurement and sourcing**

**Purchase orders**

*All purchase orders confirmations. We must fetch the last version of confirmation and some of `PURCHQTY` may be null or zero so we lookup for item qty in prev confirmations.*

* Step 1: Purch table all version data: 
	- [x] Fetch the last confirmation: `Done`

* Step 1: Purch line table all version data: 
	- [x] lookup for item qty in prev confirmations : `Done`