# 3.0 Deploy Infrastructure

The objective of this chapter is to guide you through the process of deploying the AKS baseline infrastructure. This infrastructure consists of the essential components and configurations that are required for running a secure and scalable AKS cluster. By following the steps in this chapter, you will be able to set up the AKS baseline infrastructure.

## 3.1 Deployment

### 3.1.1 Prepare Environment Variables for infrastructure

This configuration sets up environment variables for the names and locations of various network and security resources, such as resource group, virtual network, subnets, network security groups, firewall, application gateway, route table, identity, virtual machine, AKS cluster, and ACR registry.

> **_! Note:_** Since the Azure container registry has a globally unique FQDN name, you need to assign a distinct value to the **ACR_NAME** environment variable, else the ACR deployment will fail. 

````bash
HUB_RG=rg-hub
SPOKE_RG=rg-spoke
LOCATION=eastus 
BASTION_NSG_NAME=Bastion_NSG
JUMPBOX_NSG_NAME=Jumpbox_NSG
AKS_NSG_NAME=Aks_NSG
ENDPOINTS_NSG_NAME=Endpoints_NSG
LOADBALANCER_NSG_NAME=Loadbalancer_NSG
APPGW_NSG=Appgw_NSG
FW_NAME=azure-firewall
APPGW_NAME=AppGateway
ROUTE_TABLE_NAME=spoke-rt
AKS_IDENTITY_NAME=aks-msi
JUMPBOX_VM_NAME=Jumpbox-VM
AKS_CLUSTER_NAME=private-aks
ACR_NAME=<NAME OF THE AZURE CONTAINER REGISTRY>
STUDENT_NAME=<WRITE YOUR STUDENT NAME HERE>
````

### 3.1.2 Create the Resource Group for the Hub and Spoke.

````bash
az group create --name $HUB_RG --location $LOCATION
az group create --name $SPOKE_RG --location $LOCATION
````

### 3.1.3 Create Network Security Groups (NSG) and Virtual Network (Vnet) for the Hub.
In this step, we will begin by establishing a Network Security Group (NSG) that will subsequently be associated with their respective subnet. It is crucial to note that there are specific prerequisites concerning security rules for certain subnets that must be met  before a service can be deployed, Azure Bastion is one of them.

For Azure Bastion, we are establishing security rules to permit both the control and data plane access to the AzureBastion. For a more detailed understanding of these rules, please refer to the following resource: [More Information](https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg).

1) Lets Create the NSG for AzureBastionSubnet.
````bash
az network nsg create \
    --resource-group $HUB_RG \
    --name $BASTION_NSG_NAME \
    --location $LOCATION
````

2) Associate the required **inbound** security rules to the NSG.
````bash
    az network nsg rule create --name AllowHttpsInbound \
    --nsg-name $BASTION_NSG_NAME --priority 120 --resource-group $HUB_RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "Internet" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"
	
   	az network nsg rule create --name AllowGatewayManagerInbound \
    --nsg-name $BASTION_NSG_NAME --priority 130 --resource-group $HUB_RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "GatewayManager" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"
	
	az network nsg rule create --name AllowAzureLoadBalancerInbound \
    --nsg-name $BASTION_NSG_NAME --priority 140 --resource-group $HUB_RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "AzureLoadBalancer" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"
	
	
	az network nsg rule create --name AllowBastionHostCommunication \
    --nsg-name $BASTION_NSG_NAME --priority 150 --resource-group $HUB_RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "VirtualNetwork" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 8080 5701
````

3) Associate the required **outbound** security rules to the NSG.

````bash
    az network nsg rule create --name AllowSshRdpOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 100 --resource-group $HUB_RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 22 3389
	
    az network nsg rule create --name AllowAzureCloudOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 110 --resource-group $HUB_RG\
    --access Allow --protocol Tcp --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "AzureCloud" \
    --destination-port-ranges 443
	
	az network nsg rule create --name AllowBastionCommunication \
    --nsg-name $BASTION_NSG_NAME --priority 120 --resource-group $HUB_RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "VirtualNetwork" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 8080 5701
	
	az network nsg rule create --name AllowHttpOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 130 --resource-group $HUB_RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "Internet" \
    --destination-port-ranges 80
````

4) Create an NSG for the JumpBox subnet.

````bash
az network nsg create \
    --resource-group $HUB_RG \
    --name $JUMPBOX_NSG_NAME \
    --location $LOCATION
````
5) Create the HUB VNET with one subnet for **Azure Bastion Subnet** and associate it to the bastion NSG.

