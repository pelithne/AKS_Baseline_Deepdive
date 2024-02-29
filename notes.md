### Setup environment variables


````bash
RG=AKS_Security_RG
LOCATION=westeurope 
HUB_VNET_PREFIX=10.0.0.0/16 
HUB_VNET_NAME=Hub_VNET
FW_SUBNET_NAME=AzureFirewallSubnet
BASTION_SUBNET_NAME=AzureBastionSubnet
JUMPBOX_SUBNET_NAME=JumpboxSubnet
ENDPOINTS_SUBNET_NAME=endpoints-subnet
APPGW_SUBNET_NAME=app-gw-subnet
AKS_SUBNET_NAME=aks-subnet
LOADBALANCER_SUBNET_NAME=loadbalancer-subnet
BASTION_NSG_NAME=Bastion_NSG
JUMPBOX_NSG_NAME=Jumpbox_NSG
AKS_NSG_NAME=Aks_NSG
ENDPOINTS_NSG_NAME=Endpoints_NSG
LOADBALANCER_NSG_NAME=Loadbalancer_NSG
APPGW_NSG=Appgw_NSG
SPOKE_VNET_PREFIX=10.1.0.0/16
SPOKE_VNET_NAME=Spoke_VNET
FW_NAME=azure-firewall
APPGW_NAME=AppGateway
ROUTE_TABLE_NAME=spoke-rt
AKS_IDENTITY_NAME=aks-msi
JUMPBOX_VM_NAME=Jumpbox-VM
AKS_CLUSTER_NAME=private-aks
ACR_NAME=acraksbl

````

### Create the resource group for the virtual networks

````bash
az group create --name $RG --location westeurope
````


### Create Network Security Group (NSG) for the Hub.



In this step, we will begin by establishing a Network Security Group (NSG) that will subsequently be associated with the AzureBastionSubnet. It is crucial to note that there are specific prerequisites concerning security rules that must be met before Azure Bastion can be deployed.

Essentially, we are establishing security rules to permit both the control and data plane access to the AzureBastion. For a more detailed understanding of these rules, please refer to the following resource: [More Information](https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg).

Lets Create the NSG for AzureBastionSubnet.
````bash
az network nsg create \
    --resource-group $RG \
    --name $BASTION_NSG_NAME \
    --location $LOCATION
````

Associate the required **inbound** security rules to the NSG.
````bash
    az network nsg rule create --name AllowHttpsInbound \
    --nsg-name $BASTION_NSG_NAME --priority 120 --resource-group $RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "Internet" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"
	
   	az network nsg rule create --name AllowGatewayManagerInbound \
    --nsg-name $BASTION_NSG_NAME --priority 130 --resource-group $RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "GatewayManager" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"
	
	az network nsg rule create --name AllowAzureLoadBalancerInbound \
    --nsg-name $BASTION_NSG_NAME --priority 140 --resource-group $RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "AzureLoadBalancer" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"
	
	
	az network nsg rule create --name AllowBastionHostCommunication \
    --nsg-name $BASTION_NSG_NAME --priority 150 --resource-group $RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "VirtualNetwork" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 8080 5701
````

Associate the required **outbound** security rules to the NSG.

````bash
    az network nsg rule create --name AllowSshRdpOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 100 --resource-group $RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 22 3389
	
    az network nsg rule create --name AllowAzureCloudOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 110 --resource-group $RG\
    --access Allow --protocol Tcp --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "AzureCloud" \
    --destination-port-ranges 443
	
	az network nsg rule create --name AllowBastionCommunication \
    --nsg-name $BASTION_NSG_NAME --priority 120 --resource-group $RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "VirtualNetwork" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 8080 5701
	
	az network nsg rule create --name AllowHttpOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 130 --resource-group $RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "Internet" \
    --destination-port-ranges 80
````

Create an NSG for the JumpBox subnet.

