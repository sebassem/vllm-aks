targetScope = 'subscription'

@description('Location for all resources.')
param location string = deployment().location

@description('Name of the resource group to create.')
param resourceGroupName string = 'rg-${location}-aks'

@description('Name of the AKS cluster to create.')
param aksClusterName string = 'aks-${location}-aks'

@description('Number of nodes in the system node pool.')
param systemNodePoolCount int = 1

@description('Name of the system node pool.')
param systemNodePoolName string = 'systempool'

@description('VM size for the system node pool.')
param systemNodePoolVmSize string = 'Standard_D2s_v6'

@description('VM size for the CPU user node pool.')
param cpuNodePoolVmSize string = 'Standard_D4s_v6'

@description('VM size for the GPU user node pool. NC24ads_A100_v4 or NC4as_T4_v3 are recommended.')
param gpuNodePoolVmSize string = 'NC4as_T4_v3'

@description('Enable or disable public network access to the AKS API server.')
param publicNetworkAccessEnabled bool = true

@description('Deploy a GPU node pool.')
param deployGPUNodePool bool = false

@description('Number of nodes in the user node pool.')
param userNodePoolCount int = 1

@description('Use spot instances for the user node pool.')
param useSpotInstances bool = false

@description('Enable or disable MIG for GPU node pool.')
param enableMIG bool = false

@description('Name of the Log Analytics workspace to create.')
param logAnalyticsWorkspaceName string = 'law-${location}-aks2'

@description('Name of the Azure Container Registry to use.')
param acrName string = 'acrllm87232'

@description('Resource group of the Azure Container Registry to use.')
param acrResourceGroup string = 'vllm'

var deployerId = deployer().objectId

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
    name: resourceGroupName
    location: location
}

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
    scope: rg
    params: {
        name: logAnalyticsWorkspaceName
        location: location
    }
}

resource acr 'Microsoft.ContainerRegistry/registries@2025-05-01-preview' existing = {
    name: acrName
    scope: resourceGroup(acrResourceGroup)
}

module aks 'br/public:avm/res/container-service/managed-cluster:0.10.1' = {
    scope: rg
    params: {
        name: aksClusterName
        location: location
        primaryAgentPoolProfiles: [
            {
                name: systemNodePoolName
                count: systemNodePoolCount
                osType: 'Linux'
                type: 'VirtualMachineScaleSets'
                mode: 'System'
                vmSize: systemNodePoolVmSize
                availabilityZones: []
            }
        ]
        agentPools: [
            {
                name: deployGPUNodePool ? 'gpupool' : 'cpupool'
                count: userNodePoolCount
                gpuInstanceProfile: enableMIG ? 'MIG1g' : null
                vmSize: deployGPUNodePool ? gpuNodePoolVmSize : cpuNodePoolVmSize
                scaleSetPriority: useSpotInstances ? 'Spot' : 'Regular'
                scaleDownMode: useSpotInstances ? 'Delete' : null
                availabilityZones: []
            }
        ]
        aadProfile: {
            aadProfileEnableAzureRBAC: true
            aadProfileManaged: true
        }
        roleAssignments: [
            {
                principalId: deployerId
                roleDefinitionIdOrName:'0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8'
                description: 'AKS Cluster Admin Role Assignment for Deployer'
            }
        ]
        enableAzureMonitorProfileMetrics: true
        enableContainerInsights: true
        enableImageCleaner: true
        enableStorageProfileDiskCSIDriver: true
        omsAgentEnabled: true
        monitoringWorkspaceResourceId: logAnalytics.outputs.resourceId
        loadBalancerSku: 'standard'
        networkPlugin: 'azure'
        networkPolicy: 'azure'
        outboundType: 'managedNATGateway'
        managedIdentities: {
            systemAssigned: true
        }
        skuTier: 'Standard'
        skuName: 'Base'
        publicNetworkAccess: publicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
        fluxExtension: {
            configurations: [
                {
                    namespace: 'flux-system'
                    scope: 'cluster'
                    gitRepository:{
                        repositoryRef: {
                            branch: 'main'
                        }
                        syncIntervalInSeconds: 300
                        timeoutInSeconds: 3600
                        url: 'https://github.com/sebassem/vllm-aks'
                    }
                    kustomizations:{
                        bootstrap:{
                            path: './cluster-config/bootsrap/base'
                            dependsOn: []
                            prune: true
                            syncIntervalInSeconds: 600
                            timeoutInSeconds: 3600
                        }
                        apps: {
                            dependsOn: [
                                'bootstrap'
                            ]
                            path: './cluster-config/apps/overlays/EMEA'
                            prune: true
                            retryIntervalInSeconds: 120
                            syncIntervalInSeconds: 600
                            timeoutInSeconds: 3600
                            }
                    }
                }
            ]
        }
    }
}

module acrPullRole 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
    scope: resourceGroup('vllm')
    params: {
        principalId: aks.outputs.?kubeletIdentityObjectId ?? ''
        resourceId: acr.id
        roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
        description: 'AcrPull role assignment for AKS cluster'
    }
}
