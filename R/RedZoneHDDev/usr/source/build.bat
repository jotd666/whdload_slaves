@echo off
cd /D %~PD0
wmake.py
set X=%ERRORLEVEL%
pause
exit %X%