````bash
az network nsg create \
    --resource-group $RG \
    --name $JUMPBOX_NSG_NAME \
    --location $LOCATION
````

### Create the hub virtual network with three subnets, and associate the NSG to their respective subnet.


Create the HUB VNET with one subnet for **Azure Bastion Subnet** and associate it to the bastion NSG.

````bash
az network vnet create \
    --resource-group $RG  \
    --name $HUB_VNET_NAME \
    --address-prefixes $HUB_VNET_PREFIX \
    --subnet-name $BASTION_SUBNET_NAME \
    --subnet-prefixes $BASTION_SUBNET_PREFIX \
    --network-security-group $BASTION_NSG_NAME

````
Create subnet for the Azure Firewall


````bash
az network vnet subnet create \
    --resource-group $RG  \
    --vnet-name $HUB_VNET_NAME \
    --name $FW_SUBNET_NAME \
    --address-prefixes $FW_SUBNET_PREFIX

````
Create subnet for the Virtual Machine that will be used as "jumpbox".

````bash

az network vnet subnet create \
    --resource-group $RG  \
    --vnet-name $HUB_VNET_NAME \
    --name $JUMPBOX_SUBNET_NAME \
    --address-prefixes $JUMPBOX_SUBNET_PREFIX \
    --network-security-group $JUMPBOX_NSG_NAME
````

### Create Network Security Group (NSG) for the Spoke.
````bash
az network nsg create \
    --resource-group $RG \
    --name $AKS_NSG_NAME \
    --location $LOCATION
	
az network nsg create \
    --resource-group $RG \
    --name $ENDPOINTS_NSG_NAME \
    --location $LOCATION

az network nsg create \
    --resource-group $RG \
    --name $LOADBALANCER_NSG_NAME \
    --location $LOCATION

az network nsg create \
    --resource-group $RG \
    --name $APPGW_NSG \
    --location $LOCATION

# Allow Internet Client request on Port 443 and 80
az network nsg rule create \
    --resource-group $RG \
    --nsg-name $APPGW_NSG \
    --name Allow-Internet-Inbound-HTTP-HTTPS \
    --priority 100 \
    --source-address-prefixes Internet \
    --destination-port-ranges 80 443 \
    --access Allow \
    --protocol Tcp \
    --description "Allow inbound traffic to port 80 and 443 to Application Gateway from client requests originating from the Internet"

# Infrastructure ports
az network nsg rule create \
    --resource-group $RG \
    --nsg-name $APPGW_NSG \
    --name Allow-GatewayManager-Inbound \
    --priority 110 \
    --source-address-prefixes "GatewayManager" \
    --destination-port-ranges 65200-65535 \
    --access Allow \
    --protocol Tcp \
    --description "Allow inbound traffic to ports 65200-65535 from GatewayManager service tag"
````



### Create the spoke virtual network with 4 subnets, and associate the NSG to their respective subnet.


Create the spoke VNET with one subnet for **AKS Subnet** and associate it to the AKS NSG.

````bash
az network vnet create \
    --resource-group $RG  \
    --name $SPOKE_VNET_NAME \
    --address-prefixes $SPOKE_VNET_PREFIX \
    --subnet-name $AKS_SUBNET_NAME \
    --subnet-prefixes $AKS_SUBNET_PREFIX \
	--network-security-group $AKS_NSG_NAME

````

Create subnet for the Endpoints and associate it to the endpoints NSG.


````bash
az network vnet subnet create \
    --resource-group $RG  \
    --vnet-name $SPOKE_VNET_NAME  \
    --name $ENDPOINTS_SUBNET_NAME \
    --address-prefixes $ENDPOINTS_SUBNET_PREFIX \
	--network-security-group $ENDPOINTS_NSG_NAME

````

Create subnet for the load balancer that will be used for ingress traffic and associate it to the loadbalancer NSG.

