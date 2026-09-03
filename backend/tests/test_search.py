from fastapi.testclient import TestClient

from tests.test_posts import _create_post


def test_search_matches_post_text(client: TestClient):
    _create_post(client, "Hello from Almaty")
    _create_post(client, "Working on the feed")

    response = client.get("/search", params={"q": "almaty"})
    assert response.status_code == 200
    posts = response.json()
    assert len(posts) == 1
    assert "Almaty" in posts[0]["text"]


def test_search_matches_hashtags(client: TestClient):
    _create_post(client, "Weekend plans #travel")
    _create_post(client, "Just a regular post")

    by_tag = client.get("/search", params={"q": "#travel"}).json()
    by_word = client.get("/search", params={"q": "travel"}).json()
    assert len(by_tag) == 1
    assert len(by_word) == 1
    assert by_tag[0]["text"] == "Weekend plans #travel"


def test_search_returns_empty_when_nothing_matches(client: TestClient):
    _create_post(client, "Hello")
    response = client.get("/search", params={"q": "xyz-missing"})
    assert response.status_code == 200
    assert response.json() == []


def test_search_requires_query(client: TestClient):
    response = client.get("/search")
    assert response.status_code == 422