````bash
az network vnet create \
    --resource-group $HUB_RG  \
    --name $HUB_VNET_NAME \
    --address-prefixes $HUB_VNET_PREFIX \
    --subnet-name $BASTION_SUBNET_NAME \
    --subnet-prefixes $BASTION_SUBNET_PREFIX \
    --network-security-group $BASTION_NSG_NAME
````
6) Create a subnet for the Azure Firewall.


````bash
az network vnet subnet create \
    --resource-group $HUB_RG  \
    --vnet-name $HUB_VNET_NAME \
    --name $FW_SUBNET_NAME \
    --address-prefixes $FW_SUBNET_PREFIX
````

7) Create a subnet for the Virtual Machine that will be used as "jumpbox".

````bash
az network vnet subnet create \
    --resource-group $HUB_RG  \
    --vnet-name $HUB_VNET_NAME \
    --name $JUMPBOX_SUBNET_NAME \
    --address-prefixes $JUMPBOX_SUBNET_PREFIX \
    --network-security-group $JUMPBOX_NSG_NAME
````
You have successfully configured the network for your hub virtual network.You have established three subnets and two NSGs, as depicted on the image:

![Screenshot](images/HubVnetandNsgOnly.jpg)

Validate your deployment in the Azure portal.

8) Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com) and enter your login credentials.

9) Once logged in, locate and select your resource group called **rg-hub** where the hub vnet is deployed.

10) Select your vnet called **HUB_VNET**.

11) In the left-hand side menu, under the **Settings** section, select **Subnets**.
12) Make sure that your subnets have the appropriate IP range and that Network Security Groups (NSGs) are correctly associated with their respective subnets as depicted below.

![Screenshot](images/hubandspokevnet.jpg)

### 3.1.4 Create Network Security Groups and Virtual Network for the Spoke.
We will now start to setup the spoke vnet, subnets and their respective NSGs,

1) Create the NSG for AKS subnet.
````bash
az network nsg create \
    --resource-group $SPOKE_RG \
    --name $AKS_NSG_NAME \
    --location $LOCATION
````
2) Create the NSG for endpoints subnet, were the endpoints will reside.
````bash
az network nsg create \
    --resource-group $SPOKE_RG \
    --name $ENDPOINTS_NSG_NAME \
    --location $LOCATION
````
3) Create the NSG for load balancer subnet, were the internal load balancer will reside.
````bash
az network nsg create \
    --resource-group $SPOKE_RG \
    --name $LOADBALANCER_NSG_NAME \
    --location $LOCATION
````
4) To use an NSG with your application gateway, you need to open these port ranges:

Inbound rules: The **Internet service tag** needs access to port **65200-65535** for the backend health API. Your application traffic needs access to TCP port **80 and/or 443**. for futher information refer to [Required security rules for Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#required-security-rules) for more information.
````bash
az network nsg create \
    --resource-group $SPOKE_RG \
    --name $APPGW_NSG \
    --location $LOCATION
````
5) Create the NSG rule to allow application traffic, on port 443 and 80.

````bash
# Allow Internet Client request on Port 443 and 80
az network nsg rule create \
    --resource-group $SPOKE_RG \
    --nsg-name $APPGW_NSG \
    --name Allow-Internet-Inbound-HTTP-HTTPS \
    --priority 100 \
    --source-address-prefixes Internet \
    --destination-port-ranges 80 443 \
    --access Allow \
    --protocol Tcp \
    --description "Allow inbound traffic to port 80 and 443 to Application Gateway from client requests originating from the Internet"
````
5) Create the NSG rule to allow application traffic, on port 443 and 80.
````bash
# Infrastructure ports
az network nsg rule create \
    --resource-group $SPOKE_RG \
    --nsg-name $APPGW_NSG \
    --name Allow-GatewayManager-Inbound \
    --priority 110 \
    --source-address-prefixes "GatewayManager" \
    --destination-port-ranges 65200-65535 \
    --access Allow \
    --protocol Tcp \
    --description "Allow inbound traffic to ports 65200-65535 from GatewayManager service tag"
````
6) Create the spoke VNET with one subnet for **AKS Subnet** and associate it to the AKS NSG.

````bash
az network vnet create \
    --resource-group $SPOKE_RG  \
    --name $SPOKE_VNET_NAME \
    --address-prefixes $SPOKE_VNET_PREFIX \
    --subnet-name $AKS_SUBNET_NAME \
    --subnet-prefixes $AKS_SUBNET_PREFIX \
	--network-security-group $AKS_NSG_NAME
````

7) Create the subnet for **Endpoints** and associate it to the endpoints NSG.

````bash
az network vnet subnet create \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME  \
    --name $ENDPOINTS_SUBNET_NAME \
    --address-prefixes $ENDPOINTS_SUBNET_PREFIX \
	--network-security-group $ENDPOINTS_NSG_NAME
