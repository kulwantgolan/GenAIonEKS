<img width="780" height="573" alt="image" src="https://github.com/user-attachments/assets/788c3ba4-9807-43bc-9e54-1f6fdb7e4fa2" />

<img width="1014" height="669" alt="image" src="https://github.com/user-attachments/assets/21cfaa5d-4009-46f7-b6be-aca951f86842" />

Inference on Amazon EKS:

1. Learned about downloading model weights to the FSx for Lustre filesystem
2. Deployed a Mistral LLM model using vLLM with AWS Deep Learning Containers and RAM volume optimization
3. Tested the deployed model by sending an inference request to the service

Scaling LLM inference using vLLM and Ray:

1. Deploy the Mistral-7B-Instruct-v0.3  model using RayServe and vLLM.
2. Set up a vLLM Python application with FastAPI-based serving logic for efficient model inference.
3. Leverage Ray's autoscaling features with Nvidia instances to optimize performance.
4. Configure environment settings and scaling parameters for model serving.
5. Deploy Open WebUI, a user-friendly interface for interacting with your LLM.

RAG on Aamazon EKS

1. Set Up S3 Vector Database: Configure Amazon S3 Vectors for storing document embeddings with semantic search capabilities
2. Create Document Processing Pipeline: Build a Kubernetes job to process documents and generate embeddings
3. Deploy RAG Service: Create a RayServe deployment that combines Mistral LLM with RAG capabilities
4. Create Gradio Interface: Implement a user-friendly web interface for interacting with the RAG system