````bash
az network vnet subnet create \
    --resource-group $RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $LOADBALANCER_SUBNET_NAME \
    --address-prefixes $LOADBALANCER_SUBNET_PREFIX \
	--network-security-group $LOADBALANCER_NSG_NAME
````

Create subnet for the Application Gateway and associate it to the Application Gateway NSG.

````bash
az network vnet subnet create \
    --resource-group $RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $APPGW_SUBNET_NAME \
    --address-prefixes $APPGW_SUBNET_PREFIX \
	--network-security-group $APPGW_NSG

````

### Create a peering connection between the hub and spoke virtual networks


````bash
az network vnet peering create \
    --resource-group $RG  \
    --name hub-to-spoke \
    --vnet-name $HUB_VNET_NAME \
    --remote-vnet $SPOKE_VNET_NAME \
    --allow-vnet-access

````

### Create a peering connection between the spoke and hub virtual networks


````bash
az network vnet peering create \
    --resource-group $RG  \
    --name spoke-to-hub \
    --vnet-name $SPOKE_VNET_NAME \
    --remote-vnet $HUB_VNET_NAME \
    --allow-vnet-access

````

### Create a public IP address for the bastion host


````bash
az network public-ip create \
    --resource-group $RG  \
    --name Bastion-PIP \
    --sku Standard \
    --allocation-method Static
````


### Create JumpBox host

````bash
az vm create \
    --resource-group $RG \
    --name $JUMPBOX_VM_NAME \
    --image Ubuntu2204 \
    --admin-username azureuser \
    --admin-password Ericsson_2055 \
    --vnet-name $HUB_VNET_NAME \
    --subnet $JUMPBOX_SUBNET_NAME \
    --size Standard_B2s \
    --storage-sku Standard_LRS \
    --os-disk-name $JUMPBOX_VM_NAME-VM-osdisk \
    --os-disk-size-gb 128 \
    --public-ip-address "" \
    --nsg ""  
  
````
````bash
az vm extension set --resource-group $RG --vm-name $JUMPBOX_VM_NAME --name customScript --publisher Microsoft.Azure.Extensions --version 2.0 --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/abengtss-max/simple_aks/main/install.sh\"]}" --protected-settings "{\"commandToExecute\": \"sh install.sh\"}"

````
### Create the bastion host in hub vnet



````bash
az network bastion create \
    --resource-group $RG \
    --name bastionhost \
    --public-ip-address Bastion-PIP \
    --vnet-name $HUB_VNET_NAME \
    --location westeurope

````

### Connect to VM using the portal:

Upon successful installation of the Jumpbox Virtual Machine (VM), the next step is to validate the connectivity between the Bastion and Jumpbox host. Here are the steps to follow:

1) Navigate to the Azure portal at **portal.azure.com** and enter your login credentials.
2) Once logged in, locate and select your **resource group** where the Jumpbox has been deployed.
3) Within your resource group, find and click on the **Jumpbox VM**.
4) In the left-hand side menu, under the **Operations** section, select ‘Bastion’.
5) Enter the **credentials** for the Jumpbox VM and verify that you can log in successfully, 

