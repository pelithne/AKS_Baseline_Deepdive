# 5.0 Access management

**In This Article:**
- [5.0 Access management](#50-access-management)
  - [5.1 Introduction](#51-introduction)
  - [5.2 Deployment](#52-deployment)
    - [5.2.1 Prepare Environment Variables](#521-prepare-environment-variables)
    - [5.2.2 Create Microsoft Entra ID Security Groups](#522-create-microsoft-entra-id-security-groups)
    - [5.2.3 Integrate AKS with Microsoft Entra ID](#523-integrate-aks-with-microsoft-entra-id)
    - [5.2.4 Scope and Role Assignment for Security Groups](#524-scope-and-role-assignment-for-security-groups)
    - [5.2.5 Create Users and Assign them to Security Groups.](#525-create-users-and-assign-them-to-security-groups)
    - [5.2.5 Validate the Access for the Different Users.](#525-validate-the-access-for-the-different-users)


Azure Kubernetes Service (AKS) supports Azure Active Directory (AAD) integration, which allows you to control access to your cluster resources using Azure role-based access control (RBAC). In this tutorial, you will learn how to integrate AKS with AAD and assign different roles and permissions to three types of users:

An admin user, who will have full access to the AKS cluster and its resources.
A backend ops team, who will be responsible for managing the backend application deployed in the AKS cluster. They will only have access to the backend namespace and the resources within it.
A frontend ops team, who will be responsible for managing the frontend application deployed in the AKS cluster. They will only have access to the frontend namespace and the resources within it.
By following this tutorial, you will be able to implement the least privilege access model, which means that each user or group will only have the minimum permissions required to perform their tasks.

## 5.1 Introduction

In this section, you will learn how to:

- Harden your AKS cluster.
- Update an existing AKS cluster to support AAD integration enabled.
- Create an AAD admin group and assign it the Azure Kubernetes Service Cluster Admin Role.
 - Create an AAD backend ops group and assign it the Azure Kubernetes Service Cluster User Role.
- Create an AAD frontend ops group and assign it the Azure Kubernetes Service Cluster User Role.
- Create Users in AAD
- Create role bindings to grant access to the backend ops group and the frontend ops group to their respective namespaces.
- Test the access of each user type by logging in with different credentials and running kubectl commands.

## 5.2 Deployment

### 5.2.1 Prepare Environment Variables
This code defines the environment variables for the resources that you will create later in the tutorial.

> **_! Note:_** Ensure environment variable **$STUDENT_NAME** is set before adding the code below.

````bash
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
````
### 5.2.2 Create Microsoft Entra ID Security Groups 

We will now start by creating 3 security groups for respective team.

1) Create the security group for **Cluster Admins**

````bash
az ad group create --display-name $ADMIN_GROUP --mail-nickname $ADMIN_GROUP
````
2) Create the security group for **Application Operations Frontend Team**
````bash
az ad group create --display-name $OPS_FE_GROUP --mail-nickname $OPS_FE_GROUP
````
3) Create the security group for **Application Operations Backend Team**
````bash
az ad group create --display-name $OPS_BE_GROUP --mail-nickname $OPS_BE_GROUP
````


### 5.2.3 Integrate AKS with Microsoft Entra ID

1) Lets update our existing AKS cluster to support Microsoft Entra ID integration, and configure a cluster admin group, and disable local admin accounts in AKS, as this will prevent anyone from using the **--admin** switch to get the cluster credentials.

````bash
az aks update -g $RG -n $AKS_CLUSTER_NAME --enable-azure-rbac --enable-aad --disable-local-accounts
````
### 5.2.4 Scope and Role Assignment for Security Groups
This chapter will explain how to create the scope for the operation teams to perform their daily tasks. The scope is based on the AKS resource ID and a fixed path in AKS, which is **/namespaces/<NAMESPACE>**. The scope will assign the **Application Operations Frontend Team** to the **frontend namespace** and the **Application Operation Backend Team** to the **backend namespace**.


 1) Lets start by constructing the scope for the operations team.
 ````bash
 AKS_BACKEND_NAMESPACE='/namespaces/backend'
 AKS_FRONTEND_NAMESPACE='/namespaces/frontend'
 AKS_RESOURCE_ID=$(az aks show -g $RG -n $AKS_CLUSTER_NAME --query 'id' --output tsv)
 ````
2) lets fetch the Object ID of the operations teams and admin security groups.

  Application Operation Frontend Team.
 ````bash
 fe_group_object_id=$(az ad group show --group $OPS_FE_GROUP --query 'id' --output tsv)
 ````
 Application Operation Backend Team.
  ````bash
 be_group_object_id=$(az ad group show --group $OPS_BE_GROUP --query 'id' --output tsv)
 ````
 Admin.
 ````bash
 admin_group_object_id=$(az ad group show --group $ADMIN_GROUP --query 'id' --output tsv)
 
````

 3) This commands will grant the **Application Operations Frontend Team** group users the permissions to download the credential for AKS, and only operate within given namespace.

````bash
az role assignment create --assignee $fe_group_object_id --role "Azure Kubernetes Service RBAC Writer" --scope ${AKS_RESOURCE_ID}${AKS_FRONTEND_NAMESPACE}
 ````

 ````bash
 az role assignment create --assignee $fe_group_object_id --role "Azure Kubernetes Service Cluster User Role" --scope ${AKS_RESOURCE_ID}
 ````
 4) This commands will grant the **Application Operations Backend Team** group users the permissions to download the credential for AKS, and only operate within given namespace.

````bash
az role assignment create --assignee $be_group_object_id --role "Azure Kubernetes Service Cluster User Role" --scope ${AKS_RESOURCE_ID}${AKS_BACKEND_NAMESPACE}
 ````
  ````bash
 az role assignment create --assignee $be_group_object_id --role "Azure Kubernetes Service Cluster User Role" --scope ${AKS_RESOURCE_ID}
 ````

 4) This command will grant the **Admin** group users the permissions to connect to and manage all aspects of the AKS cluster.

