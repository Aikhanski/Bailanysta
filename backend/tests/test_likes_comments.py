from fastapi.testclient import TestClient

from tests.test_posts import _create_post


def test_like_and_unlike_post(client: TestClient):
    post_id = _create_post(client).json()["id"]

    liked = client.post(f"/posts/{post_id}/like", headers={"X-User-Id": "1"})
    assert liked.status_code == 200
    assert liked.json()["like_count"] == 1
    assert liked.json()["is_liked"] is True

    listed = client.get("/posts", headers={"X-User-Id": "1"}).json()
    assert listed[0]["like_count"] == 1
    assert listed[0]["is_liked"] is True

    other = client.get("/posts", headers={"X-User-Id": "2"}).json()
    assert other[0]["like_count"] == 1
    assert other[0]["is_liked"] is False

    unliked = client.delete(f"/posts/{post_id}/like", headers={"X-User-Id": "1"})
    assert unliked.status_code == 200
    assert unliked.json()["like_count"] == 0
    assert unliked.json()["is_liked"] is False


def test_like_unknown_post(client: TestClient):
    response = client.post("/posts/99/like", headers={"X-User-Id": "1"})
    assert response.status_code == 404


def test_list_and_create_comments(client: TestClient):
    post_id = _create_post(client).json()["id"]

    empty = client.get(f"/posts/{post_id}/comments")
    assert empty.status_code == 200
    assert empty.json() == []

    created = client.post(
        f"/posts/{post_id}/comments",
        json={"text": "Nice one"},
        headers={"X-User-Id": "2"},
    )
    assert created.status_code == 201
    assert created.json()["text"] == "Nice one"
    assert created.json()["author"]["username"] == "bob"

    comments = client.get(f"/posts/{post_id}/comments").json()
    assert len(comments) == 1
    assert comments[0]["text"] == "Nice one"

    post = client.get("/posts", headers={"X-User-Id": "1"}).json()[0]
    assert post["comment_count"] == 1


def test_create_comment_rejects_blank_text(client: TestClient):
    post_id = _create_post(client).json()["id"]
    response = client.post(
        f"/posts/{post_id}/comments",
        json={"text": "  "},
        headers={"X-User-Id": "1"},
    )
    assert response.status_code == 422
