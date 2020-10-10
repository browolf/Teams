#Connect-MsolService
#Install-Module MicrosoftTeams
#Connect-MicrosoftTeams  

#get useraccounts, drop in file
get-msoluser -all | where-object {$_.office} | Select-Object Userprincipalname,office | export-csv -path msoluser.csv -NoTypeInformation

#add useraccounts to lookup table
write-output "Adding pupils to lookup"
$xpupils = @{}
import-csv msoluser.csv | foreach {
    $xpupils.add($_.office,$_.userprincipalname)
    }

#fetch teams
write-output "Fetching teams"
$xteams = get-team | Select-Object groupid,displayname

#process teams
write-output "processing teams"
foreach ($xteam in $xteams)  
{

    $xgroupid = $xteam.groupid
    $xname = $xteam.displayname

    $xListofCodes = [regex]::match($xname,'#:(.*)#').Groups[1].Value

    if ($xListofCodes.length -gt 3){


        $xCodeArray = $xListofCodes -split ","
        Write-Output $xteam.groupid
        foreach ($xcode in $xCodeArray) {
                Write-Output $xcode
                #Write-Output $xcode    
                #make an array of admission numbers that are assigned to this code
                $xclassarray = @()    
                import-csv studentclasses.csv | foreach {
                    #check row classcode matches $xcode
                    if ($_.class -eq $xcode) {
                            #add to array
                            $xclassarray += $xpupils[$_.adno]
                            }

                    
                    



                     }
            #printarray
            foreach ($ad in $xclassarray) {
            
            
                    Write-Output $ad
                    
                    #add to team. 

                    Add-TeamUser -GroupID $xgroupid -user $ad
                    
                    }
            
            
            }
        
        
        
        }


}
