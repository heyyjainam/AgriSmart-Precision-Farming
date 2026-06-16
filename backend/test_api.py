import requests

try:
    response = requests.post(
        "http://127.0.0.1:8000/api/v1/chatbot-query",
        json={"query": "test"}
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
except Exception as e:
    print(f"Error: {e}")
