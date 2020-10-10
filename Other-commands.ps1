#Connect to Office365 
Connect-MsolService  

#Connect to exchange online
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking

#if you need to enable running scripts
set-executionpolicy remotesigned

#Connect to teams
Install-Module MicrosoftTeams
Connect-MicrosoftTeams

#Export emails with a specific domain
get-msoluser -all | where-object {$_.userprincipalname -like "*@school*"} | select-object userprincipalname | export-csv -path "staffemails.csv"

#Computers in AD and their last logon date
get-adcomputer -filter * -properties Name,LastLogonDate | sort LastLogonDate | FT Name,LastLogonDate -autosize | out-file "allcomputers.txt"


#Add specific domain users to security group
get-msoluser -all | where-object {$_.userprincipalname -like "*@school*"} | export-csv -path "staffemails.csv" 
$securitygroup = get-msolgroup | where-object {$_.displayname -eq "Encrypted_mail_users"}
import-csv staffemails.csv | Foreach {add-msolgroupmember -groupobjectid $securitygroup.objectid -groupmembertype "User" -groupmemberobjectid $_.objectid}


#Add users to mail enabled group using exchange online
#make csv  of emails with msol. 
import-csv "staffemails.csv" | foreach {add-distributiongroupmember -identity "groupname" -member $_.userprincipalname}

#Remove a user or many users
#userprincipalname is usually their email address. CSV needs userprincipalname as column name
import-csv d:\tobedeleted.csv | foreach {remove-msoluser -userprincipalname $_.userprincipalname -force}

#Assign license to many users
#Set usage location first
import-csv d:\2019emails.csv | foreach {set-msoluser -userprincipalname $_.userprincipalname -usagelocation GB}
import-csv d:\2019emails.csv | foreach {set-msoluserlicense -userprincipalname $_.userprincipalname -addlicenses 8884137:STANDARDWOFFPACK_IW_STUDENT}

#(it has an invalid error if the license is already assigned) 

#Add office field from AD to many users
#the column headings in the csv can be referenced with $_.
import-csv pupils.csv | foreach {set-msoluser -userprincipalname $_.emailaddress -office $_.officecolumn}

#Account SKU IDs for students
get-msolaccountsku
#000000:STANDARDWOFFPACK_IW_STUDENT this one includes office apps 
#000000:STANDARDWOFFPACK_IW_FACULTY staff with office365 apps

#Get a list of specific domain users UPNs
get-msoluser -all | where-object {$_.userprincipalname -like "*school*"} | select-object userprincipalname,displayname | export-csv -path "allemail.csv"

#Get last useractivity time
#Need to do the above command to get the UPNs 
import-csv "allemail.csv" | foreach {$UPN = $_.UserPrincipalName; get-mailboxstatistics -identity $UPN | select @{n='UserPrincipalName';e={$UPN}},displayname,lastuseractiontime}

#Remove groups using exchange online
#export groups from admin groups list
import csv groups.csv | foreach {remove-unifiedgroup -identity $_.groupemail -confirm:$False}

#Change the name (firstname,surname) of Ad-Users
import-csv .\update.csv | foreach {set-aduser -identity $_.UserName -givenname $_.Forename -surname $_.Surname -displayname $_.Fullname}
set-aduser $_.Username -passthru | rename-adobject -newname $_.Fullname

#Change the name (firstname,surname) of  office365 accounts
#(it will have an error for ones that are synchronized from AD) 
Import-Csv .\update.csv | foreach {set-msoluser -UserPrincipalName $_.EMail -FirstName $_.Forename -Lastname $_.Surname -DisplayName "$_.Fullname"}

#Remove all members from a distribution list
get-distributiongroupmember -identity "allteachingstaff"  | foreach { Remove-DistributionGroupMember -Identity "allteachingstaff" -member $_.name -confirm:$false}

#Add members to a distribution-list
import-csv .\staff1.csv | foreach { Add-DistributionGroupMember -identity "allteachingstaff" -member $_.email}
