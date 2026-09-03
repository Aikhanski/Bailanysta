from fastapi.testclient import TestClient


def test_get_user(client: TestClient):
    response = client.get("/users/1")
    assert response.status_code == 200
    body = response.json()
    assert body["username"] == "alice"
    assert body["display_name"] == "Alice"
    assert "created_at" in body


def test_get_unknown_user(client: TestClient):
    response = client.get("/users/99")
    assert response.status_code == 404


def test_get_user_posts_empty(client: TestClient):
    response = client.get("/users/1/posts")
    assert response.status_code == 200
    assert response.json() == []


def test_get_user_posts(client: TestClient):
    client.post("/posts", json={"text": "Alice post"}, headers={"X-User-Id": "1"})
    client.post("/posts", json={"text": "Bob post"}, headers={"X-User-Id": "2"})

    response = client.get("/users/1/posts")
    assert response.status_code == 200
    posts = response.json()
    assert len(posts) == 1
    assert posts[0]["text"] == "Alice post"
    assert posts[0]["author"]["username"] == "alice"
