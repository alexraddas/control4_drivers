--[[=============================================================================
    AVSwitch Proxy Class Code

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.properties = "2015.03.31"
end

AVSwitchProxy = inheritsFrom(nil)

function AVSwitchProxy:construct(avswitchBindingID, bProcessesDeviceMessages, tVolumeRampingTracking, bUsePulseCommandsForVolumeRamping)
	-- member variables
	self._AVSwitchBindingID = avswitchBindingID
	self._PowerState = {}						--Valid Values: "ON", "OFF", "POWER_ON_SEQUENCE", "POWER_OFF_SEQUENCE"
	self._VolumeIsRamping = false
	self._VolumeRamping = tVolumeRampingTracking		--[0] = {state = false,mode = "",} ||	"state" is boolean, "mode" values: "VOLUME_UP" & "VOLUME_DOWN"
	self._UsePulseCommandsForVolumeRamping = bUsePulseCommandsForVolumeRamping or false
	self._LastVolumeStatusValue = {}	
	self._MenuNavigationInProgress = false
     self._MenuNavigationMode = ""
	self._MenuNavigationProxyID = ""
	self._MenuNavigationOutput = ""
	self._CurrentlySelectedInput = {}
	self._PreviouslySelectedInput = {}
	self._ProcessesDeviceMessages = bProcessesDeviceMessages
	self._ControlMethod = ""						--Valid Values: "NETWORK", "SERIAL", "IR" 
end

------------------------------------------------------------------------
-- AVSwitch Proxy Commands (PRX_CMD)
------------------------------------------------------------------------
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Power Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_ON(tParams)
	--Handled by CONNECT_OUTPUT
	--ON()
end

function AVSwitchProxy:prx_OFF(tParams)
	--Handled by DISCONNECT_OUTPUT
	--OFF()
end

function AVSwitchProxy:prx_CONNECT_OUTPUT(tParams)
	local output = tonumber(tParams.OUTPUT) % 1000 
	local class = tParams.CLASS
	local output_id = tonumber(tParams["OUTPUT"])
	
	if (self._ProcessesDeviceMessages == false) then
		self._PowerState[output] = 'ON'
	else	
		self._PowerState[output] = 'POWER_ON_SEQUENCE'
	end	
	
	CONNECT_OUTPUT(output, class, output_id)
end

function AVSwitchProxy:prx_DISCONNECT_OUTPUT(tParams)
    local output = tonumber(tParams.OUTPUT) % 1000
    local class = tParams.CLASS
    local output_id = tonumber(tParams["OUTPUT"])
    if (self._ProcessesDeviceMessages == false) then
	   self._PowerState[output] = 'OFF'
    else	
	   self._PowerState[output] = 'POWER_OFF_SEQUENCE'
    end	
    DISCONNECT_OUTPUT(output, class, output_id)
  
    self._CurrentlySelectedInput[output] = -1
    self._PreviouslySelectedInput[output_id] = -1
    C4:SendToProxy(self._AVSwitchBindingID, 'INPUT_OUTPUT_CHANGED', {INPUT = -1, OUTPUT = 4000 + output})
    C4:SendToProxy(self._AVSwitchBindingID, 'INPUT_OUTPUT_CHANGED', {INPUT = -1, OUTPUT = 2000 + output})
end


--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Input Selection and AV Path Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_SET_INPUT(idBinding, tParams)
	local input = tonumber(tParams["INPUT"] % 1000)
	local output = tonumber(tParams["OUTPUT"] % 1000)
	local input_id = tonumber(tParams["INPUT"])
	local class = tParams["CLASS"]
	local output_id = tonumber(tParams["OUTPUT"])
	local bSwitchSeparate, bVideo, bAudio = false, false, false
	local bSwitchSeparate = tParams["SWITCH_SEPARATE"]
	if (tParams["SWITCH_SEPARATE"] == "True") then bSwitchSeparate = true end
	if (tParams["VIDEO"] == "True") then bVideo = true end
	if (tParams["AUDIO"] == "True") then bAudio = true end
	self._CurrentlySelectedInput[output_id] = input_id
	if (gControlMethod == "IR") then			
		NOTIFY.INPUT_OUTPUT_CHANGED(self._AVSwitchBindingID, input, output)		
	end 		
	SET_INPUT(idBinding, output, input, input_id, class, output_id, bSwitchSeparate, bVideo, bAudio)
	self._PreviouslySelectedInput[output_id] = input_id
end

function AVSwitchProxy:prx_BINDING_CHANGE_ACTION(idBinding, tParams)
    BINDING_CHANGE_ACTION(tParams)
end

function AVSwitchProxy:prx_IS_AV_OUTPUT_TO_INPUT_VALID(idBinding, tParams)
    return IS_AV_OUTPUT_TO_INPUT_VALID(tParams)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Volume Control Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_MUTE_OFF(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) or DEFAULT_OUTPUT_ID
	if (gControlMethod == "IR") then			
		NOTIFY.MUTE_CHANGED(self._AVSwitchBindingID, output, "False")
	end 		
	MUTE_OFF(output)
end

function AVSwitchProxy:prx_MUTE_ON(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) or DEFAULT_OUTPUT_ID
	if (gControlMethod == "IR") then			
		NOTIFY.MUTE_CHANGED(self._AVSwitchBindingID, output, "True")
	end 		
	MUTE_ON(output)
end

function AVSwitchProxy:prx_MUTE_TOGGLE(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	MUTE_TOGGLE(output)
end

function AVSwitchProxy:prx_SET_VOLUME_LEVEL(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	local c4VolumeLevel = tonumber(tParams['LEVEL'])
	SET_VOLUME_LEVEL(output, c4VolumeLevel)
end

function AVSwitchProxy:prx_PULSE_VOL_DOWN(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	PULSE_VOL_DOWN(output)
end

function AVSwitchProxy:prx_PULSE_VOL_UP(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	PULSE_VOL_UP(output)
end

function AVSwitchProxy:prx_START_VOL_DOWN(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	self:ChangeVolume(output, "START_VOL_DOWN")
end

function AVSwitchProxy:prx_START_VOL_UP(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000)
	self:ChangeVolume(output, "START_VOL_UP")
end

function AVSwitchProxy:prx_STOP_VOL_DOWN(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000)
	self:ChangeVolume(output, "STOP_VOL_DOWN")
end

function AVSwitchProxy:prx_STOP_VOL_UP(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000)
	self:ChangeVolume(output, "STOP_VOL_UP")
end

function AVSwitchProxy:prx_PULSE_BASS_DOWN(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	PULSE_BASS_DOWN(output)
end

function AVSwitchProxy:prx_PULSE_BASS_UP(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	PULSE_BASS_UP(output)
end

function AVSwitchProxy:prx_SET_BASS_LEVEL(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	local c4BassLevel = tonumber(tParams['LEVEL'])
	SET_BASS_LEVEL(output, c4BassLevel)
end

function AVSwitchProxy:prx_PULSE_TREBLE_DOWN(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	PULSE_TREBLE_DOWN(output)
end

function AVSwitchProxy:prx_PULSE_TREBLE_UP(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	PULSE_TREBLE_UP(output)
end

function AVSwitchProxy:prx_SET_TREBLE_LEVEL(tParams)
	local output = tonumber(tParams["OUTPUT"] % 1000) 
	local c4TrebleLevel = tonumber(tParams['LEVEL'])
	SET_TREBLE_LEVEL(output, c4TrebleLevel)
end

---------------------- Volume Helper Functions ----------------------
function AVSwitchProxy:ChangeVolume(output, command_name)
	if (command_name == "STOP_VOL_UP") or (command_name == "STOP_VOL_DOWN") then
		self._VolumeIsRamping = false
		self._VolumeRamping[output].state = false
		self._VolumeRamping[output].mode = ""
	elseif (command_name == "START_VOL_UP") then 
		self._VolumeIsRamping = true
		self._VolumeRamping[output].state = true
		self._VolumeRamping[output].mode = "VOLUME_UP" 
		PULSE_VOL_UP(output)	
	elseif (command_name == "START_VOL_DOWN") then 	
		self._VolumeIsRamping = true
		self._VolumeRamping[output].state = true
		self._VolumeRamping[output].mode = "VOLUME_DOWN"	
		PULSE_VOL_DOWN(output)		
	else
		LogWarn(command_name .. " not handled in ChangeVolume()")
	end
end

function AVSwitchProxy:ContinueVolumeRamping(output)
	local command
	if (gControlMethod == "IR") then   
		if (self._VolumeRamping[output].mode == "VOLUME_UP") then
			PULSE_VOL_UP(output)	
		elseif (self._VolumeRamping[output].mode == "VOLUME_DOWN") then
			PULSE_VOL_DOWN(output)	
		else
			LogWarn("ContinueVolumeRamping() ramping mode is not valid.")
		end	
	else
	     if (self._UsePulseCommandsForVolumeRamping) then
		    if (self._VolumeRamping[output].mode == "VOLUME_UP") then
			 PULSE_VOL_UP(output)	
		    elseif (self._VolumeRamping[output].mode == "VOLUME_DOWN") then
			 PULSE_VOL_DOWN(output)	
		    else
			 LogWarn("ContinueVolumeRamping() ramping mode is not valid.")
		    end	
		else
		    local volume = self._LastVolumeStatusValue[output]
		    local deviceVolumeLevel = self:GetNextVolumeCurveValue(output, volume)
		    if (deviceVolumeLevel ~= nil) then
			    self._LastVolumeStatusValue[output] = deviceVolumeLevel
			    SET_VOLUME_LEVEL_DEVICE(output, deviceVolumeLevel)                                 
		    else
			    LogWarn("ContinueVolumeRamping() next value is nil")
			    return
		    end
	     end
	end 
end

function AVSwitchProxy:GetNextVolumeCurveValue(output, volume)
	local i, point
	volume=tonumber(volume)
	if (self._VolumeRamping[output].mode == "VOLUME_UP") then
		for i=1,table.maxn(tVolumeCurve) do
			point=tonumber(tVolumeCurve[i])
			if point > volume then		
				return tVolumeCurve[i]
			end
		end
	elseif (self._VolumeRamping[output].mode == "VOLUME_DOWN") then
		for i=table.maxn(tVolumeCurve),1,-1 do
			point=tonumber(tVolumeCurve[i])
			if point < volume then
				return tVolumeCurve[i]
			end
		end
	else
		LogWarn("Volume Ramping Mode not set for "  .. tOutputConnMap[output])
		return nil
	end 
end

function AVSwitchProxy:CreateVolumeCurve(steps, slope, minDeviceLevel, maxDeviceLevel)
    local curveV = {}
    curveV.__index = curveV

    function curveV:new(min, max, base)
	 local len = max-min
	 local logBase = math.log(base)
	 local baseM1 = base-1

	 local instance = {
	   min = min,
	   max = max,
	   len = len,
	   base = base,
	   logBase = logBase,
	   baseM1 = baseM1,
	   toNormal = function(x)
		return (x-min)/len
	   end,
	   fromNormal = function(x)
		return min+x*len
	   end,
	   value = function(x)
		return math.log(x*baseM1+1)/logBase
	   end,
	   invert = function(x)
		return (math.exp(x*logBase)-1)/baseM1
	   end
	 }
	 return setmetatable(instance, self)
    end

    function curveV:list(from, to, steps)
	 local fromI = self.invert(self.toNormal(from))
	 local toI = self.invert(self.toNormal(to))

	 for i = 1, steps do
	   --print(i, self.fromNormal(self.value(fromI+(i-1)*(toI-fromI)/(steps-1))))
	    print(i, math.floor(self.fromNormal(self.value(fromI+(i-1)*(toI-fromI)/(steps-1)))))
	 end
    end
    
    function curveV:create_curve(from, to, steps)
	 local fromI = self.invert(self.toNormal(from))
	 local toI = self.invert(self.toNormal(to))
	 
      local tCurve = {}
	 for i = 1, steps do
	   --print(i, self.fromNormal(self.value(fromI+(i-1)*(toI-fromI)/(steps-1))))
	   --print(i, math.floor(self.fromNormal(self.value(fromI+(i-1)*(toI-fromI)/(steps-1)))))
	    
	    local x = math.floor(self.fromNormal(self.value(fromI+(i-1)*(toI-fromI)/(steps-1))))
	    
	    if (has_value(tCurve, x) == false) then
		  table.insert(tCurve, x)
		  print(i, x)
	    end
	 end
	 
	 return tCurve
    end
    
    

    -- min, max, base of log (must be > 1), try some for the best results
    local a = curveV:new(minDeviceLevel, maxDeviceLevel, slope)

    -- from, to, steps
    --a:list(minDeviceLevel, maxDeviceLevel, steps)
    
    local t = a:create_curve(minDeviceLevel, maxDeviceLevel, steps)
    
    return t

end

function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function ConvertVolumeToC4(volume, minDeviceLevel, maxDeviceLevel)
	--to be used when converting a volume level from a device to a 
	--percentage value that can be used by C4 proxies
	--"volume" is the volume value from the device
	--"minDeviceLevel" & "maxDeviceLevel" are the minimum and maximum volume levels
	--as specified in the device protocol documentation
	return ProcessVolumeLevel(volume, minDeviceLevel, maxDeviceLevel, 0, 100)
end

function ConvertVolumeToDevice(volume, minDeviceLevel, maxDeviceLevel)
	--to be used when converting a volume level from a C4 proxy to a 
	--value that can be used by the device 
	--"volume" is the volume value from the C4 proxy
	--"minDeviceLevel" & "maxDeviceLevel" are the minimum and maximum volume levels
	--as specified in the device protocol documentation
	return ProcessVolumeLevel(volume, 0, 100, minDeviceLevel, maxDeviceLevel)
end

function ProcessVolumeLevel(volLevel, minVolLevel, maxVolLevel, minDeviceLevel, maxDeviceLevel)
	  local level = (volLevel-minVolLevel)/(maxVolLevel-minVolLevel)
	  --LogInfo("level = " .. level)
	  local vl=(level*(maxDeviceLevel-minDeviceLevel))+minDeviceLevel
	  --LogInfo("vl = " .. vl)
	  vl= tonumber_loc(("%.".."0".."f"):format(vl))
	  --LogInfo("vl new = " .. vl)
	  LogInfo("ProcessVolumeLevel(level in=" .. volLevel .. ", level out=" .. vl .. ")")
	  return vl
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Menu Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_INFO(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "INFO")
end

function AVSwitchProxy:prx_GUIDE(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "GUIDE")
end

function AVSwitchProxy:prx_MENU(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "MENU")
end

function AVSwitchProxy:prx_CANCEL(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "CANCEL")
end

function AVSwitchProxy:prx_UP(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "UP")
end

function AVSwitchProxy:prx_DOWN(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "DOWN")
end

function AVSwitchProxy:prx_LEFT(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "LEFT")
end

function AVSwitchProxy:prx_RIGHT(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "RIGHT")
end

function AVSwitchProxy:prx_START_DOWN(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	self:NavigateMenu(idBinding, output, "START_DOWN")
end

function AVSwitchProxy:prx_START_UP(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	self:NavigateMenu(idBinding, output,  "START_UP")
end

function AVSwitchProxy:prx_START_LEFT(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	self:NavigateMenu(idBinding, output, "START_LEFT")
end

function AVSwitchProxy:prx_START_RIGHT(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	self:NavigateMenu(idBinding, output, "START_RIGHT")
end

function AVSwitchProxy:prx_STOP_DOWN(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	self:NavigateMenu(idBinding, output, "STOP_DOWN")
end

function AVSwitchProxy:prx_STOP_UP(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	self:NavigateMenu(idBinding, output, "STOP_UP")
end

function AVSwitchProxy:prx_STOP_LEFT(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	self:NavigateMenu(idBinding, output, "STOP_LEFT")
end

function AVSwitchProxy:prx_STOP_RIGHT(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	self:NavigateMenu(idBinding, output, "STOP_RIGHT")
end

function AVSwitchProxy:prx_ENTER(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "ENTER")
end

function AVSwitchProxy:prx_RECALL(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "RECALL")
end

function AVSwitchProxy:prx_OPEN_CLOSE(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "OPEN_CLOSE")
end

function AVSwitchProxy:prx_PROGRAM_A(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "PROGRAM_A")
end

function AVSwitchProxy:prx_PROGRAM_B(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "PROGRAM_B")
end

function AVSwitchProxy:prx_PROGRAM_C(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "PROGRAM_C")
end

function AVSwitchProxy:prx_PROGRAM_D(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "PROGRAM_D")
end

---------------------- Menu Navigation Helper Functions ----------------------
function AVSwitchProxy:NavigateMenu(idBinding, output, command_name)
	if (command_name == "STOP_UP") 
				or (command_name == "STOP_DOWN") 
				or (command_name == "STOP_LEFT") 
				or (command_name == "STOP_RIGHT") then
		self._MenuNavigationInProgress = false
		self._MenuNavigationMode = ""
		self._MenuNavigationProxyID = ""
		return
	elseif (command_name == "START_UP") then 
		self._MenuNavigationMode = "UP"
	elseif (command_name == "START_DOWN") then 	
		self._MenuNavigationMode = "DOWN"	
	elseif (command_name == "START_LEFT") then 
		self._MenuNavigationMode = "LEFT"	
     elseif (command_name == "START_RIGHT") then 
		self._MenuNavigationMode = "RIGHT"
	else
		LogWarn(command_name .. " not handled in NavigateMenu()")
	end
	
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, self._MenuNavigationMode)
	self._MenuNavigationInProgress = true
	self._MenuNavigationProxyID = idBinding
	self._MenuNavigationOutput = output
	
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Digit Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function AVSwitchProxy:prx_NUMBER_0(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_0")
end

function AVSwitchProxy:prx_NUMBER_1(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_1")
end

function AVSwitchProxy:prx_NUMBER_2(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_2")
end

function AVSwitchProxy:prx_NUMBER_3(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_3")
end

function AVSwitchProxy:prx_NUMBER_4(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_4")
end

function AVSwitchProxy:prx_NUMBER_5(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_5")
end

function AVSwitchProxy:prx_NUMBER_6(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_6")
end

function AVSwitchProxy:prx_NUMBER_7(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_7")
end

function AVSwitchProxy:prx_NUMBER_8(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_8")
end

function AVSwitchProxy:prx_NUMBER_9(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "NUMBER_9")
end

function AVSwitchProxy:prx_STAR(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "STAR")
end

function AVSwitchProxy:prx_POUND(idBinding, tParams)
	local output = get_output_with_nil_test(tParams["OUTPUT"])
	SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, "POUND")
end

function get_output_with_nil_test(output)
	local id = nil
	if (output ~= nil) then
		id = tonumber(output % 1000)
	end
	return id
end

------------------------------------------------------------------------
-- AVSwitch Proxy Notifies
------------------------------------------------------------------------

function AVSwitchProxy:dev_InputOutputChanged(input_id, output_id)
	NOTIFY.INPUT_OUTPUT_CHANGED(self._AVSwitchBindingID, input_id, output_id)
end

function AVSwitchProxy:dev_PowerOn(output)
	self._PowerState[output] = "ON"
	NOTIFY.ON()	
end

function AVSwitchProxy:dev_PowerOff(output)
	self._PowerState[output] = "OFF"
	NOTIFY.OFF()
end

function AVSwitchProxy:dev_VolumeLevelChanged(output, c4Level, deviceLevel)
	NOTIFY.VOLUME_LEVEL_CHANGED(self._AVSwitchBindingID, output, c4Level)	
	
	if (self._VolumeIsRamping) then
		--do nothing
		--during volume ramping, LastVolumeStatusValue is set in ContinueVolumeRamping()
	else
		self._LastVolumeStatusValue[output] = deviceLevel
	end	
end

function AVSwitchProxy:dev_MuteChanged(output, state)
	NOTIFY.MUTE_CHANGED(self._AVSwitchBindingID, output, state)
end		

function AVSwitchProxy:dev_BassLevelChanged(output, level)
	NOTIFY.BASS_LEVEL_CHANGED(self._AVSwitchBindingID, output, level)
end	

function AVSwitchProxy:dev_TrebleLevelChanged(output, level)
	NOTIFY.TREBLE_LEVEL_CHANGED(self._AVSwitchBindingID, output, level)
end	

function AVSwitchProxy:dev_BalanceLevelChanged(output, level)
	NOTIFY.BALANCE_LEVEL_CHANGED(self._AVSwitchBindingID, output, level)
end	

function AVSwitchProxy:dev_LoudnessChanged(output, state)
	NOTIFY.LOUDNESS_CHANGED(self._AVSwitchBindingID, output, state)
end
