#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Res_Description=Xbox Controller Battery Watcher
#AutoIt3Wrapper_Res_Fileversion=1.6.0.0
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
#include <helper.au3>
#include <battery.au3>
#include <hotkeys.au3>
#include <autostart.au3>



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

local $statusTrayItem = TrayCreateItem( " " )
TrayItemSetState( -1, $TRAY_DISABLE )

$hotkeysStatusTrayItem = TrayCreateItem( " " )
TrayItemSetState( -1, $TRAY_DISABLE )

TrayCreateItem( "" )

$autostartTrayItem = TrayCreateItem( "Autostart" )
TrayItemSetOnEvent( -1, "AutostartClicked" )
if GetAutostart() then
	TrayItemSetState( -1, $TRAY_CHECKED )
endif

TrayCreateItem( "Reload Hotkey Settings" )
TrayItemSetOnEvent( -1, "ReadHotkeysIni" )

TrayCreateItem( "" )

TrayCreateItem( "Exit" )
TrayItemSetOnEvent( -1, "ExitScript" )



local $hotkeyTimerStart = 0
local $batteryTimerStart = 0
local $controllerIndex = -1

;HotKeySet( "{ESC}", "ExitScript" )

ReadHotkeysIni()

while 1

	if $currentWinTrans <> 0 then
		Sleep( 100 )
	else
		Sleep( 1000 )
	endif

	if TimerDiff( $hotkeyTimerStart ) >= $HOTKEY_POLLING_DELAY then
		CheckHotkey( $controllerIndex )
		$hotkeyTimerStart = TimerInit()
	endif

    if TimerDiff( $batteryTimerStart ) >= $BATTERY_POLLING_DELAY then

		; get battery info
		$batteryInfo = GetXboxGetBatteryLevel()

		if $batteryInfo[0] == $XBOX_CONTROLLER_TYPE_DISCONNECTED or $batteryInfo[0] == $XBOX_CONTROLLER_TYPE_WIRED then

			; controller is disconnected or wired
			if $isConnected then
				$storedText = "Disconnected Controller Battery Level"
				$storedBatteryLevel = $lastBatteryLevel
				ShowInfo( $storedText, $lastBatteryLevel )
			endif

			$isConnected = false
			$wasWarnedLow = false
			$wasWarnedEmpty = false
			$controllerIndex = -1

			TrayItemSetText( $statusTrayItem, "Controller Battery Level: no controller" )

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
			elseif not $isConnected then
				$showInfo = true
			endif

			if $showInfo then
				$storedText = $text
				$storedBatteryLevel = $batteryInfo[1]
				ShowInfo( $text, $batteryInfo[1] )
			endif

			TrayItemSetText( $statusTrayItem, "Controller Battery Level: " & Level2Text( $batteryInfo[1] ) )

			$lastBatteryLevel = $batteryInfo[1]

			$isConnected = true
			$wasFullscreen = false
			$controllerIndex = $batteryInfo[2]

		endif

		; check if fullscreen is shown currently
		if $SHOW_INFO_ON_FULLSCREEN_EXIT and IsFullscreen() then
			$wasFullscreen = true
		endif

        $batteryTimerStart = TimerInit()

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

Exit( 0 )
