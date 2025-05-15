; NASDS Installer Script
; Created by Augment Agent

!include "MUI2.nsh"
!include "FileFunc.nsh"

; General settings
Name "NASDS"
OutFile "NASDS_Setup.exe"
InstallDir "$PROGRAMFILES64\NASDS"
InstallDirRegKey HKLM "Software\NASDS" "Install_Dir"
RequestExecutionLevel admin

; Interface settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\win.bmp"
!define MUI_HEADERIMAGE_RIGHT

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

; Installer sections
Section "Install"
  SetOutPath "$INSTDIR"
  
  ; Copy all files from the Release folder
  File /r "build\windows\x64\runner\Release\*.*"
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\NASDS"
  CreateShortcut "$SMPROGRAMS\NASDS\NASDS.lnk" "$INSTDIR\nasds.exe"
  CreateShortcut "$DESKTOP\NASDS.lnk" "$INSTDIR\nasds.exe"
  
  ; Write registry keys for uninstaller
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NASDS" "DisplayName" "NASDS"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NASDS" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NASDS" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NASDS" "NoRepair" 1
  
  ; Get estimated size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NASDS" "EstimatedSize" "$0"
SectionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove files and uninstaller
  RMDir /r "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\NASDS\NASDS.lnk"
  RMDir "$SMPROGRAMS\NASDS"
  Delete "$DESKTOP\NASDS.lnk"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\NASDS"
  DeleteRegKey HKLM "Software\NASDS"
SectionEnd
