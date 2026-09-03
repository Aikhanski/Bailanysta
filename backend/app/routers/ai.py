from fastapi import APIRouter, Depends, HTTPException, status

from app.ai_service import AINotConfigured, AIProviderError, generate_post_text
from app.dependencies import get_current_user
from app.models import User
from app.schemas import GeneratePostOut, GeneratePostRequest

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/generate-post", response_model=GeneratePostOut)
def generate_post(
    payload: GeneratePostRequest,
    current_user: User = Depends(get_current_user),
) -> GeneratePostOut:
    try:
        text = generate_post_text(payload.prompt)
    except AINotConfigured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI is not configured",
        )
    except AIProviderError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=exc.message,
        )
    return GeneratePostOut(text=text)
