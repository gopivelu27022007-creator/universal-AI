@echo off
title Universal AI Chatbot
echo Starting Universal AI Chatbot on http://localhost:8080 ...
start /b powershell -ExecutionPolicy Bypass -File .\serve.ps1
timeout /t 1 /nobreak >nul
start "" "http://localhost:8080"
exit
