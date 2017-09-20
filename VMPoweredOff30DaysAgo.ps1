#*************************************************************************************************************
#      Script Name	:   VMPoweredOff30DaysAgo.ps1
#      Purpose		:   Get the report of VMS Powered Off 30 Days ago				
#
#*************************************************************************************************************
#
If(!(Get-PSSnapin | Where {$_.Name -Eq "VMware.VimAutomation.Core"}))
{
	Add-PSSnapin VMware.VimAutomation.Core
}
$VCServer = Read-Host 'Enter VC Server name'
$vcUSERNAME = Read-Host 'Enter user name'
$vcPassword = Read-Host 'Enter password' -AsSecureString
$vccredential = New-Object System.Management.Automation.PSCredential ($vcusername, $vcPassword)


$LogFile = "VMPoweredOff_" + (Get-Date -UFormat "%d-%b-%Y-%H-%M") + ".csv" 

Write-Host "Connecting to $VCServer..." -Foregroundcolor "Yellow" -NoNewLine
$connection = Connect-VIServer -Server $VCServer -Cred $vccredential -ErrorAction SilentlyContinue -WarningAction 0 | Out-Null
$Global:Report = @()


If($? -Eq $True)

{
	Write-Host "Connected" -Foregroundcolor "Green" 

	$PoweredOffAge = (Get-Date).AddDays(-30)
	$Output = @{}
	$PoweredOffvms = Get-VM | where {$_.PowerState -eq "PoweredOff"}
	$EventsLog = Get-VIEvent -Entity $PoweredOffvms -Finish $PoweredOffAge  -MaxSamples ([int]::MaxValue) | where{$_.FullFormattedMessage -like "*is powered off"}
	If($EventsLog)
	{
		$EventsLog | %{ if($Output[$_.Vm.Name] -lt $_.CreatedTime)
			{
				$Output[$_.Vm.Name] = $_.CreatedTime
			}
		}
	}
	$Result = $Output.getEnumerator() | select @{N="VM";E={$_.Key}},@{N="Powered Off Date";E={$_.Value}}

	If($Result)
	{
		$Result | Export-Csv -NoTypeInformation $LogFile
	}
	Else
	{
		"NO VM's Powered off last 30 Days"
	}
}
Else
{
	Write-Host "Error in Connecting to $VIServer; Try Again with correct user name &amp; password!" -Foregroundcolor "Red" 
}

Disconnect-VIServer * -Confirm:$false
#
#-------------------------------------------------------------------------------------------------------------