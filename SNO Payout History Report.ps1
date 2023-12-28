
function Get-NodeInfo
{
	$nodeInfo = Get-Content "nodeandurl.txt" | ForEach-Object {
		$parts = $_ -split ','
		[PSCustomObject]@{
			NodeAlias = $parts[0].Trim()
			NodeURL   = $parts[1].Trim()
		}
	}
	
	return $nodeInfo
}

function Get-EarliestJoinedDate
{
	param (
		[PSCustomObject]$NodeInfo
	)
	
	$satelliteAPI = "$($NodeInfo.NodeURL)/api/sno/satellites"
	$satellites = Invoke-WebRequest -Uri $satelliteAPI | ConvertFrom-Json
	
	$earliestJoinedDate = $satellites.earliestJoinedAt
	
	if ($earliestJoinedDate)
	{
		return $earliestJoinedDate.ToString("yyyy-MM")
	}
	else
	{
		Write-Host "Error: Could not determine the earliest joined date. Please check the satellite API."
		exit
	}
}

function Get-SatelliteData
{
	param (
		[string]$Date,
		[PSCustomObject]$NodeInfo
	)
	
	$endpoint = "$($NodeInfo.NodeURL)/api/heldamount/payout-history/$Date"
	$satelliteData = Invoke-RestMethod -Uri $endpoint
	return $satelliteData
}

function Create-HTMLReport
{
	param (
		[string]$OutputFilePath,
		[array]$MonthlySatelliteData
	)
	
	$PSStyle.Progress.View = "Minimal"
	$PSStyle.Progress.Style = "`e[45m"
	
	$nerdCSS = @{
		head = @"
<title>NAW's SNO PH Report</title>

<!-- Import Material Design Lite styles -->
<link rel="stylesheet" href="https://code.getmdl.io/1.3.0/material.indigo-pink.min.css">
<script defer src="https://code.getmdl.io/1.3.0/material.min.js"></script>

<style type="text/css">
    body {
        background-color: #f8f9fa;
        font-family: 'Roboto', sans-serif;
        margin: 0;
        padding: 0;
    }

    header {
        background-color: #333f4d;
        padding: 10px;
        color: white;
        font-size: 20px;
        position: fixed;
        width: 100%;
		z-index: 1000;
		display: flex;
        justify-content: space-between;
        align-items: center;
		
    }
	
	.header-text{
		flex-grow: 1;
		text-align: center;
		padding-left: 150px;
	}

	.tax-info{
		text-align: right;
		padding-right: 12px;
	}
	
    h2, h3 {
        color: #2196F3;
        text-align: center;
    }

	h5{
		text-align: center;
		text-decoration: underline;
	}

	h6{
		text-align: center;
		color: green;
		font-weight: bold;
	}

    td {
        background-color: #FFFFFF;
        border: 1px solid #E0E0E0;
        color: #616161;
        font-size: 14px;
        padding: 12px;
    }

    th {
        background-color: #1976D2;
        color: white;
        font-size: 14px;
        padding: 12px;
    }
	
    .year-table {
        margin-top: 20px;
        width: 80%;
        margin-left: auto;
        margin-right: auto;
    }

    .collapsible {
        background-color: #1976D2;
        color: white;
        cursor: pointer;
        padding: 15px;
        width: 100%;
        border: none;
        text-align: center;
        outline: none;
        font-size: 18px;
        transition: background-color 0.3s;
    }

    .collapsible:hover {
        background-color: #1565C0;
    }

    .content {
        padding: 0 18px;
        max-height: 0;
        overflow: hidden;
        transition: max-height 0.2s ease-out;
    }

    .receipt-link {
        color: #2196F3;
        text-decoration: underline;
        cursor: pointer;
    }

    footer {
        background-color: #333f4d;
        color: white;
        padding: 10px;
        position: fixed;
        bottom: 0;
        width: 100%;
		text-align: center;
    }

    .alert {
        color: #EF5350;
        text-align: center;
        font-weight: bold;
    }
	
	table {
		position: relative;
		margin-left: 200px; /* Set to the width of the background image */
        width: calc(100% - 200px);
        border-collapse: collapse;
	}

	table::before {
      content: attr(data-background-text);
      position: absolute;
      left: -150px; /* Adjust as needed */
      top: 50%;
      transform: rotate(-90deg) translateY(-50%);
      font-size: 22px;
      color: rgba(0, 0, 0, 0.2);
      white-space: nowrap;
    }

	#goToTopBtn {
        display: none; /* Hide the button by default */
        position: fixed;
        bottom: 40px;
        right: 20px;
        background-color: #007bff;
        color: white;
        border: none;
        border-radius: 5px;
        padding: 10px 15px;
        cursor: pointer;
		z-index: auto;
    }

    #goToTopBtn:hover {
        background-color: #0056b3;
    }

	.total-amount {
        font-weight: bold;
        color: gold; 

</style>

<script>
    window.onscroll = function() { scrollFunction(); };

    function scrollFunction() {
        var btn = document.getElementById("goToTopBtn");

        if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
            btn.style.display = "block";
        } else {
            btn.style.display = "none";
        }
    }

    function goToTop() {
        document.body.scrollTop = 0;
        document.documentElement.scrollTop = 0;
    }
