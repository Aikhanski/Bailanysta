from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user, get_optional_user
from app.models import User
from app import services
from app.schemas import CommentOut, CommentWrite, PostOut, PostWrite

router = APIRouter(prefix="/posts", tags=["posts"])


def _require_post(db: Session, post_id: int):
    post = services.get_post(db, post_id)
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    return post


@router.get("", response_model=list[PostOut])
def get_posts(
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
) -> list[PostOut]:
    viewer_id = current_user.id if current_user else None
    return services.serialize_posts(services.list_posts(db), viewer_id)


@router.post("", response_model=PostOut, status_code=status.HTTP_201_CREATED)
def create_post(
    payload: PostWrite,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostOut:
    post = services.create_post(db, current_user, payload.text)
    return services.serialize_post(post, current_user.id)


@router.patch("/{post_id}", response_model=PostOut)
def update_post(
    post_id: int,
    payload: PostWrite,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostOut:
    post = _require_post(db, post_id)
    if post.author_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only edit your own posts",
        )
    post = services.update_post(db, post, payload.text)
    return services.serialize_post(post, current_user.id)


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    post = _require_post(db, post_id)
    if post.author_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own posts",
        )
    services.delete_post(db, post)


@router.post("/{post_id}/like", response_model=PostOut)
def like_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostOut:
    post = _require_post(db, post_id)
    post = services.like_post(db, current_user, post)
    return services.serialize_post(post, current_user.id)


@router.delete("/{post_id}/like", response_model=PostOut)
def unlike_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostOut:
    post = _require_post(db, post_id)
    post = services.unlike_post(db, current_user, post)
    return services.serialize_post(post, current_user.id)


@router.get("/{post_id}/comments", response_model=list[CommentOut])
def get_comments(post_id: int, db: Session = Depends(get_db)) -> list[CommentOut]:
    _require_post(db, post_id)
    return services.list_comments(db, post_id)


@router.post("/{post_id}/comments", response_model=CommentOut, status_code=status.HTTP_201_CREATED)
def create_comment(
    post_id: int,
    payload: CommentWrite,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> CommentOut:
    post = _require_post(db, post_id)
    return services.create_comment(db, post, current_user, payload.text)
