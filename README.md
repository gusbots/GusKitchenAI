# GusKitchenAI

Open-source smart kitchen display powered by Raspberry Pi, Python, and AI. Includes calendar, recipes, voice control, and custom kitchen apps.

## 🚀 Run with Docker (Recommended)

```bash
git clone https://github.com/your-repo/GusKitchenAI.git
cd GusKitchenAI
docker compose up --build
```

Then open:

-   App: http://localhost:8000\
-   Health: http://localhost:8000/health\
-   API docs: http://localhost:8000/docs

## 💻 Development (VS Code Devcontainer)

1.  Open the project in VS Code\
2.  Reopen in Container\
3.  Run the backend:

``` bash
python3 -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

Then open:

-   App: http://localhost:8000

## 🛠️ Troubleshooting

### Fix permissions (if needed)

If you run into Git permission issues inside the devcontainer:

```bash
sudo chown -R ubuntu:ubuntu /workspaces/GusKitchenAI
```
