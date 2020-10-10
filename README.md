# Teams
Teams Powershell Scripts

The purpose of these scripts are to manage Microsoft Teams. 

Although Microsoft Provides "School Data Sync", this is useless if staff jump the gun and create their own teams. 

The essential problem you have is connecting sims classes to teams. 

# Usage
Required: 

A sims csv file with the columns classcode,admission number
  
The admission number of students in the office field of their Office365 account. 
  
The teacher puts the classcode anywhere in their team name in the format e.g. #:10a\Gg1#  for the class 10a\Gg1 (our classes have a slash in)

In the case of a mega team containing multiple classes use the format #:10a\Gg1,10b\Gg1,10c\Gg1# 


the file listteams.ps1 can be used to list what teams have the codes. 
