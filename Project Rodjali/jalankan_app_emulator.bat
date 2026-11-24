@echo off
title Rodjali - Flutter App (Android Emulator)
echo ====================================================
echo        MEMULAI RODJALI MOBILE APP DI ANDROID EMULATOR
echo ====================================================

echo [INFO] Menyalakan emulator Medium_Phone...
start "" flutter emulators --launch Medium_Phone
echo [INFO] Menunggu emulator siap (15 detik)...
timeout /t 15 >nul

cd /d "%~dp0\rodjali_app"
flutter run -d Medium_Phone --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
pause
