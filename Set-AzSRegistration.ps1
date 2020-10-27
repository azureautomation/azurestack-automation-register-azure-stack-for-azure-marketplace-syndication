<# 
.Synopsis 
ASDK Single Node only! - Automate AzureStack to Azure Market Place Syndication
 
.DESCRIPTION 
ASDK Single Node only! - Register Azure Stack with Azure for Market Place Syndication.
Installs and Import AzureStack Modules 1.2.10 & Tools, Import AzureStack 1.2.10 & AzureStack-Tools Modules, 
Sets AzureStackAdmin & AzureStackUser ARM Endpoints, add AzureRmAccount, Registers AzureStack RP in Azure Subscription, 
Register Azure Stack with Azure for Market Place Syndication and Registers RPs in AzureStack. 

.NOTES    
Name: Set-AzSRegistration 
Author: Gary Gallanes - GDog@Outlook.com
Version: 1.0 
DateCreated: 2017-05-19 
DateUpdated: 2017-07-26
 
.PARAMETER None
No Parameters are used with this script
 
.EXAMPLE 
&'.\Set-AzSRegistration.ps1' 
#>
 
### Set-AzSRegistration.ps1 ###############################################

### Check/Uninstall incompatable AzureStack Modules & Install/Import correct version 1.2.10
Get-Module -ListAvailable | where-Object ($_.Name -like "Azure*") | Uninstall-Module
Remove-Item  $PSHome\modules\Azure* -Force
dir $PSHome\modules\Azure*
Remove-Item 'C:\Program Files (x86)\WindowsPowerShell\Modules\Azure*' -Force
dir 'C:\Program Files (x86)\WindowsPowerShell\Modules\Azure*'
 
# Set Repository polcies
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
 
### Install and Import AzureStack Modules 1.2.10 & Tools
Install-Module -Name  AzureRm.BootStrapper
Use-AzureRmProfile -Profile 2017-03-09-profile -Force
Install-Module -Name  AzureStack -RequiredVersion  1.2.10
Import-Module -Name  AzureStack -RequiredVersion  1.2.10 
cd c:\
invoke-webrequest  https://github.com/Azure/AzureStack-Tools/archive/master.zip -OutFile master.zip
expand-archive master.zip -DestinationPath . -Force
cd AzureStack-Tools-master
copy .\Registration\R* c:\temp
Import-Module .\Connect\AzureStack.Connect.psm1
Import-Module .\ComputeAdmin\AzureStack.ComputeAdmin.psm1
   
### Capture Subscription Credentials
$AADUserName = read-host "Enter your Subscription credentials/Azure Service Admin Username"
$ADPwd = read-host "Enter your Azure Service Admin Password"
$AADPassword = $ADPwd | ConvertTo-SecureString -Force  -AsPlainText
$AADCredential = New-Object PSCredential($AADUserName,$AADPassword)
$AADTenantID = ($AADUserName -split  '@')[1]
$Credential = $AADCredential
 
### Get Azure SubscriptionID & Register AzureStack RP in Azure Subscription
Login-AzureRmAccount -Credential $Credential
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.AzureStack -Force
Get-AzureRmResourceProvider -ProviderNamespace Microsoft.AzureStack
$AzureSub = Get-AzureRmSubscription  | Select-Object -Property SubscriptionID | fl | Out-String
$AzureSubID = ($AzureSub -split  ' : ')[1]  
$SubID = $AzureSubID.Substring(0,36)
 
### Setup AzureStackAdmin ARM Endpoint
Add-AzureRMEnvironment -Name "AzureStackAdmin" -ArmEndpoint "https://adminmanagement.local.azurestack.external"
### Get TenantID GUID for AzureStackAdmin
$TenantID = Get-AzsDirectoryTenantId -AADTenantName $AADTenantID -EnvironmentName AzureStackAdmin
### Login the AAD Admin into AzureStackAdmin ARM Env
Login-AzureRmAccount -EnvironmentName "AzureStackAdmin" -TenantId $TenantID -Credential $Credential
 
### Register Resource Providers
foreach($s in (Get-AzureRmSubscription)) {
        Select-AzureRmSubscription -SubscriptionId $s.SubscriptionId | Out-Null
        Write-Progress $($s.SubscriptionId + " : " + $s.SubscriptionName)
Get-AzureRmResourceProvider -ListAvailable | Register-AzureRmResourceProvider -Force
    } 
  
### Register Azure Stack with Azure - Market Place Syndication
c:\temp\RegisterWithAzure.ps1 -azureSubscriptionId $SubID -azureDirectoryTenantName $AADTenantID -azureAccountId $AADUserName
 

