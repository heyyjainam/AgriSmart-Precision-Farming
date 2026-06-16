from fastapi import APIRouter, HTTPException
from app.schemas.models import ChatbotRequest, ChatbotResponse
from app.services.rag_service import RAGService

router = APIRouter()
rag_service = RAGService()

@router.post("/chatbot-query", response_model=ChatbotResponse)
async def chatbot_query(request: ChatbotRequest):
    try:
        result = rag_service.query(request.query)
        return ChatbotResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
