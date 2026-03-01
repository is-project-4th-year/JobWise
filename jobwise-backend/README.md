# JobWise Backend

Python FastAPI backend for interview transcription and analysis.

## Features

- ✅ Whisper ASR (fine-tuned for Kenyan English)
- ✅ Rule-based feedback generation
- ✅ Firebase integration
- ✅ Auto-processing of pending sessions (every 30s)

## Quick Start

1. **Install dependencies:**
   ```bash
   python -m venv venv
   venv\Scripts\activate  # Windows
   pip install -r requirements.txt
   ```

2. **Setup files:**
   - Copy `whisper-kenyan-finetuned` folder to `models/`
   - Download `serviceAccountKey.json` from Firebase
   - Create `.env` file (see template in docs)

3. **Run server:**
   ```bash
   python -m app.main
   ```

4. **Test:**
   - Health: http://localhost:8000/health
   - Docs: http://localhost:8000/docs

## API Endpoints

- `GET /` - Health check
- `GET /health` - Detailed status
- `POST /process` - Manually trigger processing
- `GET /sessions/pending` - View pending sessions

## How It Works

1. Flutter app uploads audio → Firebase Storage
2. Backend polls Firestore every 30s for pending sessions
3. Downloads audio → Transcribes with Whisper
4. Calculates metrics → Generates scores & feedback
5. Updates Firestore with results
6. Flutter app displays results

## Testing

```bash
# Check health
curl http://localhost:8000/health

# Process pending
curl -X POST http://localhost:8000/process

# View pending count
curl http://localhost:8000/sessions/pending
```
```

---

## 8. Run the Backend

```bash
# Activate virtual environment
venv\Scripts\activate  # Windows
source venv/bin/activate  # Mac/Linux

# Run server
python -m app.main
```

Server will start at `http://localhost:8000`

**Check logs for:**
- ✅ Firebase initialized
- ✅ Whisper model loaded successfully
- ✅ Auto-processing 