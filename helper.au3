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



func IsFullscreen()
	local $pos = WinGetPos( "[ACTIVE]" )
	return $pos[0] == 0 and $pos[1] == 0 and $pos[2] == @DesktopWidth and $pos[3] == @DesktopHeight
endfunc



func GetVersion()
	$fullVersion = FileGetVersion( @AutoItExe )
	$EndPos = StringInStr( $fullVersion, ".", $STR_NOCASESENSEBASIC, 3 )
	return StringMid( $fullVersion, 1, $EndPos - 1 )
endfunc



func GetApplicationPath()
	return @AutoItExe
endfunc



func ExitScript()
    Exit( 0 )
endfunc