</script>


"@
		
	}
	
	$htmlReport = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    $($nerdCSS['head'])
    <script>
        function toggleContent(nodealias, nodeurl, year) {
            var content = document.getElementById('content_' + nodealias  + '_' + nodeurl + '_' + year);
            content.style.maxHeight = content.style.maxHeight === '0px' ? content.scrollHeight + 'px' : '0px';
        }

        function openReceiptLink(url) {
            window.open(url, '_blank');
        }
    </script>
</head>
<body>

<header>
	<div class="header-text"> NerdAtWork's SNO Payout History Report </div>
	<div class="tax-info"> <a href="https://support.storj.io/hc/en-us/articles/360042696711-What-tax-forms-do-Storage-Node-Operators-need-to-submit" target="_blank" style="text-align:right"> Tax Information </a></div>
</header>
			<br>
"@
	
	$nodeInfoList = Get-NodeInfo
	
	foreach ($nodeInfo in $nodeInfoList)
	{
		$startingDate = Get-EarliestJoinedDate -NodeInfo $nodeInfo
		
		$currentDate = Get-Date
		$currentMonth = Get-Date -Format "yyyy-MM"
		
		$htmlReport += @"
    <h5>$($nodeInfo.NodeAlias)'s Payout History Report</h5>
"@

		$lifetimeTotal = 0
		
		$monthlySatelliteData = @()
		
		$totalMonths = [math]::ceiling(($currentDate - [datetime]::parse($startingDate)).TotalDays / 30)
		
		$i = 0
		while ($startingDate -le $currentMonth)
		{
			$satelliteData = Get-SatelliteData -Date $startingDate -NodeInfo $nodeInfo
			
			$monthlySatelliteData += [PSCustomObject]@{
				Month		  = $startingDate
				SatelliteData = $satelliteData
			}
			
			$startingDate = (Get-Date $startingDate).AddMonths(1).ToString("yyyy-MM")
			
			$progress = ($i + 1) / $totalMonths * 100
			Write-Progress -Activity "Processing Months" -Status "Month $startingDate" -PercentComplete $progress
			$i++
		}
		
		$currentYear = $null
		foreach ($monthlyData in $monthlySatelliteData)
		{
			$month = $monthlyData.Month
			$year = $month.Substring(0, 4) 
			$satelliteData = $monthlyData.SatelliteData
			
			$totalAmount = 0
			$yearlyData = $monthlySatelliteData | Where-Object { $_.Month -like "$year-*" }
			
			for ($i = 0; $i -lt $yearlyData.SatelliteData.count; $i++)
			{
				$totalAmount += $yearlyData.SatelliteData[$i].distributed
			}
			
			$totalAmount /= 1e6 
			
			
			if ($currentYear -ne $year)
			{
				if ($currentYear)
				{
					$htmlReport += @"
    </div>
"@
				}
				
				$lifetimeTotal += $totalAmount.ToString("0.00")
				
				$htmlReport += @" 
    <button class='collapsible' data-target='$($nodeInfo.NodeAlias)_$($nodeInfo.NodeURL)_$year' onclick='toggleContent("$($nodeInfo.NodeAlias)", "$($nodeInfo.NodeURL)", "$year")'>$year &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; [ Paid: <span class='total-amount'>$($totalAmount.ToString("0.00")) USD</span> ] </button>
    <div class='content' id='content_$($nodeInfo.NodeAlias)_$($nodeInfo.NodeURL)_$year'>
"@
				$currentYear = $year
			}
			
			if ($satelliteData -and $satelliteData.Count -gt 0)
			{
				$htmlReport += @"
    <h3>$month</h3>
    <table class='year-table' data-background-text="$($NodeInfo.NodeAlias) @ $($NodeInfo.NodeURL)">
        <tr>
            <th>Property</th>
"@
				
				$satelliteIDs = $satelliteData | ForEach-Object { $_.satelliteID } | Select-Object -Unique
				
				foreach ($satelliteID in $satelliteIDs)
				{
					$shortenedSatelliteID = $satelliteID.Substring(0, 4) + "..." + $satelliteID.Substring($satelliteID.Length - 4)
					$htmlReport += @"
            <th>$shortenedSatelliteID</th>
"@
				}
				
				$htmlReport += @"
        </tr>
"@
			
				$properties = $satelliteData[0].PSObject.Properties.Name | Where-Object { $_ -ne 'satelliteID' } | Select-Object -Unique
				
				foreach ($property in $properties)
				{
					$htmlReport += @"
        <tr>
            <td>$property</td>
"@
					
					foreach ($satelliteID in $satelliteIDs)
					{
						$value = ($satelliteData | Where-Object { $_.satelliteID -eq $satelliteID }).$property
						$cellContent = $value
						
						if ($property -eq 'receipt' -and $value -match 'eth:[0-9a-fA-F]+')
						{
							$ethValue = $value -replace 'eth:'
							$shortenedValue = "eth: " + $ethValue.Substring(0, 6) + "..." + $ethValue.Substring($ethValue.Length - 4)
							$cellContent = "<span class='receipt-link' onclick='openReceiptLink(`"https://etherscan.io/tx/$ethValue`")'>$shortenedValue</span>"
						}
						elseif ($property -eq 'receipt' -and $value -match 'zkwithdraw:[0-9a-fA-F]+')
						{							
							$zkValue = $value -replace 'zkwithdraw:'
							$shortenedZKValue = "zkwithdraw: " + $zkValue.Substring(0, 6) + "..." + $zkValue.Substring($zkValue.Length - 4)
							$cellContent = "<span class='receipt-link' onclick='openReceiptLink(`"https://explorer.zksync.io/tx/$zkValue`")'>$shortenedZKValue</span>"
						}
						
						$htmlReport += @"
            <td>$cellContent</td>
"@
					}
					
					$htmlReport += @"
        </tr>
"@
				}
				
				$htmlReport += @"
    </table>
	<hr>
"@
				
			}
			else
			{
				$htmlReport += @"
    <p class='alert'>No data available for $month.</p>
"@
			}
		}
		
		$htmlReport += @"
    </div>
<button id="goToTopBtn" onclick="goToTop()"> ? Top</button>
<script>
        function goToTop() {
            document.body.scrollTop = 0;
            document.documentElement.scrollTop = 0;
        }

// Set background text dynamically using JavaScript
    document.addEventListener('DOMContentLoaded', function() {
      var tables = document.querySelectorAll('table');
      tables.forEach(function(table) {
        var backgroundText = table.getAttribute('data-background-text');
        table.style.setProperty('--background-text', "'" + backgroundText + "'");
      });
    });

 // Set initial maxHeight when the page loads
    document.addEventListener('DOMContentLoaded', function() {
        var buttons = document.querySelectorAll('.collapsible');
        buttons.forEach(function(button) {
            var content = document.getElementById('content_' + button.getAttribute('data-target'));
            content.style.maxHeight = '0px';
        });
    });


    </script>

<h6>Lifetime Total Paid: $lifetimeTotal USD &nbsp;&nbsp;&nbsp;&nbsp; (Bonus multipliers aren't included) </h6> 
<hr>
    <footer>
        Generated by NerdAtWork's PowerShell script
	</footer>
</body>
</html>
"@
		
		Write-Progress -Activity "Processing Months" -Status "Completed" -Completed
	}
	

	$htmlReport | Out-File -FilePath $OutputFilePath
}


Create-HTMLReport -OutputFilePath "SNO-Payout-History-Report.html"
Write-Host "`t`t`t SNO PHR created for all node(s)." -ForegroundColor Green

Start-Process "SNO-Payout-History-Report.html"