For additional information on accessing VMs through Bastion, please refer to this [Microsoft Azure Bastion tutorial](https://learn.microsoft.com/en-us/azure/bastion/create-host-cli#steps)

### Create an Azure Firewall and setup a UDR


To secure your AKS outbound traffic, you need to follow these steps for a basic cluster deployment. These steps will help you restrict the outbound access to only certain FQDNs that are needed by the cluster.

````bash
az network firewall create \
    --resource-group $RG \
    --name $FW_NAME \
    --location westeurope \
    --vnet-name $HUB_VNET_NAME \
    --enable-dns-proxy true

````

````bash
az network public-ip create \
    --name fw-pip \
    --resource-group $RG \
    --location westeurope \
    --allocation-method static \
    --sku standard

````

````bash
az network firewall ip-config create \
    --firewall-name $FW_NAME \
    --name FW-config \
    --public-ip-address fw-pip \
    --resource-group $RG \
    --vnet-name $HUB_VNET_NAME

````

````bash
az network firewall update \
    --name $FW_NAME \
    --resource-group $RG 

````

### Create Azure firewall network rules    


````bash
az network firewall network-rule create -g $RG -f $FW_NAME --collection-name 'aksfwnr' -n 'apiudp' --protocols 'UDP' --source-addresses '*' --destination-addresses "AzureCloud.$LOCATION" --destination-ports 1194 --action allow --priority 100
````

````bash
az network firewall network-rule create -g $RG -f $FW_NAME --collection-name 'aksfwnr' -n 'apitcp' --protocols 'TCP' --source-addresses '*' --destination-addresses "AzureCloud.$LOCATION" --destination-ports 9000
````

````bash
az network firewall network-rule create -g $RG -f $FW_NAME --collection-name 'aksfwnr' -n 'time' --protocols 'UDP' --source-addresses '*' --destination-fqdns 'ntp.ubuntu.com' --destination-ports 123

````

### Create Azure firewall application rules
This rules specifies the FQDN's which are required by AKS, **AzureKubernetesService** tag which include all the FQDNs listed in Outbound network and FQDN rules for AKS clusters.

````bash
az network firewall application-rule create -g $RG -f $FW_NAME --collection-name 'aksfwar' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --fqdn-tags "AzureKubernetesService" --action allow --priority 100

````

### Create a route table for the spoke virtual network


````bash
az network route-table create \
    --resource-group $RG  \
    --name $ROUTE_TABLE_NAME

````

### Create a route to the internet via the Azure Firewall
````bash
 fw_private_ip=$(az network firewall show \
    --resource-group $RG \
    --name $FW_NAME \
    --query 'ipConfigurations[0].privateIpAddress' \
    --output tsv)
````


````bash
az network route-table route create \
    --resource-group $RG  \
    --name default-route \
    --route-table-name $ROUTE_TABLE_NAME \
    --address-prefix 0.0.0.0/0 \
    --next-hop-type VirtualAppliance \
    --next-hop-ip-address $fw_private_ip

````

### Associate the route table with the aks-subnet


````bash
az network vnet subnet update \
    --resource-group $RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $AKS_SUBNET_NAME \
    --route-table $ROUTE_TABLE_NAME

````

### Create a user-assigned managed identity


````bash
az identity create \
    --resource-group $RG \
    --name $AKS_IDENTITY_NAME

````

### Get the id of the user managed identity
````bash
 identity_id=$(az identity show \
    --resource-group $RG \
    --name $AKS_IDENTITY_NAME \
    --query id \
    --output tsv)

````

### Get the principal id of the user managed identity
````bash
principal_id=$(az identity show \
    --resource-group $RG \
    --name $AKS_IDENTITY_NAME \
    --query principalId \
    --output tsv)

````

### Get the scope of the routing table

````bash
rt_scope=$(az network route-table show \
    --resource-group $RG \
    --name $ROUTE_TABLE_NAME  \
    --query id \
    --output tsv)
````
### Assign permissions for the AKS user defined managed identity to the routing table


````bash
az role assignment create \
    --assignee $principal_id \
    --scope $rt_scope \
    --role "Network Contributor"

````
### Assign permission for the AKS user defined managed identity to the load balancer subnet

````bash
lb_subnet_scope=$(az network vnet subnet list \
    --resource-group $RG \
    --vnet-name $SPOKE_VNET_NAME \
    --query "[?name=='$LOADBALANCER_SUBNET_NAME'].id" \
    --output tsv)
````

````bash
az role assignment create \
    --assignee $principal_id \
    --scope $lb_subnet_scope \
    --role "Network Contributor"

````
> **_! Note:_**
In the context of Azure Kubernetes Service (AKS), granting the Network Contributor role to the load balancer subnet could potentially result in over-privileged access. To adhere to the principle of least privilege access, it is recommended to only provide AKS with the necessary permissions it needs to function effectively. This approach minimizes potential security risks by limiting the access rights of AKS to the bare minimum required for it to perform its tasks. For more information refer to [Creating Azure custom role](./docs/customrole.md)



### Create the AKS cluster in the aks-subnet

````bash
aks_subnet_scope=$(az network vnet subnet list \
    --resource-group $RG \
    --vnet-name $SPOKE_VNET_NAME \
    --query "[?name=='$AKS_SUBNET_NAME'].id" \
    --output tsv)
````

````bash
az aks create --resource-group $RG --node-count 3 --vnet-subnet-id $aks_subnet_scope --name $AKS_CLUSTER_NAME --enable-private-cluster --outbound-type userDefinedRouting --enable-oidc-issuer --enable-workload-identity --generate-ssh-keys --assign-identity $identity_id

````

### Link the the hub network to the private DNS zone. 

````bash
NODE_GROUP=$(az aks show --resource-group $RG --name $AKS_CLUSTER_NAME --query nodeResourceGroup -o tsv)
````

````bash
DNS_ZONE_NAME=$(az network private-dns zone list --resource-group $NODE_GROUP --query "[0].name" -o tsv)

````

````bash
HUB_VNET_ID=$(az network vnet show -g $RG -n $HUB_VNET_NAME --query id --output tsv)
````

````bash
az network private-dns link vnet create --name "hubnetdnsconfig" --registration-enabled false --resource-group $NODE_GROUP --virtual-network $HUB_VNET_ID --zone-name $DNS_ZONE_NAME 

````

### Verify AKS control plane connectivity

In this section we will verify that we are able to connect to the AKS cluster from the jumpbox, firstly we need to connect to the cluster successfully and secondly we need to verify that the kubernetes client is able to communicate with the AKS control plane. 

1) Navigate to the Azure portal at **portal.azure.com** and enter your login credentials.
2) Once logged in, locate and select your **resource group** where the Jumpbox has been deployed.
3) Within your resource group, find and click on the **Jumpbox VM**.
4) In the left-hand side menu, under the **Operations** section, select ‘Bastion’.
5) Enter the **credentials** for the Jumpbox VM and verify that you can log in successfully.
6) Once successfully logged in to the jumbox **login to Azure** in order to obtain AKS credentials.

