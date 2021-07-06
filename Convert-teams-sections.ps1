# Searches teams for the name containing  #00000
# and then sets the primary smtp and mail nickname to be Section_00000@domain 
# Used in conjunction with the software locker connect


$cred = get-credential
#Connect-MsolService
#Install-Module MicrosoftTeams
#Install-module ExchangeOnlineManagement -verbose -force 
connect-microsoftteams -credential $cred
connect-Exchangeonline -credential $cred 


#fetch teams
write-output "Fetching  teams..."
$xteams = get-team | select-object groupid,displayname

#process teams
Write-Output "Processing teams..."
foreach ($xteam in $xteams)
{
    $xgroupid = $xteam.groupid
    $xname = $xteam.displayname
 

   
    $section_num = [regex]::match($xname,'#\d{5}').Groups[0].Value
    if ($section_num){
        $section_num = $section_num.substring(1,5)
    
        write-output $section_num

        #$searchcode = [regex]::match($xname,'#:(.*)#').Groups[1].Value
        #write-output $searchcode
        
        $mailnick = "Section_" + $section_num
        $new_email="Section_" + $section_num + "@domain"
    
    
        #echo "found! " + $xname 
        set-unifiedgroup $xgroupid -primarysmtpaddress $new_email
        set-team -GroupId $xgroupid -MailNickName $mailnick    
    } 
    #change email address of team

    #write-output "Done: " + $xname
    

}
