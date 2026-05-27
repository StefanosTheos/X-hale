"""
FastAPI dependency helpers for authentication.
Import `get_current_user` and use it as `Depends(get_current_user)` on any protected endpoint.
"""
from __future__ import annotations

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.auth.appwrite_jwt import verify_appwrite_jwt

_bearer = HTTPBearer(auto_error=True)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
) -> str:
    """
    Extract and verify the Appwrite JWT from the Authorization header.
    Returns the authenticated user_id on success.
    Raises HTTP 401 if the token is missing or invalid.
    """
    token = credentials.credentials
    user_id = await verify_appwrite_jwt(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session token.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user_id