````
8) Create subnet for the **load balancer** that will be used for ingress traffic and associate it to the loadbalancer NSG.

````bash
az network vnet subnet create \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $LOADBALANCER_SUBNET_NAME \
    --address-prefixes $LOADBALANCER_SUBNET_PREFIX \
	--network-security-group $LOADBALANCER_NSG_NAME
````

9) Create subnet for the **Application Gateway** and associate it to the Application Gateway NSG.

````bash
az network vnet subnet create \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $APPGW_SUBNET_NAME \
    --address-prefixes $APPGW_SUBNET_PREFIX \
	--network-security-group $APPGW_NSG
````
You have successfully configured the network for your spoke virtual network. You should now have established the following setup in your Azure subscription.

![Screenshot](/images/hubandspokeonly.jpg)

Validate your deployment in the Azure portal.

10) Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com) and enter your login credentials.

11) Once logged in, locate and select your resource group called **rg-spoke** where the hub vnet is deployed.

12) Select your vnet called **Spoke_VNET**.

13) In the left-hand side menu, under the **Settings** section, select **Subnets**.
14) Make sure that your subnets have the appropriate IP range and that Network Security Groups (NSGs) are correctly associated with their respective subnets as depicted below.

![Screenshot](images/spokevnet.jpg)

### 3.1.5 Create Vnet Peering Between Hub and Spoke

The next step is to create a virtual network peering between the hub and spoke VNets. This will enable the communication between the VNets and allow the AKS cluster to route traffic to the Firewall.

1) Before we can do a Vnet peering we need to obtain the full resource id of the Spoke_VNET and Hub_VNET as they resides in different resource group.

````bash
SPOKE_VNET_ID=$(az network vnet show --resource-group $SPOKE_RG --name $SPOKE_VNET_NAME --query id --output tsv)
````

````bash
HUB_VNET_ID=$(az network vnet show --resource-group $HUB_RG --name $HUB_VNET_NAME --query id --output tsv)
````

1) Create a peering connection from the hub to spoke virtual networks.

````bash
az network vnet peering create \
    --resource-group $HUB_RG  \
    --name hub-to-spoke \
    --vnet-name $HUB_VNET_NAME \
    --remote-vnet $SPOKE_VNET_ID \
    --allow-vnet-access
````

2) Create a peering connection from  the spoke to hub virtual networks.

````bash
az network vnet peering create \
    --resource-group $SPOKE_RG  \
    --name spoke-to-hub \
    --vnet-name $SPOKE_VNET_NAME \
    --remote-vnet $HUB_VNET_ID \
    --allow-vnet-access
````
Peering should be established and the high level design should now look like this.

![Screenshot](/images/hubandspokewithpeering.jpg)

Validate your deployment in the Azure portal.

3) Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com) and enter your login credentials.

4) Once logged in, locate and select your resource group called **rg-spoke** where the hub vnet is deployed.

5) Select your vnet called **Spoke_VNET**.

6) In the left-hand side menu, under the **Settings** section, select **peerings**.
7) Ensure that the peering status is set to **Connected**

8) Repeat step 4 - 7 but for Hub_VNET.

![Screenshot](/images/vnetpeeringconnected.jpg)

### 3.1.6 Create Azure Bastion and Jumpbox VM

1) Create a public IP address for the bastion host

````bash
az network public-ip create \
    --resource-group $HUB_RG  \
    --name Bastion-PIP \
    --sku Standard \
    --allocation-method Static
````
2) Create JumpBox Virtual Machine.

> **_! Note:_**  Ensure you specify a **password** for the admin user called **azureuser**.

````bash
az vm create \
    --resource-group $HUB_RG \
    --name $JUMPBOX_VM_NAME \
    --image Ubuntu2204 \
    --admin-username azureuser \
    --admin-password <SPECIFY A PASSWORD HERE> \
    --vnet-name $HUB_VNET_NAME \
    --subnet $JUMPBOX_SUBNET_NAME \
    --size Standard_B2s \
    --storage-sku Standard_LRS \
    --os-disk-name $JUMPBOX_VM_NAME-VM-osdisk \
    --os-disk-size-gb 128 \
    --public-ip-address "" \
    --nsg ""  
  ````



4) Create the bastion host in hub vnet and associate it to the public IP.
> **_! Note:_**  Azure Bastion service requires a dedicated subnet named **AzureBastionSubnet** to provide secure and seamless RDP/SSH connectivity to your virtual machines. When you deploy Azure Bastion service, it will automatically create this subnet for you, if it does not exist in the target virtual network. However, if the subnet already exists, it must meet the minimum size of **/26** or larger, otherwise the deployment will fail.

