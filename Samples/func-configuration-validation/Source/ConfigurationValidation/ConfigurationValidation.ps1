using namespace System.Net
using namespace Newtonsoft.Json

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$ErrorActionPreference = "Stop"

$OperationResult = @{
    StatusCode = [HttpStatusCode]::OK
    Content = "Configuration is valid."
}

try {
    $Config = $Request.Body 

    # Get Schema
    $SchemaUri = ($Config| ConvertFrom-Json).'$schema'
    if(!$SchemaUri) {
        throw [JsonException]::New("Uri for Schema is missing!")
    }
    $Schema = (Invoke-WebRequest $SchemaUri).Content
    
    # Check Config
    $Perfect = Test-Json -Json $Config -Schema $Schema  -ErrorAction SilentlyContinue -ErrorVariable Defects
    $Result = @()
    if(!$Perfect) {
        foreach($Defect in $Defects) {
            $Result  += $Defect.ErrorDetails.Message
        }
        $OperationResult.Content = @{
            Code = "Failed"
            Schema = $SchemaUri
            Result = $Result
        }    
    }
} catch [JsonException] {
    Write-Host "Error: $($Error[0])"
    $OperationResult.StatusCode = [HttpStatusCode]::BadRequest
    $OperationResult.Content = "Config could not be parsed."
}

# Output
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode =  $OperationResult.StatusCode
    Body = $OperationResult.Content 
})