from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore, storage
from transformers import WhisperProcessor, WhisperForConditionalGeneration
import torch
import librosa
import soundfile as sf
import os
import tempfile
import asyncio
import logging
from datetime import datetime
from typing import List
import re
from jiwer import wer

from app.config import get_settings
from app.models import (
    ProcessingResult, Metrics, Scores, Feedback, FillerWords
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize settings
settings = get_settings()

# Initialize FastAPI
app = FastAPI(
    title="JobWise Backend",
    description="Interview transcription and analysis API",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for services
db = None
bucket = None
whisper_model = None
whisper_processor = None
device = None

# ============================================================================
# INITIALIZATION
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    global db, bucket, whisper_model, whisper_processor, device
    
    logger.info("🚀 Starting JobWise Backend...")
    
    # Initialize Firebase
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.firebase_credentials)
            firebase_admin.initialize_app(cred, {
                'storageBucket': settings.firebase_storage_bucket
            })
        
        db = firestore.client()
        bucket = storage.bucket()
        logger.info("✅ Firebase initialized")
    except Exception as e:
        logger.error(f"❌ Firebase initialization failed: {e}")
        raise
    
    # Load Whisper model
    try:
        device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"📱 Using device: {device}")
        
        logger.info(f"📥 Loading Whisper model from {settings.whisper_model_path}...")
        whisper_processor = WhisperProcessor.from_pretrained(settings.whisper_model_path)
        whisper_model = WhisperForConditionalGeneration.from_pretrained(settings.whisper_model_path)
        whisper_model = whisper_model.to(device)
        whisper_model.eval()
        
        logger.info("✅ Whisper model loaded successfully")
    except Exception as e:
        logger.error(f"❌ Whisper model loading failed: {e}")
        raise
    
    # Start auto-processing loop
    asyncio.create_task(auto_process_loop())
    logger.info("✅ Auto-processing enabled (checks every 30s)")
    logger.info("🎉 Backend ready!")

# ============================================================================
# TRANSCRIPTION SERVICE
# ============================================================================

def transcribe_audio(audio_path: str) -> dict:
    """Transcribe audio file using Whisper"""
    try:
        # Load audio
        audio, sr = librosa.load(audio_path, sr=16000)
        duration = len(audio) / sr
        
        # Prepare input
        input_features = whisper_processor(
            audio,
            sampling_rate=16000,
            return_tensors="pt"
        ).input_features.to(device)
        
        # Generate transcription
        with torch.no_grad():
            predicted_ids = whisper_model.generate(input_features)
        
        transcript = whisper_processor.batch_decode(
            predicted_ids,
            skip_special_tokens=True
        )[0]
        
        return {
            "transcript": transcript.strip(),
            "duration": duration
        }
    
    except Exception as e:
        logger.error(f"❌ Transcription failed: {e}")
        raise

# ============================================================================
# METRICS CALCULATION
# ============================================================================

def count_filler_words(text: str) -> FillerWords:
    """Count filler words in transcript"""
    text_lower = text.lower()
    
    um_count = len(re.findall(r'\bum\b', text_lower))
    uh_count = len(re.findall(r'\buh\b', text_lower))
    like_count = len(re.findall(r'\blike\b', text_lower))
    you_know_count = len(re.findall(r'\byou know\b', text_lower))
    basically_count = len(re.findall(r'\bbasically\b', text_lower))
    actually_count = len(re.findall(r'\bactually\b', text_lower))
    
    total = um_count + uh_count + like_count + you_know_count + basically_count + actually_count
    
    return FillerWords(
        um=um_count,
        uh=uh_count,
        like=like_count,
        you_know=you_know_count,
        basically=basically_count,
        actually=actually_count,
        total=total
    )

def calculate_metrics(transcript: str, duration: float) -> Metrics:
    """Calculate speech metrics"""
    words = transcript.split()
    word_count = len(words)
    
    # Words per minute
    minutes = duration / 60
    wpm = word_count / minutes if minutes > 0 else 0
    
    # Filler words
    filler_words = count_filler_words(transcript)
    
    # Long pauses (simplified - based on transcript patterns)
    long_pauses = transcript.count('...') + transcript.count('...')
    
    return Metrics(
        word_count=word_count,
        words_per_minute=round(wpm, 1),
        duration_seconds=round(duration, 1),
        filler_word_count=filler_words.total,
        filler_words=filler_words,
        long_pauses_count=long_pauses
    )

# ============================================================================
# SCORING (RULE-BASED)
# ============================================================================