````bash
az network bastion create \
    --resource-group $HUB_RG \
    --name bastionhost \
    --public-ip-address Bastion-PIP \
    --vnet-name $HUB_VNET_NAME \
    --location $LOCATION
````
5) Connect to VM using the portal:

Upon successful installation of the Jumpbox Virtual Machine (VM), the next step is to validate the connectivity between the Bastion and Jumpbox host. Here are the steps to follow:

6) Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com) and enter your login credentials.

7) Once logged in, locate and select your **rg-hub** where the Jumpbox has been deployed.

8) Within your resource group, find and click on the **Jumpbox VM**.

9) In the left-hand side menu, under the **Operations** section, select ‘Bastion’.

10) Enter the **credentials** for the Jumpbox VM and verify that you can log in successfully. 

For additional information on accessing VMs through Bastion, please refer to this [Microsoft Azure Bastion tutorial](https://learn.microsoft.com/en-us/azure/bastion/create-host-cli#steps)

After completing these steps, The high-level targeted architecture now matches the following diagram:

![Screenshot](/images/hubandspokewithpeeringBastionJumpbox.jpg)

### 3.1.7 Create an Azure Firewall and setup a UDR

To secure your AKS outbound traffic, you need to follow these steps for a basic cluster deployment. These steps will help you restrict the outbound access and to certain FQDNs that are needed by the cluster. further information can be found here: [Control egress traffic using Azure Firewall in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic)

1) Create Azure Firewall, and deploy it to it to firewall subnet in hub vnet.
````bash
az network firewall create \
    --resource-group $HUB_RG \
    --name $FW_NAME \
    --location $LOCATION \
    --vnet-name $HUB_VNET_NAME \
    --enable-dns-proxy true

````
2) Create the Public IP address resource.

````bash
az network public-ip create \
    --name fw-pip \
    --resource-group $HUB_RG \
    --location $LOCATION \
    --allocation-method static \
    --sku standard

````

3) Associate the public IP address with the Firewall.

````bash
az network firewall ip-config create \
    --firewall-name $FW_NAME \
    --name FW-config \
    --public-ip-address fw-pip \
    --resource-group $HUB_RG \
    --vnet-name $HUB_VNET_NAME

````
4) Update the existing Azure Firewall configuration.

````bash
az network firewall update \
    --name $FW_NAME \
    --resource-group $HUB_RG 
````
5) Create Network rules in Azure Firewall
 
The following network rules allows outbound traffic from any source address to certain destinations and ports. If the required destination is not specified the AKS cluster will fail to deploy.

````bash
az network firewall network-rule create -g $HUB_RG -f $FW_NAME --collection-name 'aksfwnr' -n 'apiudp' --protocols 'UDP' --source-addresses '*' --destination-addresses "AzureCloud.$LOCATION" --destination-ports 1194 --action allow --priority 100
````
````bash
az network firewall network-rule create -g $HUB_RG -f $FW_NAME --collection-name 'aksfwnr' -n 'apitcp' --protocols 'TCP' --source-addresses '*' --destination-addresses "AzureCloud.$LOCATION" --destination-ports 9000
````
````bash
az network firewall network-rule create -g $HUB_RG -f $FW_NAME --collection-name 'aksfwnr' -n 'time' --protocols 'UDP' --source-addresses '*' --destination-fqdns 'ntp.ubuntu.com' --destination-ports 123
````
6) Create Azure Firewall application rule

This rules specifies the FQDN's which are required by AKS, **AzureKubernetesService** tag which include all the FQDNs listed in Outbound network and FQDN rules for AKS clusters.

````bash
az network firewall application-rule create -g $HUB_RG -f $FW_NAME --collection-name 'aksfwar' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --fqdn-tags "AzureKubernetesService" --action allow --priority 100
````

7) Create a route table in the spoke.
````bash
az network route-table create \
    --resource-group $SPOKE_RG  \
    --name $ROUTE_TABLE_NAME

````

8) Create a route to the internet via the Azure Firewall

In order to create the route we need to obtain the private IP address of the Firewall.To get the private IP address of the Firewall, you need to run the following command:

````bash
az network firewall show --resource-group $HUB_RG --name $FW_NAME |grep  privateIPAddress
````

Then store the output (the ip address) in an environment variable:
````bash
FW_PRIVATE_IP=<IP Address from previous command>
````

To get the private IP address of the Firewall, you need to run the following command and store the output in an environment variable.
````bash
az network route-table route create \
    --resource-group $SPOKE_RG  \
    --name default-route \
    --route-table-name $ROUTE_TABLE_NAME \
    --address-prefix 0.0.0.0/0 \
    --next-hop-type VirtualAppliance \
    --next-hop-ip-address $FW_PRIVATE_IP

