# Environment

This file contains all the environment varibles that are set during the workshop. Use this file if you need to restore your environment variables. For instance you could loose them if your **cloud shell** times out, or if you close your terminal.

To save you some time during restore, make sure to populate this file with your own values. 

````bash
HUB_VNET_NAME=Hub_VNET
FW_SUBNET_NAME=AzureFirewallSubnet
BASTION_SUBNET_NAME=AzureBastionSubnet
HUB_VNET_PREFIX= # IP address range of the Virtual network (VNet).
BASTION_SUBNET_PREFIX= # IP address range of the Bastion subnet 
FW_SUBNET_PREFIX= # IP address range of the Firewall subnet
JUMPBOX_SUBNET_PREFIX= # IP address range of the Jumpbox subnet

SPOKE_VNET_NAME=Spoke_VNET
JUMPBOX_SUBNET_NAME=JumpboxSubnet
ENDPOINTS_SUBNET_NAME=endpoints-subnet
APPGW_SUBNET_NAME=app-gw-subnet
AKS_SUBNET_NAME=aks-subnet
LOADBALANCER_SUBNET_NAME=loadbalancer-subnet
SPOKE_VNET_PREFIX= # IP address range of the Virtual network (VNet).
AKS_SUBNET_PREFIX= # IP address range of the AKS subnet
LOADBALANCER_SUBNET_PREFIX= # IP address range of the Loadbalancer subnet
APPGW_SUBNET_PREFIX= # IP address range of the Application Gateway subnet
ENDPOINTS_SUBNET_PREFIX= # IP address range of the Endpoints subnet

HUB_RG=rg-hub
SPOKE_RG=rg-spoke
LOCATION=swedencentral 
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

FRONTEND_NAMESPACE="frontend"
BACKEND_NAMESPACE="backend"
SERVICE_ACCOUNT_NAME="workload-identity-sa"
SUBSCRIPTION="$(az account show --query id --output tsv)"
USER_ASSIGNED_IDENTITY_NAME="keyvaultreader"
FEDERATED_IDENTITY_CREDENTIAL_NAME="keyvaultfederated"
KEYVAULT_NAME="<DEFINE A KEYVAULT NAME HERE>"
KEYVAULT_SECRET_NAME="redissecret"

ADMIN_GROUP='ClusterAdminGroup-'${STUDENT_NAME}
OPS_FE_GROUP='Ops_Fronted_team-'${STUDENT_NAME}
OPS_BE_GROUP='Ops_Backend_team-'${STUDENT_NAME}

AAD_OPS_FE_UPN='opsfe-'${STUDENT_NAME}'@MngEnvMCAP148390.onmicrosoft.com'
AAD_OPS_FE_DISPLAY_NAME='Frontend-'${STUDENT_NAME}
AAD_OPS_FE_PW=<ENTER USER PASSWORD>

AAD_OPS_BE_UPN='opsbe-'${STUDENT_NAME}'@MngEnvMCAP148390.onmicrosoft.com'
AAD_OPS_BE_DISPLAY_NAME='Backend-'${STUDENT_NAME}
AAD_OPS_BE_PW=<ENTER USER PASSWORD>


AAD_ADMIN_UPN='clusteradmin'${STUDENT_NAME}'@MngEnvMCAP148390.onmicrosoft.com'
AAD_ADMIN_PW=<ENTER USER PASSWORD>
AAD_ADMIN_DISPLAY_NAME='Admin-'${STUDENT_NAME}

AZ_MON_WORKSPACE=azmon-ws
MANAGED_GRAFANA_NAME=grafana-$STUDENT_NAME
LOG_ANALYTICS_WORKSPACE=log-analytics-ws


````