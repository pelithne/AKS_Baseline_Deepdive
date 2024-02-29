### Create a custom role, with least privilage access for AKS load balancer subnet

This script is designed to create a custom role in Azure with least privilege access for an Azure Kubernetes Service (AKS) load balancer subnet. The role is named "aks-net-contributor" and has specific permissions that allow it to read, write, and delete load balancers, as well as read, write, and join actions on subnets within a specific virtual network.

The script follows these steps:

1. **Create a JSON file**: The `touch aks-net-contributor.json` command creates a new JSON file named `aks-net-contributor.json`.

2. **Define the custom role**: The JSON file is populated with the properties of the custom role, including its name, description, assignable scopes, and permissions.

3. **Create the custom role in Azure**: The `az role definition create --role-definition ./aks-net-contributor.json` command creates the custom role in Azure using the properties defined in the JSON file.

4. **Identify the service principal ID**: The `az identity show --name <AKS_IDENTITY_NAME> --resource-group <RESOURCE_GROUP> --query principalId --output tsv` command retrieves the principal ID of the user-assigned managed identity.

5. **Assign the custom role to the user-assigned managed identity**: The `az role assignment create --assignee $principalId --role "aks-net-contributor"` command assigns the custom role to the user-assigned managed identity.

Please replace `RESOURCE_GROUP`, `VIRTUAL_NETWORK_NAME`, `LOADBALANCER_SUBNET_NAME`, and `AKS_IDENTITY_NAME` with your actual resource group name, virtual network name, load balancer subnet name, and AKS identity name respectively when running this script.

This script assumes that you have Azure CLI installed and configured with the appropriate permissions to run these commands.

````
touch aks-net-contributor.json
````

add the following information to the json file.
````
{
    "properties": {
        "roleName": "aks-net-contributor",
        "description": "least privilige access",
        "assignableScopes": [
            "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Network/virtualNetworks/<VIRTUAL_NETWORK_NAME>/subnets/<LOADBALANCER_SUBNET_NAME>"
        ],
        "permissions": [
            {
                "actions": [
                    "Microsoft.Network/loadBalancers/read",
                    "Microsoft.Network/loadBalancers/write",
                    "Microsoft.Network/networkSecurityGroups/join/action",
                    "Microsoft.Network/loadBalancers/delete",
                    "Microsoft.Network/virtualNetworks/subnets/read",
                    "Microsoft.Network/virtualNetworks/subnets/write",
                    "Microsoft.Network/virtualNetworks/subnets/join/action"
                ],
                "notActions": [],
                "dataActions": [],
                "notDataActions": []
            }
        ]
    }
}
````

### Create a role


````
az role definition create --role-definition ./aks-net-contributor.json
````


assign the custom role to the user assigned managed identity, first identify the service principal ID

````
principalId=$(az identity show --name <AKS_IDENTITY_NAME> --resource-group <RESOURCE_GROUP> --query principalId --output tsv)

````

````
az role assignment create --assignee $principalId --role "aks-net-contributor"
````