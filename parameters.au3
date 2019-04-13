const $MAX_CONTROLLERS = 4

const $XBOX_CONTROLLER_TYPE_DISCONNECTED = 0
const $XBOX_CONTROLLER_TYPE_WIRED = 1
const $XBOX_CONTROLLER_TYPE_ALKALINE = 2
const $XBOX_CONTROLLER_TYPE_NIMH = 3
const $XBOX_CONTROLLER_TYPE_UNKNOWN = 255
const $XBOX_CONTROLLER_LEVEL_EMPTY = 0
const $XBOX_CONTROLLER_LEVEL_LOW = 1
const $XBOX_CONTROLLER_LEVEL_MEDIUM = 2
const $XBOX_CONTROLLER_LEVEL_FULL = 3

const $BATTERY_POLLING_DELAY = 5000
const $MESSAGE_SHOW_DELAY = 10000

const $FADING_REFRESH_RATE = 33 ; 16 = 60fps | 33 = 30fps
const $FADING_STEPS = 256
const $FADING_TARGET_SHOW = $FADING_STEPS - 1
const $FADING_TARGET_HIDE = 0
const $FADING_TARGET_TRANSPARENT = 128
const $FADING_IN_SPEED = 500
const $FADING_OUT_SPEED = 250
const $FADING_IN_STEPS_PER_REFRESH = $FADING_STEPS / ( $FADING_IN_SPEED / $FADING_REFRESH_RATE )
const $FADING_OUT_STEPS_PER_REFRESH = $FADING_STEPS / ( $FADING_OUT_SPEED / $FADING_REFRESH_RATE )

const $SHOW_INFO_ON_FULLSCREEN_EXIT = false
local $wasFullscreen = false

dim $controllerIsConnected[$MAX_CONTROLLERS]
dim $controllerWarnedLow[$MAX_CONTROLLERS]
dim $controllerWarnedEmpty[$MAX_CONTROLLERS]
dim $controllerLastBatteryLevel[$MAX_CONTROLLERS]

local $fadingStatus = ""
local $fadingTarget = $FADING_TARGET_HIDE
local $waitingForMouseOver = false
local $mouseOver = false
local $waitingForMouseOver = false
local $fadingIsRunning = false
local $fadingStopRequested = false
local $currentIcon = ""
