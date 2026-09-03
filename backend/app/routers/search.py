from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_optional_user
from app.models import User
from app import services
from app.schemas import PostOut

router = APIRouter(tags=["search"])


@router.get("/search", response_model=list[PostOut])
def search_posts(
    q: str = Query(min_length=1, max_length=100),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
) -> list[PostOut]:
    viewer_id = current_user.id if current_user else None
    return services.serialize_posts(services.search_posts(db, q), viewer_id)
