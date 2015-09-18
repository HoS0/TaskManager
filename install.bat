@echo off
call msiexec.exe /i node-v4.0.0-x64.msi /qn
call npm install qckwinsvc -g
call npm install -g coffee-script
call coffee -o lib -c src
call qckwinsvc --name HoSTaskManager --description Task manager for HoS environment --script %~dp0\lib\app.js --startImmediately no