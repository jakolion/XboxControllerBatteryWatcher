#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Res_Description=Xbox Controller Battery Watcher
#AutoIt3Wrapper_Res_Fileversion=1.5.0.0
#AutoIt3Wrapper_Res_File_Add=iconController\iconControllerFullSmall.jpg, rt_rcdata, iconFull
#AutoIt3Wrapper_Res_File_Add=iconController\iconControllerMediumSmall.jpg, rt_rcdata, iconMedium
#AutoIt3Wrapper_Res_File_Add=iconController\iconControllerLowSmall.jpg, rt_rcdata, iconLow
#AutoIt3Wrapper_Res_File_Add=iconController\iconControllerEmptySmall.jpg, rt_rcdata, iconEmpty
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Array.au3>
#include <TrayConstants.au3>
#include <String.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Timers.au3>
#include <resources.au3>

const $XBOX_CONTROLLER_TYPE_DISCONNECTED = 0
const $XBOX_CONTROLLER_TYPE_WIRED = 1
const $XBOX_CONTROLLER_TYPE_ALKALINE = 2
const $XBOX_CONTROLLER_TYPE_NIMH = 3
const $XBOX_CONTROLLER_TYPE_UNKNOWN = 255
const $XBOX_CONTROLLER_LEVEL_EMPTY = 0
const $XBOX_CONTROLLER_LEVEL_LOW = 1
const $XBOX_CONTROLLER_LEVEL_MEDIUM = 2
const $XBOX_CONTROLLER_LEVEL_FULL = 3

const $AUTOSTART_REGISTRY_PATH = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
const $AUTOSTART_REGISTRY_NAME = "XboxControllerBatteryWatcher"

const $POLLING_DELAY = 5000
const $MESSAGE_SHOW_DELAY = 10000

const $FADING_REFRESH_RATE = 33; 16 = 60fps | 33 = 30fps
const $FADING_STEPS = 256
const $FADING_TARGET_SHOW = $FADING_STEPS - 1
const $FADING_TARGET_HIDE = 0
const $FADING_TARGET_TRANSPARENT = 128
const $FADING_IN_SPEED = 500
const $FADING_OUT_SPEED = 250
const $FADING_IN_STEPS_PER_REFRESH = $FADING_STEPS / ( $FADING_IN_SPEED / $FADING_REFRESH_RATE )
const $FADING_OUT_STEPS_PER_REFRESH = $FADING_STEPS / ( $FADING_OUT_SPEED / $FADING_REFRESH_RATE )

const $SHOW_INFO_ON_FULLSCREEN_EXIT = false

const $INI_FILE_NAME = "XboxControllerBatteryWatcher.ini"
const $INI_HOTKEY_SECTION_NAME = "hotkey"
const $INI_HOTKEY_KEYS_NAME = "keys"
const $INI_HOTKEY_KEYS_DEFAULT = 0x11
const $INI_HOTKEY_COMMAND_NAME = "command"
const $INI_HOTKEY_COMMAND_DEFAULT = "start steam://open/bigpicture"