````
> **_! Note:_** The route will direct all traffic (0.0.0.0/0) to the next hop type of VirtualAppliance, which is the firewall instance. The next hop IP address is the private IP address of the firewall, which is stored in the environment variable $FW_PRIVATE_IP. This way, the traffic from the AKS subnet will be routed to the firewall instance on its private endpoint. This will allow you to perform inspection on outbound traffic.

9) Associate the route table with the AKS subnet.

````bash
az network vnet subnet update \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $AKS_SUBNET_NAME \
    --route-table $ROUTE_TABLE_NAME
````
You have successfully configured the firewall in the hub VNet, set up network and application rules, and created a route table associated with the AKS subnet to direct all internet-bound traffic through the Azure Firewall.

![Screenshot](/images/hubandspokewithpeeringBastionJumpboxFirewall.jpg)
![Screenshot](/images/OutboundTraffic.jpg)

Validate your deployment in the Azure portal.

10) Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com) and enter your login credentials.

11) Once logged in, locate and select your resource group called **rg-hub** where the hub vnet is deployed.

12) Select your firewall called **azure-firewall**.

13) In the left-hand side menu, under the **Settings** section, select **Rules**.

14) Click on  **Network rule collection**

15) Verify that you have a network rule collection called **aksfwnr** which should contain 3 rules. Inspect the rules.

![Screenshot](/images/azfwnr.jpg)

16) Click on **Application rule collection**.

17) Verify that you have an application rule collection called **aksfwar** which should contain 1 rule. Inspect the rule.

![Screenshot](/images/azfwar.jpg)

18) Lets validate the routing between AKS subnet and Azure Firewall, in the Azure portal, in the top menu select **Resource Groups**. 
19) Select resource group **rg-spoke**.

20) Select routing table called **spoke-rt**.

21) Ensure that the default route has a prefix of **0.0.0.0/0** and the next hop is set to the **virtual appliance** with the **IP** address of the Azure Firewall. Also, make sure that the routing table is associated with the AKS subnet called **aks-subnet**.

![Screenshot](/images/spokert.jpg)



### 3.1.6 Deploy Azure Kubernetes Service

In this chapter, we will learn how to deploy AKS and configure its outbound traffic to use the user-defined routing table that we created in the previous chapter. By doing this, we will ensure that all outbound traffic from the AKS subnet will pass through the Azure Firewall for inspection and filtering. Since we are deploying AKS into an existing virtual network, we need to assign an identity to the cluster that has the necessary permissions to modify the routing table. This identity is called a user assigned identity and it is a type of managed identity in Azure. we will also need to assign the user managed identity to the load balancer subnet, as AKS will need permissions to update load balancer with rules. We will see how to create and assign this identity in the following steps.

1) Create a user-assigned managed identity
````bash
az identity create \
    --resource-group $RG \
    --name $AKS_IDENTITY_NAME
````
2) Get the id of the user managed identity
````bash
 identity_id=$(az identity show \
    --resource-group $RG \
    --name $AKS_IDENTITY_NAME \
    --query id \
    --output tsv)
````
3) Get the principal id of the user managed identity

````bash
principal_id=$(az identity show \
    --resource-group $RG \
    --name $AKS_IDENTITY_NAME \
    --query principalId \
    --output tsv)
````

4) Get the scope of the routing table

````bash
rt_scope=$(az network route-table show \
    --resource-group $RG \
    --name $ROUTE_TABLE_NAME  \
    --query id \
    --output tsv)
````
5) Assign permissions for the AKS user defined managed identity to the routing table

````bash
az role assignment create \
    --assignee $principal_id \
    --scope $rt_scope \
    --role "Network Contributor"
````

6) Assign permission for the AKS user defined managed identity to the load balancer subnet

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

7) Retrieve the scope of AKS subnet, were AKS shall be deployed.

````bash
aks_subnet_scope=$(az network vnet subnet list \
    --resource-group $RG \
    --vnet-name $SPOKE_VNET_NAME \
    --query "[?name=='$AKS_SUBNET_NAME'].id" \
    --output tsv)
````
8) Deploy a Private AKS cluster.

````bash
az aks create --resource-group $RG --node-count 2 --vnet-subnet-id $aks_subnet_scope --name $AKS_CLUSTER_NAME --enable-private-cluster --outbound-type userDefinedRouting --enable-oidc-issuer --enable-workload-identity --generate-ssh-keys --assign-identity $identity_id --network-plugin azure --network-policy azure --disable-public-fqdn
````

