@echo off
title Rodjali - Backend API Server
echo ====================================================
echo        MEMULAI BACKEND RODJALI (LARAVEL + MYSQL)
echo ====================================================

:: Pastikan MySQL XAMPP aktif
tasklist /FI "IMAGENAME eq mysqld.exe" 2>NUL | find /I /N "mysqld.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [OK] MySQL XAMPP sudah aktif.
) else (
    echo [INFO] Menyalakan MySQL XAMPP...
    start /B "" "C:\xampp\mysql\bin\mysqld.exe" --defaults-file=C:\xampp\mysql\bin\my.ini --standalone
    timeout /t 3 >nul
)

cd /d "%~dp0\rodjali_backend"
echo [INFO] Menjalankan Laravel API di http://127.0.0.1:8000 ...
php artisan serve --host=0.0.0.0 --port=8000
pause
