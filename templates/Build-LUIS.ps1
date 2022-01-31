# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
# 
# Builds and trains LUIS models. Used in conjunction with CICD, performs the following:
#  - Determines what models to build based on the recognizer configured for each dialog and writes a luConfig file with the list
#  - Builds Orchestrator language models (english and multilingual) snapshot files
#  - Creates configuration file used by runtime (orchestrator.settings.json)

Param(
	[string] $outputDirectory,
	[string] $sourceDirectory,
	[string] $crossTrainedLUDirectory,
	[string] $authoringKey,
	[string] $botName,
    [string] $resourceGroupName,
    [string] $endpoint,
    [string] $luisPredictionResourceName
)

# Import script with common functions
. ($PSScriptRoot + "/LUUtils.ps1")

if ($PSBoundParameters.Keys.Count -lt 5) {
    Write-Host "Builds, trains and publishes LUIS models" 
    Write-Host "Usage:"
    Write-Host "`t Build-LUIS.ps1 -outputDirectory ./generated -sourceDirectory ./ -crossTrainedLUDirectory ./generated/interruption -authoringKey 12345612345 -botName MyBotName"  
    Write-Host "Parameters: "
    Write-Host "`t  outputDirectory - Directory for processed config file"
    Write-Host "`t  sourceDirectory - Directory containing bot's source code."
    Write-Host "`t  crossTrainedLUDirectory - Directory containing .lu/.qna files to process."
    Write-Host "`t  authoringKey - LUIS Authoring key."
    Write-Host "`t  botName - Bot's name."
    exit 1
}

# Find the lu models for the dialogs configured to use a LUIS recognizer
$models = Get-LUModels -recognizerType "Microsoft.LuisRecognizer" -crossTrainedLUDirectory $crossTrainedLUDirectory -sourceDirectory $sourceDirectory
if ($models.Count -eq 0)
{
    Write-Host "No LUIS models found."
    exit 0        
}

# Create luConfig file with a list of the LUIS models
$luConfigFile = "$crossTrainedLUDirectory/luConfigLuis.json"
Write-Host "Creating $luConfigFile..."
New-LuConfigFile -luConfig $luConfigFile -luModels $models -path "."

# Output the generated settings
Get-Content $luConfigFile

# Publish and train LUIS models
bf luis:build --out $outputDirectory --authoringKey $authoringKey --botName $botName --suffix composer --force --log --luConfig $luConfigFile

# Assign prediction resources
Write-Host "Assigning prediction resources..."

# Get LUIS models
$luisModels = bf luis:application:list --endpoint $endpoint --subscriptionKey $authoringKey
$jsonModels = $luisModels | out-string | ConvertFrom-Json

# Login
$azAccessToken = az account get-access-token --output json | ConvertFrom-Json 
$azAccount = az account show --output json | ConvertFrom-Json

foreach ($model in $jsonModels) {

    if ($model.name -like $botName + "*") {
        Write-Host AppName : $model.name
        bf luis:application:assignazureaccount `
            --accountName $luisPredictionResourceName `
            --resourceGroup $resourceGroupName `
            --armToken $azAccessToken.accessToken `
            --azureSubscriptionId $azAccount.id   `
            --appId $model.id`
            --endpoint $endpoint `
            --subscriptionKey $authoringKey

        # Check the version of the LUIS App 
        $versionList = bf luis:version:list --appId $model.id --endpoint $endpoint --subscriptionKey $authoringKey --skip 5
        $jsonVersionList = $versionList | out-string | ConvertFrom-Json
        Write-Host versionList : $jsonVersionList 
        $versionCount = $jsonVersionList.Count
        Write-Host versionCount : $versionCount 
        if($versionCount -gt 0){
            foreach($version in $jsonVersionList)
            {
                bf luis:version:delete --appId $model.id --versionId $version.version --endpoint $endpoint --subscriptionKey $authoringKey
            }
            
        }
    }
}