> **_! Note:_** A private AKS cluster is a type of AKS cluster that has its Kubernetes API endpoint isolated from public access. This means that you can only access the API endpoint if you are within the same virtual network as the cluster. However, in our scenario, we have our jumpbox in a different virtual network than the cluster. Therefore, we need to create a virtual network link between the two networks to enable DNS resolution across them. This will allow us to use the jumpbox to communicate with the private AKS cluster. We will see how to create and configure this link in the next section.

9) Create an additional nodepool for hosting user workloads.
````bash
az aks nodepool add --resource-group $RG --cluster-name $AKS_CLUSTER_NAME --name nodepool2 --node-count 3 --mode user
````

10) Create a virtual network link to resolve AKS private endpoint from HUB vnet.

Fetch the node group of the AKS cluster, and save it in an environment variable.
````bash
NODE_GROUP=$(az aks show --resource-group $RG --name $AKS_CLUSTER_NAME --query nodeResourceGroup -o tsv)
````
Fetch the AKS DNS zone name.
````bash
DNS_ZONE_NAME=$(az network private-dns zone list --resource-group $NODE_GROUP --query "[0].name" -o tsv)

````
Fetch the ID of the HUB virtual network.
````bash
HUB_VNET_ID=$(az network vnet show -g $RG -n $HUB_VNET_NAME --query id --output tsv)
````
Create a virtual network link between the hub virtual network and the AKS private DNS zone.
that was created for the AKS cluster.
````bash
az network private-dns link vnet create --name "hubnetdnsconfig" --registration-enabled false --resource-group $NODE_GROUP --virtual-network $HUB_VNET_ID --zone-name $DNS_ZONE_NAME 
````

11) Verify AKS control plane connectivity

In this section we will verify that we are able to connect to the AKS cluster from the jumpbox, firstly we need to connect to the cluster successfully and secondly we need to verify that the kubernetes client is able to communicate with the AKS control plane from the jumpbox. 

1) Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com)and enter your login credentials.

2) Once logged in, locate and select your **resource group** where the Jumpbox has been deployed.

3) Within your resource group, find and click on the **Jumpbox VM**.

4) In the left-hand side menu, under the **Operations** section, select ‘Bastion’.

5) Enter the **credentials** for the Jumpbox VM and verify that you can log in successfully.

6) Once successfully logged in to the jumbox you need to install a few tools
````bash
#!/bin/bash
# Update apt repo
sudo apt update 
# Install Docker
sudo apt install docker.io -y
# Install azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# Install AKS CLI (kubectl)
sudo az aks install-cli
````

  
7) Now, **login to Azure** in order to obtain AKS credentials.

````bash
az login
az account set --subscription <SUBSCRIPTION ID>
````
> **_! Note:_**
To check the current subscription, run the command: **az account show**
To change the subscription, run the command: **az account set --subscription <SUBSCRIPTION ID>, where <SUBSCRIPTION ID>** the ID of the desired subscription. You can find the subscription ID by running the command: **az account list --output table**

8) Download the AKS credentials onto the jumpbox.

````bash
az aks get-credentials --resource-group $RG --name $AKS_CLUSTER_NAME
````
9) Ensure you can list resources in AKS.

````bash
kubectl get nodes
````

The following output shows the result of running the command kubectl get nodes on with kubectl CLI.

````bash
azureuser@Jumpbox-VM:~$ sudo kubectl get nodes
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-33590162-vmss000000   Ready    agent   11h   v1.26.6
aks-nodepool1-33590162-vmss000001   Ready    agent   11h   v1.26.6
aks-nodepool1-33590162-vmss000002   Ready    agent   11h   v1.26.6
````
10) log out from the Jumpbox host.

Congratulations! You have completed the steps to deploy a private AKS cluster and configure its network settings. You have assigned a user assigned identity to the cluster that has the required permissions to modify the user-defined routing table and load balancer subnet. You have also created a virtual network link between the hub virtual network and the private DNS zone of the cluster. This enables the jumpbox to resolve the private API server of the cluster and access it for management and maintenance purposes.

![Screenshot](/images/hubandspokewithpeeringBastionJumpboxFirewallaksvirtualnetlink.jpg)
![Screenshot](/images/aksjumpbox.jpg)

### 3.1.7 Deploy Azure Container Registry
In this chapter, we will learn how to deploy a private Azure container registry that will store our container images. A private container registry is a type of container registry that is not accessible from the public internet. To enable access to the private container registry from the jumpbox, we need to create some network resources that will allow us to resolve the container registry name and connect to it securely. These resources are: a private endpoint, a private link, and a virtual network link. We will see how to create and configure these resources in the following steps. We will also test the connection to the private container registry by pushing some images to it from the jumpbox.

