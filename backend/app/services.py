from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.database import utcnow
from app.models import Comment, Like, Post, User
from app.schemas import PostOut


def get_user(db: Session, user_id: int) -> User | None:
    return db.get(User, user_id)


def _post_query():
    return (
        select(Post)
        .options(
            joinedload(Post.author),
            selectinload(Post.likes),
            selectinload(Post.comments),
        )
    )


def list_posts(db: Session, user_id: int | None = None) -> list[Post]:
    statement = _post_query()
    if user_id is not None:
        statement = statement.where(Post.author_id == user_id)
    statement = statement.order_by(Post.created_at.desc())
    return list(db.scalars(statement).unique().all())


def search_posts(db: Session, query: str) -> list[Post]:
    term = query.strip()
    if term.startswith("#"):
        term = term.lstrip("#").strip()
    if not term:
        return []
    pattern = f"%{term}%"
    statement = (
        _post_query()
        .where(Post.text.ilike(pattern))
        .order_by(Post.created_at.desc())
    )
    return list(db.scalars(statement).unique().all())


def get_post(db: Session, post_id: int) -> Post | None:
    statement = _post_query().where(Post.id == post_id)
    return db.scalars(statement).unique().one_or_none()


def serialize_post(post: Post, viewer_id: int | None = None) -> PostOut:
    liked_by = {like.user_id for like in post.likes}
    return PostOut(
        id=post.id,
        author_id=post.author_id,
        text=post.text,
        created_at=post.created_at,
        updated_at=post.updated_at,
        author=post.author,
        like_count=len(post.likes),
        comment_count=len(post.comments),
        is_liked=viewer_id in liked_by if viewer_id is not None else False,
    )


def serialize_posts(posts: list[Post], viewer_id: int | None = None) -> list[PostOut]:
    return [serialize_post(post, viewer_id) for post in posts]


def create_post(db: Session, author: User, text: str) -> Post:
    post = Post(author=author, text=text)
    db.add(post)
    db.commit()
    return get_post(db, post.id) or post


def update_post(db: Session, post: Post, text: str) -> Post:
    post.text = text
    post.updated_at = utcnow()
    db.commit()
    return get_post(db, post.id) or post


def delete_post(db: Session, post: Post) -> None:
    db.delete(post)
    db.commit()


def like_post(db: Session, user: User, post: Post) -> Post:
    existing = db.get(Like, (user.id, post.id))
    if existing is None:
        db.add(Like(user_id=user.id, post_id=post.id))
        db.commit()
    return get_post(db, post.id) or post


def unlike_post(db: Session, user: User, post: Post) -> Post:
    existing = db.get(Like, (user.id, post.id))
    if existing is not None:
        db.delete(existing)
        db.commit()
    return get_post(db, post.id) or post


def list_comments(db: Session, post_id: int) -> list[Comment]:
    statement = (
        select(Comment)
        .options(joinedload(Comment.author))
        .where(Comment.post_id == post_id)
        .order_by(Comment.created_at.asc())
    )
    return list(db.scalars(statement).unique().all())


def create_comment(db: Session, post: Post, author: User, text: str) -> Comment:
    comment = Comment(post=post, author=author, text=text)
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return comment
