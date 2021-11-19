<#
.SYNOPSIS
Removes firewall rules according to a list in a CSV or JSON file.
.DESCRIPTION
Removes firewall rules according to a with Export-FirewallRules generated list in a CSV or JSON file.
CSV files have to be separated with semicolons. Only the field Name or - if Name is missing - DisplayName
is used, alle other fields can be omitted
anderen
.PARAMETER CSVFile
Input file
.PARAMETER JSON
Input in JSON instead of CSV format
.PARAMETER PolicyStore
Store from which rules are removed (default: PersistentStore).
Allowed values are PersistentStore, ActiveStore (the resultant rule set of all sources), localhost,
a computer name, <domain.fqdn.com>\<GPO_Friendly_Name> and others depending on the environment.
.NOTES
Author: Markus Scholtes
Version: 1.1.0
.CHANGE LOG
    Build date: 2020/12/12 Markus Scholtes
    Update 2021/11/19 ThisIsJeremiah@protonmail.com
        -Rename path parameter for CSVFile to Path.
        -Added logic to validate file path
        -Added logic to determine file type

.EXAMPLE
Remove-FirewallRules -Path .\FWRules.json
    Removes all firewall rules listed in the specified json file

#>
function Remove-FirewallRules
{
Param(
            [Parameter(Mandatory = $True)]
            $Path,
            [Parameter(Mandatory = $false)]
            [STRING]$PolicyStore = "PersistentStore")

	#Requires -Version 4.0
  #Validate path & determine filetype
    Write-Output "Validating path: $path"
    IF(Test-Path -Path $Path) #throw error if path does not exit
        {
        #parse path to confirm json or csv
        
        if ($Path |Select-String -Pattern ".csv") #Test for CSV
            {
            $PathOk = $true
            $FileType = "CSV"
            Write-Output "Data is CSV"
            }
        ELSE
            {
            IF($Path |Select-String -Pattern ".json") # Test for json
                {
                $PathOk = $true
                $FileType = "JSON"
                Write-Output "Data is JSON"
                }
                ELSE
                    {
                    throw "Invalid Input file type."
                    }
            
            }
        }
    ELSE
        {
        throw "Invalid FilePath"
        }

        #Read File
         Write-Output "Loading Firewall rules to memory"
    SWITCH($FileType)
        {
        "CSV" # read CSV file
            {
		    #if ([STRING]::IsNullOrEmpty($path)) { $CSVFile = ".\FirewallRules.csv" }
		    $FirewallRules = Get-Content $path | ConvertFrom-CSV -Delimiter ";"
            }
        "JSON" # Read JSON file
            {
            #if ([STRING]::IsNullOrEmpty($CSVFile)) { $CSVFile = ".\FirewallRules.json" }
	    	$FirewallRules = Get-Content $path | ConvertFrom-JSON
            }
        }


	# iterate rules
	ForEach ($Rule In $FirewallRules)
	{
		$CurrentRule = $NULL
		if (![STRING]::IsNullOrEmpty($Rule.Name)) #Set Current Rule based on Rule Name
		{
			$CurrentRule = Get-NetFirewallRule -EA SilentlyContinue -Name $Rule.Name
			if (!$CurrentRule)
			{
				Write-Error "Firewall rule `"$($Rule.Name)`" does not exist"
				continue
			}
		}
		else
		{
			if (![STRING]::IsNullOrEmpty($Rule.DisplayName)) #Set Current Rule if name is null, set name based off of displayname
			{
				$CurrentRule = Get-NetFirewallRule -EA SilentlyContinue -DisplayName $Rule.DisplayName
				if (!$CurrentRule)
				{
					Write-Error "Firewall rule `"$($Rule.DisplayName)`" does not exist"
					continue
				}
			}
			else
			{
				Write-Error "Failure in data record"
				continue
			}
		}

		Write-Output "Removing firewall rule `"$($CurrentRule.DisplayName)`" ($($CurrentRule.Name))"
		Get-NetFirewallRule -EA SilentlyContinue -PolicyStore $PolicyStore -Name $CurrentRule.Name | Remove-NetFirewallRule
	}

}