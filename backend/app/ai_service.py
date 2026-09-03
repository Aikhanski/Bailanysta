from __future__ import annotations

import httpx

from app import config

OPENAI_URL = "https://api.openai.com/v1/chat/completions"
MODEL = "gpt-4o-mini"
MAX_POST_LENGTH = 1000

SYSTEM_PROMPT = (
    "You write short social media posts. Turn the user's idea into one polished post. "
    "Return only the post text, with no title, quotes, or explanation. "
    "Keep it under 1000 characters. Use a natural first-person tone. "
    "Add light hashtags only if they fit."
)


class AINotConfigured(Exception):
    pass


class AIProviderError(Exception):
    def __init__(self, message: str = "Could not generate a post right now"):
        super().__init__(message)
        self.message = message


def generate_post_text(prompt: str) -> str:
    api_key = config.OPENAI_API_KEY
    if not api_key:
        raise AINotConfigured

    try:
        response = httpx.post(
            OPENAI_URL,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": MODEL,
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": prompt},
                ],
                "max_tokens": 400,
                "temperature": 0.7,
            },
            timeout=30.0,
        )
    except httpx.TimeoutException as exc:
        raise AIProviderError("The AI provider timed out") from exc
    except httpx.RequestError as exc:
        raise AIProviderError("Could not reach the AI provider") from exc

    if response.status_code != 200:
        raise AIProviderError("The AI provider could not generate a post")

    try:
        data = response.json()
        text = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError, ValueError) as exc:
        raise AIProviderError("The AI provider returned an invalid response") from exc

    if not isinstance(text, str) or not text.strip():
        raise AIProviderError("The AI provider returned an empty post")

    return text.strip()[:MAX_POST_LENGTH]
