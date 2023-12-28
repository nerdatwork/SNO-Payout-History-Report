# SNO Payout History Report
**Storage Node Operator Payout History Report** 
<hr>




SNO PHR in short is a report created in Powershell. Powershell can run on [Windows/Linux/Mac](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell). The report collects data from `/api/heldamount/payout-history/<yyyy-mm>` endpoint. 

SNO PHR supports single and multiple nodes on the same network. So the **single** final report will include all nodes and their payout history details. 

<hr>

In order to get started, you have to enter `node alias` and `dashboard url` in the `nodeandurl.txt` file.

![image](https://github.com/nerdatwork/SNO-Payout-History-Report/assets/15882196/e787a8a9-a22b-4930-a9c3-bbed0010f984)



`node alias` is a nickname to uniquely identify your node in **your** network. As you can see the first line shows a node running with `node alias` = `Laptop` and its `dashboard url` = `192.168.1.1:14002` separated by a comma.

**Please make sure there aren't any leading or trailing spaces while entering `node alias` and `dashboard url` in the file.**

<hr>

Below is the format in which the data is presented in the report.

1. The report will show years of your node's entire life. 
2. Each year will show the year followed by the amount of USD you were paid in that year. *Since bonus multipliers aren't included in the endpoint these aren't accounted for in the yearly calculations.*
3. `Lifetime total` is shown at the end of every node's lifetime payout history data. If you have multiple nodes in the same network then it will be shown at the end of every node.
4. A month will be shown with `yyyy-mm` format as its title followed by the properties shown in the endpoint. Each column is individual `satellite id` the node was accessing in that month. 
5. When a node is paid for the month a receipt is shown in the endpoint. This receipt is shown as hyperlink linking to `ETH` or `Zksync` in the report. So, yes, ETH and ZkSync are both shown as links to their respective explorers. ETH links go to `etherscan` while ZkSync go to Zksync explorer.
6. In order to make it visually clear your node's `node alias` and `dashboard url` are shown next to each month. It is show on the left hand side of the table. 
7. At the top right of the page `Tax Information` is shown with a link to SNO's Tax information page. https://support.storj.io/hc/en-us/articles/360042696711-What-tax-forms-do-Storage-Node-Operators-need-to-submit

<hr>

Here is a sample month.

![image](https://github.com/nerdatwork/SNO-Payout-History-Report/assets/15882196/44ad5496-70d2-401b-b7c4-b9223353f543)




Here is a sample report.

![image](https://github.com/nerdatwork/SNO-Payout-History-Report/assets/15882196/4d493730-3474-4731-b75b-9a4ba94a030e)