const $INI_HEADER_TEXT = "" & _
";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;" & @CRLF & _
";;                                              ;;" & @CRLF & _
";;  Xbox Controller Battery Watcher Hotkeys     ;;" & @CRLF & _
";;  =======================================     ;;" & @CRLF & _
";;                                              ;;" & @CRLF & _
";;  These are the values for the Xbox           ;;" & @CRLF & _
";;  Controller buttons:                         ;;" & @CRLF & _
";;                                              ;;" & @CRLF & _
";;  GAMEPAD_DPAD_UP         0x0001              ;;" & @CRLF & _
";;  GAMEPAD_DPAD_DOWN       0x0002              ;;" & @CRLF & _
";;  GAMEPAD_DPAD_LEFT       0x0004              ;;" & @CRLF & _
";;  GAMEPAD_DPAD_RIGHT      0x0008              ;;" & @CRLF & _
";;  GAMEPAD_START           0x0010              ;;" & @CRLF & _
";;  GAMEPAD_BACK            0x0020              ;;" & @CRLF & _
";;  GAMEPAD_LEFT_THUMB      0x0040              ;;" & @CRLF & _
";;  GAMEPAD_RIGHT_THUMB     0x0080              ;;" & @CRLF & _
";;  GAMEPAD_LEFT_SHOULDER   0x0100              ;;" & @CRLF & _
";;  GAMEPAD_RIGHT_SHOULDER  0x0200              ;;" & @CRLF & _
";;  GAMEPAD_A =             0x1000              ;;" & @CRLF & _
";;  GAMEPAD_B =             0x2000              ;;" & @CRLF & _
";;  GAMEPAD_X =             0x4000              ;;" & @CRLF & _
";;  GAMEPAD_Y =             0x8000              ;;" & @CRLF & _
";;                                              ;;" & @CRLF & _
";;  For setting up combinations of buttons you  ;;" & @CRLF & _
";;  have to sum the corresponding values.       ;;" & @CRLF & _
";;  The following example starts Steam in Big   ;;" & @CRLF & _
";;  Picture mode when pressing and holding      ;;" & @CRLF & _
";;  START and DPAD_UP for a second:             ;;" & @CRLF & _
";;                                              ;;" & @CRLF & _
";;  [hotkey1]                                   ;;" & @CRLF & _
";;  keys=0x0011                                 ;;" & @CRLF & _
";;  command=start steam://open/bigpicture       ;;" & @CRLF & _
";;                                              ;;" & @CRLF & _
";;  For additional hotkeys you have to create   ;;" & @CRLF & _
";;  sections with continuous numeration like    ;;" & @CRLF & _
";;  [hotkey2], [hotkey3] and so on.             ;;" & @CRLF & _
";;                                              ;;" & @CRLF & _
";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;" & @CRLF & _
"" & @CRLF



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



Opt( "GUIOnEventMode", 1 )
local $formWidth = 450
local $formHeight = 82
local $distanceFromBottom = 60
local $iconSize = 80
local $labelHeight = 22
local $bordersVertical = 10
local $bordersHorizontal = 15
; form
local $gui = GUICreate( "", $formWidth, $formHeight, @DesktopWidth-$formWidth, @DesktopHeight-$formHeight-$distanceFromBottom, BitOR( $WS_POPUP, $WS_CLIPCHILDREN ), BitOR( $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW ) )
GUISetBkColor( 0x222222, $gui )
GUISetOnEvent( $GUI_EVENT_PRIMARYDOWN, "FadeOutClick", $gui )
; border left
GUICtrlCreateGraphic( 0, 0, 1, $formHeight, $SS_BLACKRECT )
GUICtrlSetBkColor( -1, 0xaaaaaa )
; border top
GUICtrlCreateGraphic( 0, 0, $formWidth, 1, $SS_BLACKRECT )
GUICtrlSetBkColor( -1, 0xaaaaaa )
; border bottom
GUICtrlCreateGraphic( 0, $formHeight - 1, $formWidth, 1, $SS_BLACKRECT )
GUICtrlSetBkColor( -1, 0xaaaaaa )
; x
local $labelX = GUICtrlCreateLabel( "x", $formWidth - 35, 1, 20, $formHeight - 2, $WS_CLIPSIBLINGS )
GUICtrlSetColor( -1, 0xaaaaaa )
GUICtrlSetFont( -1, 20, 0, 0, "Segoe UI", 0 )
GUICtrlSetStyle( -1, $SS_RIGHT )
; icon
local $icon = GUICtrlCreatePic( "", $bordersHorizontal, ( ( $formHeight - $iconSize ) / 2 ), $iconSize, $iconSize )
; label top
local $labelTop = GUICtrlCreateLabel( "", $bordersHorizontal + $iconSize + $bordersHorizontal, $bordersVertical, $formWidth - 2 * $bordersHorizontal, $labelHeight, $WS_CLIPSIBLINGS )
GUICtrlSetColor( -1, 0xffffff )
GUICtrlSetFont( -1, 12, 0, 0, "Segoe UI", 0 )
; label bottom
local $labelBottom = GUICtrlCreateLabel( "", $bordersHorizontal + $iconSize + $bordersHorizontal, $bordersVertical + $labelHeight, $formWidth - 2 * $bordersHorizontal, $labelHeight, $WS_CLIPSIBLINGS )
GUICtrlSetColor( -1, 0xaaaaaa )
GUICtrlSetFont( -1, 12, 0, 0, "Segoe UI", 0 )
; trans
local $currentWinTrans = 0
WinSetTrans( $gui, "", $currentWinTrans )
GUISetState( @SW_SHOW, $gui )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



