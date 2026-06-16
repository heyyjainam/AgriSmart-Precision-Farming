import os
from dotenv import load_dotenv

# Load .env file
env_path = os.path.join(os.path.dirname(__file__), "../../.env")
if os.path.exists(env_path):
    load_dotenv(env_path)
else:
    load_dotenv()  # fallback to standard dotenv search

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyA12jZNVLzMfgcLFQAbrrU8MPC01NjZfBI")
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./backend_data.db")
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8000"))
