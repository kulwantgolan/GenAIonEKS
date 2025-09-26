## Initial Setup and access 
1. Create the stack - Cloudformation template load from S3 bucket URL
2. Create On-Demand Capacity Reservation (ODCR): After your stack is created, you need to set up an On-Demand Capacity Reservation (ODCR) for the GPU instances required by this workshop/
3. Access the IDE
4. https://catalog.us-east-1.prod.workshops.aws/event/account-login

## Understand the Environment
The Amazon FSx for Lustre  integrates with EKS to provide high-performance file storage, which is crucial for GenAI workloads. Its CSI Driver  implements the Container Storage Interface (CSI) specification to manage these filesystems in our Kubernetes cluster.
   
Karpenter  is a Kubernetes cluster autoscaler that automatically provisions right-sized compute resources in response to changing application load. 

## Optimizing GPU Infrastructure for LLM Inference

For LLM inference with GPU workloads, we use Karpenter  for automatic node provisioning.

```
Karpenter NodePool:
Instance Types: GPU-enabled instances (g6e.2xlarge)
AMI: EKS-optimized Accelerated Amazon Linux 2023 with NVIDIA support
SOCI Snapshotter: Enabled for faster container image loading
Taints: nvidia.com/gpu:NoSchedule to ensure GPU workloads only
Labels: nvidia.com/gpu.present=true for GPU node identification
```
The NodeClass includes SOCI (Seekable OCI) snapshotter configuration, which significantly accelerates container startup times for large images.

The NVIDIA device plugin runs as a DaemonSet and automatically configures GPU nodes when they're provisioned.

Before testing GPU functionality, we need to configure our Ec2NodeClass to use On-Demand Capacity Reservations (ODCR). This ensures that our GPU workloads have guaranteed capacity when needed.

```
The nvidia-smi output should display detailed information about the GPU, including:
GPU model and architecture
CUDA user-mode driver version (libcuda.so)
Memory capacity and usage
Power usage and temperature
Running processes (if any)
```
<img width="962" height="647" alt="image" src="https://github.com/user-attachments/assets/eec694b1-069d-4e26-a417-5e00458dbae8" />


