Set EXE=iPFX.exe
Set TOOL="signtool.exe"
Set TS=http://timestamp.verisign.com/scripts/timstamp.dll
upx %EXE%
%TOOL% sign /a /t %TS% %EXE%
