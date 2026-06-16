import os
from app.core import config

GEMINI_API_KEY = config.GEMINI_API_KEY


try:
    import google.generativeai as genai
    _GEMINI_AVAILABLE = True
except ImportError:
    _GEMINI_AVAILABLE = False
    print("Google Generative AI package not found.")

class RAGService:
    def __init__(self):
        self.gemini_model = None
        self._initialize_gemini()
        
    def _initialize_gemini(self):
        if _GEMINI_AVAILABLE and GEMINI_API_KEY and GEMINI_API_KEY != "YOUR_API_KEY_HERE":
            try:
                genai.configure(api_key=GEMINI_API_KEY)
                # Using 2.5-flash which is the current supported model
                self.gemini_model = genai.GenerativeModel('gemini-2.5-flash')
                print("[AI] Gemini Generative AI successfully initialized!")
            except Exception as e:
                print(f"[AI] Failed to initialize Gemini: {e}")
        else:
            print("[AI] Gemini API Key not set.")

    def query(self, text: str):
        if not self.gemini_model:
            reason = "Unknown"
            if not _GEMINI_AVAILABLE:
                reason = "Google Generative AI package is missing in Uvicorn environment! Please stop uvicorn and restart it."
            elif not GEMINI_API_KEY or GEMINI_API_KEY == "YOUR_API_KEY_HERE":
                reason = "API Key is missing."
            return {"answer": f"Error: Gemini model is not initialized. Reason: {reason}"}
            
        try:
            prompt = f"""
            You are AgriSmart Assistant, a highly knowledgeable and friendly agricultural expert AI.
            A farmer has asked you the following question: "{text}"
            
            Please provide a helpful, practical, and easy-to-understand answer in plain text or markdown.
            Be conversational and professional.
            """
            response = self.gemini_model.generate_content(prompt)
            
            # Check if response was blocked by safety filters
            if not response.parts:
                return {"answer": "I'm sorry, I cannot provide an answer to that question due to safety filters."}
                
            return {"answer": response.text.strip()}
            
        except Exception as e:
            print(f"[AI] Gemini generation failed: {e}")
            return {"answer": f"API Error: {str(e)}"}
