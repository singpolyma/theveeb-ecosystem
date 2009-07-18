#!/usr/bin/makensis

!include "EnvVarUpdate.nsi"

Name "The Veeb Ecosystem"
OutFile ..\tve.exe
BrandingText " "
InstallColors /windows
InstallDir $PROGRAMFILES\TheVeeb
LicenseData EULA.txt
LicenseForceSelection checkbox "I Agree"
RequestExecutionLevel admin
XPStyle on
SetCompressor /SOLID LZMA
#AddBrandingImage bottom height 5
#SetBrandingImage
#Icon theveeb.ico

VIAddVersionKey "ProductName" "The Veeb Ecosystem"
VIAddVersionKey "CompanyName" "The Veeb"
VIAddVersionKey "FileVersion" "1.0"
VIProductVersion "1.0.0.0"

Page license
Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "The Veeb Ecosystem"
	# Environment variables
	WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" TVEROOT "$INSTDIR"
	SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
	${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$INSTDIR\bin"
	${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$INSTDIR\usr\bin"
	${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$INSTDIR\usr\local\bin"

	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVE" "DisplayName" "The Veeb Ecosystem"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVE" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVE" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVE" "Publisher" "The Veeb"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVE" "URLInfoAbout" "http://theveeb.com"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVE" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVE" "NoRepair" 1

	SetOutPath $INSTDIR
	File /a /r dist\*.*
	WriteUninstaller $INSTDIR\uninstall.exe
SectionEnd

Section "Uninstall"
	Delete $INSTDIR\uninstall.exe
	RMDir /r /REBOOTOK $INSTDIR\bin
	RMDir /r /REBOOTOK $INSTDIR\usr
	RMDir /REBOOTOK $INSTDIR
	DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" TVEROOT
	SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
	${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\bin"
	${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\usr\bin"
	${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\usr\local\bin"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVE"
SectionEnd