def calculate_scores(metrics: Metrics, transcript: str) -> Scores:
    """Calculate scores based on metrics (rule-based)"""
    
    # Clarity score (based on filler words)
    filler_ratio = metrics.filler_word_count / max(metrics.word_count, 1)
    if filler_ratio < 0.02:
        clarity = 90
    elif filler_ratio < 0.05:
        clarity = 75
    elif filler_ratio < 0.10:
        clarity = 60
    else:
        clarity = 40
    
    # Pacing score (based on WPM - ideal is 120-150)
    wpm = metrics.words_per_minute
    if 120 <= wpm <= 150:
        pacing = 95
    elif 100 <= wpm <= 170:
        pacing = 80
    elif 80 <= wpm <= 190:
        pacing = 65
    else:
        pacing = 50
    
    # Structure score (based on length and coherence)
    if metrics.word_count < 20:
        structure = 40
    elif metrics.word_count < 50:
        structure = 60
    elif metrics.word_count < 100:
        structure = 75
    else:
        structure = 85
    
    # Confidence score (inverse of long pauses)
    pause_ratio = metrics.long_pauses_count / max(metrics.word_count / 50, 1)
    if pause_ratio < 1:
        confidence = 90
    elif pause_ratio < 2:
        confidence = 75
    elif pause_ratio < 3:
        confidence = 60
    else:
        confidence = 45
    
    # Overall score (weighted average)
    overall = int(
        clarity * 0.3 +
        pacing * 0.3 +
        structure * 0.2 +
        confidence * 0.2
    )
    
    return Scores(
        overall=overall,
        clarity=clarity,
        pacing=pacing,
        structure=structure,
        confidence=confidence
    )

# ============================================================================
# FEEDBACK GENERATION (RULE-BASED)
# ============================================================================

def generate_feedback(metrics: Metrics, scores: Scores, transcript: str) -> Feedback:
    """Generate rule-based feedback"""
    strengths = []
    improvements = []
    suggestions = []
    
    # Analyze clarity
    if scores.clarity >= 80:
        strengths.append("Clear articulation with minimal filler words")
    elif scores.clarity < 60:
        improvements.append(f"Reduce filler words (found {metrics.filler_word_count} instances)")
        suggestions.append("Practice pausing instead of using filler words like 'um' and 'uh'")
    
    # Analyze pacing
    wpm = metrics.words_per_minute
    if 120 <= wpm <= 150:
        strengths.append("Excellent speaking pace - clear and easy to follow")
    elif wpm < 100:
        improvements.append(f"Speaking pace is slow ({wpm:.0f} WPM)")
        suggestions.append("Try to speak more confidently and maintain a steady pace")
    elif wpm > 170:
        improvements.append(f"Speaking pace is fast ({wpm:.0f} WPM)")
        suggestions.append("Slow down to ensure clarity - aim for 120-150 words per minute")
    
    # Analyze structure
    if scores.structure >= 75:
        strengths.append("Good response length with adequate detail")
    else:
        improvements.append("Response could be more detailed")
        suggestions.append("Aim for 50-100 words to fully address the question")
    
    # Analyze confidence
    if scores.confidence >= 80:
        strengths.append("Confident delivery with minimal hesitation")
    else:
        improvements.append("Hesitation detected - work on confidence")
        suggestions.append("Practice your responses to build confidence and reduce pauses")
    
    # Default suggestions if none generated
    if not strengths:
        strengths.append("You completed the interview question")
    
    if not suggestions:
        suggestions.append("Keep practicing to improve your interview skills")
    
    return Feedback(
        strengths=strengths,
        improvements=improvements,
        suggestions=suggestions
    )

# ============================================================================
# FIREBASE OPERATIONS
# ============================================================================

def get_pending_sessions() -> List[dict]:
    """Get all sessions with status='pending'"""
    sessions = []
    users_ref = db.collection('users')
    
    for user_doc in users_ref.stream():
        user_id = user_doc.id
        sessions_ref = users_ref.document(user_id).collection('sessions')
        
        # Query pending sessions
        query = sessions_ref.where('status', '==', 'pending')
        
        for session_doc in query.stream():
            session_data = session_doc.to_dict()
            session_data['id'] = session_doc.id
            session_data['user_id'] = user_id
            sessions.append(session_data)
    
    return sessions

def update_session_status(user_id: str, session_id: str, status: str, error: str = None):
    """Update session status"""
    session_ref = (
        db.collection('users')
        .document(user_id)
        .collection('sessions')
        .document(session_id)
    )
    
    update_data = {
        'status': status,
        'updatedAt': firestore.SERVER_TIMESTAMP
    }
    
    if error:
        update_data['error'] = error
    
    session_ref.update(update_data)

def update_session_results(user_id: str, session_id: str, result: ProcessingResult):
    """Update session with processing results"""
    session_ref = (
        db.collection('users')
        .document(user_id)
        .collection('sessions')
        .document(session_id)
    )
    
    update_data = {
        'status': 'completed',
        'transcript': result.transcript,
        'scores': result.scores.model_dump(),
        'metrics': result.metrics.model_dump(),
        'feedback': result.feedback.model_dump(),
        'processedAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP
    }
    
    session_ref.update(update_data)
    logger.info(f"✅ Updated session {session_id} with results")

