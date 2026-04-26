# GusKitchenAI

Open-source smart kitchen display powered by Raspberry Pi, Python, and AI. Includes calendar, recipes, voice control, and custom kitchen apps.

## 🚀 Getting Started

### 1. Fix permissions (if needed)

If you run into Git permission issues inside the devcontainer:

```bash
sudo chown -R ubuntu:ubuntu /workspaces/GusKitchenAI
```

### 2. Install dependencies

```bash
pip install --break-system-packages -r requirements.txt
```

### 3. Run the backend server

```bash
python3 -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

### 4. Open in browser

* Main app: http://localhost:8000
* Health check: http://localhost:8000/health
* API docs: http://localhost:8000/docs
