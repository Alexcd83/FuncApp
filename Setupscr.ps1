Clear-Host
# Get user Info
$tenant      = (Get-AzureADDomain).name
$subscr2     = Get-AzSubscription
$wloc        = Read-host ('Are you want to use WestUs2 location? If Yes, press Enter. If No, enter your location')
Write-Host ("")
If([string]::IsNullOrEmpty($wloc)) {$location = 'WestUS2'} else {$location = $wloc}
$qname      = Read-host ('Use standard Resource Group name "Processica-Newsletter-Distribution"? If Yes, press Enter. If No, enter your name')
Write-Host ("")
If([string]::IsNullOrEmpty($qname)) {$grname = 'Processica-Newsletter-Distribution'} else {$grname = $qname}
$usern2      = Read-host ('Enter User name in format (AccountName@mycompany.com)')
# Create Resource Group
New-AzResourceGroup -Name $grname -Location $location
Start-Sleep -Seconds 1
$rand = Get-Random -Minimum 1 -Maximum 99999
# Create Storage Acc
$storageAccountName = "storage$rand"
az storage account create --name $storageAccountName --location $location -g $grname --sku Standard_LRS
Start-Sleep -Seconds 1
# Create Function
$FunctionAppName = "Function$rand"
$functionAppName = "func$rand"
az functionapp create -n $FunctionAppName --storage-account $storageAccountName --consumption-plan-location $location --runtime node -g $grname --disable-app-insights true --functions-version 3
az functionapp deployment source config --branch master --name $FunctionAppName --repo-url https://github.com/Alexcd83/FuncApp/blob/main/processicawfdevzaf.zip --resource-group $grname --consumption-plan-location $location --runtime node --disable-app-insights true --functions-version 3
# Change CORS
az functionapp cors remove -g $grname -n $FunctionAppName --allowed-origins
az functionapp cors add -g $grname -n $FunctionAppName --allowed-origins "*"
# Get and Set Connection String
$storageconnect = az storage account show-connection-string --name $storageAccountName --resource-group $grname
$storageconnect = $storageconnect.Trim('{   "connectionString": "')
$storageconnect = $storageconnect.TrimEnd('}')
az functionapp config appsettings set --name $FunctionAppName --resource-group $grname --settings "ProcessicaStorage=$storageconnect"
# Replace data in Template file
$find        = '$subscr'
$replace     = $subscr2
$find1       = '$location'
$replace1    = $location
$newusername = '$usern'
$username    = $usern2
$funcn       = '$funcname'
$funcrep     = $FunctionAppName
$resgr       = '$resnam'
$resname     = $grname
(Get-Content -Path ./template.json).replace("'$find'", "$replace") | Set-Content -Path ./template.json
(Get-Content -Path ./template.json).replace("'$find1'", "$replace1") | Set-Content -Path ./template.json
(Get-Content -Path ./template.json).replace("'$newusername'", "$username") | Set-Content -Path ./template.json
(Get-Content -Path ./template.json).replace("'$funcn'", "$funcrep") | Set-Content -Path ./template.json
(Get-Content -Path ./template.json).replace("'$resgr'", "$resname") | Set-Content -Path ./template.json
New-AzResourceGroupDeployment -ResourceGroupName $grname -TemplateUri https://github.com/Alexcd83/FuncApp/blob/main/template.json
Start-Sleep -Seconds 1
# Generate Link for API Connection
$apiurl      = "https://portal.azure.com\#@"+$tenant
$apiurl2     = "/resource/subscriptions/"+$subscr2
$apiurl3     = "/resourceGroups/"+$grname
$apiurl4     = "/providers/Microsoft.Web/connections/office365/connection"
$o365        = $apiurl+$apiurl2+$apiurl3+$apiurl4
Start-Sleep -Seconds 1
# Info for user
#Clear-Host
Write-Host ("Deployment process complete 100%") -ForegroundColor green
Write-Host ("")
Write-Host ("Using these link authorize your Logic Apps Connectors:") -ForegroundColor green
Write-Host ("")
Write-Host ($o365) -ForegroundColor yellow
Start-Sleep -Seconds 1