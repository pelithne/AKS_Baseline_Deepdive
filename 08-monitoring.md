# 8 Monitoring

# Enable monitoring for Kubernetes clusters

This section describes how to enable monitoring of your Kubernetes clusters using the following Azure Monitor features:

- *Managed Prometheus* for metric collection
- *Container insights* for log collection
- *Managed Grafana* for visualization.

You can enable monitoring in multiple different ways. You can use the Azure Portal, Azure CLI, Azure Resource Manager template, Terraform, or Azure Policy. In this section, we will use Azure CLI, but feel free to learn more. A good place to start is here: https://learn.microsoft.com/en-us/azure/azure-monitor/containers/kubernetes-monitoring-enable 


## Enable Prometheus and Grafana

The only requirement to enable Azure Monitor managed service for Prometheus is to create an Azure Monitor workspace, which is where Prometheus metrics are stored. Once this workspace is created, you can onboard services that collect Prometheus metrics.

```azurecli
az monitor account create --name <azure-monitor-workspace-name> --resource-group <resource-group-name> --location <location>
```

Make a note of the resource id. It should look similar to this
````
 "/subscriptions/e1519e1a-ec51-4173-b5c1-f5d92fb8f8a4/resourcegroups/akstemp/providers/microsoft.monitor/accounts/monitorworkspace
 ````

To enable Grafana, you also need to create a Grafana workspace

```azurecli
az grafana create --name <managed-grafana-resource-name> --resource-group <resource-group-name>
```

Make a note of the resource id. It should look similar to this
````
 /subscriptions/e1519e1a-ec51-4173-b5c1-f5d92fb8f8a4/resourceGroups/akstemp/providers/Microsoft.Dashboard/grafana/managedgrafanaws"
 ````


> [!Note]
> If you don't specify an existing Azure Monitor workspace in the following commands, the default workspace for the resource group will be used. If a default workspace doesn't already exist in the cluster's region, one with a name in the format DefaultAzureMonitorWorkspace-<mapped_region> will be created in a resource group with the name DefaultRG-<cluster_region>.



 az aks update --enable-azure-monitor-metrics -n aks -g akstemp --azure-monitor-workspace-resource-id "/subscriptions/e1519e1a-ec51-4173-b5c1-f5d92fb8f8a4/resourcegroups/akstemp/providers/microsoft.monitor/accounts/monitorworkspace"  --grafana-resource-id  "/subscriptions/e1519e1a-ec51-4173-b5c1-f5d92fb8f8a4/resourceGroups/akstemp/providers/Microsoft.Dashboard/grafana/managedgrafanaws"

Use the `-enable-azure-monitor-metrics` option for `az aks update`  to install the metrics add-on that scrapes Prometheus metrics.


```azurecli
### Use default Azure Monitor workspace
az aks update --enable-azure-monitor-metrics -n <cluster-name> -g <cluster-resource-group>

```



## Enable Container insights


```azurecli
### Use default Log Analytics workspace
az aks enable-addons -a monitoring -n <cluster-name> -g <cluster-resource-group-name>

```


## Verify deployment
Use the *kubectl*  to verify that the agent is deployed properly.

### Managed Prometheus

**Verify that the DaemonSet was deployed properly on the Linux node pools**

```bash
kubectl get ds ama-metrics-node --namespace=kube-system
```

The number of pods should be equal to the number of Linux nodes on the cluster. The output should resemble the following example:

```output
User@aksuser:~$ kubectl get ds ama-metrics-node --namespace=kube-system
NAME               DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
ama-metrics-node   1         1         1       1            1           <none>          10h
```

**Verify that the two ReplicaSets were deployed for Prometheus**

```bash
kubectl get rs --namespace=kube-system
```

The output should resemble the following example:

```output
User@aksuser:~$kubectl get rs --namespace=kube-system
NAME                            DESIRED   CURRENT   READY   AGE
ama-metrics-5c974985b8          1         1         1       11h
ama-metrics-ksm-5fcf8dffcd      1         1         1       11h
```


### Container insights

**Verify that the DaemonSets were deployed properly on the Linux node pools**

```bash
kubectl get ds ama-logs --namespace=kube-system
```

The number of pods should be equal to the number of Linux nodes on the cluster. The output should resemble the following example:

```output
User@aksuser:~$ kubectl get ds ama-logs --namespace=kube-system
NAME       DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
ama-logs   2         2         2         2            2           <none>          1d
```



**Verify deployment of the Container insights solution**

```bash
kubectl get deployment ama-logs-rs --namespace=kube-system
```

The output should resemble the following example:

```output
User@aksuser:~$ kubectl get deployment ama-logs-rs --namespace=kube-system
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
ama-logs-rs   1/1     1            1           24d
```

**View configuration with CLI**

Use the `aks show` command to find out whether the solution is enabled, the Log Analytics workspace resource ID, and summary information about the cluster.

```azurecli
az aks show -g <resourceGroupofAKSCluster> -n <nameofAksCluster>
```

The command will return JSON-formatted information about the solution. The `addonProfiles` section should include information on the `omsagent` as in the following example:

```output
"addonProfiles": {
    "omsagent": {
        "config": {
            "logAnalyticsWorkspaceResourceID": "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/my-resource-group/providers/microsoft.operationalinsights/workspaces/my-workspace",
            "useAADAuth": "true"
        },
        "enabled": true,
        "identity": null
    },
}
```


## Resources provisioned

When you enable monitoring, the following resources are created in your subscription:

| Resource Name | Resource Type | Resource Group | Region/Location | Description |
|:---|:---|:---|:---|:---|
| `MSCI-<aksclusterregion>-<clustername>` | **Data Collection Rule** | Same as cluster | Same as Log Analytics workspace | This data collection rule is for log collection by Azure Monitor agent, which uses the Log Analytics workspace as destination, and is associated to the AKS cluster resource. |
| `MSPROM-<aksclusterregion>-<clustername>` | **Data Collection Rule** | Same as cluster | Same as Azure Monitor workspace | This data collection rule is for prometheus metrics collection by metrics addon, which has the chosen Azure monitor workspace as destination, and also it is associated to the AKS cluster resource |
| `MSPROM-<aksclusterregion>-<clustername>` | **Data Collection endpoint** | Same as cluster | Same as Azure Monitor workspace | This data collection endpoint is used by the above data collection rule for ingesting Prometheus metrics from the metrics addon|
    
When you create a new Azure Monitor workspace, the following additional resources are created as part of it

| Resource Name | Resource Type | Resource Group | Region/Location | Description |
|:---|:---|:---|:---|:---|
| `<azuremonitor-workspace-name>` | **Data Collection Rule** | MA_\<azuremonitor-workspace-name>_\<azuremonitor-workspace-region>_managed | Same as Azure Monitor Workspace | DCR created when you use OSS Prometheus server to Remote Write to Azure Monitor Workspace. |
| `<azuremonitor-workspace-name>` | **Data Collection Endpoint** | MA_\<azuremonitor-workspace-name>_\<azuremonitor-workspace-region>_managed | Same as Azure Monitor Workspace | DCE created when you use OSS Prometheus server to Remote Write to Azure Monitor Workspace.|
    
