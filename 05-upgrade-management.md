# 5 Upgrade Management

As part of the application and cluster lifecycle, you need to make sure to stay on a current version of Kubernetes. You can upgrade your Azure Kubernetes Service (AKS) cluster using the Azure CLI, Azure PowerShell, or the Azure portal. In this instuction you will use the Azure CLI.

In this section you learn how to:

* Identify current and available Kubernetes versions.
* Upgrade your Kubernetes nodes.
* Validate a successful upgrade.


## 5.1 Get available cluster versions

Before you upgrade, check which Kubernetes releases are available for your cluster using the ````az aks get-upgrades```` command.

````bash
az aks get-upgrades --resource-group $RESOURCE_GROUP --name $CLUSTERNAME
````

The following example output shows the current version as *1.26.6* and lists the available versions under *upgrades*.

````output

  "agentPoolProfiles": null,
  "controlPlaneProfile": {
    "kubernetesVersion": "1.26.6",
    "name": null,
    "osType": "Linux",
    "upgrades": [
      {
        "isPreview": null,
        "kubernetesVersion": "1.27.3"
      },
      {
        "isPreview": null,
        "kubernetesVersion": "1.27.1"
      }
    ]
  }
````


## 5.2 Upgrade a cluster

AKS nodes are carefully cordoned and drained to minimize any potential disruptions to running applications. During this process, AKS performs the following steps:

* Adds a new buffer node (or as many nodes as configured in ````max surge````) to the cluster that runs the specified Kubernetes version.
* Cordons and drains one of the old nodes to minimize disruption to running applications. If you're using max surge, it cordons and drains as many nodes at the same time as the number of buffer nodes specified.
* When the old node is drained, it's reimaged to receive the new version and becomes the buffer node for the following node to be upgraded.
* This process repeats until all nodes in the cluster have been upgraded.


Upgrade your cluster to 1.27.3 using the ````az aks upgrade```` command.

````bash
az aks upgrade \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTERNAME \
    --kubernetes-version 1.27.3
````

Select "y" to the questions.


The following example output shows part of the result of upgrading to *1.27.3*. Notice the *kubernetesVersion* now shows *1.27.3*. 

````
"kubernetesVersion": "1.27.3",
"linuxProfile": null,
"location": "northeurope",
"maxAgentPools": 100,
"name": "k8s",
"networkProfile": {
"dnsServiceIp": "10.0.0.10",
"ipFamilies": [
    "IPv4"
],
````


## 5.3 View the upgrade events

When you upgrade your cluster, the following Kubernetes events may occur on the nodes:
 * **Surge**: Create a surge node.
 * **Drain**: Evict pods from the node. Each pod has a *five minute timeout* to complete the eviction.
 * **Update**: Update of a node has succeeded or failed.
 * **Delete**: Delete a surge node.

View the upgrade events in the default namespaces using the `kubectl get events` command.

````bash
kubectl get events 
````

The following example output shows some of the above events listed during an upgrade.

````output
...
default 2m1s Normal Drain node/aks-nodepool1-96663640-vmss000001 Draining node: [aks-nodepool1-96663640-vmss000001]
...
default 9m22s Normal Surge node/aks-nodepool1-96663640-vmss000002 Created a surge node [aks-nodepool1-96663640-vmss000002 nodepool1] for agentpool 
...
````



## 5.4 Validate an upgrade

Confirm the upgrade was successful using the ````az aks show```` command.

````bash
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTERNAME --output table
````

The following example output shows the AKS cluster runs *KubernetesVersion 1.27.3:

````output
 Name    Location       ResourceGroup      KubernetesVersion    CurrentKubernetesVersion    ProvisioningState    Fqdn
------  -------------  -----------------  -------------------  --------------------------  -------------------  ----------------------------------------------------------------
k8s     northeurope     security-workshop  1.27.3               1.27.3                      Succeeded            k8s-security-worksho-16153f-mwrte3d1.hcp.northeurope.azmk8s.io
````

## 5.5 Allowed upgrade paths
Kubernetes can only be upgraded one minor version at a time. For example, you can upgrade from 1.26.x to 1.27.x, but you can't upgrade from 1.26.x to 1.28.x directly. To upgrade from 1.26.x to 1.28.x, you must first upgrade from 1.26.x to 1.27.x, then perform another upgrade from 1.27.x to 1.28.x.

As you are now on 1.27.3, you should be able to see the available upgrade to 1.28.0. You can confirm this by once again running this command:

````
az aks get-upgrades --resource-group $RESOURCE_GROUP --name $CLUSTERNAME
````

You should see the following output

````
  "agentPoolProfiles": null,
  "controlPlaneProfile": {
    "kubernetesVersion": "1.27.3",
    "name": null,
    "osType": "Linux",
    "upgrades": [
      {
        "isPreview": true,
        "kubernetesVersion": "1.28.0"
      }
    ]
  }
````