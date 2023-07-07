$storageAccSubid = "2def5af2-7dd0-41bc-8ae2-3424c1e3f64f"
$resourceGroupName = "az-rg-test-001" 
$storageAccName = "logicstr001"   
$storageContainerName = "finops"

# Function to download blob contents  
Function DownloadBlobContent {   
    ## Get the storage account  
    $storageAcc = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccName      
    ## Get the storage account context  
    $ctx = $storageAcc.Context    
    ## Download a file  
    Get-AzStorageBlobContent -Container $storageContainerName -Blob "CacheRedis_Inventory_Metrics.xlsx" -Destination "$env:temp\CacheRedis_Inventory_Metrics.xlsx" -Context $ctx -Force
} 

# Function to upload blob contents  
Function UploadBlobContent {   
    ## Get the storage account  
    $storageAcc = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccName      
    ## Get the storage account context  
    $ctx = $storageAcc.Context    
    ## Upload a file  
    Set-AzStorageBlobContent -Container $storageContainerName -File $filePath -Blob $fileName -Context $ctx -Force    
}

$fileName = "CacheRedis_Inventory_Metrics.xlsx"
$filePath = ".\$fileName"

# Connect to Azure with system-assigned managed identity
Connect-AzAccount -Identity -WarningAction Ignore

#Select-AzSubscription -SubscriptionId $storageAccSubid | Out-null
Write-Output "Downloading Content from Blob Container"
DownloadBlobContent

$importfile = Import-Excel "$env:temp\CacheRedis_Inventory_Metrics.xlsx"

foreach ($line in $importfile)

{

$resourcegroup = $line.'Resource Group Name'
$redisname = $line.'RC Name'
$newsize = $line.'Desired Size'
$newsku = $line.'Desired Sku'
$existingsku = $line.'SKU'
$existingsize = $line.'Size'

if($line.'Action' -match "TRUE")
    {
    Write-Host "Working on $redisname, Scaling from SKU $existingsku having Size $existingsize to new SKU $newsku having New Size $newsize"
    #Set-AzRedisCache -ResourceGroupName $resourcegroup -Name $redisname -Sku $newsku -Size $newsize
    $line.'Post Remediation' = "Scaling Completed"
    }
else
    {
    Write-Host "Scaling not granted"
    $line.'Post Remediation' = "No Action Requested by Administrator"
    }
$exportredisdata += $line
}

$exportredisdata | Export-Excel -Path $filePath

# Write output to a blob in SA
#Select-AzSubscription -SubscriptionId $storageAccSubid | Out-null
Write-Output "Uploading Content to Blob Container"#
UploadBlobContent

Write-Output "Finished!"