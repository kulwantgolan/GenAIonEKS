## Initial Setup and access 
1. Create the stack - Cloudformation template load from S3 bucket URL
2. Create On-Demand Capacity Reservation (ODCR): After your stack is created, you need to set up an On-Demand Capacity Reservation (ODCR) for the GPU instances required by this workshop/
3. Access the IDE: VSCODE
4. AWS console: https://catalog.us-east-1.prod.workshops.aws/event/account-login

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

## Inference on Amazon EKS

vLLM  is one of several popular, open-source inference and serving engines specifically designed to optimize the performance of generative AI applications through more efficient GPU memory utilization. While vLLM is not mandatory for running generative AI applications, the advantages it offer make it a compelling choice for production deployments. Alternative inference engines like TensorRT-LLM can also be used for running generative AI models.

We will use the `Mistral-7B-Instruct-v0.3` model . The model and weights have already been downloaded into the FSx for Lustre filesystem (to save time). The model is saved in the FSx for Lustre filesystem under the path of /models/mistral-7b-v0-3/.
```
consolidated.safetensors: This is the main model weights file using the SafeTensors format.
params.json: Contains the model's configuration parameters
tokenizer.model.v3: handles text preprocessing
```

### Deploying the model
To deploy the model, we will use a vanilla Kubernetes service and deployment.
Deployment will use AWS Deep Learning Containers with vLLM to load the model - with optimised configuration copies model weights to RAM.

```
Note: This deployment uses AWS Deep Learning Containers which provide optimized vLLM images with better compatibility and performance. The configuration includes an init container that copies the model from FSx to a RAM volume, significantly improving model loading times compared to direct network filesystem access.
```
Since this deployment requires GPU nodes, Karpenter will automatically provision a new GPU-enabled node if one doesn't already exist.
This typically takes 2-3 minutes - demonstrating Karpenter's rapid scaling capabilities for GPU workloads.

<img width="1318" height="657" alt="image" src="https://github.com/user-attachments/assets/bf6a0696-1465-4a87-a6b6-03c33689c2f7" />

## Interact with LLM
To access the model service from your local machine, you need to set up port forwarding from the Kubernetes service to your local environment.

You can test the deployed model by sending a completion request using curl.

## Conclusion
In this session, we have:
- Learned about downloading model weights to the FSx for Lustre filesystem
- Deployed a Mistral LLM model using vLLM with AWS Deep Learning Containers and RAM volume optimization
- Tested the deployed model by sending an inference request to the service

## Clean up to avoid $$

Remove the deployed Mistral model and the associated service.

---

## Scaling LLM Inference using vLLM & Ray
What You'll Build
In this module, you will:
1. Deploy the Mistral-7B-Instruct-v0.3  model using RayServe and vLLM.
2. Set up a vLLM Python application with FastAPI-based serving logic for efficient model inference.
3. Leverage Ray's autoscaling features with Nvidia instances to optimize performance.
4. Configure environment settings and scaling parameters for model serving.
5. Deploy Open WebUI, a user-friendly interface for interacting with your LLM.

<img width="1153" height="623" alt="image" src="https://github.com/user-attachments/assets/413f8b8a-e9d8-4b31-aeff-3b2a668b8da2" />

## Deploy the ConfigMap containing our vllm_serve.py script
This ConfigMap will allow us to manage our application code separately from our Kubernetes deployment configuration, setting up the foundation for a `vLLM serving system`.

The Python script defines a system that:
- loads and serves large language models efficiently,
- handles chat completion requests in a format compatible with OpenAI's API,
- scales the service across multiple workers using Ray, and
- can be customized through environment variables.
Key Component of Python Script:
1. Application Setup: The code establishes a FastAPI application with necessary imports for API handling, Ray Serve integration, and vLLM engine components.
2. VLLMDeployment Class:
   - Decorated with Ray Serve annotations (@serve.deployment and @serve.ingress) to make it available as a distributed service.
   - The constructor initializes the model
   - Creates a ModelConfig with settings optimized for inference.
3. API Endpoints: for easier integration with existing tools and applications, returns information about available models and Processes chat completion requests.
4. Model Serving Infrastructure:
   - Configures the vLLM engine with `AsyncEngineArgs` - including GPU utilization settings and chunked prefill for memory optimization.
   - Creates the `AsyncLLMEngine` - handles the actual model inference operations.
   - Uses `OpenAIServingChat`: format response as per OpenAI's expected formats.
5. Configuration and Deployment: The deployment is bound with environment variables that can be customized. 

## RayService with vLLM on EKS

