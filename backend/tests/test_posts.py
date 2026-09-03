from fastapi.testclient import TestClient


def _create_post(client: TestClient, text: str = "Hello world", user_id: int = 1):
    return client.post(
        "/posts",
        json={"text": text},
        headers={"X-User-Id": str(user_id)},
    )


def test_get_posts_empty(client: TestClient):
    response = client.get("/posts")
    assert response.status_code == 200
    assert response.json() == []


def test_create_and_list_posts(client: TestClient):
    created = _create_post(client, "First post")
    assert created.status_code == 201
    body = created.json()
    assert body["text"] == "First post"
    assert body["author_id"] == 1
    assert body["author"]["username"] == "alice"

    response = client.get("/posts")
    assert response.status_code == 200
    posts = response.json()
    assert len(posts) == 1
    assert posts[0]["text"] == "First post"


def test_create_post_requires_user(client: TestClient):
    response = client.post("/posts", json={"text": "No user"})
    assert response.status_code == 422


def test_create_post_unknown_user(client: TestClient):
    response = client.post(
        "/posts",
        json={"text": "Hi"},
        headers={"X-User-Id": "99"},
    )
    assert response.status_code == 401


def test_create_post_rejects_blank_text(client: TestClient):
    response = client.post(
        "/posts",
        json={"text": "   "},
        headers={"X-User-Id": "1"},
    )
    assert response.status_code == 422


def test_create_post_rejects_too_long_text(client: TestClient):
    response = _create_post(client, "x" * 1001)
    assert response.status_code == 422


def test_update_own_post(client: TestClient):
    post_id = _create_post(client).json()["id"]
    response = client.patch(
        f"/posts/{post_id}",
        json={"text": "Updated"},
        headers={"X-User-Id": "1"},
    )
    assert response.status_code == 200
    assert response.json()["text"] == "Updated"


def test_update_rejects_other_users_post(client: TestClient):
    post_id = _create_post(client).json()["id"]
    response = client.patch(
        f"/posts/{post_id}",
        json={"text": "Hacked"},
        headers={"X-User-Id": "2"},
    )
    assert response.status_code == 403


def test_delete_own_post(client: TestClient):
    post_id = _create_post(client).json()["id"]
    response = client.delete(f"/posts/{post_id}", headers={"X-User-Id": "1"})
    assert response.status_code == 204
    assert client.get("/posts").json() == []


def test_delete_rejects_other_users_post(client: TestClient):
    post_id = _create_post(client).json()["id"]
    response = client.delete(f"/posts/{post_id}", headers={"X-User-Id": "2"})
    assert response.status_code == 403


def test_update_unknown_post(client: TestClient):
    response = client.patch(
        "/posts/99",
        json={"text": "Missing"},
        headers={"X-User-Id": "1"},
    )
    assert response.status_code == 404
