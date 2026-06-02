import os
os.environ["ALLOW_CHROMA_TELEMETRY"] = "FALSE" 

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from apiRoutes import router

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)
