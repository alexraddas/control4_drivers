--[[=============================================================================
    Commands received from the AVSwitch proxy (ReceivedFromProxy)

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.device_messages = "2015.03.31"
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Power Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[
	Proxy Command: CONNECT_OUTPUT
	Parameters:
		output: mod 1000 value of Output Connection id
		class:  connection class
		output_id: value of Output Connection id
--]]
function CONNECT_OUTPUT(output, class, output_id)
    --[[ TODO:  The code below is intended as an example to expose the various elements involved in creating a valid Zone On command.
			 Special care should be taken to understand your device's capabilities and protocol syntax and, specifically, 
			 the best method for leveraging mapping tables, when appropriate, to enable programmatic building of commands. 
			 Depending on the device protocol, you may wish to use the full connection id or a mod 1000 value in your mapping tables.
			 For simple command protocol syntax, you may elect not to use mapping tables and 
			 merely derive the proper command syntax for the connection id values.
    --]]
    
    local command_delay = tonumber(Properties["Power On Delay Seconds"])
    local delay_units = "SECONDS"
    local command
    if (gControlMethod == "IR") then
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["CONNECT_OUTPUT"]
		LogTrace("command = " .. command)
		PackAndQueueCommand("CONNECT_OUTPUT", command, command_delay, delay_units)
    else

		-- TODO: create packet/command to send to the device
		command = ""		--tPowerCommandMap[output] .. "01"
		LogTrace("command = " .. command)
		PackAndQueueCommand("CONNECT_OUTPUT", command, command_delay, delay_units)
		
	     local isAudio = (output_id >= 4000)
	     if (isAudio) then
		  GetDeviceVolumeStatus(output)
	     end		
		
		-- TODO: If the device will automatically report power status after
		--	the On command is sent, then the line below can be commented out		
		GetDevicePowerStatus(output)
		
    end
end

--[[
	Proxy Command: DISCONNECT_OUTPUT
	Parameters:
		output: mod 1000 value of Output Connection id
	     class:  connection class
		output_id: value of Output Connection id
--]]
function DISCONNECT_OUTPUT(output, class, output_id)
    --[[ TODO:  The code below is intended as an example to expose the various elements involved in creating a valid Zone Off command.
			 Special care should be taken to understand your device's capabilities and protocol syntax and, specifically, 
			 the best method for leveraging mapping tables, when appropriate, to enable programmatic building of commands. 
			 Depending on the device protocol, you may wish to use the full connection id or a mod 1000 value in your mapping tables.
			 For simple command protocol syntax, you may elect not to use mapping tables and 
			 merely derive the proper command syntax from the connection id values.
    --]]

    local command_delay = tonumber(Properties["Power Off Delay Seconds"])
    local delay_units = "SECONDS"
    local command 
    local isAudio = (output_id >= 4000)
    
    if(isAudio) then
	   LogTrace("Received From Proxy: DISCONNECT_OUTPUT for AUDIO:: Output(" .. output_id ..  ")")   
    else
	   LogTrace("Received From Proxy: DISCONNECT_OUTPUT for VIDEO:: Output(" .. output_id ..  ")") 
    end

    --[[In certain scenarios (based upon AV connections and project bindings), a DISCONNECT_OUTPUT command is sent in error by the proxy.
	   This code block utilized timers that are started in the SET_INPUT function to determine if this DISCONNECT_OUTPUT command is
	   associated with a reselection transaction, in whcih case we will abort...
    --]]
    if not (isAudio) then
	   if (isAudioSelectionInProgress(output_id) == true) then 
		  LogTrace("Audio Selection is in progress.  Not Disconnecting.")
		  return 
	   elseif (isHDMIAudioSelectionInProgress(output, output_id) == true) then 
		  LogTrace("HDMI Audio Selection is in progress.  Not Disconnecting.")
		  return  
	   end
    end    		
    
    -- TODO: create packet/command to send to the device
    if (gControlMethod == "IR") then
	   command = CMDS_IR_ZONES[output]["DISCONNECT_OUTPUT"]
    else		
	   if (isAudio) then
		  gOutputToInputAudioMap[output] = -1
		  command = ""  	--audio disconnect element
	   else
		  gOutputToInputMap[output] = -1
		  command = ""		--video disconnect element
	   end
	   -- TODO: create packet/command to send to the device
	   command = command .. "" 	--tOutputCommandMap[output]	--tPowerCommandMap[output]

	   -- TODO: If the device will automatically report power status after
	   --	the Off command is sent, then the line below can be commented out
	   GetDevicePowerStatus(output)		
    end  
    
    LogTrace("command = " .. command)
    PackAndQueueCommand("DISCONNECT_OUTPUT", command, command_delay, delay_units)    
		
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Input Selection and AV Path Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[
	Proxy Command: SET_INPUT
	Parameters:
		idBinding: proxybindingid of proxy bound to input connection
		output: 			mod 1000 value of Output Connection ID	
		input: 			mod 1000 value of Input Connection ID
		input_id:			Input Connection ID
		class:			Connection Class
		output_id:		Output Connection id
		bSwitchSeparate	Setting of can_switch_separately capability
		bVideo			indicates a video path selection
		bAudio			indicates an audio path selection
--]]
function SET_INPUT(idBinding, output, input, input_id, class, output_id, bSwitchSeparate, bVideo, bAudio)
    --[[ TODO:  The code below is intended as an example to expose the various elements involved in creating a valid Source Selection command.
			 Special care should be taken to understand your device's capabilities and protocol syntax and, specifically, 
			 the best method for leveraging mapping tables, when appropriate, to enable programmatic building of commands. 
			 Depending on the device protocol, you may wish to use the full connection id or a mod 1000 value in your mapping tables.
			 For simple command protocol syntax, you may elect not to use mapping tables and 
			 merely derive the proper command syntax from the connection id values.
    --]]
    
    local command
    if (bSwitchSeparate) then	--device switches audio and video separatley
    
	   --DEBOUNCE LOGIC - in some instances (based upon signal type and project bindings) redundant commands are sent from the proxy
	   --so we can test here and abort the command, if desired
	   if (gAVSwitchProxy._PreviouslySelectedInput[output_id] == input_id) then return end    
	   
	   local isAudio = (output_id >= 4000)
	   if (isAudio) then
		  startAudioSelectionTimer(output)		--used in DISCONNECT_OUTPUT
		  gOutputToInputAudioMap[output] = input
		  command = ""		--InputCommandMap[input] --tOutputCommandMap[output])
	   else
		  startHDMIAudioSelectionTimer(output)	--used in DISCONNECT_OUTPUT
		  
		  --[[TODO: If your device can use two HDMI outputs to route video to 
				    one device (i.e TV) and audio to another device (i.e. AV Receiver) then you must review 
				    the logic in the mirrored output functions below and adjust, if necessary. 
				    Also these functions can be useful if your device supports EDID management functions. 
				    The gVideoProviderToRoomMap, gAudioProviderToRoomMap, gOutputToInputMap, gOutputToInputAudioMap 
				    mapping tables may be beneficial in developing your code logic. 
		  --]]
		  local mirrored_output_id = getMirroredOutputID(output_id)
		  local mirrorState = getMirroredOutputState(output_id)
		  if (mirrorState == "NO MIRROR ZONE") or (mirrorState == "AUDIO ZONE WITH MIRRORED VIDEO ZONE") or (mirrorState == "VIDEO ZONE WITH MIRRORED AUDIO ZONE") then
			 gOutputToInputMap[output] = input
			 command = "" --tInputCommandMap[input] .. tOutputCommandMap[output])
		  else
			 --ERR
			 return
		  end
		  
	   end
	   
    else	--[[device does not switch audio and video separatley, so we can use the mod 1000 values of the connection id 
			 to determine the audio and video legs of a given connection --]]
	   
	   --[[DEBOUNCE LOGIC - in some instances (based upon signal type and project bindings) redundant commands are sent from the proxy
		  so we can test here and abort the command, if desired --]]
	   if (gAVSwitchProxy._PreviouslySelectedInput[output] == input) then return end 

	   if (gControlMethod == "IR") then		
		-- TODO: create packet/command to send to the device
		command = tInputCommandMap_IR[output][tInputConnMapByID[input].Name]	
	   else
		-- TODO: create packet/command to send to the device
		--Edit the Input Selection command syntax based upon the protocol specification
		--if the tables referenced below are set up properly them no editing may be necessary 	
		command = "" 	--tOutputCommandMap[output] .. tInputCommandMap[tInputConnMapByID[input].Name] 
	   end 	

    end
	
    LogTrace("command = " .. command)
    PackAndQueueCommand("SET_INPUT", command)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Volume Control Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--[[
	Proxy Command: MUTE_OFF
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function MUTE_OFF(output)
	local command
	if (gControlMethod == "IR") then		
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["MUTE_OFF"]	
	else
		-- TODO: create packet/command to send to the device
		command = tMuteCommandMap[output] .. "OFF"
	end 	
	LogTrace("command = " .. command)
	PackAndQueueCommand("MUTE_OFF", command)
end

--[[
	Proxy Command: MUTE_ON
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function MUTE_ON(output)
	local command
	if (gControlMethod == "IR") then			
		command = CMDS_IR_ZONES[output]["MUTE_ON"]	
	else
		-- TODO: create packet/command to send to the device
		command = tMuteCommandMap[output] .. "ON"
	end 	
	LogTrace("command = " .. command)
	PackAndQueueCommand("MUTE_ON", command)		
end

--[[
	Proxy Command: MUTE_TOGGLE
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function MUTE_TOGGLE(output)
	local command
	if (gControlMethod == "IR") then			
		command = CMDS_IR_ZONES[output]["MUTE_TOGGLE"]	
	else
		-- TODO: create packet/command to send to the device
		command = tMuteCommandMap[output] .. "TOGGLE"
	end 
	LogTrace("command = " .. command)
	PackAndQueueCommand("MUTE_TOGGLE", command)
end

--[[
	Proxy Command: SET_VOLUME_LEVEL
	Parameters:
		output: mod 1000 value of Output Connection id	
		c4VolumeLevel: volume level to be set represented in Control4 scale (0-100)
--]]
function SET_VOLUME_LEVEL(output, c4VolumeLevel)
	local minDeviceLevel = MIN_DEVICE_LEVEL
	local maxDeviceLevel = MAX_DEVICE_LEVEL
	local deviceVolumeLevel = ConvertVolumeToDevice(c4VolumeLevel, minDeviceLevel, maxDeviceLevel)	
	
	---- TODO: uncomment and edit string padding, if required, based upon the protocol specification
    --deviceVolumeLevel = string.rep("0", 2 - string.len(deviceVolumeLevel)) .. deviceVolumeLevel
	
	LogInfo('deviceVolumeLevel: ' .. deviceVolumeLevel)
  
	-- TODO: create packet/command to send to the device
	local command = tVolumeSetCommandMap[output] .. deviceVolumeLevel
	LogTrace("command = " .. command)
	PackAndQueueCommand("SET_VOLUME_LEVEL", command)
end

--[[
	Helper Function: SET_VOLUME_LEVEL_DEVICE
	Parameters:
		output: mod 1000 value of Output Connection id	
		deviceVolumeLevel: volume level to be set represented in device scale (as sepcified in the device's control protocol)
--]]
function SET_VOLUME_LEVEL_DEVICE(output, deviceVolumeLevel)
	--Called from ContinueVolumeRamping()
	
	-- TODO: create packet/command to send to the device
	local command = tVolumeSetCommandMap[output] .. deviceVolumeLevel
	
	LogTrace("command = " .. command)
	local command_delay = tonumber(Properties["Volume Ramp Delay Milliseconds"])
	PackAndQueueCommand("SET_VOLUME_LEVEL_DEVICE", command, command_delay)
end

--[[
	Proxy Command: PULSE_VOL_DOWN
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function PULSE_VOL_DOWN(output)
	local command
	if (gControlMethod == "IR") then		
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["VOLUME_DOWN"]	
	else
		-- TODO: create packet/command to send to the device
		command = tVolumeCommandMap[output] .. 'D'
	end 		
	LogTrace("command = " .. command)
	local command_delay = tonumber(Properties["Volume Ramp Delay Milliseconds"])
	PackAndQueueCommand("PULSE_VOL_DOWN", command, command_delay)
end

--[[
	Proxy Command: PULSE_VOL_UP
	Parameters:
		output: mod 1000 value of Output Connection id	
--]]
function PULSE_VOL_UP(output)
	local command
	if (gControlMethod == "IR") then	
		-- TODO: create packet/command to send to the device
		command = CMDS_IR_ZONES[output]["VOLUME_UP"]	
	else
		-- TODO: create packet/command to send to the device
		command = tVolumeCommandMap[output] .. 'U'
	end 		
	LogTrace("command = " .. command)
	local command_delay = tonumber(Properties["Volume Ramp Delay Milliseconds"])
	PackAndQueueCommand("PULSE_VOL_UP", command, command_delay)
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- Helper Functions
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

--[[
	Helper Function: SEND_COMMAND_FROM_COMMAND_TABLE
	Parameters:
		idBinding: proxy id	
		output: mod 1000 value of Output Connection id
		command_name: name of command to be sent
--]]
function SEND_COMMAND_FROM_COMMAND_TABLE(idBinding, output, command_name)
    local output_for_log = output or "nil"
    LogTrace("SEND_COMMAND_FROM_COMMAND_TABLE(), idBinding=" .. idBinding .. ", output=" .. output_for_log .. ", command_name=" .. command_name)
	
	-- TODO: create packet/command to send to the device
	local command = GetCommandFromCommandTable(idBinding, output, command_name)
	
	if (command == nil) then
		LogTrace("command is nil")
	else
		LogTrace("command = " .. command)
		PackAndQueueCommand(command_name, command)
	end			
end

--[[
	Helper Function: GetCommandFromCommandTable
	Parameters:
		idBinding: proxy id	
		output: mod 1000 value of Output Connection id
		command_name: name of command to be returned
--]]
function GetCommandFromCommandTable(idBinding, command_name)
	LogTrace("GetCommand()")
	local t = {}
	
	-- TODO: create appropriate commands table structure
	
	if (gControlMethod == "IR") then
		t = CMDS_IR
	else
		t = CMDS
	end	

	if (t[idBinding] ~= nil) then
	   if (t[idBinding][command_name] ~= nil) then
		  return t[idBinding][command_name]
	   end
	end
	
	if (t[command_name] ~= nil) then
		return t[command_name]
	else
		LogWarn('GetCommandFromCommandTable: command not defined - '.. command_name)
		return nil
	end	
	
end


--[[
	Helper Function: GetDeviceVolumeStatus
--]]
function GetDeviceVolumeStatus(output)
    LOG:Trace("GetDeviceVolumeStatus(), output = " .. output)
	
	-- TODO: verify table entries in tVolumeQueryMap for all zones
	local command = tVolumeQueryMap[output] 
	LOG:Trace("command = " .. command)
	PackAndQueueCommand("GetDeviceVolumeStatus: Volume", command)
	
	-- TODO: verify table entries in tMuteCommandMap for all zones, modify line below if needed
	command = tMuteCommandMap[output] .. "?"
	LOG:Trace("command = " .. command)
	PackAndQueueCommand("GetDeviceVolumeStatus: Mute", command)	
end

--[[
	Helper Function: GetDevicePowerStatus
--]]
function GetDevicePowerStatus(output)
    LOG:Trace("GetDevicePowerStatus()")
	
	-- TODO: verify table entry in Volume in QUERY table
	local command = tPowerCommandMap[output] .. "?"
	LOG:Trace("command = " .. command)
	PackAndQueueCommand("GetDevicePowerStatus: Volume", command)	
end
