--[[=============================================================================
    Basic Template for AVSwitch Driver

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]------------
require "common.c4_driver_declarations"
require "common.c4_common"
require "common.c4_init"
require "common.c4_property"
require "common.c4_command"
require "common.c4_notify"
require "common.c4_network_connection"
require "common.c4_serial_connection"
require "common.c4_ir_connection"
require "common.c4_utils"
require "lib.c4_timer"
require "actions"
require "device_specific_commands"
require "device_messages"
require "avswitch_init"
require "properties"
require "proxy_commands"
require "connections"
require "avswitch.avswitch_proxy_class"
require "avswitch.avswitch_proxy_commands"
require "avswitch.avswitch_proxy_notifies"
require "av_path"


-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.driver = "2015.03.31"
end

--[[=============================================================================
    Constants
===============================================================================]]
AVSWITCH_PROXY_BINDINGID = 5001

--[[
    Device Volume Range
    COMPLETE: edit "MIN_DEVICE_LEVEL" & "MAX_DEVICE_LEVEL" values based upon the protocol specification for volume range.
    If zones have volume ranges that vary, convert these constants into a table indexed by the mod value of the output connection 
    and then update all references to handle the table structure.
--]]
MIN_DEVICE_LEVEL = 0
MAX_DEVICE_LEVEL = 100	


--[[=============================================================================
    Initialization Code
===============================================================================]]
function ON_DRIVER_EARLY_INIT.main()
	
end

function ON_DRIVER_INIT.main()

	-- TODO: If cloud based driver then uncomment the following line
	--ConnectURL()
end

function ON_DRIVER_LATEINIT.main()
    C4:urlSetTimeout (20) 
    DRIVER_NAME = C4:GetDriverConfigInfo("name")
	
	SetLogName(DRIVER_NAME)
end

function ON_DRIVER_EARLY_INIT.avswitch_driver()

end

function ON_DRIVER_INIT.avswitch_driver()
    -- TODO: Modify tVolumeRamping to have on entry per Output connection
    --index is mod 1000 value of output connection
    local tVolumeRamping = {
		[0] = {state = false,mode = "",},
		[1] = {state = false,mode = "",},
		[2] = {state = false,mode = "",},	
		[3] = {state = false,mode = "",},
	}
	
	
	-- Map to keep track of inputs and outputs.  Useful for EDID management logic...
     gOutputToInputMap={
	 [0]=-1,
	 [1]=-1,
	 [2]=-1,
     [3]=-1,
	 [4]=-1,
	 [5]=-1,
	 [6]=-1,
	 [7]=-1, 
     }

     gOutputToInputAudioMap={
	 [0]=-1,
	 [1]=-1,
	 [2]=-1,
     [3]=-1,
	 [4]=-1,
	 [5]=-1,
	 [6]=-1,
	 [7]=-1, 
     }
	
     -- Map to track full output id to Room id. This will be used in DISCONNECT_OUTPUT
     --to prevent the zone  from turning off when we are just selecting an alternate audio source
     --entries will be seeded in AV_OUTPUT_TO_INPUT_VALID
     gVideoProviderToRoomMap = {}
     gAudioProviderToRoomMap = {}

     --entries will be seeded in AV_OUTPUT_TO_INPUT_VALID
     gLastReportedAVPaths = {}
	
     --Connection Type 
     gAVPathType = {
	    [5] = "VIDEO",
	    [6] = "AUDIO",
	    [7] = "ROOM",
     }	
	
     gAudioSelectionInProgressOutput0Timer = c4_timer:new("AudioSelectionInProgressOutput0Timer", 500, "MILLISECONDS", OnAudioSelectionInProgressOutput0TimerExpired)
     gAudioSelectionInProgressOutput1Timer = c4_timer:new("AudioSelectionInProgressOutput1Timer", 500, "MILLISECONDS", OnAudioSelectionInProgressOutput1TimerExpired)
     gAudioSelectionInProgressOutput2Timer = c4_timer:new("AudioSelectionInProgressOutput2Timer", 500, "MILLISECONDS", OnAudioSelectionInProgressOutput2TimerExpired)
     gAudioSelectionInProgressOutput3Timer = c4_timer:new("AudioSelectionInProgressOutput3Timer", 500, "MILLISECONDS", OnAudioSelectionInProgressOutput3TimerExpired)

		
     gHDMIAudioSelectionInProgressOutput0Timer = c4_timer:new("HDMIAudioSelectionInProgressOutput0Timer", 500, "MILLISECONDS", OnHDMIAudioSelectionInProgressOutput0TimerExpired)	
	gHDMIAudioSelectionInProgressOutput1Timer = c4_timer:new("HDMIAudioSelectionInProgressOutput1Timer", 500, "MILLISECONDS", OnHDMIAudioSelectionInProgressOutput1TimerExpired)
     gHDMIAudioSelectionInProgressOutput2Timer = c4_timer:new("HDMIAudioSelectionInProgressOutput2Timer", 500, "MILLISECONDS", OnHDMIAudioSelectionInProgressOutput2TimerExpired)
     gHDMIAudioSelectionInProgressOutput3Timer = c4_timer:new("HDMIAudioSelectionInProgressOutput3Timer", 500, "MILLISECONDS", OnHDMIAudioSelectionInProgressOutput3TimerExpired)
	
    -- Create an instance of the AVSwitchProxy class
    -- TODO: Change bProcessesDeviceMessages to false if Device Messages will not be processes
    local  bProcessesDeviceMessages = true
    local bUsePulseCommandsForVolumeRamping = false
    if (Properties["Ramping Method"] == "Pulse Commands") then bUsePulseCommandsForVolumeRamping = true end
    gAVSwitchProxy = AVSwitchProxy:new(AVSWITCH_PROXY_BINDINGID, bProcessesDeviceMessages, tVolumeRamping, bUsePulseCommandsForVolumeRamping)

    local minDeviceLevel = MIN_DEVICE_LEVEL
    local maxDeviceLevel = MAX_DEVICE_LEVEL
    tVolumeCurve = getVolumeCurve(minDeviceLevel, maxDeviceLevel)
	
	--[[
	For the "Volume Curve" method, tVolumeCurve is used to store volume level values that will be used to build volume commands during volume ramping. Specifically, they are used in GetNextVolumeCurveValue() which is called from the ContinueVolumeRamping() function.  Property values for "Volume Ramping Steps" and "Volume Ramping Slope" can be adjusted to get a smooth volume ramping from low to high volume.
	--]]
end

function getVolumeCurve(minDeviceLevel, maxDeviceLevel)
    local steps = tonumber(Properties["Volume Ramp Steps"])
    local slope = tonumber(Properties["Volume Ramp Slope"])
    local tCurve = gAVSwitchProxy:CreateVolumeCurve(steps, slope, minDeviceLevel, maxDeviceLevel)
    
    return tCurve 
end

--[[=============================================================================
    Driver Code
===============================================================================]]
function PackAndQueueCommand(...)
    local command_name = select(1, ...) or ""
    local command = select(2, ...) or ""
    local command_delay = select(3, ...) or tonumber(Properties["Command Delay Milliseconds"])
    local delay_units = select(4, ...) or "MILLISECONDS"
    LogTrace("PackAndQueueCommand(), command_name = " .. command_name .. ", command delay set to " .. command_delay .. " " .. delay_units)
    if (command == "") then
	   LogWarn("PackAndQueueCommand(), command_name = " .. command_name .. ", command string is empty - exiting PackAndQueueCommand()")
	   return
    end
	
	-- COMPLETE: pack command with any any required starting or ending characters
    local cmd, stx, etx
    LogWarn(gControlMethod)
    if (gControlMethod == "Network") then
		-- COMPLETE: define any required starting or ending characters. 
		stx = ""
		etx = "."
		cmd = stx .. command .. etx
    elseif (gControlMethod == "Serial") then
		-- COMPLETE: define any required starting or ending characters. 
		stx = ""
		etx = "."
		cmd = stx .. command .. etx
    elseif (gControlMethod == "IR") then
		cmd = command
    else
		LogWarn("PackAndQueueCommand(): gControlMethod is not valid, ".. gControlMethod)
		return
    end
    gCon:QueueCommand(cmd, command_delay, delay_units, command_name)	
	
end