if OtherInstanceExists() then
	Exit( 0 )
endif



; tray settings
Opt( "TrayIconHide", 0 )
Opt( "TrayMenuMode", 3 )
Opt( "TrayOnEventMode", 1 )
TraySetToolTip( "Xbox Controller Battery Watcher" )

TrayCreateItem( "Xbox Controller Battery Watcher " & GetVersion() )
TrayItemSetState( -1, $TRAY_DISABLE )
Local $statusTrayItem = TrayCreateItem( " " )
TrayItemSetState( -1, $TRAY_DISABLE )
Local $hotkeysStatusTrayItem = TrayCreateItem( " " )
TrayItemSetState( -1, $TRAY_DISABLE )
TrayCreateItem( "" )
Local $autostartItem = TrayCreateItem( "Autostart" )
TrayItemSetOnEvent( -1, "AutostartClicked" )
if GetAutostart() then
	TrayItemSetState( -1, $TRAY_CHECKED )
endif
TrayCreateItem( "Reload Hotkey Settings" )
TrayItemSetOnEvent( -1, "ReadIni" )
TrayCreateItem( "" )
TrayCreateItem( "Exit" )
TrayItemSetOnEvent( -1, "ExitScript" )



local $tStart = 0
local $wasConnected = false
local $wasWarnedLow = false
local $wasWarnedEmpty = false
local $batteryInfo
local $wasFullscreen = false
local $lastBatteryLevel
local $storedText
local $storedBatteryLevel
local $waitingForMouseOver = false
local $fadingStatus = ""
local $fadingTarget = $FADING_TARGET_HIDE
local $mouseOver = false
local $waitingForMouseOver = false
local $fadingIsRunning = false
local $fadingStopRequested = false
local $hotkeyList[0]

local $guiShowHotkeyDetectedBackground
local $guiShowHotkeyDetectedText

;HotKeySet( "{ESC}", "ExitScript" )

ReadIni()

while 1

	Sleep( 1000 )

	CheckHotkey()

    if TimerDiff( $tStart ) >= $POLLING_DELAY then

		; get battery info
		$batteryInfo = XboxGetBatteryLevel()

		if $batteryInfo[0] == $XBOX_CONTROLLER_TYPE_DISCONNECTED or $batteryInfo[0] == $XBOX_CONTROLLER_TYPE_WIRED then

			; controller is disconnected or wired

			if $wasConnected then
				$storedText = "Disconnected Controller Battery Level"
				$storedBatteryLevel = $lastBatteryLevel
				ShowInfo( $storedText, $lastBatteryLevel )
			endif

			$wasConnected = false
			$wasWarnedLow = false
			$wasWarnedEmpty = false

			TrayItemSetText( $statusTrayItem, "No controller found" )

		else

			; controller is connected wireless

			local $text = "Controller Battery Level"

			local $showInfo = false

			if $SHOW_INFO_ON_FULLSCREEN_EXIT and not IsFullscreen() and $wasFullscreen then
				$showInfo = true
			endif

			if $batteryInfo[1] == $XBOX_CONTROLLER_LEVEL_LOW and not $wasWarnedLow then
				$showInfo = true
				$wasWarnedLow = true
			elseif $batteryInfo[1] == $XBOX_CONTROLLER_LEVEL_EMPTY and not $wasWarnedEmpty then
				$showInfo = true
				$wasWarnedEmpty = true
			elseif not $wasConnected then
				$showInfo = true
			endif

			if $showInfo then
				$storedText = $text
				$storedBatteryLevel = $batteryInfo[1]
				ShowInfo( $text, $batteryInfo[1] )
			endif

			TrayItemSetText( $statusTrayItem, "Controller Battery Level: " & Level2Text( $batteryInfo[1] ) )

			$lastBatteryLevel = $batteryInfo[1]

			$wasConnected = true
			$wasFullscreen = false

		endif

		; check if fullscreen is shown currently
		if $SHOW_INFO_ON_FULLSCREEN_EXIT and IsFullscreen() then
			$wasFullscreen = true
		endif

        $tStart = TimerInit()

    endif

	; check if window is transparent and we are waiting for a mouse over
	if $waitingForMouseOver then
		local $mousePos = MouseGetPos()
		local $guiPos = WinGetPos( $gui )
		if $mousePos[0] >= $guiPos[0] and $mousePos[0] <= $guiPos[0] + $guiPos[2] and $mousePos[1] >= $guiPos[1] and $mousePos[1] <= $guiPos[1] + $guiPos[3] then
			$waitingForMouseOver = false
			ShowInfo( $storedText, $storedBatteryLevel )
		endif
	endif

	if $fadingStatus <> "" then
		GuiFade()
	endif