1. Deploying KubeRay Operator and RayService: While Ray can be deployed directly on Kubernetes using basic resources like Deployments and Services, KubeRay Operator  provides significant advantages for production environments.
2. We'll deploy the KubeRay Operator, which provides Kubernetes custom resource definitions (CRDs) for Ray clusters, followed by deploying a RayService configuration that sets up the serving infrastructure for our vLLM system on Amazon EKS.
3. Deploy KubeRay Operator manages to Ray resources in Kubernetes. Use Helm to deploy it.
4. Create and Apply the RayService Configuration.
5. Monitor the Deployment. ( Check wheteher Karpenter provisioned node with GPU capabilities: `kubectl get nodes -l nvidia.com/gpu.present=true` )
6. Ray Dashboard: While the Ray cluster initializes and loads the large language model into memory (which takes a few minutes), let's monitor the cluster's status through the Ray Dashboard. The dashboard provides valuable visibility into jobs, actors, and overall cluster health (`kubectl port-forward svc/vllm 8265:8265`)
https://d1daa9dsdfa45l.cloudfront.net/proxy/8265/#/overview
<img width="1862" height="879" alt="image" src="https://github.com/user-attachments/assets/0c9c0011-12a7-434b-8b1c-482da7502fe6" />
<img width="1859" height="862" alt="image" src="https://github.com/user-attachments/assets/5064893c-0e78-485b-94ed-b5dcde03e0e4" />


<img width="942" height="155" alt="image" src="https://github.com/user-attachments/assets/be639a91-8585-4dfd-b465-f795beb63ca2" />

## Chat with Mistral
1. Deploy Open WebUI Application: Deploy `Open WebUI` , a feature-rich, self-hosted web interface that serves as your gateway to interacting with Large Language Models (LLMs).
2.  To enhance security, you can restrict access to the load balancer by allowing only your public IP address. First, determine your public IP address by visiting `https://checkip.amazonaws.com/`  in your web browser. Update the load balancer configuration by modifying, file: `manifests/200-inference/openwebui.yml`, the alb.ingress.kubernetes.io/inbound-cidrs annotation from line 80. Replace the default value 0.0.0.0/0 (which allows all IP addresses) with your-ip-address/32 (which specifies only your IP). AND apply the Open WebUI deployment `kubectl apply -f manifests/200-inference/openwebui.yml`

## Access the application

Note: It takes up to 2-3 minutes for the LoadBalancer to become active. Once it's ready, you can access the Open WebUI web interface through your browser.
If the URL fails to appear, this is likely due to a race condition during the initial environment setup. To resolve this issue, restart the AWS Load Balancer Controller. 
http://open-webui-ingress-1306108428.us-west-2.elb.amazonaws.com/

<img width="1871" height="896" alt="image" src="https://github.com/user-attachments/assets/739b0d30-dfe7-47f7-a6af-275bb5f9b332" />

<img width="1882" height="876" alt="image" src="https://github.com/user-attachments/assets/4a570748-f97b-4a6e-806c-88074ed1d538" />

## Observing LLM inference workloads

1. Setup Observability stack: Deployed several key components in the `monitoring` namespace that form our observability stack
   - Prometheus Stack
      - Prometheus Server: Central metrics collection and storage
      - Node Exporter: Collects hardware and OS metrics from each node (runs as DaemonSet)
      - Kube State Metrics: Generates metrics about Kubernetes objects
   - Grafana Stack: Grafana server and Grafana Operator to provision Dashboards using custom resources (YAML files).
   - The `NVIDIA Data Center GPU Manager (DCGM) Exporter` is a tool that exposes GPU metrics for NVIDIA GPUs.
      - Create a values file for the DCGM Exporter configuration.
      - Using helm, Install the NVIDIA DCGM Exporter to collect GPU metrics
      - Verify GPU Metrics using port-forwarding
    
   <img width="1566" height="448" alt="image" src="https://github.com/user-attachments/assets/cdc42bc9-f6bc-442d-a341-960fa663521a" />

2. Configuring NVIDIA DCGM Monitoring Dashboard in Grafana: In order to reach the Grafana service we will need to create an Ingress. To enhance security, you can restrict access to the load balancer by allowing only your public IP address. Consider that it takes 2-3 minutes for the load balancer to provision and become active. Get loadbalancer URL. Get Grafana admin password and K8s secret.
   - Open Grafana, If everything is configured correctly you should see a dashboard called NVIDIA DCGM Exporter Dashboard under the monitoring folder.
  <img width="756" height="519" alt="image" src="https://github.com/user-attachments/assets/63134db6-3d04-41bd-95b0-b7cd54513b45" />
