--[[=============================================================================
    AVSwitch Advance AV Path Handling Functions

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

function ON_DRIVER_LATEINIT.avpath()
     --[[
	   TODO: 	 If advanced path handling is required, uncomment the C4:SendToProxy call below which will notify the proxy 
			 that your protocol driver will handle the validation of all valid paths. This is accomplished via the
			 IS_AV_OUTPUT_TO_INPUT_VALID() proxy command which reports all paths based upon the driver connections and current 
			 project bindings. The value that you return with this function will flag a given path as valid or invalid. 
	--]]
	
     --C4:SendToProxy(AVSWITCH_PROXY_BINDINGID, 'PROTOCOL_WILL_HANDLE_AV_VALID', {})
end


--[[
IS_AV_OUTPUT_TO_INPUT_VALID PROXY COMMAND
PARAMS:
	[PARAM NAME]				(Sample Data)		[DESCRIPTION]
	
	Params_idRoom 				(31)				Room Id - INTEGER
	Params_bindingType 			(6)				Connection Type - INTEGER (Video=5, Audio=6, Room Binding=7)
	
	Consumer_idBinding 			(1000)			Input Connection Id 	- INTEGER
	Consumer_avClass 			(10)				Input Connection Class 	- INTEGER
	Consumer_sClass 			(HDMI)			Input Connection Class 	- STRING
	
	Provider_idBinding			(2009)			Output Connection Id 	- INTEGER
	Provider_sClass			(HDMI)			Output Connection Class 	- STRING
	Provider_avClass			(10)				Output Connection Class 	- INTEGER
		
	Params_pathType 			(0)				UNKNOWN (Always returns zero)
	Consumer_sConnName 			()				UNKNOWN (Always returns NIL)
	Provider_sConnName 			()				UNKNOWN (Always returns NIL)
	Params_idSource 			(0)				UNKNOWN (Always returns zero)
	Params_bIsSource 			(0)				UNKNOWN (Always returns zero)
	Params_idCurrentSource 		(0)				UNKNOWN (Always returns zero)
	Params_idQueue 			(0)				UNKNOWN (Always returns zero)
	Params_idMedia				(0)				UNKNOWN (Always returns zero)
	Params_sMediaType			()				UNKNOWN (Always returns NIL)
	
RETURN VALUES:
     "True"									The reported path is valid
     "False"									The reported path is invalid

This command is sent from the proxy for each valid connection path. A path is created for each input class to each output class for each approriate room binding type.
We need clarification of the frequency on which this commands sends the same path.
Examples:
	* One HDMI INPUT to One HDMI OUTPUT bound to a Room with 3 bound endpoints (Audio, Video & Video's Audio) will receiver 6 commands - 4 audio (type 6) and 2 video (type 5)
	* One DIGITAL_COAX INPUT to one HDMI OUTPUT & one STEREO OUTPUT bound to a Room with 3 bound endpoints (Audio, Video & Video's Audio) will receiver 4 commands - 4 audio (type 6) and 0 video (type 5)
	* One DIGITAL_COAX INPUT to one STEREO OUTPUT bound to a Room with 3 bound endpoints (Audio, Video & Video's Audio) will receiver 2 commands - 2 audio (type 6) and 0 video (type 5)
--]]
function IS_AV_OUTPUT_TO_INPUT_VALID(params)
    --[[
	   TODO: If all paths are not valid due to signal conversion limitations on your device, uncomment the call to 
			 the isPathValid() function below. You will also need to create the validation logic based upon the 
			 devices conversion capabilities. Note that if all paths are valid then just leave the default values in place.
    --]]
    
    --local pathIsValid, pathStatus = isPathValid(params)
    
    --TODO: Comment these lines if you uncomment the line above...
    local pathIsValid =  "True"
    local pathStatus = "VALID"
    
    --[[
	   A key benefit of the IS_AV_OUTPUT_TO_INPUT_VALID() function is to build mapping tables that enable your 
	   driver to make decsions based upon actual project bindings and room associations.
	   This can be beneifical in implementing EDID managment on HDMI matrices, mirroring outputs for delivery 
	   of audio and video to separate devices (i.d. TV & Receiver), and selection of separate audio sources 
	   while keeping same video source
    --]]
    updateMappingTables(params,pathStatus)
    
    return pathIsValid
end

function isPathValid(params)
    local consumer_idBinding 	= tonumber(params["Consumer_idBinding"])	-- we are consuming the source, so the consumer binding is the source
    local provider_idBinding 	= tonumber(params["Provider_idBinding"]) 	-- we are providing the output, to the output is the provider binding  
    local consumer_class    	= params["Consumer_sClass"]
    local provider_class    	= params["Provider_sClass"]
    
    --here is sample logic for illustration only. you will need to contruct the logic to match the signal conversion capabilities of your device
    if ((consumer_class == "DIGITAL_COAX") and (provider_class == "HDMI") and (Properties["SPDIF to HDMI Connections"] == "DISABLED")) then
		return "False","INVALID"
    elseif ((consumer_class == "HDMI") and (provider_class == "STEREO") and (Properties["Analog Audio Matrix to Matrix Mode"] == "ENABLED")) then
          --lock each HDMI input to only one STEREO output, detemined by id (input1 to output1, etc.)
		if (consumer_idBinding % 1000 == provider_idBinding % 1000) then
			return "True","VALID"
		else	
			return "False","INVALID"
		end
    else
		return "True","VALID"
    end
end 

--[[
	Proxy Command: BINDING_CHANGE_ACTION
	Parameters:
		idBinding: proxybindingid of proxy bound to input connection
		output: mod 1000 value of Output Connection id	
		input: mod 1000 value of Input Connection id
--]]
function BINDING_CHANGE_ACTION(params)
  --reintitalizing mapping tables to handle deleted bindings
  --current bindings will be re-added during input selection and any other instances where IS_AV_OUTPUT_TO_INPUT_VALID is called
  gVideoProviderToRoomMap = {}
  gAudioProviderToRoomMap = {}
  gLastReportedAVPaths = {}
  
  return nil
end

function updateMappingTables(params, pathStatus)
    --table to track path information
    local t = {
	   ["RoomID"]  				= tonumber(params["Params_idRoom"]),
	   ["PathType"]  				= tonumber(params["Params_bindingType"]),
	   ["PathStatus"]  				= pathStatus,
	   ["InputConnectionID"]  		= tonumber(params["Consumer_idBinding"]),
	   ["InputConnectionClassID"]  	= tonumber(params["Consumer_avClass"]),
	   ["InputConnectionClass"]  		= params["Consumer_sClass"],
	   ["OutputConnectionID"]  		= tonumber(params["Provider_idBinding"]),
	   ["OutputConnectionClassID"]  	= tonumber(params["Provider_avClass"]),
	   ["OutputConnectionClass"]  	= params["Provider_sClass"],
    }
	
    --build a unique key to avoid duplicate entries...
    local key = params["Params_idRoom"] .. ":" .. params["Params_bindingType"] .. ":" .. params["Provider_idBinding"] ..  ":" .. params["Provider_avClass"] .. ":" .. params["Consumer_idBinding"] ..  ":" .. params["Consumer_avClass"]
    gLastReportedAVPaths[key] = t   
    
	if (gAVPathType[tonumber(params["Params_bindingType"])] == "VIDEO") then
		--Video Output to Room mapping table
		gVideoProviderToRoomMap[params["Provider_idBinding"]] = params["Params_idRoom"]
	elseif (gAVPathType[tonumber(params["Params_bindingType"])] == "AUDIO") then
		--Audio Output Room mapping table 
		local apKey = params["Params_idRoom"] .. ":" .. params["Provider_idBinding"]
		gAudioProviderToRoomMap[apKey] = {["RoomID"] = params["Params_idRoom"], ["OutputConnectionID"] = params["Provider_idBinding"]}
	end	
end

function getMirroredOutputID(output_id)
	LogTrace("getMirroredOutputID, OUTPUT_ID=" .. output_id)
	local output, room_id
	
	--find audio leg of mirrored pair
	room_id = gVideoProviderToRoomMap[output_id]
	if (room_id ~= nil) then
		for j,k in pairs(gAudioProviderToRoomMap) do 
			if ( (tonumber(k.OutputConnectionID) >= 2000) and (tonumber(k.OutputConnectionID) <= 2999)) then --mirrored zone must be an HDMI output, not an audio output
				if (k.OutputConnectionID ~= output_id) and (k.RoomID == room_id) then
					--output = (k.OutputConnectionID % 1000) 
					return k.OutputConnectionID
				end
			end
		end
	end
	
	--find video leg of mirrored pair
	local room, out
	for j,k in pairs(gAudioProviderToRoomMap) do 
	    room, out = string.match(j, "(.+):(.+)")
		if (out == output_id) then
			room_id = room
			for o,r in pairs(gVideoProviderToRoomMap) do 
			  if (r == room_id) then
				if ( (tonumber(o) >= 2000) and (tonumber(o) <= 2999)) then --mirrored zone must be an HDMI output, not an audio output
					if (o ~= output_id) and (r == room_id) then
						--output = (o % 1000) 
						return o
					end
				end			  
			  end
			end
		end	
	end	

	return -1
  
end

function getPathTypeFromOutputID(output_id)
  --mirrored zone ids are all in video range
  for j,k in pairs(gLastReportedAVPaths) do
    if (output_id == tonumber(k.OutputConnectionID)) then
      local pathType = gAVPathType[k.PathType]
	 return pathType
    end
  end  
end

function getMirroredOutputState(output_id)
  LogTrace("getMirroredOutputState(Output = " .. tOutputConnMap[output_id] .. ")")
  local mirrored_output_id = getMirroredOutputID(output_id)  
  if (mirrored_output_id == -1) then
    --no mirror zone
	return "NO MIRROR ZONE"  
  else
    if (getPathTypeFromOutputID(output_id) == "AUDIO") then
	   --this is the Audio Zone, so the Mirrored Zone is Video
	   return "AUDIO ZONE WITH MIRRORED VIDEO ZONE"
    else 
	   return "VIDEO ZONE WITH MIRRORED AUDIO ZONE"
    end	 
  end
end

function startAudioSelectionTimer(output)
  if (output == 0) then
    gAudioSelectionInProgressOutput0Timer:StartTimer() 
  elseif (output == 1) then
    gAudioSelectionInProgressOutput1Timer:StartTimer() 
  elseif (output == 2) then
    gAudioSelectionInProgressOutput2Timer:StartTimer() 
  elseif (output == 3) then
    gAudioSelectionInProgressOutput3Timer:StartTimer()  
  else
	LogTrace("startAudioSelectionTimer, invalid output = " .. output)
  end
end

function startHDMIAudioSelectionTimer(output)
  if (output == 0) then
    gHDMIAudioSelectionInProgressOutput0Timer:StartTimer() 
  elseif (output == 1) then
    gHDMIAudioSelectionInProgressOutput1Timer:StartTimer() 
  elseif (output == 2) then
    gHDMIAudioSelectionInProgressOutput2Timer:StartTimer() 
  elseif (output == 3) then
    gHDMIAudioSelectionInProgressOutput3Timer:StartTimer()     	
  else
	LogTrace("startHDMIAudioSelectionTimer, invalid output = " .. output)
  end
end

function isAudioSelectionInProgress(output_id)
  local bInProgress = false
  local output
  local room_id = gVideoProviderToRoomMap[output_id]
  for j,k in pairs(gAudioProviderToRoomMap) do 
	if ( (tonumber(k.OutputConnectionID) >= 4000) and (tonumber(k.OutputConnectionID) <= 4999)) then --zone must be an audio output, not an HDMI output
		if (k.RoomID == room_id) then
		  output = (k.OutputConnectionID % 1000)
		  bInProgress = isAudioSelectionInProgressByOutput(output)
		  if (bInProgress) then break end
		end
	end	
  end
  
  if (output == nil) then 
    if (room_id == nil) then --commands coming from programming may not have roomid
      LogTrace("isAudioSelectionInProgress, Selection in progress is False for Video Output("  .. output_id .. "), no Audio Output is mapped.")
    else 
	 LogTrace("isAudioSelectionInProgress, Selection in progress is False for Video Output("  .. output_id .. ") in room(" .. room_id .. "), no Audio Output is mapped.")
    end
    
    return false 
  end
  
  local sInProgress
  if (bInProgress == true) then
    sInProgress = "True"
  else
    sInProgress = "False"
  end
  
  --since we only know of the valid paths, not the actual path that director has taken in a matrix to matrix setup, this test is not conclusive...
  --we will abort the disconnect if any valid path has a audio selection in progress...
  LogTrace("isAudioSelectionInProgress, Audio Selection in progress is " .. sInProgress .. " for Video Output("  .. output_id .. ") in room(" .. room_id .. ") is mapped to Audio Output(" .. output .. ").")
  
  return bInProgress 
  
end

function isAudioSelectionInProgressByOutput(output)
  local bInProgress = false
  if (output == 0) then
    if(gAudioSelectionInProgressOutput0Timer:TimerStarted()) then
      bInProgress = true
    end
  elseif (output == 1) then
    if(gAudioSelectionInProgressOutput1Timer:TimerStarted()) then
      bInProgress = true
    end	
  elseif (output == 2) then
    if(gAudioSelectionInProgressOutput2Timer:TimerStarted()) then
      bInProgress = true
    end 
  elseif (output == 3) then
    if(gAudioSelectionInProgressOutput3Timer:TimerStarted()) then
      bInProgress = true
    end
  else
	LogTrace("isAudioSelectionInProgressByOutput, bogus output = " .. output)
  end
  
  return bInProgress
  
end

function isHDMIAudioSelectionInProgress(output, output_id)
  local bInProgress = false

  if (output == 0) then
    if(gHDMIAudioSelectionInProgressOutput0Timer:TimerStarted()) then
      bInProgress = true
    end  
  elseif (output == 1) then
    if(gHDMIAudioSelectionInProgressOutput1Timer:TimerStarted()) then
      bInProgress = true
    end
  elseif (output == 2) then
    if(gHDMIAudioSelectionInProgressOutput2Timer:TimerStarted()) then
      bInProgress = true
    end 
  elseif (output == 3) then
    if(gHDMIAudioSelectionInProgressOutput3Timer:TimerStarted()) then
      bInProgress = true
    end
  else
	LogTrace("isHDMIAudioSelectionInProgress, bogus output = " .. output)
  end
  
  --check if mirrored zone has an input selection in progress
  if (bInProgress == false) then
	local mirrored_output_id = getMirroredOutputID(output_id)
	bInProgress = isHDMIAudioSelectionInProgressInMirroredZone(mirrored_output_id)
	return bInProgress
  end	
  
  local sInProgress
  if (bInProgress == true) then
    sInProgress = "True"
  else
    sInProgress = "False"
  end
  
  LogTrace("isHDMIAudioSelectionInProgress, Selection in progress is " .. sInProgress .. " for Output(" .. output .. ").")
  return bInProgress 
  
end

function isHDMIAudioSelectionInProgressInMirroredZone(mirrored_output_id)
  local output = mirrored_output_id % 1000
  local bInProgress = false

  if (output == 0) then
    if(gHDMIAudioSelectionInProgressOutput0Timer:TimerStarted()) then
      bInProgress = true
    end  
  elseif (output == 1) then
    if(gHDMIAudioSelectionInProgressOutput1Timer:TimerStarted()) then
      bInProgress = true
    end
  elseif (output == 2) then
    if(gHDMIAudioSelectionInProgressOutput2Timer:TimerStarted()) then
      bInProgress = true
    end 
  elseif (output == 3) then
    if(gHDMIAudioSelectionInProgressOutput3Timer:TimerStarted()) then
      bInProgress = true
    end
  else
	LogTrace("isHDMIAudioSelectionInProgressInMirroredZone, bogus output = " .. output)
  end
  
  local sInProgress
  if (bInProgress == true) then
    sInProgress = "True"
  else
    sInProgress = "False"
  end
  
  LogTrace("isHDMIAudioSelectionInProgressInMirroredZone, Selection in progress is " .. sInProgress .. " for Output(" .. output .. ").")
  return bInProgress 
  
end


--[[=============================================================================
    Timer Expriation Code
===============================================================================]]
function OnAudioSelectionInProgressOutput0TimerExpired()
    LogTrace("OnAudioSelectionInProgressOutput0TimerExpired()")
    gAudioSelectionInProgressOutput0Timer:KillTimer()
end

function OnAudioSelectionInProgressOutput1TimerExpired()
    LogTrace("OnAudioSelectionInProgressOutput1TimerExpired()")
    gAudioSelectionInProgressOutput1Timer:KillTimer()
end

function OnAudioSelectionInProgressOutput2TimerExpired()
    LogTrace("OnAudioSelectionInProgressOutput2TimerExpired()")
    gAudioSelectionInProgressOutput2Timer:KillTimer()
end

function OnAudioSelectionInProgressOutput3TimerExpired()
    LogTrace("OnAudioSelectionInProgressOutput3TimerExpired()")
    gAudioSelectionInProgressOutput3Timer:KillTimer()
end


function OnHDMIAudioSelectionInProgressOutput0TimerExpired()
    LogTrace("OnHDMIAudioSelectionInProgressOutput0TimerExpired()")
    gHDMIAudioSelectionInProgressOutput0Timer:KillTimer()
end

function OnHDMIAudioSelectionInProgressOutput1TimerExpired()
    LogTrace("OnHDMIAudioSelectionInProgressOutput1TimerExpired()")
    gHDMIAudioSelectionInProgressOutput1Timer:KillTimer()
end

function OnHDMIAudioSelectionInProgressOutput2TimerExpired()
    LogTrace("OnHDMIAudioSelectionInProgressOutput2TimerExpired()")
    gHDMIAudioSelectionInProgressOutput2Timer:KillTimer()
end

function OnHDMIAudioSelectionInProgressOutput3TimerExpired()
    LogTrace("OnHDMIAudioSelectionInProgressOutput3TimerExpired()")
    gHDMIAudioSelectionInProgressOutput3Timer:KillTimer()
end
