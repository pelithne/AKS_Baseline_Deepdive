# Automation

**In This Article:**

- [Azure Devops](#Azure Devops)


## Introduction
This section contains instructions about how to automate deployment of the infrastructure for AKS Secure Baseline, using Azure Devops Pipelines and Terraform. The central idea is to have the complete infrastructure defined as code (IaC) and that deployment of that infrastructure can be completely automated using Deployment Pipelines. 


## Terraform
In this repository, there are a number of Terraform templates. You will not use them directly, and instead call them from a pipeline. It is still a good idea to understand the content of the terraform templates. 

In the folder named "Terraform" you will find the main template, aptly named ````main.tf````

This main template is referencing a number of *modules*. The modules in term are responsible for deploying the various Azure resources used in the AKS Secure Baseline. YOu will see an AKS module, an application_gateway module, a virtual_network module, and so on.

Please take some time to familiarize yourself with the content of the templates. No need to understand everything, but try to get an overview at least.

## Azure Devops

Azure Devops is the tool that will be used to run the templates. In order to do so, you need to go through a couple of steps, which will be detailed further down:

* Login to the Azure Devops organization (we have prepared this for you)
* Create a service connection to Azure, to allow the pipeline to interact with Azure and AKS
* Create a self-hosted agent that will run all the tasks in the pipeline (we have prepared this as well)
* Clone repository (this repository) to give Azure Devops access to the Terraform templates, and the preconfigured pipeline definitions (we have prepared this )
* Edit the necessary parameters, and run the pipeline
* Troubleshoot... :-)