````bash
sudo az login
sudo az account set --subscription <SUBSCRIPTION ID>
````

> **_! Note:_**
To check the current subscription, run the command: **az account show**
To change the subscription, run the command: **az account set --subscription <SUBSCRIPTION ID>, where <SUBSCRIPTION ID>** is the ID of the desired subscription. You can find the subscription ID by running the command: **az account list --output table**

7) Download the credentials

````bash
sudo az aks get-credentials --resource-group $RG --name $AKS_CLUSTER_NAME
````
8) Ensure you can list resources in AKS.

````bash
sudo kubectl get nodes
````
The following output shows the result of running the command kubectl get nodes on the Azure CLI.

````bash
azureuser@Jumpbox-VM:~$ sudo kubectl get nodes
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-33590162-vmss000000   Ready    agent   11h   v1.26.6
aks-nodepool1-33590162-vmss000001   Ready    agent   11h   v1.26.6
aks-nodepool1-33590162-vmss000002   Ready    agent   11h   v1.26.6
````
### Create ACR 


````bash
az acr create \
    --resource-group $RG \
    --name $ACR_NAME \
    --sku Premium \
    --admin-enabled false \
    --location westeurope \
    --allow-trusted-services false \
    --public-network-enabled false

````

### Disable network policies in subnet


````bash
az network vnet subnet update \
 --name $ENDPOINTS_SUBNET_NAME \
 --vnet-name $SPOKE_VNET_NAME\
 --resource-group $RG \
 --disable-private-endpoint-network-policies

````
### Configure the private DNS zone

