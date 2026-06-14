# X-hale — Boot Instructions

Physical Android device via USB. Everything runs in **one terminal**.

---

## Start

```powershell
# 1. Verify ADB sees the phone
adb devices
# Expected: one line ending in "device" — if "unauthorized", unlock phone and accept the USB debugging prompt

# 2. Forward backend port to phone
adb reverse tcp:7860 tcp:7860
# Expected output: 7860

# 3. Start backend (no --reload — it watches the directory and restarts on any file change,
#    which would drop active SSE connections mid-chat; logs go to home dir for the same reason)
Start-Process `
  -FilePath "C:\Users\steve\smoking2.0\rag_backend2.0\.venv\Scripts\uvicorn.exe" `
  -ArgumentList "app.main:app --port 7860" `
  -WorkingDirectory "C:\Users\steve\smoking2.0\rag_backend2.0" `
  -RedirectStandardOutput "C:\Users\steve\uvicorn.log" `
  -RedirectStandardError "C:\Users\steve\uvicorn_err.log" `
  -NoNewWindow
Start-Sleep 5
Invoke-RestMethod http://localhost:7860/health
# Expected: {"status":"ok", ...}

# 4. Run Flutter
Set-Location "C:\Users\steve\smoking2.0"
flutter run --dart-define=HAILEY_API_URL=http://localhost:7860
```

---

## Stop

```powershell
# Press q in the terminal first, then:
Stop-Process -Name uvicorn -Force -ErrorAction SilentlyContinue
adb reverse --remove tcp:7860
```

---

## Hot reload shortcuts (while flutter run is active)

| Key | Action |
|-----|--------|
| `r` | Hot reload — fastest, preserves state |
| `R` | Hot restart — full restart, clears state |
| `q` | Quit |

---

## Troubleshooting

**Hailey doesn't respond**
```powershell
adb reverse tcp:7860 tcp:7860              # re-forward if phone reconnected
Get-Content "C:\Users\steve\uvicorn.log" -Tail 20   # check backend logs
```

**Backend crashed mid-session**
```powershell
Stop-Process -Name uvicorn -Force -ErrorAction SilentlyContinue
Start-Process `
  -FilePath "C:\Users\steve\smoking2.0\rag_backend2.0\.venv\Scripts\uvicorn.exe" `
  -ArgumentList "app.main:app --port 7860" `
  -WorkingDirectory "C:\Users\steve\smoking2.0\rag_backend2.0" `
  -RedirectStandardOutput "C:\Users\steve\uvicorn.log" `
  -RedirectStandardError "C:\Users\steve\uvicorn_err.log" `
  -NoNewWindow
Start-Sleep 5
Invoke-RestMethod http://localhost:7860/health
```

**Backend starts then exits immediately** — check `.env` is present and all keys are filled:
```powershell
Set-Location "C:\Users\steve\smoking2.0\rag_backend2.0"
.\.venv\Scripts\python -c "from app.config import settings; print('Config OK')"
```

**Flutter build errors**
```powershell
flutter pub get          # restore packages
flutter clean            # nuclear option — full rebuild on next run
```

**Phone shows "unauthorized"** — unlock screen, accept USB debugging prompt, then `adb devices` again.

**Multiple devices connected** — add `-d <device-id>` to `flutter run`. Get IDs with `flutter devices`.