1) Create the Azure Container Registry, and disable public access to the registry.

````bash
az acr create \
    --resource-group $RG \
    --name $ACR_NAME \
    --sku Premium \
    --admin-enabled false \
    --location $LOCATION \
    --allow-trusted-services false \
    --public-network-enabled false
````
> **_! Note:_**
Ensure you have a global unique name for your ACR, else the deployment will fail.


2) Disable endpoint network policies.

````bash
az network vnet subnet update \
 --name $ENDPOINTS_SUBNET_NAME \
 --vnet-name $SPOKE_VNET_NAME\
 --resource-group $RG \
 --disable-private-endpoint-network-policies
````
3) Configure the private DNS zone for ACR

````bash
az network private-dns zone create \
  --resource-group $RG \
  --name "privatelink.azurecr.io"
````

 
4) Create a virtual network link to the spoke network
````bash
az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name "privatelink.azurecr.io" \
  --name ACRDNSSpokeLink \
  --virtual-network $SPOKE_VNET_NAME \
  --registration-enabled false
````
5) Creates a virtual network link to the hub network
````bash

az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name "privatelink.azurecr.io" \
  --name ACRDNSHubLink \
  --virtual-network $HUB_VNET_NAME \
  --registration-enabled false
````

6) Create ACR private endpoint 

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
7) Configure DNS record for ACR
before we can configure the DNS record we need to obtain the private IP address for of the ACR, both the control and dataplane.

Get endpoint IP configuration:
````bash
NETWORK_INTERFACE_ID=$(az network private-endpoint show \
  --name ACRPrivateEndpoint \
  --resource-group $RG \
  --query 'networkInterfaces[0].id' \
  --output tsv)
 ```` 

Fetch the container registry private IP address

Find the private IP addresses used for data and control of the Container Registry
````bash
az network nic show --ids $NETWORK_INTERFACE_ID |grep azurecr.io -B 7
````
In the output you should see two IP addresses, and their associated FQDNS. It should look similar to this:

````
      "name": "privateEndpointIpConfig.9c4c0ee4-c187-4094-aede-fc0dabb70236",
      "primary": true,
      "privateIPAddress": "10.1.1.20",
      "privateIPAddressVersion": "IPv4",
      "privateIPAllocationMethod": "Dynamic",
      "privateLinkConnectionProperties": {
        "fqdns": [
          "acrforakssecurity.westus2.data.azurecr.io"
--
      "name": "privateEndpointIpConfig.7ffb814c-aacc-4199-a07d-35f61df0ea1f",
      "primary": false,
      "privateIPAddress": "10.1.1.21",
      "privateIPAddressVersion": "IPv4",
      "privateIPAllocationMethod": "Dynamic",
      "privateLinkConnectionProperties": {
        "fqdns": [
          "acrforakssecurity.azurecr.io"
````
The **privateIPAddress** and **fqdns** will be used in a later step (when creating DNS zones).


8) Create DNS records in the private DNS zone

````bash
az network private-dns record-set a create \
  --name $ACR_NAME \
  --zone-name privatelink.azurecr.io \
  --resource-group $RG
````

9) Specify registry region in data endpoint name

````bash
az network private-dns record-set a create \
  --name $ACR_NAME.$LOCATION.data \
  --zone-name privatelink.azurecr.io \
  --resource-group $RG
````
10) Create the A records for the registry endpoint and data endpoint

````bash
az network private-dns record-set a add-record \
  --record-set-name $ACR_NAME \
  --zone-name privatelink.azurecr.io \
  --resource-group $RG \
  --ipv4-address <IP address associated with FQDN "$ACR_NAME.azurecr.io">

````

11) Specify registry region in data endpoint name

````bash
az network private-dns record-set a add-record \
  --record-set-name $ACR_NAME.$LOCATION.data \
  --zone-name privatelink.azurecr.io \
  --resource-group $RG \
  --ipv4-address <IP address assicoated with FQDN "$ACR_NAME.$LOCATION.data.azurecr.io">
````
12) Test the connection to ACR from the Jumpbox

In this section, you will learn how to check if you can access your private Azure Container Registry (ACR) and push Docker images to it. You will need to have the Azure CLI installed and logged in to your Azure account. You will also need to have Docker installed and running on your Jumpbox. Here are the steps to follow:

1) Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com) and enter your login credentials.
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
7) Validate private link connection 

List your ACR in your subscription and note down the ACR name.
````bash
az acr list -o table
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
8. Create a Dockerfile, build the docker image, authenticate towards ACR and push the image to the container registry.