````bash
az network private-dns zone create \
  --resource-group $RG \
  --name "privatelink.azurecr.io"

````

### Create a virtual network association link 
 


````bash
# creates a virtual network link to the spoke network
az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name "privatelink.azurecr.io" \
  --name ACRDNSSpokeLink \
  --virtual-network $SPOKE_VNET_NAME \
  --registration-enabled false
 
````

````bash
# Creates a virtual network link to the hub network
az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name "privatelink.azurecr.io" \
  --name ACRDNSHubLink \
  --virtual-network $HUB_VNET_NAME \
  --registration-enabled false

````

### Create a private registry endpoint 
````bash
REGISTRY_ID=$(az acr show --name $ACR_NAME \
  --query 'id' --output tsv)

````

````bash
az network private-endpoint create \
    --name ACRPrivateEndpoint \
    --resource-group $RG \
    --vnet-name $SPOKE_VNET_NAME \
    --subnet $ENDPOINTS_SUBNET_NAME \
    --private-connection-resource-id $REGISTRY_ID \
    --group-ids registry \
    --connection-name PrivateACRConnection
````

#### Configure DNS record 

### Get endpoint IP configuration
````bash
NETWORK_INTERFACE_ID=$(az network private-endpoint show \
  --name ACRPrivateEndpoint \
  --resource-group $RG \
  --query 'networkInterfaces[0].id' \
  --output tsv)

 ```` 

### Fetch the container registry private IP address
````bash
REGISTRY_PRIVATE_IP=$(az network nic show --ids $NETWORK_INTERFACE_ID --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry'].privateIPAddress" -o tsv)
````
### Fetch the data endpoint IP address of the container registry
````bash
DATA_ENDPOINT_PRIVATE_IP=$(az network nic show --ids $NETWORK_INTERFACE_ID --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry_data_westeurope'].privateIPAddress" -o tsv)
````

### Fetch the FQDN associated with the registry and data endpoint
````bash
REGISTRY_FQDN=$(az network nic show \
  --ids $NETWORK_INTERFACE_ID \
  --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry'].privateLinkConnectionProperties.fqdns" \
  --output tsv)
````
````bash
DATA_ENDPOINT_FQDN=$(az network nic show \
  --ids $NETWORK_INTERFACE_ID \
  --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry_data_westeurope'].privateLinkConnectionProperties.fqdns" \
  --output tsv)
````


### Create DNS records in the private zone

````bash
az network private-dns record-set a create \
  --name $ACR_NAME \
  --zone-name privatelink.azurecr.io \
  --resource-group $RG

  ````

### Specify registry region in data endpoint name

````bash
az network private-dns record-set a create \
  --name $ACR_NAME.westeurope.data \
  --zone-name privatelink.azurecr.io \
  --resource-group $RG

````
  
### create the A records for the registry endpoint and data endpoint

````bash
az network private-dns record-set a add-record \
  --record-set-name $ACR_NAME \
  --zone-name privatelink.azurecr.io \
  --resource-group $RG \
  --ipv4-address $REGISTRY_PRIVATE_IP

````

### Specify registry region in data endpoint name

````bash
az network private-dns record-set a add-record \
  --record-set-name $ACR_NAME.westeurope.data \
  --zone-name privatelink.azurecr.io \
  --resource-group $RG \
  --ipv4-address $DATA_ENDPOINT_PRIVATE_IP

````

### Test the connection to ACR

In this section, you will learn how to check if you can access your private Azure Container Registry (ACR) and push Docker images to it. You will need to have the Azure CLI installed and logged in to your Azure account. You will also need to have Docker installed and running on your Jumpbox. Here are the steps to follow:

1) Navigate to the Azure portal at **portal.azure.com** and enter your login credentials.
2) Once logged in, locate and select your **resource group** where the Jumpbox has been deployed.
3) Within your resource group, find and click on the **Jumpbox VM**.
4) In the left-hand side menu, under the **Operations** section, select ‘Bastion’.
5) Enter the **credentials** for the Jumpbox VM and verify that you can log in successfully.
6) Once successfully logged in to the jumpbox **login to Azure** if you have not already done so in previous steps.