<img width="1873" height="446" alt="image" src="https://github.com/user-attachments/assets/94914bb4-d36a-4db4-a612-eac470d8263d" />

3. Ray Monitoring: Create a `PodMonitor` resource for Ray head and worker nodes - tells Prometheus which pods to scrape for metrics collection.
   - Create Ray Grafana Dashboard using Grafana Operator: Together, these dashboards provide a powerful toolkit for monitoring, troubleshooting, and optimizing your Ray-powered LLM inference services.
     - `Deafult Dashboard` in monitoring
     - `Serve Dashboard` focuses specifically on Ray Serve performance metrics, displaying request latencies, throughput, and queue lengths for your deployed models.
     - `Serve Deployment Dashboard` provides detailed monitoring for individual Ray Serve deployments, tracking replica scaling, resource consumption, and deployment-specific performance indicators.
   - You already have:
     - OPENWEBUI to interact with model
     - GRAFANA URL to access the dashboard
    <img width="858" height="475" alt="image" src="https://github.com/user-attachments/assets/20999faa-f8ad-4fc4-a1f2-60d7eab34ad1" />

Clean up the monitoring resources and RayServe deployment, Delete Open Web UI provisioned previously.      

4. vLLM Model Monitoring
   - Ensure vLLm is deployed
   - Creating vLLM ServiceMonitor
   - Create vLLM Grafana Dashboard using Grafana Operator
   - Accessing Grafana Dashboard: `vLLM dashboard`: vLLM metrics dashboard provides comprehensive monitoring of your LLM inference deployment, helping you understand performance, resource utilization, and request processing.
      - vLLM Iterations Token: Useful for understanding processing patterns and optimization opportunities
      - vLLM Generations Tokens: Important for capacity planning and usage monitoring
      - vLLM Time Per Output Token: average time taken to generate each token - identify performance bottlenecks
      - vLLM Time to First Token Counter: Tracks the latency between request receipt and first token generation - monitor initial response time performance
      - vLLM Time in Queue Requests: how long requests wait 
      - vLLM Request Prompt Tokens: number of input tokens in requests - optimizing prompt engineering and resource allocation
      - vLLM Request Inference Time: total time taken for inference processing - overall system performance
      - vLLM Num Preemptions Total: the number of request preemptions - Indicates resource contention and scheduling efficiency

<img width="827" height="490" alt="image" src="https://github.com/user-attachments/assets/b9efff58-9c2d-41f2-a170-b65c6b37f1db" />

Cleanup

---

## Advanced AI on Amazon EKS
Focusing on advanced techniques and architectures that go beyond basic inference.
### RAG
Build a complete RAG pipeline on Amazon EKS using Ray for distributed computing, Qdrant as our vector database, and Mistral as our large language model.

The module is divided into four sequential sections:
- Set Up S3 Vector Database: Configure Amazon S3 Vectors for storing document embeddings with semantic search capabilities
   - Before we can deploy Ray-based workloads, we need to install the KubeRay Operator
   - Setup Env variables
   - Create S3 Vector Bucket
   - Create the vector index with 384 dimensions (matching the all-MiniLM-L6-v2 model)
    <img width="1492" height="345" alt="image" src="https://github.com/user-attachments/assets/da265315-5ac9-4499-b59d-6b38d70058f1" />
   - Set Up IAM Permissions for S3 Vectors
   - Create an IAM role for our document processor
   - Create the EKS Pod Identity association: This configures Pod Identity to assign the IAM role to pods using the s3-access-sa service account.
   - Create the service account
   - Test the S3 Vectors Connection: showing your index with name "knowledge-base"
   <img width="1512" height="651" alt="image" src="https://github.com/user-attachments/assets/7190840b-be05-41c0-b249-bf3fc132182b" />