wend

Exit(0)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



func OtherInstanceExists()
	local $processList = ProcessList( "XboxControllerBatteryWatcher.exe" )
	;_ArrayDisplay( $processList, @AutoItPID )
	for $i = 1 to UBound( $processList ) - 1
		if $processList[$i][1] <> @AutoItPID then
			; found another process
			return true
		endif
	next
endfunc



func ReadIni()
	if FileExists( @ScriptDir & "\" & $INI_FILE_NAME ) then
		; read ini file
		dim $hotkeyList[0]
		local $sectionIndex = 0
		local $sectionFound = true
		while $sectionFound
			$sectionIndex += 1
			local $commandStr = IniRead( @ScriptDir & "\" & $INI_FILE_NAME, $INI_HOTKEY_SECTION_NAME & $sectionIndex, $INI_HOTKEY_COMMAND_NAME, "" )
			if $commandStr = "" then
				$sectionFound = false
			else
				local $keys = Number( IniRead( @ScriptDir & "\" & $INI_FILE_NAME, $INI_HOTKEY_SECTION_NAME & $sectionIndex, $INI_HOTKEY_KEYS_NAME, 0 ) )
				if $keys > 0 then
					local $dict = ObjCreate( "Scripting.Dictionary" )
					$dict.Add( $INI_HOTKEY_KEYS_NAME, $keys )
					$dict.Add( $INI_HOTKEY_COMMAND_NAME, $commandStr )
					_ArrayAdd( $hotkeyList, $dict )
				endif
			endif
		wend
	else
		; create default ini file
		$hFileOpen = FileOpen( @ScriptDir & "\" & $INI_FILE_NAME, $FO_OVERWRITE )
		if $hFileOpen <> -1 then
			FileWrite( $hFileOpen, $INI_HEADER_TEXT )
			FileClose( $hFileOpen )
			IniWrite( @ScriptDir & "\" & $INI_FILE_NAME, $INI_HOTKEY_SECTION_NAME & "X", $INI_HOTKEY_KEYS_NAME, "0x" & Hex( $INI_HOTKEY_KEYS_DEFAULT, 4 ) )
			IniWrite( @ScriptDir & "\" & $INI_FILE_NAME, $INI_HOTKEY_SECTION_NAME & "X", $INI_HOTKEY_COMMAND_NAME, $INI_HOTKEY_COMMAND_DEFAULT )
		endif
	endif
	if Ubound( $hotkeyList ) > 0 then
		TrayItemSetText( $hotkeysStatusTrayItem, "Hotkeys: enabled" )
	else
		TrayItemSetText( $hotkeysStatusTrayItem, "Hotkeys: disabled" )
	endif
endfunc



func GetXboxButtonStatus()
	local $hStruct
    $hStruct = DllStructCreate( "dword;short;ubyte;ubyte;short;short;short;short" )
    if DllCall( "xinput1_3.dll", "long", "XInputGetState", "long", 0, "ptr", DllStructGetPtr( $hStruct ) ) = 0 then return SetError( 5, 0, false )
    if @error then return SetError( @error, @extended, false )
	return DllStructGetData( $hStruct, 2 )
endfunc



func XboxButtonIsPressed( $key, $buttonStatus )
	if $key < 16385 then
		return Number( BitXOR( $key, $buttonStatus ) = 0 )
	endif
    return false
endfunc



func XboxGetBatteryLevel()
	dim $return[3]
	$return[0] = $XBOX_CONTROLLER_TYPE_DISCONNECTED
	$return[1] = $XBOX_CONTROLLER_LEVEL_EMPTY
	$return[2] = -1
	$controllerIndex = 0
	$struct = DllStructCreate( "byte type;byte level" )
	$pointer = DllStructGetPtr( $struct )
	for $controllerIndex = 0 to 3
		DllCall( "xinput1_3.dll", "dword", "XInputGetBatteryInformation", "dword", $controllerIndex, "byte", 0x00, "ptr", $pointer )
		$return[0] = DllStructGetData( $struct, "type" )
		if $return[0] <> $XBOX_CONTROLLER_TYPE_DISCONNECTED then
			$return[1] = DllStructGetData( $struct, "level" )
			$return[2] = $controllerIndex
			ExitLoop
		endif
	next
	return $return
endfunc



func CheckHotkey()
	if $wasConnected and Ubound( $hotkeyList ) > 0 then
		$buttonStatus = GetXboxButtonStatus()
		for $i = 0 to Ubound( $hotkeyList ) - 1
			if XboxButtonIsPressed( $hotkeyList[$i]( $INI_HOTKEY_KEYS_NAME ), $buttonStatus ) then
				ShowHotkeyDetected()
				Run( @ComSpec & " /c " & $hotkeyList[$i]( $INI_HOTKEY_COMMAND_NAME ), @ScriptDir, @SW_HIDE )
				$buttonStatus = GetXboxButtonStatus()
				while XboxButtonIsPressed( $hotkeyList[$i]( $INI_HOTKEY_KEYS_NAME ), $buttonStatus )
					sleep( 250 )
					$buttonStatus = GetXboxButtonStatus()
				wend
				ExitLoop
			endif
		next
	endif
endfunc



func IsFullscreen()
	local $pos = WinGetPos( "[ACTIVE]" )
	return $pos[0] == 0 and $pos[1] == 0 and $pos[2] == @DesktopWidth and $pos[3] == @DesktopHeight
endfunc



func Level2Text( $batteryLevel )
	local $level = ""
	switch $batteryLevel
		case $XBOX_CONTROLLER_LEVEL_EMPTY
			$level = "empty"
		case $XBOX_CONTROLLER_LEVEL_LOW
			$level = "low"
		case $XBOX_CONTROLLER_LEVEL_MEDIUM
			$level = "medium"
		case $XBOX_CONTROLLER_LEVEL_FULL
			$level = "full"
		case else
			$level = "unknown level (" & $batteryLevel & ")"
	endswitch
	return $level
endfunc



func Level2Icon( $batteryLevel )
	local $icon = ""
	switch $batteryLevel
		case $XBOX_CONTROLLER_LEVEL_EMPTY
			$icon = "iconEmpty"
		case $XBOX_CONTROLLER_LEVEL_LOW
			$icon = "iconLow"
		case $XBOX_CONTROLLER_LEVEL_MEDIUM
			$icon = "iconMedium"
		case $XBOX_CONTROLLER_LEVEL_FULL
			$icon = "iconFull"
	endswitch
	return $icon
endfunc



func ShowHotkeyDetected()
	HideHotkeyDetected()

	local const $width = 170
	local const $height = 50
	local const $posLeft = -1
	local const $posTop = @DesktopHeight/5
	local const $trans = 150
	local const $backgroundColor = 0x000000
	local const $textColor = 0xffffff
	local const $layerColor = Dec( Hex( 256-$trans, 2 ) & Hex( 256-$trans, 2 ) & Hex( 256-$trans, 2 ) )

	$guiShowHotkeyDetectedBackground = GUICreate( "", $width, $height, $posLeft, $posTop, BitOR( $WS_POPUP, $WS_CLIPCHILDREN ), BitOR( $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW, $WS_EX_LAYERED, $WS_EX_TRANSPARENT ) )
	GUISetBkColor( $backgroundColor, $guiShowHotkeyDetectedBackground )
	WinSetTrans( $guiShowHotkeyDetectedBackground, "", $trans )

	$guiShowHotkeyDetectedText = GUICreate( "", $width, $height, $posLeft, $posTop, BitOR( $WS_POPUP, $WS_CLIPCHILDREN ), BitOR( $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW, $WS_EX_LAYERED, $WS_EX_TRANSPARENT ) )
	GUISetBkColor( $layerColor, $guiShowHotkeyDetectedText )
	_WinAPI_SetLayeredWindowAttributes( $guiShowHotkeyDetectedText, $layerColor )
	GUICtrlCreateLabel( "Hotkey detected", 0, 0, $width, $height )
	GUICtrlSetColor( -1, $textColor )
	GUICtrlSetFont( -1, 14, 0, 0, "Segoe UI", 0 )
	GUICtrlSetStyle( -1, BitOR( $SS_CENTER, $SS_CENTERIMAGE ) )

	GUISetState( @SW_SHOW, $guiShowHotkeyDetectedBackground )
	GUISetState( @SW_SHOW, $guiShowHotkeyDetectedText )

	AdlibRegister( "HideHotkeyDetected", 3000 )
endfunc



func HideHotkeyDetected()
	if $guiShowHotkeyDetectedBackground then
		AdlibUnRegister( "HideHotkeyDetected" )
		GUISetState( @SW_HIDE, $guiShowHotkeyDetectedText )
		GUISetState( @SW_HIDE, $guiShowHotkeyDetectedBackground )
	endif
endfunc



func ShowInfo( $text, $batteryLevel )
	AdlibUnRegister( "FadeOutTimer" )
	AdlibUnRegister( "FadeOutToTransparentTimer" )
	local $fadeOutAfterTimer = true
	local $x = $GUI_HIDE
	local $textAddition = ""
	if $batteryLevel == $XBOX_CONTROLLER_LEVEL_EMPTY or $batteryLevel == $XBOX_CONTROLLER_LEVEL_LOW then
		$fadeOutAfterTimer = false
		$x = $GUI_SHOW
		$textAddition = "!"
	endif

	_ResourceSetImageToCtrl( $icon, Level2Icon( $batteryLevel ) )
	GUICtrlSetData( $labelTop, $text )
	GUICtrlSetData( $labelBottom, _StringProper( Level2Text( $batteryLevel ) ) & $textAddition )
	GUICtrlSetState( $labelX, $x )

	$fadingStatus = "in"
	$fadingTarget = $FADING_TARGET_SHOW

	if $fadeOutAfterTimer then
		AdlibRegister( "FadeOutTimer", $MESSAGE_SHOW_DELAY )
		$waitingForMouseOver = false
	else
		AdlibRegister( "FadeOutToTransparentTimer", $MESSAGE_SHOW_DELAY )
		$waitingForMouseOver = true
	endif
endfunc



func GuiFade()
	while $fadingStatus <> ""

		while $fadingStatus == "in"
			if $currentWinTrans <= $fadingTarget then
				$currentWinTrans += $FADING_IN_STEPS_PER_REFRESH
			endif
			if $currentWinTrans > $fadingTarget then
				$currentWinTrans = $fadingTarget
			endif
			WinSetTrans( $gui, "", $currentWinTrans )
			if $currentWinTrans == $fadingTarget then
				$fadingStatus = ""
			else
				Sleep( $FADING_REFRESH_RATE )
			endif
		wend

		while $fadingStatus == "out"
			if $currentWinTrans >= $fadingTarget then
				$currentWinTrans -= $FADING_OUT_STEPS_PER_REFRESH
			endif
			if $currentWinTrans < $fadingTarget then
				$currentWinTrans = $fadingTarget
			endif
			WinSetTrans( $gui, "", $currentWinTrans )
			if $currentWinTrans == $fadingTarget then
				$fadingStatus = ""
			else
				Sleep( $FADING_REFRESH_RATE )
			endif
		wend

	wend
endfunc



func FadeOutClick()
	AdlibUnRegister( "FadeOutTimer" )
	AdlibUnRegister( "FadeOutToTransparentTimer" )
	$fadingStatus = "out"
	$fadingTarget = $FADING_TARGET_HIDE
	$waitingForMouseOver = false
endfunc



func FadeOutTimer()
	AdlibUnRegister( "FadeOutTimer" )
	$fadingStatus = "out"
	$fadingTarget = $FADING_TARGET_HIDE
endfunc



func FadeOutToTransparentTimer()
	AdlibUnRegister( "FadeOutToTransparentTimer" )
	$fadingStatus = "out"
	$fadingTarget = $FADING_TARGET_TRANSPARENT
endfunc



func GetVersion()
	$fullVersion = FileGetVersion( @AutoItExe )
	$secondDotPos = StringInStr( $fullVersion, ".", $STR_NOCASESENSEBASIC, 2 )
	return StringMid( $fullVersion, 1, $secondDotPos - 1 )
endfunc



func AutostartClicked()
	SetAutostart ( not GetAutostart() )
	if GetAutostart() then
		TrayItemSetState( $autostartItem, $TRAY_CHECKED )
	else
		TrayItemSetState( $autostartItem, $TRAY_UNCHECKED )
	endif
endfunc



func GetApplicationPath()
	return @AutoItExe
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



func ExitScript()
    Exit( 0 )
endfunc
