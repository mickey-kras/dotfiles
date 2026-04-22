@echo off
if exist "%ProgramFiles%\Git\bin\bash.exe" (
  "%ProgramFiles%\Git\bin\bash.exe" "%USERPROFILE%\.local\bin\bw-login" %*
  exit /b %ERRORLEVEL%
)

bash "%USERPROFILE%\.local\bin\bw-login" %*
