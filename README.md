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
