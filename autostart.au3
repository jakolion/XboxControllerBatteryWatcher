const $AUTOSTART_REGISTRY_PATH = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
const $AUTOSTART_REGISTRY_NAME = "XboxControllerBatteryWatcher"

local $autostartTrayItem



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



func AutostartClicked()
	SetAutostart ( not GetAutostart() )
	if GetAutostart() then
		TrayItemSetState( $autostartTrayItem, $TRAY_CHECKED )
	else
		TrayItemSetState( $autostartTrayItem, $TRAY_UNCHECKED )
	endif
endfunc



func GetAutostart()
	local $path = RegRead( $AUTOSTART_REGISTRY_PATH, $AUTOSTART_REGISTRY_NAME )
	if $path == "" Then
		return false
	else
		if $path == GetApplicationPath() then
			return true
		else
			SetAutostart( true )
			return true
		endif
	endif
endfunc



func SetAutostart( $enable )
	if $enable then
		if StringRight( GetApplicationPath(), 16 ) <> "\autoit3_x64.exe" then
			RegWrite( $AUTOSTART_REGISTRY_PATH, $AUTOSTART_REGISTRY_NAME, "REG_SZ", GetApplicationPath() )
		endif
	else
		RegDelete( $AUTOSTART_REGISTRY_PATH, $AUTOSTART_REGISTRY_NAME )
	endif
endfunc
