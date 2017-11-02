#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Res_Description=Xbox Controller Battery Watcher
#AutoIt3Wrapper_Res_Fileversion=1.1.0.0
#AutoIt3Wrapper_Res_File_Add=iconController\iconControllerFullSmall.jpg, rt_rcdata, iconFull
#AutoIt3Wrapper_Res_File_Add=iconController\iconControllerMediumSmall.jpg, rt_rcdata, iconMedium
#AutoIt3Wrapper_Res_File_Add=iconController\iconControllerLowSmall.jpg, rt_rcdata, iconLow
#AutoIt3Wrapper_Res_File_Add=iconController\iconControllerEmptySmall.jpg, rt_rcdata, iconEmpty
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;#include <Array.au3>
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

global $fadingStatus = ""
global $fadingTarget = $FADING_TARGET_HIDE
global $mouseOver = false
global $waitingForMouseOver = false
global $fadingIsRunning = false
global $fadingStopRequested = false

const $SHOW_INFO_ON_FULLSCREEN_EXIT = false



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



Opt( "GUIOnEventMode", 1 )
global $formWidth = 450
global $formHeight = 80
global $distanceFromBottom = 60
local $labelHeight = 22
local $bordersVertical = 10
local $bordersHorizontal = 15
; form
global $gui = GUICreate( "", $formWidth, $formHeight, @DesktopWidth-$formWidth, @DesktopHeight-$formHeight-$distanceFromBottom, BitOR( $WS_POPUPWINDOW, $WS_CLIPCHILDREN ), BitOR( $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW ) )
GUISetBkColor( 0x222222, $gui )
GUISetOnEvent( $GUI_EVENT_PRIMARYDOWN, "FadeOutClick", $gui )
; x
global $labelX = GUICtrlCreateLabel( "x", $formWidth - 35, 0, 20, $formHeight, $WS_CLIPSIBLINGS )
GUICtrlSetColor( -1, 0xaaaaaa )
GUICtrlSetFont( -1, 20, 0, 0, "Segoe UI", 0 )
GUICtrlSetStyle( -1, $SS_RIGHT )
; icon
local $iconSize = $formHeight
global $icon = GUICtrlCreatePic( "", $bordersHorizontal, 0, $iconSize, $iconSize )
; label top
global $labelTop = GUICtrlCreateLabel( "", $bordersHorizontal + $iconSize + $bordersHorizontal, $bordersVertical, $formWidth - 2 * $bordersHorizontal, $labelHeight, $WS_CLIPSIBLINGS )
GUICtrlSetColor( -1, 0xffffff )
GUICtrlSetFont( -1, 12, 0, 0, "Segoe UI", 0 )
; label bottom
global $labelBottom = GUICtrlCreateLabel( "", $bordersHorizontal + $iconSize + $bordersHorizontal, $bordersVertical + $labelHeight, $formWidth - 2 * $bordersHorizontal, $labelHeight, $WS_CLIPSIBLINGS )
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

while 1

	if $currentWinTrans <> 0 then
		Sleep( 100 )
	else
		Sleep( 1000 )
	endif

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
			; Found another process
			return true
		endif
	next
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
			;$icon = "iconController\iconControllerEmptySmall.jpg"
		case $XBOX_CONTROLLER_LEVEL_LOW
			$icon = "iconLow"
			;$icon = "iconController\iconControllerLowSmall.jpg"
		case $XBOX_CONTROLLER_LEVEL_MEDIUM
			$icon = "iconMedium"
			;$icon = "iconController\iconControllerMediumSmall.jpg"
		case $XBOX_CONTROLLER_LEVEL_FULL
			$icon = "iconFull"
			;$icon = "iconController\iconControllerFullSmall.jpg"
	endswitch
	return $icon
endfunc



func ShowInfo( $text, $batteryLevel )
	AdlibUnRegister( "FadeOutTimer" )
	AdlibUnRegister( "FadeOutToTransparentTimer" )
	local $fadeOutAfterTimer = true
	local $x = $GUI_HIDE
	;local $icon = $TIP_ICONASTERISK
	local $textAddition = ""
	if $batteryLevel == $XBOX_CONTROLLER_LEVEL_EMPTY or $batteryLevel == $XBOX_CONTROLLER_LEVEL_LOW then
		$fadeOutAfterTimer = false
		$x = $GUI_SHOW
		;$icon = $TIP_ICONEXCLAMATION
		$textAddition = "!"
	endif
	;TrayTip( $text, _StringProper( Level2Text( $batteryLevel ) ) & $textAddition, $fadeOutAfterTimer/1000, $icon ) ;$TIP_ICONNONE ;$TIP_ICONASTERISK ;$TIP_ICONEXCLAMATION

	;GUICtrlSetImage( $icon, Level2Icon( $batteryLevel ) )
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



func ExitScript()
    Exit( 0 )
endfunc