- Create Document Processing Pipeline: Build a Kubernetes job to process documents and generate embeddings
  <img width="1038" height="575" alt="image" src="https://github.com/user-attachments/assets/d97c50f4-33f1-4833-b887-d33fca3175b9" />
   - We'll upload a sample dataset to Amazon S3, then create a processing script that uses the model `all-MiniLM-L6-v2` to generate embeddings and store them in our S3 Vectors database.
   - Prepare Sample Data and S3 Bucket
   - Create a ConfigMap with the Document Processing Script
   - Create a Kubernetes Job for the Document Processor
   - Process and Deploy the Document Processor Job (let's substitute the environment variables and deploy our job; Monitor the Job Progress)
      - Let's check the logs of the pod (The will Install the required dependencies; Connect to S3 Vectors and set up the collection if needed; Find documents in S3; Process the documents and generate embeddings;  Store the embeddings in S3 Vectors)
   - Verify the Data in S3 Vectors
- Deploy RAG Service: Create a RayServe deployment that combines Mistral LLM with RAG capabilities
  <img width="1144" height="689" alt="image" src="https://github.com/user-attachments/assets/2654cf48-74c1-40c0-ab87-e5d3e13763a3" />
  - Now that we have our vector database with document embeddings; Deploy Mistral LLM (to be used by RAG service) deployed on RayServer.
  - Deploy the RAG Service
       - Create a ConfigMap containing our RAG service implementation
       - Create the RayService that will deploy our RAG service
       - Check the RayService named `rag-service` to be ready
      <img width="743" height="229" alt="image" src="https://github.com/user-attachments/assets/0d6184d8-8bae-467c-ba66-e432c2f12b94" />
       - Create a Service for External Access
       - Test the RAG Service; and compare the results of the query without RAG Service
- Create Gradio Interface: Implement a user-friendly web interface for interacting with the RAG system
  <img width="1146" height="682" alt="image" src="https://github.com/user-attachments/assets/f47dbd26-d7ac-492a-bcdf-ed33278b081d" />
   - 
You have successfully built and deployed a complete RAG pipeline on Amazon EKS with a user-friendly Gradio interface. This system showcases how the combination of Ray for distributed computing, S3 Vectors for vector storage, and Mistral as the LLM creates a powerful and cost-effective RAG solution.
<img width="1590" height="919" alt="image" src="https://github.com/user-attachments/assets/f5611571-bcdd-41d4-9caf-be96d8837032" />

<img width="1562" height="489" alt="image" src="https://github.com/user-attachments/assets/12e68d18-5d4e-445b-a322-5145f56af143" />
- Slight issue of color theme (possibly only tested for Dark theme)

- Clean up; verigy GPU Availability (`kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPUS:.status.capacity.'nvidia\.com/gpu'`)
### Agentic AI
Deploy intelligent agents on Amazon EKS using the `Strands Agents SDK`, enabling LLMs to remember past interactions, make decisions, and use tools like time and weather services to respond to location-based queries.
<img width="1125" height="625" alt="image" src="https://github.com/user-attachments/assets/3887941a-6094-4efd-9ee9-b2c1c279317c" />

Unlike basic LLM applications, agents can remember past interactions, make decisions, and use tools—enabling richer, multi-turn experiences like customer support or task planning.

We are building the following:

### Deploying Strands Agents:
- Build agents using Strands SDK
- Configure time and weather tools for location-based queries
- Connect models with tools using the Strands framework
- Deploy agents on Amazon EKS

Strands is lightweight, production-ready, and model-agnostic.It integrates with the Model Context Protocol (MCP), allowing agents to connect with external services and maintain structured context across sessions. 

1. Deploying the Model: vanilla Kubernetes service and deployment.
   - specific arguments required for automatic function calling (these parameters are essential for our agents to intelligently decide when and how to use the time and weather tools)
     -  --enable-auto-tool-choice: Enables the model to automatically generate tool calls when appropriate
     -  --tool-call-parser=mistral: Specifies the parser format for tool calls
     -  
2. Building the agent
   - Build and deploy a Strands agent to the EKS cluster (strands-agent/strands-agent.py; strands-agent/requirements.txt; strands-agent/Dockerfile )
      - Create an Amazon ECR repository to store our Docker image.
      - Build the container image and push it to ECR.
      - Create a deployment manifest that uses this image.
        
### Testing the agents
- Query agents for time and weather information
- Test location-based functionality
- Interact with deployed agents

You might be curious about how the request flow works and why the model gets invoked twice. When you send a query to the agent, it may appear that a single response is generated — but behind the scenes, two separate model calls are occurring. Here's the process:

- First call: The LLM receives the user's query and decides which tool (e.g., weather or time) to use. Instead of responding directly, it returns a structured tool call for the agent to execute.
- Second call: Once the tool returns factual data, the LLM is called again to generate a conversational and informative reply using that data.
  
This strategy separates reasoning from response generation — giving your agent both intelligent behavior and natural language capabilities.
<img width="655" height="295" alt="image" src="https://github.com/user-attachments/assets/704cd15b-be0c-4ebe-ad4a-385beb86f864" />


<img width="1267" height="343" alt="image" src="https://github.com/user-attachments/assets/03862923-a20a-4ef0-839d-e0f7a191f651" />