````bash
vim Dockerfile
````
Add the following content to the Dockerfile

````bash
FROM nginx
EXPOSE 80
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
Authenticate to ACR. Use "--expose-token" to access token instead of automatically logging in through Docker CLI.
````bash
az acr login --name <CONTAINER REGISTRY NAME> --expose-token
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

9) Attach AKS to the ACR, this command updates our existing AKS cluster and attaches it to the ACR, this allows the cluster to pull images from the ACR.

````bash
az aks update \
    --resource-group $RG \
    --name $AKS_CLUSTER_NAME \
    --attach-acr $ACR_NAME
````
10) Validate AKS is able to pull images from ACR.

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
    image: <ACR NAME>.azurecr.io/nginx
    ports:
    - containerPort: 80
````
Create the pod.
````yaml
kubectl create -f test-pod.yaml
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
Our next step is to set up an internal load balancer that will direct the traffic to our internal Pod. The internal load balancer will be deployed in the load balancer subnet of the spoke-vnet.


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

````bash
sudo kubectl create -f internal-app-service.yaml
````
Verify that your service object is created and associated with the Pod that you have created, also ensure that you have recieved an external IP, which should be a private IP address range from the load balancer subnet.

````bash
sudo kubectl get svc -o wide
````
Example output:

````bash
azureuser@Jumpbox-VM:~$ sudo kubectl get svc -o wide
NAME                        TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE   SELECTOR
internal-test-app-service   LoadBalancer   10.0.252.53   10.1.3.4      80:30161/TCP   39s   app=internal-test-app
kubernetes                  ClusterIP      10.0.0.1      <none>        443/TCP        43h   <none>
azureuser@Jumpbox-VM:~$ 
````
> **_! Note:_** Note down the EXTERNAL-IP (Private IP of the load balancer), as this will be used for creating the application gateway.  

You have completed the steps to deploy a private Azure Container Registry, which is accessible from the jumpbox host.

![Screenshot](/images/hubandspokewithpeeringBastionJumpboxFirewallaksvirtualnetlinkandacrandinternalloadbalancer.jpg)

### 3.1.8 Deploy Azure Application Gateway.

In this chapter, you will set up an application gateway that can terminate TLS connections at its own level. You will also learn how to perform these tasks: create an application gateway and upload a certificate to it, configure AKS as a backend pool for routing traffic to its internal load balancer, create a health probe to check the health of the AKS backend pool, and set up a WAF (web application firewall) to defend against common web attacks.

1) Create public IP address with a domain name associated to the PIP resource

> **_! Note:_** Your workshop instructor will provide you a student name for your domain name.  


````bash
az network public-ip create -g $RG -n AGPublicIPAddress --dns-name $STUDENT_NAME --allocation-method Static --sku Standard --location $LOCATION
````
2) Create WAF policy 


````bash
az network application-gateway waf-policy create --name ApplicationGatewayWAFPolicy --resource-group $RG
````
3) Create Application Gateway.

> **_! Note:_** Your workshop instructor will provide you a **password** for the certificate. Before executing this command ensure the certificate is in **your working directory**.

````bash
az network application-gateway create \
  --name AppGateway \
  --location $LOCATION \
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
  --servers <LOAD BALANCER PRIVATE IP>
```` 
4) Create a custom probe for the application gateway that will monitor the health of the AKS backend pool.

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
5) Associate the health probe to the backend pool.
````bash
az network application-gateway http-settings update -g $RG --gateway-name $APPGW_NAME -n appGatewayBackendHttpSettings --probe health-probe
````

We have successfully completed the deployment and configuration of our network and cluster resources. The following diagram shows the high-level architecture of our solution. As you can see, we have a test pod running in AKS that can receive traffic from the internet through the Azure Application Gateway and the Azure Internal Load Balancer. We can also access the private API server of the AKS cluster and the private container registry from the jumpbox using the private endpoints and links. We have also enabled outbound traffic from the AKS subnet to go through the Azure Firewall for inspection and filtering. In the next chapter, we will validate if we can access our test Pod.

![Screenshot](/images/hubandspokewithpeeringBastionJumpboxFirewallaksvirtualnetlinkandacrandinternalloadbalancerandapplicationgw.jpg)


### 3.1.9 Validate ingress connection.
Open your web browser and access your domain: **STUDENT NAME.akssecurity.se**
you should see a similar output as to the one below.

![Screenshot](/images/splashscreen.jpg)

### 3.1.10 Clean up resources in AKS
Once you have verified that everything works as depicted earlier. from the jumpbox host delete the resources.

````bash
kubectl delete -f test-pod.yaml
kubectl delete -f internal-app-service.yaml
````