````bash
sudo az login
````
Identify your subscription id from the list, if you have several subscriptions.

````bash
az account list -o table
````
Set your subscription id to be the default subscription.
````bash
sudo az account set --subscription <SUBSCRIPTION ID>
````
7. Validate private link connection 

List your ACR in your subscription and note down the ACR name.
````bash
sudo az acr list -o table
````
````bash
dig <REGISTRY NAME>.azurecr.io
````
Example output shows the registry's private IP address in the address space of the subnet:
````dns
azureuser@Jumpbox-VM:~$ dig acraksbl.azurecr.io

; <<>> DiG 9.18.12-0ubuntu0.22.04.3-Ubuntu <<>> acraksbl.azurecr.io
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 39202
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;acraksbl.azurecr.io.INA

;; ANSWER SECTION:
acraksbl.azurecr.io.60INCNAMEacraksbl.privatelink.azurecr.io.
acraksbl.privatelink.azurecr.io. 1800 IN A10.1.2.5

;; Query time: 8 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Mon Oct 02 07:51:55 UTC 2023
;; MSG SIZE  rcvd: 99
````
7. Create a Dockerfile, build the docker image, authenticate towards ACR and push the image to the container registry.
````bash
touch Dockerfile
vim Dockerfile
````
Add the following content to the Dockerfile

