using './main.bicep'

param location = 'swedencentral'
param systemNodePoolCount = 1
param deployGPUNodePool = false
param systemNodePoolVmSize = 'Standard_D2s_v6'
param cpuNodePoolVmSize = 'Standard_D4s_v6'
param gpuNodePoolVmSize = 'NC4as_T4_v3'
param enableMIG = false
