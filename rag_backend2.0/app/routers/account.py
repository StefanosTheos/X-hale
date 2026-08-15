"""Authenticated, explicit account-wide deletion endpoint."""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.auth.dependencies import get_current_user
from app.services.account_deletion import delete_account_data

router = APIRouter(prefix="/account", tags=["account"])


class DeleteAccountRequest(BaseModel):
    confirmation: str = Field(description='Must be exactly "DELETE".')


@router.delete("/", status_code=status.HTTP_200_OK)
async def delete_account(
    request: DeleteAccountRequest,
    user_id: str = Depends(get_current_user),
):
    if request.confirmation != "DELETE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Account deletion requires confirmation="DELETE".',
        )
    report = await delete_account_data(user_id)
    if report.errors or not report.identity_deleted:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"message": "Account deletion was incomplete and can be retried.", **report.to_dict()},
        )
    return {"deleted": True, **report.to_dict()}
