from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/", response_class=HTMLResponse)
def root():
    with open("index.html") as f:
        return f.read()

@app.get("/calendar")
def get_calendar():
    return [
        {"time": "9:00 AM", "event": "Team Meeting"},
        {"time": "12:00 PM", "event": "Lunch"},
        {"time": "6:00 PM", "event": "Cook Dinner"}
    ]