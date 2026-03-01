from pydantic import BaseModel, Field
from typing import Dict, List, Optional
from datetime import datetime

class FillerWords(BaseModel):
    um: int = 0
    uh: int = 0
    like: int = 0
    you_know: int = 0
    basically: int = 0
    actually: int = 0
    total: int = 0

class Metrics(BaseModel):
    word_count: int
    words_per_minute: float
    duration_seconds: float
    filler_word_count: int
    filler_words: FillerWords
    long_pauses_count: int

class Scores(BaseModel):
    overall: int
    clarity: int
    pacing: int
    structure: int
    confidence: int

class Feedback(BaseModel):
    strengths: List[str]
    improvements: List[str]
    suggestions: List[str]

class ProcessingResult(BaseModel):
    session_id: str
    status: str
    transcript: str
    scores: Scores
    metrics: Metrics
    feedback: Feedback
    processed_at: datetime
