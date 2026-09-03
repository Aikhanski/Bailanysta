from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


def nonempty_text(value: str) -> str:
    stripped = value.strip()
    if not stripped:
        raise ValueError("text cannot be empty")
    return stripped


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    display_name: str
    bio: str
    created_at: datetime


class PostWrite(BaseModel):
    text: str = Field(min_length=1, max_length=1000)

    @field_validator("text")
    @classmethod
    def text_not_blank(cls, value: str) -> str:
        return nonempty_text(value)


class PostOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    author_id: int
    text: str
    created_at: datetime
    updated_at: datetime
    author: UserOut
    like_count: int
    comment_count: int
    is_liked: bool


class CommentWrite(BaseModel):
    text: str = Field(min_length=1, max_length=500)

    @field_validator("text")
    @classmethod
    def text_not_blank(cls, value: str) -> str:
        return nonempty_text(value)


class CommentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    post_id: int
    author_id: int
    text: str
    created_at: datetime
    author: UserOut


class GeneratePostRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=1000)

    @field_validator("prompt")
    @classmethod
    def prompt_not_blank(cls, value: str) -> str:
        return nonempty_text(value)


class GeneratePostOut(BaseModel):
    text: str
