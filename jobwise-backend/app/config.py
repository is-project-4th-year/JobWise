from pydantic_settings import BaseSettings
from functools import lru_cache
import os

class Settings(BaseSettings):
    # Firebase
    firebase_credentials: str
    firebase_storage_bucket: str
    
    # Model paths
    whisper_model_path: str
    
    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = True
    
    # Processing
    max_audio_duration: int = 300
    min_audio_duration: int = 5
    temp_audio_dir: str = "./temp"
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()

# Ensure temp directory exists
settings = get_settings()
os.makedirs(settings.temp_audio_dir, exist_ok=True)