using './main.bicep'

param location = 'swedencentral'
param systemNodePoolCount = 1
param deployGPUNodePool = true
param systemNodePoolVmSize = 'Standard_D4s_v6'
param cpuNodePoolVmSize = 'Standard_D4s_v6'
param gpuNodePoolVmSize = 'Standard_NC4as_T4_v3'
param enableMIG = false
param suffix = 'pod'
