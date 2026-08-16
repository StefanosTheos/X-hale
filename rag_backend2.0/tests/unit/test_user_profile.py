"""User-profile normalization tests."""
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest

from app.tools.user_profile import get_user_profile


@pytest.mark.asyncio
@pytest.mark.parametrize("data", [{"locale": None}, {"language": None, "locale": None}, {}])
async def test_missing_or_null_locale_defaults_to_english(data):
    row = SimpleNamespace(data={"userId": "u1", **data}, createdat=None, updatedat=None)
    db = MagicMock()
    db.list_rows.return_value = SimpleNamespace(rows=[row])
    with patch("app.tools.user_profile._build_db", return_value=(db, "db")):
        profile = await get_user_profile("u1")

    assert profile.locale == "en"
