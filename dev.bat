@echo off
:: Career Pilot — 快速啟動 (Android emulator 預設)
:: 雙擊此檔案即可同時啟動後端 + Flutter
powershell.exe -NoLogo -ExecutionPolicy Bypass -File "%~dp0dev.ps1" %*
