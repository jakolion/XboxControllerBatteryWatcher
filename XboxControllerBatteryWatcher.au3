#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Res_Description=Xbox Controller Battery Watcher
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
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
#include <parameters.au3>
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

; version
TrayCreateItem( "Xbox Controller Battery Watcher " & GetVersion() )
TrayItemSetState( -1, $TRAY_DISABLE )

; hotkey status
$hotkeysStatusTrayItem = TrayCreateItem( " " )
TrayItemSetState( -1, $TRAY_DISABLE )

; spacer
TrayCreateItem( "" )

; battery levels
TrayCreateItem( "Controller Battery Level:" )
TrayItemSetState( -1, $TRAY_DISABLE )
dim $statusTrayItem[$MAX_CONTROLLERS]
for $i = 0 to $MAX_CONTROLLERS - 1
	$statusTrayItem[$i] = TrayCreateItem( " " )
	TrayItemSetState( -1, $TRAY_DISABLE )
next

; spacer
TrayCreateItem( "" )

; autostart checkbox
$autostartTrayItem = TrayCreateItem( "Autostart" )
TrayItemSetOnEvent( -1, "AutostartClicked" )
if GetAutostart() then
	TrayItemSetState( -1, $TRAY_CHECKED )
endif

; reload hotkey settings file
TrayCreateItem( "Reload Hotkey Settings" )
TrayItemSetOnEvent( -1, "ReadHotkeysIni" )

; spacer
TrayCreateItem( "" )

; exit
TrayCreateItem( "Exit" )
TrayItemSetOnEvent( -1, "ExitScript" )



local $hotkeyTimerStart = 0
local $batteryTimerStart = 0

;HotKeySet( "{ESC}", "ExitScript" )

ReadHotkeysIni()

while 1

	if $currentWinTrans <> 0 then
		Sleep( 100 )
	else
		Sleep( 1000 )
	endif

	if TimerDiff( $hotkeyTimerStart ) >= $HOTKEY_POLLING_DELAY then
		CheckHotkey()
		$hotkeyTimerStart = TimerInit()
	endif

    if TimerDiff( $batteryTimerStart ) >= $BATTERY_POLLING_DELAY then

		; get battery info
		local $batteryInfos = GetXboxGetBatteryLevel()

		for $controllerIndex = 0 to $MAX_CONTROLLERS - 1

			local $controllerNumber = $controllerIndex + 1
			local $batteryInfo = $batteryInfos[$controllerIndex]

			if $batteryInfo[0] == $XBOX_CONTROLLER_TYPE_DISCONNECTED or $batteryInfo[0] == $XBOX_CONTROLLER_TYPE_WIRED then

				; controller is disconnected or wired
				if $controllerIsConnected[$controllerIndex] then
					ShowInfo( $controllerIndex, "Controller " & $controllerNumber & " disconnected - Battery Level", $controllerLastBatteryLevel[$controllerIndex] )
				endif

				$controllerIsConnected[$controllerIndex] = false
				$controllerWarnedLow[$controllerIndex] = false
				$controllerWarnedEmpty[$controllerIndex] = false

				TrayItemSetText( $statusTrayItem[$controllerIndex], "    " & $controllerNumber & ". -" )

			else

				; controller is connected wireless
				local $showInfo = false

				if $SHOW_INFO_ON_FULLSCREEN_EXIT and not IsFullscreen() and $wasFullscreen then
					$showInfo = true
				endif

				if $batteryInfo[1] == $XBOX_CONTROLLER_LEVEL_LOW and not $controllerWarnedLow[$controllerIndex] then
					$showInfo = true
					$controllerWarnedLow[$controllerIndex] = true
				elseif $batteryInfo[1] == $XBOX_CONTROLLER_LEVEL_EMPTY and not $controllerWarnedEmpty[$controllerIndex] then
					$showInfo = true
					$controllerWarnedEmpty[$controllerIndex] = true
				elseif not $controllerIsConnected[$controllerIndex] then
					$showInfo = true
				endif

				if $showInfo then
					$newText = "Controller " & $controllerNumber & " - Battery Level"
					if not $controllerIsConnected[$controllerIndex] then
						$newText = "Controller " & $controllerNumber & " connected - Battery Level"
					endif
					ShowInfo( $controllerIndex, $newText, $batteryInfo[1] )
				endif

				$controllerIsConnected[$controllerIndex] = true
				$controllerLastBatteryLevel[$controllerIndex] = $batteryInfo[1]
				$wasFullscreen = false

				TrayItemSetText( $statusTrayItem[$controllerIndex], "    " & $controllerNumber & ". " & Level2Text( $batteryInfo[1] ) )

			endif

		next

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
			ShowInfo( Null, Null, Null )
		endif
	endif

	if $fadingStatus <> "" then
		GuiFade()
	endif

wend

Exit( 0 )
