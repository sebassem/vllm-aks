from openai import OpenAI
import json

client = OpenAI(base_url="http://4.165.84.189:5000/v1/",api_key="EMPTY")

response = client.chat.completions.create(
    model=client.models.list().data[0].id,
    messages=[{"role": "user", "content": "Why would I want to host an LLM on Kubernetes?"}],
    temperature=0.4
)

print(response.choices[0].message.content)
