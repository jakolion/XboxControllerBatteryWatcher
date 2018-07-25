const $HOTKEY_POLLING_DELAY = 1000
const $INI_HOTKEY_INI_NAME = "XboxControllerBatteryWatcher.ini"
const $INI_HOTKEY_SECTION_NAME = "hotkey"
const $INI_HOTKEY_KEYS_NAME = "keys"
const $INI_HOTKEY_KEYS_DEFAULT = 0x11
const $INI_HOTKEY_COMMAND_NAME = "command"
const $INI_HOTKEY_COMMAND_DEFAULT = "start steam://open/bigpicture"

const $INI_HEADER_TEXT = "" & _
";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;" & @CRLF & _
";;                                                    ;;" & @CRLF & _
";;  Xbox Controller Battery Watcher Hotkeys           ;;" & @CRLF & _
";;  =======================================           ;;" & @CRLF & _
";;                                                    ;;" & @CRLF & _
";;  In this file you can define multiple hotkeys for  ;;" & @CRLF & _
";;  the Xbox Controller. The buttons have to be       ;;" & @CRLF & _
";;  pressed and hold for a second in order to be      ;;" & @CRLF & _
";;  detected.                                         ;;" & @CRLF & _
";;  These are the values for the buttons:             ;;" & @CRLF & _
";;                                                    ;;" & @CRLF & _
";;  GAMEPAD_DPAD_UP          0x0001                   ;;" & @CRLF & _
";;  GAMEPAD_DPAD_DOWN        0x0002                   ;;" & @CRLF & _
";;  GAMEPAD_DPAD_LEFT        0x0004                   ;;" & @CRLF & _
";;  GAMEPAD_DPAD_RIGHT       0x0008                   ;;" & @CRLF & _
";;  GAMEPAD_START            0x0010                   ;;" & @CRLF & _
";;  GAMEPAD_BACK             0x0020                   ;;" & @CRLF & _
";;  GAMEPAD_LEFT_THUMB       0x0040                   ;;" & @CRLF & _
";;  GAMEPAD_RIGHT_THUMB      0x0080                   ;;" & @CRLF & _
";;  GAMEPAD_LEFT_SHOULDER    0x0100                   ;;" & @CRLF & _
";;  GAMEPAD_RIGHT_SHOULDER   0x0200                   ;;" & @CRLF & _
";;  GAMEPAD_A =              0x1000                   ;;" & @CRLF & _
";;  GAMEPAD_B =              0x2000                   ;;" & @CRLF & _
";;  GAMEPAD_X =              0x4000                   ;;" & @CRLF & _
";;  GAMEPAD_Y =              0x8000                   ;;" & @CRLF & _
";;                                                    ;;" & @CRLF & _
";;  For setting up combinations of buttons you have   ;;" & @CRLF & _
";;  to sum the corresponding values.                  ;;" & @CRLF & _
";;  The following example starts Steam in Big         ;;" & @CRLF & _
";;  Picture mode when pressing and holding START      ;;" & @CRLF & _
";;  and DPAD_UP for a second:                         ;;" & @CRLF & _
";;                                                    ;;" & @CRLF & _
";;  [hotkey1]                                         ;;" & @CRLF & _
";;  keys=0x0011                                       ;;" & @CRLF & _
";;  command=start steam://open/bigpicture             ;;" & @CRLF & _
";;                                                    ;;" & @CRLF & _
";;  For additional hotkeys you have to create         ;;" & @CRLF & _
";;  sections with continuous numeration like          ;;" & @CRLF & _
";;  [hotkey2], [hotkey3] and so on.                   ;;" & @CRLF & _
";;                                                    ;;" & @CRLF & _
";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;" & @CRLF & _
"" & @CRLF

local $hotkeysStatusTrayItem
local $hotkeyList[0]
local $guiShowHotkeyDetectedBackground
local $guiShowHotkeyDetectedText



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



