#Connect-MsolService
#Install-Module MicrosoftTeams
#Connect-MicrosoftTeams 


#fetch teams
write-output "Fetching teams"
$xteams = get-team | Select-Object groupid,displayname

#process teams
write-output "processing teams"
foreach ($xteam in $xteams)  
{

    $xname = $xteam.displayname

    $xListofCodes = [regex]::match($xname,'#:(.*)#').Groups[1].Value

    if ($xListofCodes.length -gt 3){


        $xCodeArray = $xListofCodes -split ","
        foreach ($xcode in $xCodeArray) {
                Write-Output $xcode        
            }

        }


}
