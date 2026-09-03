from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Comment, Like, Post, User


def seed_if_empty(db: Session) -> None:
    has_users = db.scalar(select(User.id).limit(1))
    if has_users is not None:
        return

    aikhan = User(username="aikhan", display_name="Aikhan Khassenov", bio="Building Bailanysta.")
    dana = User(username="dana", display_name="Dana", bio="Coffee and long walks.")
    nurlan = User(username="nurlan", display_name="Nurlan", bio="")

    db.add_all([aikhan, dana, nurlan])
    db.flush()

    welcome = Post(author=aikhan, text="Welcome to Bailanysta. #hello")
    dana_post = Post(author=dana, text="First post from Dana.")
    nurlan_post = Post(author=nurlan, text="Hello from Almaty. #travel")
    feed_post = Post(author=aikhan, text="Working on the feed today.")
    db.add_all([welcome, dana_post, nurlan_post, feed_post])
    db.flush()

    db.add_all(
        [
            Like(user_id=dana.id, post_id=welcome.id),
            Like(user_id=nurlan.id, post_id=welcome.id),
            Like(user_id=aikhan.id, post_id=dana_post.id),
            Comment(post=welcome, author=dana, text="Glad this is live."),
            Comment(post=welcome, author=nurlan, text="Looking good."),
            Comment(post=dana_post, author=aikhan, text="Nice post!"),
        ]
    )
    db.commit()