def download_audio(audio_url: str) -> str:
    """Download audio from Firebase Storage"""
    try:
        from urllib.parse import unquote
        
        # Extract blob path from URL
        # Format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media
        parts = audio_url.split('/o/')[1].split('?')[0]
        blob_path = unquote(parts)  # Decode URL encoding
        
        # Download from Storage
        blob = bucket.blob(blob_path)
        
        # Create temp file
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.m4a')
        temp_file.close()  # Close file handle before downloading
        blob.download_to_filename(temp_file.name)
        
        logger.info(f"✅ Downloaded audio to {temp_file.name}")
        return temp_file.name
    
    except Exception as e:
        logger.error(f"❌ Audio download failed: {e}")
        raise

# ============================================================================
# PROCESSING PIPELINE
# ============================================================================

def process_session(session: dict):
    """Process a single session"""
    user_id = session['user_id']
    session_id = session['id']
    
    logger.info(f"🔄 Processing session {session_id} for user {user_id}")
    
    audio_file = None
    
    try:
        # Update status to processing
        update_session_status(user_id, session_id, 'processing')
        
        # Download audio
        audio_url = session.get('audio_url')
        if not audio_url:
            raise ValueError("No audio URL found")
        
        audio_file = download_audio(audio_url)
        
        # Transcribe
        logger.info("🎤 Transcribing audio...")
        transcription_result = transcribe_audio(audio_file)
        transcript = transcription_result['transcript']
        duration = transcription_result['duration']
        
        # Calculate metrics
        logger.info("📊 Calculating metrics...")
        metrics = calculate_metrics(transcript, duration)
        
        # Calculate scores
        logger.info("🎯 Calculating scores...")
        scores = calculate_scores(metrics, transcript)
        
        # Generate feedback
        logger.info("💬 Generating feedback...")
        feedback = generate_feedback(metrics, scores, transcript)
        
        # Create result
        result = ProcessingResult(
            session_id=session_id,
            status='completed',
            transcript=transcript,
            scores=scores,
            metrics=metrics,
            feedback=feedback,
            processed_at=datetime.now()
        )
        
        # Update Firestore
        update_session_results(user_id, session_id, result)
        
        logger.info(f"✅ Session {session_id} processed successfully!")
        logger.info(f"   Overall Score: {scores.overall}/100")
        logger.info(f"   Transcript: {transcript[:100]}...")
    
    except Exception as e:
        logger.error(f"❌ Session {session_id} processing failed: {e}")
        update_session_status(user_id, session_id, 'failed', str(e))
    
    finally:
        # Clean up temp file
        if audio_file and os.path.exists(audio_file):
            try:
                os.remove(audio_file)
            except:
                pass

# ============================================================================
# AUTO-PROCESSING LOOP
# ============================================================================

async def auto_process_loop():
    """Continuously check for pending sessions"""
    while True:
        try:
            pending = get_pending_sessions()
            
            if pending:
                logger.info(f"🔄 Found {len(pending)} pending session(s)")
                for session in pending:
                    process_session(session)
            
            # Wait 30 seconds before next check
            await asyncio.sleep(30)
        
        except Exception as e:
            logger.error(f"❌ Auto-process loop error: {e}")
            await asyncio.sleep(60)  # Wait longer on error

# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.get("/")
def root():
    """Health check"""
    return {
        "status": "healthy",
        "service": "JobWise Backend",
        "version": "1.0.0"
    }

@app.get("/health")
def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "firebase": "connected" if db else "disconnected",
            "whisper": "loaded" if whisper_model else "not loaded",
            "device": device
        }
    }

@app.post("/process")
def trigger_processing():
    """Manually trigger processing of pending sessions"""
    try:
        pending = get_pending_sessions()
        
        if not pending:
            return {"message": "No pending sessions", "count": 0}
        
        for session in pending:
            process_session(session)
        
        return {
            "message": f"Processed {len(pending)} session(s)",
            "count": len(pending)
        }
    
    except Exception as e:
        logger.error(f"❌ Manual processing failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/sessions/pending")
def get_pending_count():
    """Get count of pending sessions"""
    try:
        pending = get_pending_sessions()
        return {
            "pending_count": len(pending),
            "sessions": [
                {
                    "id": s['id'],
                    "user_id": s['user_id'],
                    "created_at": s.get('createdAt')
                }
                for s in pending
            ]
        }
    except Exception as e:
        logger.error(f"❌ Failed to get pending sessions: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# RUN SERVER
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )