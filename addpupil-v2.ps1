Import-Module ActiveDirectory

Write-Output "Uses quotes around names with spaces"
$firstname = Read-Host -Prompt "Input Preferred firstname"
$Surname = Read-Host -Prompt "Input Preferred Surname"
$form = Read-Host -Prompt "Input Form"

#check all the inputs are present
If ( ($firstname -eq "") -or ($surname -eq "") -or ($form -eq "")) {
    Write-Output "Exiting  -  Detected something missing"
    exit
    }

#save names as inputted
$OriginalfirstName = $firstname
$OriginalsurName = $surname  

#validate form
if ($form -notmatch "\d{1,2}[a-zA-Z]{3}") {
    Write-Output "Form $($form) - incorrect format xABC "
    exit
}

#find yeargroup from form
$pattern = "\d{1,2}"
if ($form -match $pattern){
    $yeargroup = $matches[0]
} else {
    Write-Output "Error locating Yeargroup"
    exit
}
#write-output "Yeargroup: $($yeargroup)"


#what is the start year of y7
If ( (get-date).month -ge 9){
    [string]$Y7start = (get-date).year
} else {
    [string]$Y7start = ((get-date).year)-1
}

#testyear
#$y7start = "2022"

#find the startyear for this pupil
switch ($yeargroup) {
    7 {$subtract =0;break}
    8 {$subtract =1;break}
    9 {$subtract =2;break}
    10 {$subtract =3;break}
    11 {$subtract =4;break}
}

$thisstart = [int]$y7start - $subtract
Write-Output "Admission Year: $($thisstart)"

#startyear is 2021 or later need admission number
if ([int]$thisstart -ge 2021) {
    $admission = Read-Host -Prompt "Admission Number (required):"
    #check we got admission number and it's the valid format
    if (($admission -eq "") -or ($admission -notmatch "\d{6}") -or ($admission.Substring(0,1) -ne "0"))  {
        Write-Output "Exiting - Admission number:$($admission) invalid"
        exit
    }
}

#remove non alphabetic characters from names
$pattern="[^a-zA-Z]"
$firstname = $firstname -replace $pattern
$surname = $surname -replace $pattern

#set email domain
if ([int]$thisstart -le 2018) {
    $suffix = "@student.school.county.sch.uk"
 } else {
     $suffix = "@domain.org"
 }

 #set the prefix 
if ([int]$thisstart -le 2020) {
    #find prefix from year
    $prefix=[string]$thisstart
    $username = $prefix.substring(2,2) + $firstname.Substring(0,1) + $surname.substring(0,[System.Math]::Min(5, $surname.Length))
}  else {
    $username = $admission
}

#Write-Output("Email $($email)")
Write-Output "======================================"

#get password
#set arrays of words
$colours = @('Wild','Bright','Busy','Green','Blue','Purple','Pink','Orange', "Maroon","Happy","Sleepy","Brave","Short","Tall", "Helpful", "Clean", "Cute", "Super")
$animals = @('crocodile','goat','elephant','penguin','donkey','snake','horse','rabbit','shark','mouse','tiger', 'zebra', 'panda', 'cabbage', 'potato', 'whale', 'bear', 'pencil')
#make new password
$col = Get-Random -InputObject $colours
$ani = Get-Random -InputObject $animals
$password = "1" + $col + $ani
$securepass = ConvertTo-SecureString -String $password -AsPlainText -Force

#Fields
$email = $username + $suffix
$homedirectory = "\\pupil01\pupils$\$($username)"
$samaccountname = "$($username)".ToLower()
$Displayname = "$($Originalfirstname) $($Originalsurname)"
#office field
if ([int]$thisstart -ge 2021) { 
    $office = $form
}

#go no go

$error.clear()
try {New-ADUser -name $Displayname `
    -AccountPassword $securepass `
    -AccountNotDelegated $false `
    -Description "Year starting $($thisstart)" `
    -DisplayName $Displayname `
    -EmailAddress $email `
    -GivenName $Originalfirstname `
    -Surname $Originalsurname `
    -HomeDirectory $homedirectory `
    -HomeDrive "S:" `
    -PasswordNeverExpires $true `
    -SamAccountName $samaccountname `
    -UserPrincipalName $email `
    -Office $office `
    -path "OU=Azure,OU=pupils,DC=school,DC=county,DC=sch,DC=uk" `
    -enabled $true `
    -scriptPath "ntpupils.bat"
    }
catch {
    write-output "Error adding $($Originalfirstname) $($Originalsurname)"
    Write-Output $error
    exit
}

#adduser to 365 students
$error.Clear()
try {
    Add-ADGroupMember -identity "365Students" -members $samaccountname
} catch {
    Write-Output "Error adding user to 365Students"  
}


#create folder
$User = Get-ADUser -Identity $samaccountname
$homeshare = new-item -path $homedirectory -ItemType Directory -Force
$acl = Get-Acl $homeshare
$FileSystemRights = [System.Security.AccessControl.FileSystemRights]"Modify"
$AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
$InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
$PropagationFlags = [System.Security.AccessControl.PropagationFlags]"InheritOnly"
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($User.SID, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)
$acl.AddAccessRule($AccessRule)

try { Set-Acl -Path $homeShare -AclObject $acl }
catch { write-output "Error creating $($homeshare): $($error)"}

If (!$error) {write-output "$homedirectory created"}



Write-Output "Name: $($Originalfirstname) $($OriginalSurname),`n Username:$($username)`n Password:$($password)`n Email: $($email) `n Form: $($form)"
write-output "`n`n Things to do: `n 1. Add email to sims in work Category `n 2. Add O365 account to allstudent security group"
if ([int]$thisstart -le 2020) { write-output "`n add admission number to office field in AD" }