func ReadHotkeysIni()
	if FileExists( @ScriptDir & "\" & $INI_HOTKEY_INI_NAME ) then
		; read ini file
		dim $hotkeyList[0]
		local $sectionIndex = 0
		local $sectionFound = true
		while $sectionFound
			$sectionIndex += 1
			local $commandStr = IniRead( @ScriptDir & "\" & $INI_HOTKEY_INI_NAME, $INI_HOTKEY_SECTION_NAME & $sectionIndex, $INI_HOTKEY_COMMAND_NAME, "" )
			if $commandStr = "" then
				$sectionFound = false
			else
				local $keys = Number( IniRead( @ScriptDir & "\" & $INI_HOTKEY_INI_NAME, $INI_HOTKEY_SECTION_NAME & $sectionIndex, $INI_HOTKEY_KEYS_NAME, 0 ) )
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
		$hFileOpen = FileOpen( @ScriptDir & "\" & $INI_HOTKEY_INI_NAME, $FO_OVERWRITE )
		if $hFileOpen <> -1 then
			FileWrite( $hFileOpen, $INI_HEADER_TEXT )
			FileClose( $hFileOpen )
			IniWrite( @ScriptDir & "\" & $INI_HOTKEY_INI_NAME, $INI_HOTKEY_SECTION_NAME & "_example", $INI_HOTKEY_KEYS_NAME, "0x" & Hex( $INI_HOTKEY_KEYS_DEFAULT, 4 ) )
			IniWrite( @ScriptDir & "\" & $INI_HOTKEY_INI_NAME, $INI_HOTKEY_SECTION_NAME & "_example", $INI_HOTKEY_COMMAND_NAME, $INI_HOTKEY_COMMAND_DEFAULT )
		endif
	endif
	if Ubound( $hotkeyList ) > 0 then
		TrayItemSetText( $hotkeysStatusTrayItem, "Hotkeys: enabled" )
	else
		TrayItemSetText( $hotkeysStatusTrayItem, "Hotkeys: disabled" )
	endif
endfunc



func GetXboxButtonStatus( $controllerIndex )
	$struct = DllStructCreate( "dword;short;ubyte;ubyte;short;short;short;short" )
	$pointer = DllStructGetPtr( $struct )
	DllCall( "xinput1_3.dll", "dword", "XInputGetState", "dword", $controllerIndex, "ptr", $pointer )
	$result = DllStructGetData( $struct, 2 )
	; for some reason pressing GAMEPAD_Y returns -32768
	; therefore we change these bits to 32768 (0x8000)
	if Number( BitAND( -32768, $result ) <> 0 ) then
		; reset bits for -32768
		$flippedGamepadY = BitNOT( -32768 )
		$result = BitAND( $flippedGamepadY, $result )
		; set bits for 32768 (0x8000)
		$result = BitOR( 0x8000, $result )
	endif
	return $result
endfunc



func XboxButtonIsPressed( $key, $buttonStatus )
	if $key < 65536 then
		return Number( BitXOR( $key, $buttonStatus ) = 0 )
	endif
    return false
endfunc



func CheckHotkey( $controllerIndex )
	if $isConnected and Ubound( $hotkeyList ) > 0 and $controllerIndex >= 0 then
		$buttonStatus = GetXboxButtonStatus( $controllerIndex )
		for $i = 0 to Ubound( $hotkeyList ) - 1
			if XboxButtonIsPressed( $hotkeyList[$i]( $INI_HOTKEY_KEYS_NAME ), $buttonStatus ) then
				ShowHotkeyDetected()
				Run( @ComSpec & " /c " & $hotkeyList[$i]( $INI_HOTKEY_COMMAND_NAME ), @ScriptDir, @SW_HIDE )
				$buttonStatus = GetXboxButtonStatus( $controllerIndex )
				while XboxButtonIsPressed( $hotkeyList[$i]( $INI_HOTKEY_KEYS_NAME ), $buttonStatus )
					sleep( 250 )
					$buttonStatus = GetXboxButtonStatus( $controllerIndex )
				wend
				ExitLoop
			endif
		next
	endif
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
