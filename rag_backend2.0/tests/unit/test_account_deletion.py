"""Account deletion is complete, retry-safe, and deletes identity last."""
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.account_deletion import (
    _avatar_file_id,
    _delete_matching_rows,
    _delete_user_avatar_files,
    delete_account_data,
)


@pytest.mark.asyncio
async def test_delete_matching_rows_continues_until_empty():
    db = MagicMock()
    db.list_rows.side_effect = [
        SimpleNamespace(rows=[SimpleNamespace(id="r1"), SimpleNamespace(id="r2")]),
        SimpleNamespace(rows=[]),
    ]

    count = await _delete_matching_rows(db, "db", "collection", "userId", "u1")

    assert count == 2
    assert db.list_rows.call_count == 2
    assert db.delete_row.call_count == 2


@pytest.mark.asyncio
async def test_avatar_cleanup_deletes_owned_historical_and_current_files(monkeypatch):
    from app.services import account_deletion

    monkeypatch.setattr(account_deletion.settings, "appwrite_user_avatars_bucket_id", "avatars")
    storage = MagicMock()
    storage.list_files.return_value = SimpleNamespace(files=[
        SimpleNamespace(id="old", permissions=['delete("user:u1")']),
        SimpleNamespace(id="current", permissions=[]),
        SimpleNamespace(id="other", permissions=['delete("user:u2")']),
    ])

    count = await _delete_user_avatar_files(storage, "u1", "current")

    assert count == 2
    assert {call.args[-1] for call in storage.delete_file.call_args_list} == {"old", "current"}


def test_avatar_file_id_is_parsed_from_appwrite_view_url():
    assert _avatar_file_id(
        "https://fra.cloud.appwrite.io/v1/storage/buckets/b/files/avatar123/view?project=p"
    ) == "avatar123"
    assert _avatar_file_id("assets/icons/account.png") is None


@pytest.mark.asyncio
async def test_identity_is_deleted_only_after_all_data_steps_succeed(monkeypatch):
    from app.services import account_deletion

    monkeypatch.setattr(account_deletion.settings, "appwrite_user_avatars_bucket_id", "avatars")
    monkeypatch.setattr(account_deletion.settings, "appwrite_users_collection_id", "users")
    db, storage, users = MagicMock(), MagicMock(), MagicMock()
    with (
        patch.object(account_deletion, "_build_services", return_value=(db, storage, users, "db")),
        patch.object(account_deletion, "_collection_ownership", return_value=[
            ("messages", "messages", ("userId",)),
            ("users", "users", ("userId",)),
        ]),
        patch.object(account_deletion, "_find_profile_icon", new=AsyncMock(return_value=None)),
        patch.object(account_deletion, "_delete_user_avatar_files", new=AsyncMock(return_value=0)),
        patch.object(account_deletion, "_delete_matching_rows", new=AsyncMock(return_value=2)),
    ):
        report = await delete_account_data("u1")

    assert report.errors == []
    assert report.deleted_rows == {"messages": 2, "users": 2}
    assert report.identity_deleted is True
    users.delete.assert_called_once_with("u1")


@pytest.mark.asyncio
async def test_partial_data_failure_preserves_identity_for_retry(monkeypatch):
    from app.services import account_deletion

    monkeypatch.setattr(account_deletion.settings, "appwrite_user_avatars_bucket_id", "avatars")
    db, storage, users = MagicMock(), MagicMock(), MagicMock()
    with (
        patch.object(account_deletion, "_build_services", return_value=(db, storage, users, "db")),
        patch.object(account_deletion, "_collection_ownership", return_value=[
            ("messages", "messages", ("userId",)),
        ]),
        patch.object(account_deletion, "_find_profile_icon", new=AsyncMock(side_effect=RuntimeError("down"))),
        patch.object(account_deletion, "_delete_matching_rows", new=AsyncMock(return_value=1)),
    ):
        report = await delete_account_data("u1")

    assert report.identity_deleted is False
    assert any(error.startswith("avatar:") for error in report.errors)
    users.delete.assert_not_called()