````bash
FROM nginx
EXPOSE 80
CMD [“nginx”, “-g”, “daemon off;”
````
Build the Docker image

````bash
sudo docker build --tag nginx .
````
Example out:
````bash
azureuser@Jumpbox-VM:~$ sudo docker build --tag nginx .

Sending build context to Docker daemon  222.7kB
Step 1/3 : FROM nginx
latest: Pulling from library/nginx
a803e7c4b030: Pull complete 
8b625c47d697: Pull complete 
4d3239651a63: Pull complete 
0f816efa513d: Pull complete 
01d159b8db2f: Pull complete 
5fb9a81470f3: Pull complete 
9b1e1e7164db: Pull complete 
Digest: sha256:32da30332506740a2f7c34d5dc70467b7f14ec67d912703568daff790ab3f755
Status: Downloaded newer image for nginx:latest
 ---> 61395b4c586d
Step 2/3 : EXPOSE 80
 ---> Running in d7267ee641b6
Removing intermediate container d7267ee641b6
 ---> 06a5ac2e4ba6
Step 3/3 : CMD [“nginx”, “-g”, “daemon off;”]
 ---> Running in c02c94dc283c
Removing intermediate container c02c94dc283c
 ---> 49a47448ba86
Successfully built 49a47448ba86
Successfully tagged nginx:latest
````
Create an alias of the image
````bash
sudo docker tag nginx <CONTAINER REGISTRY NAME>.azurecr.io/nginx
````
Authenticate to ACR.
````bash
sudo az acr login --name <CONTAINER REGISTRY NAME>
````
Upload the docker image to the ACR repository.
````bash
sudo docker push <CONTAINER REGISTRY NAME>.azurecr.io/nginx
````
Example output:

````bash
azureuser@Jumpbox-VM:~$ sudo docker push acraksbl.azurecr.io/nginx
Using default tag: latest
The push refers to repository [acraksbl.azurecr.io/nginx]
d26d4f0eb474: Pushed 
a7e2a768c198: Pushed 
9c6261b5d198: Pushed 
ea43d4f82a03: Pushed 
1dc45c680d0f: Pushed 
eb7e3384f0ab: Pushed 
d310e774110a: Pushed 
latest: digest: sha256:3dc6726adf74039f21eccf8f3b5de773080f8183545de5a235726132f70aba63 size: 1778
````
## Create Application Gateway

### Create public IP address with a domain name associated to the PIP resource


````bash
az network public-ip create -g $RG -n AGPublicIPAddress --dns-name mvcnstudent02 --allocation-method Static --sku Standard --location westeurope

````

### Create WAF policy 


````bash
az network application-gateway waf-policy create --name ApplicationGatewayWAFPolicy --resource-group $RG
````

### Create application Gateway 

  

````bash
az network application-gateway create \
  --name AppGateway \
  --location westeurope \
  --resource-group $RG \
  --vnet-name $SPOKE_VNET_NAME \
  --subnet $APPGW_SUBNET_NAME \
  --capacity 1 \
  --sku WAF_v2 \
  --http-settings-cookie-based-affinity Disabled \
  --frontend-port 443 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --priority "1" \
  --public-ip-address AGPublicIPAddress \
  --cert-file appgwcert.pfx \
  --cert-password "<CERTIFICATE PASSWORD>" \
  --waf-policy ApplicationGatewayWAFPolicy \
  --servers 10.1.3.4
````
### Create Health probe
````bash
 az network application-gateway probe create \
    --gateway-name $APPGW_NAME \
    --resource-group $RG \
    --name health-probe \
    --protocol Http \
    --path / \
    --interval 30 \
    --timeout 120 \
    --threshold 3 \
    --host 127.0.0.1
````

### Associate the health probe to the backend pool.
````bash
az network application-gateway http-settings update -g $RG --gateway-name $APPGW_NAME -n appGatewayBackendHttpSettings --probe health-probe
````

### Attach Kubernetes
````bash
az aks update \
    --resource-group $RG \
    --name $AKS_CLUSTER_NAME \
    --attach-acr $ACR_NAME
````
### Validate AKS is able to pull images from ACR
On the Jumpbox VM create a yaml file.

````bash
touch test-pod.yaml
vim test-pod.yaml
````
Paste in the following manifest file which creates a Pod named **internal-test-app** which fetches the docker images from our internal container registry, created in previous step. 
````yaml
apiVersion: v1
kind: Pod
metadata:
  name: internal-test-app
  labels:
    app: internal-test-app
spec:
  containers:
  - name: nginx
    image: acraksbl.azurecr.io/nginx
    ports:
    - containerPort: 80
````
Create the pod.
````yaml
kubectl create -f test-pod.yaml
````
````yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-test-app
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "<LOADBALANCER SUBNET NAME>"
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: internal-test-app
````
Verify that the Pod is in running state.
````bash
sudo kubectl get po --show-labels
````
Example output

````bash
azureuser@Jumpbox-VM:~$ sudo kubectl get po 
NAME                READY   STATUS    RESTARTS   AGE
internal-test-app   1/1     Running   0          8s
````
Our next step is to set up an internal load balancer that will direct the traffic to our intern Pod. The internal load balancer will be deployed in the load balancer subnet of the spoke-vnet.

````yaml
touch internal-app-service.yaml
vim internal-app-service.yaml
````
````yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-test-app-service
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "<LOADBALANCER SUBNET>"
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: internal-test-app
````
Deploy the service object in AKS.

````
sudo kubectl create -f internal-app-service.yaml
````
Verify that your service object is created and associated with the Pod that you have created, also ensure that you have recieved an external IP, which should be a private IP address range from the load balancer subnet.

````
sudo kubectl get svc -o wide
````
Example output:

````
azureuser@Jumpbox-VM:~$ sudo kubectl get svc -o wide
NAME                        TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE   SELECTOR
internal-test-app-service   LoadBalancer   10.0.252.53   10.1.3.4      80:30161/TCP   39s   app=internal-test-app
kubernetes                  ClusterIP      10.0.0.1      <none>        443/TCP        43h   <none>
azureuser@Jumpbox-VM:~$ 
````

Now access your domain: <STUDENT NAME>.akssecurity.se