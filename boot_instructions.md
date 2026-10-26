# X-hale Local Dev — Boot Instructions

Step-by-step checklist for testing the app on a physical Android device
connected via USB cable. Follow this every time you start a dev session.

---

## Every-session checklist

### Step 1 — Plug in the phone and verify ADB sees it

```powershell
adb devices
```

Expected output:
```
List of devices attached
XXXXXXXXXXXXXXXX    device
```

If it shows `unauthorized`, unlock your phone and accept the USB debugging prompt.

---

### Step 2 — Forward the backend port to the phone via USB

This is the key step that lets the Flutter app on your phone reach the
backend running on your laptop — no WiFi required.

```powershell
adb reverse tcp:7860 tcp:7860
```

Expected output: `7860`

> This makes `http://localhost:7860` on the Android device route to
> `localhost:7860` on your laptop. Re-run this if the phone disconnects.

---

### Step 3 — Start the Python backend

Open a **dedicated terminal** (keep it open for the whole session):

```powershell
Set-Location rag_backend2.0  # from the repository root
.\.venv\Scripts\uvicorn app.main:app --reload --port 7860
```

Wait for this line before continuing:
```
INFO:     Application startup complete.
```

> `--reload` watches for file changes and restarts automatically.
> Remove it for a stable test session if you're not editing backend code.

**Verify the backend is reachable from the laptop:**
```powershell
Invoke-RestMethod http://localhost:7860/health
```
Expected: `{"status":"ok", ...}`

---

### Step 4 — Run the Flutter app

Open a **second terminal** (leave the backend terminal running):

```powershell
# Open this terminal at the repository root
flutter run --dart-define=HAILEY_API_URL=http://localhost:7860
```

Flutter will build, install on your connected phone, and launch the app.

> If you have multiple devices connected (emulator + phone), add `-d <device-id>`.
> Get device IDs with `flutter devices`.

---

### Step 5 — Hot reload / restart shortcuts

While `flutter run` is running in the terminal:

| Key | Action |
|-----|--------|
| `r` | Hot reload (preserves app state — fastest) |
| `R` | Hot restart (full restart, clears state) |
| `q` | Quit |

---

## Stopping the session

1. Press `q` in the Flutter terminal to quit.
2. `Ctrl+C` in the backend terminal to stop uvicorn.
3. Optionally remove the ADB port forward:
   ```powershell
   adb reverse --remove tcp:7860
   ```

---

## Troubleshooting

### "Connection refused" or Hailey doesn't respond
- Is the backend running? Check Step 3 terminal for errors.
- Did you run `adb reverse`? Re-run Step 2.
- Did the phone USB disconnect and reconnect? Re-run Steps 1 and 2.

### ADB device shows "offline" or "unauthorized"
- Unlock the phone screen and accept the USB debugging prompt.
- Try a different USB cable (data cable, not charge-only).
- Run `adb kill-server` then `adb start-server`, then `adb devices`.

### Backend starts but crashes immediately
- Check that `.env` is present and all keys are filled in.
- Run:
  ```powershell
  Set-Location rag_backend2.0  # from the repository root
  .\.venv\Scripts\python.exe -c "from app.config import settings; print('Config OK')"
  ```

### Flutter build errors
- Run `flutter pub get` to restore packages.
- Run `flutter clean` then `flutter run ...` for a full rebuild.

### Phone shows "Install failed" or app doesn't launch
- Enable **Install via USB** in Developer Options.
- On some Samsung devices: Developer Options → **USB configuration → MTP**.

---

## Quick reference — full session in one copy-paste

**Terminal 1 (backend):**
```powershell
adb reverse tcp:7860 tcp:7860
Set-Location rag_backend2.0  # from the repository root
.\.venv\Scripts\uvicorn app.main:app --reload --port 7860
```

**Terminal 2 (Flutter — after backend shows "startup complete"):**
```powershell
# Open this terminal at the repository root
flutter run --dart-define=HAILEY_API_URL=http://localhost:7860
```
