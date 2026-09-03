from unittest.mock import patch

from fastapi.testclient import TestClient

from app.ai_service import AINotConfigured, AIProviderError, generate_post_text


def _generate(client: TestClient, prompt: str = "I want to write about my trip to Vietnam"):
    return client.post(
        "/ai/generate-post",
        json={"prompt": prompt},
        headers={"X-User-Id": "1"},
    )


def test_generate_post_returns_text(client: TestClient):
    with patch(
        "app.routers.ai.generate_post_text",
        return_value="Just landed in Vietnam — already in love with the food.",
    ):
        response = _generate(client)

    assert response.status_code == 200
    assert response.json() == {
        "text": "Just landed in Vietnam — already in love with the food."
    }


def test_generate_post_requires_user(client: TestClient):
    response = client.post(
        "/ai/generate-post",
        json={"prompt": "A trip to Vietnam"},
    )
    assert response.status_code == 422


def test_generate_post_rejects_blank_prompt(client: TestClient):
    response = _generate(client, "   ")
    assert response.status_code == 422


def test_generate_post_not_configured(client: TestClient):
    with patch("app.routers.ai.generate_post_text", side_effect=AINotConfigured):
        response = _generate(client)
    assert response.status_code == 503
    assert response.json()["detail"] == "AI is not configured"


def test_generate_post_provider_error(client: TestClient):
    with patch(
        "app.routers.ai.generate_post_text",
        side_effect=AIProviderError("The AI provider timed out"),
    ):
        response = _generate(client)
    assert response.status_code == 502
    assert response.json()["detail"] == "The AI provider timed out"


def test_generate_post_text_requires_api_key():
    with patch("app.ai_service.config.OPENAI_API_KEY", ""):
        try:
            generate_post_text("A trip to Vietnam")
        except AINotConfigured:
            return
        raise AssertionError("expected AINotConfigured")


def test_generate_post_text_calls_provider():
    with patch("app.ai_service.config.OPENAI_API_KEY", "test-key"):
        with patch("app.ai_service.httpx.post") as mock_post:
            mock_post.return_value.status_code = 200
            mock_post.return_value.json.return_value = {
                "choices": [
                    {"message": {"content": "  Coffee in Hanoi, then the night market.  "}}
                ]
            }
            text = generate_post_text("I want to write about my trip to Vietnam")

    assert text == "Coffee in Hanoi, then the night market."
    headers = mock_post.call_args.kwargs["headers"]
    assert headers["Authorization"] == "Bearer test-key"


def test_generate_post_text_handles_provider_http_error():
    with patch("app.ai_service.config.OPENAI_API_KEY", "test-key"):
        with patch("app.ai_service.httpx.post") as mock_post:
            mock_post.return_value.status_code = 401
            try:
                generate_post_text("A trip to Vietnam")
            except AIProviderError as exc:
                assert "could not generate" in exc.message
                return
    raise AssertionError("expected AIProviderError")
