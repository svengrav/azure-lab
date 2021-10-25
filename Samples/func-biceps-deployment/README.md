# Sample: Deploy Azure Function (Windows & Consumption)
## Part 1:
- Deploy a Azure Function with Consumption Plan, Storage and Application Insights.
- An identifier is used for the deployment and the Microsoft naming convention is used for the resources.
  - For instance: func-{identifier} => func-azure-lab
  - [Microsoft Docs - Abbreviations for Azure resource types](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)

```PowerShell
#Requries Az Module
#Requries Azure Biceps

Import-Module Az

$resourceGroupName = "rg-azure-lab"
$params = @{
    identifier = 'azure-lab'
    windowsFunction = $true
}

# Create ResourceGroup
New-AzResourceGroup -Name $resourceGroupName -Location 'WestEurope'

# Deploy Azure Function / App Service Plan / Storage / Application Insights 
New-AzResourceGroupDeployment -Name 'Deploy1' -ResourceGroupName $resourceGroupName -TemplateFile '.\azure-function.bicep' -TemplateParameterObject $params
```
- Result
![Resources](./images/resources.png)

## Part 2:
- Switch an existing function app to consumption plan mode (currently not possible via Azure Portal).
- New resource is not a problem here. If the resource does not exist, it will be created. If the resource already exists, it is simply updated.
  
```PowerShell
Import-Module Az

# Setup
$resourceGroupName = "rg-azure-lab"
$planName = "plan-azure-lab"
$functionName =  "func-azure-lab"

$params = @{
    ResourceGroupName = $resourceGroupName
    Name = $planName 

    # App Service Plan definition
    PropertyObject = @{
        location = "West Europe"
        sku = @{
            name = "Y1"
            tier = "Dynamic"
        }
        kind = "windows"
    }

    IsFullObject = $true
    ResourceType = "Microsoft.Web/serverfarms"
}

# Update plan
New-AzResource @params -Force
```

## Part 3:
- Switch an existing function app to a new service plan.
  1. Create a new plan
  2. Update the function and assign the new plan
  3. Remove the old plan

```PowerShell
Import-Module Az

# Setup
$resourceGroupName = "rg-azure-lab"
$planName = "plan-azure-lab-2"
$functionName =  "func-azure-lab"

$params = @{
    ResourceGroupName = $resourceGroupName
    Name = $planName 

    # App Service Plan definition
    PropertyObject = @{
        location = "West Europe"
        sku = @{
            name = "Y1"
            tier = "Dynamic"
        }
        kind = "windows"
    }

    IsFullObject = $true
    ResourceType = "Microsoft.Web/serverfarms"
}

# Get the function
$function = Get-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionName

# Create a new app plan which will host the function app in the resource group specified
New-AzResource @params -Force

# Update function app
Update-AzFunctionApp -ResourceGroupName $resourceGroupName -PlanName $planName -Name $functionName

# Remove old app plan
Remove-AzFunctionAppPlan -ResourceGroupName $resourceGroupName -Name $function.AppServicePlan -Force
```