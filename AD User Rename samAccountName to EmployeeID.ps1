#\\corp.ad.fmcna.com\FMCNA-Groups\Technology\Infrastructure\ECS\Desktop\Staff Shares\JGrossi\SCRIPTING\_POWERSHELL\AD User Rename
#C:\AD_Alpha_to_empID
#
#Alpha to EID AD User Object Rename
#Renames users (column 1) to the value of column 2, ie samAccountName into employee ID
#Input CSV with 2 columns: samAccountName,empID

##For command line input:
#Param([string]$pathToCSV)
#$ValidPath = Test-Path $pathToCSV
#If(-Not $ValidPath){Throw "File not found:  $pathToCSV"}

#For ISE
$pathToCSV = "C:\AD_Alpha_to_empID\usersToUpdate.csv"



Clear
$failedItems = @() #For capturing errors
$logItems = @() #For log file
$logItems += "samAccountName,empID,Result" #Log Headers



#Import CSV, determine headers and skip that header row
Get-Content -Path $pathToCSV | Select-Object -Skip 1 | Out-String | ConvertFrom-Csv -Header samAccountName,empID | ForEach-Object {
    $sam = $_.samAccountName
    $empID = $_.empID


    
    If ((Get-ADUser -LDAPFilter "(sAMAccountName=$sam)") -ne $Null -And (Get-ADUser -LDAPFilter "(sAMAccountName=$empID)") -ne $Null) 
    {
        #Check if both samAccountName and empID accounts already exist
        $samLastLogonDate = (Get-ADUser $sam -Properties *).LastLogonDate
        $empIDLastLogonDate = (Get-ADUser $empID -Properties *).LastLogonDate
        #Write-Host "Both Users Exist:  $sam Last Logon Date: $samLastLogonDate  -  $empID Last Logon Date: $empIDLastLogonDate"
        $logItems += "$sam,$empID,Both Users Exist:  $sam Last Logon Date: $samLastLogonDate  -  $empID Last Logon Date: $empIDLastLogonDate" #Log that both exist
        $failedItems += "$sam AND $empID Both Users Exist:  $sam Last Logon Date: $samLastLogonDate  -  $empID Last Logon Date: $empIDLastLogonDate" #For console output
        #Now will skip to next user
    }
    Else 
    {
        
       #Only one account exists, we may now continue...


        Try
        {
            #Attempt resolve AD User from provided samAccountName
            $userToRename = Get-ADUser $sam -ErrorAction SilentlyContinue


            Try
            {
                #Attempt renaming samAccountName and Distinguished Name
                Set-ADUser $UserToRename -SamAccountName $empID -ErrorAction SilentlyContinue
                Rename-ADObject $userToRename.DistinguishedName -newName $empID -ErrorAction SilentlyContinue
                Write-Host "Renamed $sam to $empID" #Display progress
                $logItems += "$sam,$empID,SUCCESS" #Log success
            }
            Catch
            {
                #If unable to rename account, capture and log error
                $failedItems += "$sam`t$_"
                $logItems += "$sam,$empID,$_"
            }
        }
        Catch
        {
            #If unable to get the AD User object, capture and log error
            $failedItems += "$sam`t$_"
            $logItems += "$sam,$empID,$_"
        }
    }
}

#Return any errors to console
Write-Host "`n`nThese items have failed:`n------------------------"
ForEach($fail in $failedItems) {Write-Host "$fail"}

#Create Log CSV file with full results
$logItems | ConvertFrom-Csv | Export-CSV -Path "C:\AD_Alpha_to_empID\AD-Alpha-To-EmpID_$((Get-Date).ToString('MM-dd-yyyy_hh-mm-ss')).csv" -NoTypeInformation