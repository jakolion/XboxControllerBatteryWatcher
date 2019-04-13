dim $showInfoQueue[$MAX_CONTROLLERS][2]

local $dialogCurrentlyShown
local $dialogCurrentlyShownControllerIndex
local $dialogCurrentlyShownText
local $dialogCurrentlyShownBatteryLevel



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
; icons
; Note: Because the function "_ResourceSetImageToCtrl" has
;       a memory leak when it gets called again and again,
;       we will create all needed pics and simply show and
;       hide them later.
local $iconArray[4] = [ "iconEmpty", "iconLow", "iconMedium", "iconFull" ]
local $icons = ObjCreate( "Scripting.Dictionary" )
for $i = 0 to UBound( $iconArray ) - 1
	local $icon = GUICtrlCreatePic( "", $bordersHorizontal, ( ( $formHeight - $iconSize ) / 2 ), $iconSize, $iconSize )
	GUICtrlSetState( -1, $GUI_HIDE )
	_ResourceSetImageToCtrl( $icon, $iconArray[$i] )
	$icons.add( $iconArray[$i], $icon )
next
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



func GetXboxGetBatteryLevel()
	dim $return[$MAX_CONTROLLERS]
	$struct = DllStructCreate( "byte type;byte level" )
	$pointer = DllStructGetPtr( $struct )
	for $controllerIndex = 0 to $MAX_CONTROLLERS - 1
		dim $info[3]
		$info[0] = $XBOX_CONTROLLER_TYPE_DISCONNECTED
		$info[1] = $XBOX_CONTROLLER_LEVEL_EMPTY
		$info[2] = -1
		DllCall( "xinput1_3.dll", "dword", "XInputGetBatteryInformation", "dword", $controllerIndex, "byte", 0x00, "ptr", $pointer )
		$info[0] = DllStructGetData( $struct, "type" )
		if $info[0] <> $XBOX_CONTROLLER_TYPE_DISCONNECTED then
			$info[1] = DllStructGetData( $struct, "level" )
			$info[2] = $controllerIndex
		endif
		$return[$controllerIndex] = $info
	next
	return $return
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



func ShowInfo( $controllerIndex, $text, $batteryLevel )
	if $controllerIndex <> Null and $text <> Null and $batteryLevel <> Null then
		if $dialogCurrentlyShown then
			$showInfoQueue[$controllerIndex][0] = $text
			$showInfoQueue[$controllerIndex][1] = $batteryLevel
			return
		endif
		$dialogCurrentlyShown = true
		$dialogCurrentlyShownControllerIndex = $controllerIndex
		$dialogCurrentlyShownText = $text
		$dialogCurrentlyShownBatteryLevel = $batteryLevel
	endif

	AdlibUnRegister( "FadeOutTimer" )
	AdlibUnRegister( "FadeOutToTransparentTimer" )

	local $fadeOutAfterTimer = true
	local $x = $GUI_HIDE
	local $textAddition = ""
	if $dialogCurrentlyShownBatteryLevel == $XBOX_CONTROLLER_LEVEL_EMPTY or $dialogCurrentlyShownBatteryLevel == $XBOX_CONTROLLER_LEVEL_LOW then
		$fadeOutAfterTimer = false
		$x = $GUI_SHOW
		$textAddition = "!"
	endif

	local $newIcon = Level2Icon( $dialogCurrentlyShownBatteryLevel )
	if $currentIcon <> $newIcon then
		GUICtrlSetState( $icons.item( $newIcon ), $GUI_SHOW )
		GUICtrlSetState( $icons.item( $currentIcon ), $GUI_HIDE )
		$currentIcon = $newIcon
	endif

	GUICtrlSetData( $labelTop, $dialogCurrentlyShownText )
	GUICtrlSetData( $labelBottom, _StringProper( Level2Text( $dialogCurrentlyShownBatteryLevel ) ) & $textAddition )
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
				if $currentWinTrans == $FADING_TARGET_HIDE then
					$dialogCurrentlyShown = false
					for $x = 0 to $MAX_CONTROLLERS - 1
						if $showInfoQueue[$x][0] <> "" then
							ShowInfo( $x, $showInfoQueue[$x][0], $showInfoQueue[$x][1] )
							$showInfoQueue[$x][0] = ""
							ExitLoop
						endif
					next
				endif
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
