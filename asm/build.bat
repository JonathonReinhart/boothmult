SET confpath=%cd%\dosbox_kcpsm3.conf

echo %confpath%

"C:\Program Files (x86)\DOSBox-0.74\DOSBox.exe" -userconf -conf %confpath% -c "KCPSM3.EXE program.psm"