````bash
az role assignment create --assignee $admin_group_object_id --role "Azure Kubernetes Service RBAC Cluster Admin" --scope ${AKS_RESOURCE_ID}
 ````

### 5.2.5 Create Users and Assign them to Security Groups.
This exercise will guide you through the steps of creating three users and adding them to their corresponding security groups.

1) Create the Admin user.

````bash
az ad user create --display-name $AAD_ADMIN_DISPLAY_NAME  --user-principal-name $AAD_ADMIN_UPN --password $AAD_ADMIN_PW
````
2) Assign the admin user to admin group for the AKS cluster.

First identify the object id of the user as we will need this number to assign the user to the admin group.

````bash
admin_user_object_id=$(az ad user show --id $AAD_ADMIN_UPN --query 'id' --output tsv)
````
Assign the user to the admin security group.

````bash
az ad group member add --group $ADMIN_GROUP --member-id $admin_user_object_id
````
3) Create the frontend operations user.

````bash
az ad user create --display-name $AAD_OPS_FE_DISPLAY_NAME  --user-principal-name $AAD_OPS_FE_UPN --password $AAD_OPS_FE_PW
````
4) Assign the frontend operations user to frontend security group for the AKS cluster.

First identify the object id of the user as we will need this number to assign the user to the frontend security group.

````bash
fe_user_object_id=$(az ad user show --id $AAD_OPS_FE_UPN --query 'id' --output tsv)
````
Assign the user to the frontend security group.

````bash
az ad group member add --group $OPS_FE_GROUP --member-id $fe_user_object_id
````
5) Create the backend operations user.

````bash
az ad user create --display-name $AAD_OPS_BE_DISPLAY_NAME  --user-principal-name $AAD_OPS_BE_UPN --password $AAD_OPS_BE_PW
````
6) Assign the backend operations user to backend security group for the AKS cluster.

First identify the object id of the user as we will need this number to assign the user to the backend security group.

````bash
be_user_object_id=$(az ad user show --id $AAD_OPS_BE_UPN --query 'id' --output tsv)
````
Assign the user to the backend security group.

````bash
az ad group member add --group $OPS_BE_GROUP --member-id $be_user_object_id
````
### 5.2.5 Validate the Access for the Different Users.

This section will demonstrate how to connect to the AKS cluster from the jumpbox using the user account defined in Microsoft Entra ID. We will check two things: first, that we can successfully connect to the cluster; and second, that the Operations teams have access only to their own namespaces, while the Admin has full access to the cluster.

1) Navigate to the Azure portal at [https://portal.azure.com](https://portal.azure.com)and enter your login credentials.

2) Once logged in, locate and select your **resource group** where the Jumpbox has been deployed.

3) Within your resource group, find and click on the **Jumpbox VM**.

4) In the left-hand side menu, under the **Operations** section, select ‘Bastion’.

5) Enter the **credentials** for the Jumpbox VM and verify that you can log in successfully.

6) Clean up the stored credentials on the jumpbox host.

````bash
sudo rm -R .azure/
sudo rm -R .kube/
````

7) **login to Azure** with the Frontend username and password.

>**_! Note:_** The username is stored in this variable **AAD_OPS_FE_UPN** and password is stored in **AAD_OPS_FE_PW**. Simple run an echo on the environment variables to retrieve the username and password.

````bash
sudo az login
````
>**_! Note:_** If prompted to pick an account then choose **Use another account** and supply the username in the **AAD_OPS_FE_UPN** variable.

8) Download Cluster credential.

````bash
az aks get-credentials --resource-group <RESOURCE GROUP NAME> --name <AKS CLUSTER NAME>
````
You should see a similar output as illustrated below:
````bash
azureuser@Jumpbox-VM:~$ az aks get-credentials --resource-group AKS_Security_RG --name private-aks
Merged "private-aks" as current context in /home/azureuser/.kube/config
azureuser@Jumpbox-VM:~$ 
````
9) You should be able to list all pods in namespace frontend.

>**_! Note:_** You will now be prompted to authenticate your user again, as this time it will validate your permissions within the AKS cluster.

````bash
sudo kubectl get po -n frontend
````
````bash
azureuser@Jumpbox-VM:~$ kubectl get po -n frontend
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code 
XXXXXXX to authenticate.
NAME    READY   STATUS             RESTARTS   AGE
nginx   1/1     Running               0       89m
````
10) Try to list pods in default namespace

````bash
sudo kubectl get po
````
Example output:
````bash
azureuser@Jumpbox-VM:~$ kubectl get po
Error from server (Forbidden): pods is forbidden: User "opsfe-test@MngEnvMCAP148390.onmicrosoft.com"
 cannot list resource "pods" in API group "" in the namespace "default": User does not have access t
o the resource in Azure. Update role assignment to allow access.
````
Repeat step **7** and **10** for the remaining users, and see how their permissions differs.