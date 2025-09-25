# vLLM AKS Deployment

This repository contains Kubernetes manifests for deploying vLLM on Azure Kubernetes Service (AKS) using GitOps with Flux.

## Structure

```text
├── infrastructure/          # Cluster-wide infrastructure
│   └── base/
│       ├── cluster-bootstrap.yaml  # GPU operators, Node Feature Discovery
│       └── kustomization.yaml
├── clusters/               # Application deployments
│   ├── base/
│   │   ├── vllm-deployment.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── EMEA/           # EMEA region configuration
│       │   ├── emea-patch.yaml
│       │   └── kustomization.yaml
│       └── USA/            # USA region configuration
│           ├── usa-patch.yaml
│           └── kustomization.yaml
└── kustomization.yaml      # Root kustomization combining infrastructure + apps
```

## Deployment

### Option 1: Deploy Everything Together

```bash
kubectl apply -k .
```

### Option 2: Deploy Infrastructure and Applications Separately

Deploy cluster-wide infrastructure first:

```bash
kubectl apply -k infrastructure/base
```

Deploy applications:

```bash
kubectl apply -k clusters/overlays/EMEA
kubectl apply -k clusters/overlays/USA
```

## Infrastructure Components

- **GPU Operator**: NVIDIA GPU support for Kubernetes
- **Node Feature Discovery**: Automatic hardware feature detection

## Application Components

- **vLLM Deployment**: Scalable inference service
- **Load Balancer Service**: External access to the service
- **Regional Configurations**: Different settings for EMEA and USA regions
