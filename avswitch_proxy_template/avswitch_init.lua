--[[=============================================================================
    AVSwitch Protocol Initialization Functions

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- This macro is utilized to identify the version string of the driver template version used.
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.device_messages = "2015.03.31"
end


PROTOCOL_DECLARATIONS = {}

function ON_DRIVER_EARLY_INIT.avswitch_init()

end

function ON_DRIVER_INIT.avswitch_init()
	--LogTrace("ON_DRIVER_INIT.ProtocolDeclarations()")
	for k,v in pairs(PROTOCOL_DECLARATIONS) do
		if (PROTOCOL_DECLARATIONS[k] ~= nil and type(PROTOCOL_DECLARATIONS[k]) == "function") then
			PROTOCOL_DECLARATIONS[k]()
		end
	end	
end

function ON_DRIVER_LATEINIT.avswitch_init()
end
	
function PROTOCOL_DECLARATIONS.CommandsTableInit_IR()
	LogTrace("PROTOCOL_DECLARATIONS.CommandsTableInit_IR()")

	CMDS_IR = {
		--index:  Proxy Command Name
		--value:  IR Code ID	 
		["ON"]             = "",
		["OFF"]            = "",
		["MUTE_ON"]        = "",
		["MUTE_OFF"]       = "",
		["MUTE_TOGGLE"]    = "",
		["INPUT_TOGGLE"]   = "",
		["NUMBER_0"]       = "", 	
		["NUMBER_1"]       = "",		
		["NUMBER_2"]       = "",	
		["NUMBER_3"]       = "",	
		["NUMBER_4"]       = "",	
		["NUMBER_5"]       = "",	
		["NUMBER_6"]       = "",	
		["NUMBER_7"]       = "",	
		["NUMBER_8"]       = "",	
		["NUMBER_9"]       = "",
		["STAR"]           = "",
		["DOT"]            = "",
		["INFO"]           = "", --Display
		["RECALL"]         = "",
		["PULSE_VOL_DOWN"] = "",
		["PULSE_VOL_UP"]   = "",
		["MENU"]           = "",
		["ENTER"]          = "",
		["UP"]             = "",
		["DOWN"]           = "",
		["LEFT"]           = "",
		["RIGHT"]          = "",
		["PREV"]           = "",
		["CANCEL"]         = "",
	}		
	
	--IR ZONE Commands
	CMDS_IR_ZONES = {}
	
	CMDS_IR_ZONES[0] = {
		--index:  Proxy Command Name
		--value:  IR Code ID
		["CONNECT_OUTPUT"] = "",
		["DISCONNECT_OUTPUT"] = "",	
		["VOLUME_UP"] = "",
		["VOLUME_DOWN"] = "",
		["MUTE_ON"] = "",
		["MUTE_OFF"] = "",
		["MUTE_TOGGLE"] = "",
	}	
	
	CMDS_IR_ZONES[1] = {
		["CONNECT_OUTPUT"] = "",
		["DISCONNECT_OUTPUT"] = "",
		["VOLUME_UP"] = "",
		["VOLUME_DOWN"] = "",
		["MUTE_ON"] = "",
		["MUTE_OFF"] = "",
		["MUTE_TOGGLE"] = "",
	}		
	
	CMDS_IR_ZONES[2] = {
		["CONNECT_OUTPUT"] = "",
		["DISCONNECT_OUTPUT"] = "",	
		["VOLUME_UP"] = "",
		["VOLUME_DOWN"] = "",
		["MUTE_ON"] = "",
		["MUTE_OFF"] = "",
		["MUTE_TOGGLE"] = "",		
	}	
	
	CMDS_IR_ZONES[3] = {
		["CONNECT_OUTPUT"] = "",
		["DISCONNECT_OUTPUT"] = "",	
		["VOLUME_UP"] = "",
		["VOLUME_DOWN"] = "",
		["MUTE_ON"] = "",
		["MUTE_OFF"] = "",
		["MUTE_TOGGLE"] = "",		
	}
	
	CMDS_IR[AVSWITCH_PROXY_BINDINGID] = {}	
	
end

function PROTOCOL_DECLARATIONS.CommandsTableInit_Serial()
	LogTrace("PROTOCOL_DECLARATIONS.CommandsTableInit_Serial()")

	CMDS = {
		--index:  Proxy Command Name
		--value:  Protocol Command Data
		
		--Power
		["ON"]             = "",
		["OFF"]            = "",
				
		--Menu
		["INFO"] = "",	--Display
		["GUIDE"] = "",
		["MENU"] = "",
		["CANCEL"] = "",
		["UP"] = "",
		["DOWN"] = "",
		["LEFT"] = "",
		["RIGHT"] = "",
		["ENTER"] = "",	
		["RECALL"]         = "",
		["PREV"]           = "",
		
		--Digits
		["NUMBER_0"]       = "", 	
		["NUMBER_1"]       = "",		
		["NUMBER_2"]       = "",	
		["NUMBER_3"]       = "",	
		["NUMBER_4"]       = "",	
		["NUMBER_5"]       = "",	
		["NUMBER_6"]       = "",	
		["NUMBER_7"]       = "",	
		["NUMBER_8"]       = "",	
		["NUMBER_9"]       = "",
		["STAR"]           = "",
		["DOT"]            = "",
	}
	
	CMDS[AVSWITCH_PROXY_BINDINGID] = {}
	
end

function PROTOCOL_DECLARATIONS.InputOutputTableInit()
	LogTrace("PROTOCOL_DECLARATIONS.InputOutputTableInit()")
	----------------------------------------- [*COMMAND/RESPONSE HELPER TABLES*] -----------------------------------------
	
	tOutputCommandMap = {
		--index:  value of Output Connection id
		--value:  Protocol Command Data
		[2000] = "",
		[2001] = "",
		[4000] = "",
		[4001] = "",
	}
	
	tInputCommandMap = {
		--index:  Connection Name
		--value:  Protocol Command Data	
		--["ADAPTER PORT"] = "33", 
		[""] = "",
	}
	
	tInputResponseMap = ReverseTable(tInputCommandMap)	-- Reverses the tInputCommandMap table
			
	
	tInputCommandMap_IR = { 
	}
	--Main Zone Input Selection Commands	
	tInputCommandMap_IR[0] = { 
		--index:  Connection Name
		--value:  IR Code ID
		--["ADAPTER PORT"] = "51362",
		[""] = "",
	}
	--Zone2 Input Selection Commands
	tInputCommandMap_IR[1] = { 	
		[""] = "",
	}
	--Zone3 Input Selection Commands
	tInputCommandMap_IR[2] = { 
		[""] = "",
	}
	--Zone4 Input Selection Commands	
	tInputCommandMap_IR[3] = { 
		[""] = "",
	}	
		
	----------------------------------------- [*I/O HELPER TABLES*] -----------------------------------------
	tOutputConnMap = {
		--index:  value of Output Connection id
		--value:  Output Connection Name
		[2000] = "Video 1",
		[2001] = "Video 2",
		[4000] = "Audio 1",
		[4001] = "Audio 2",
	}

	tInputConnMapByID = {
		--index:  value of Input Connection id
		--[1000] = {Name = "INPUT HDMI 1",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1000] = {Name = "",BindingID = AVSWITCH_PROXY_BINDINGID,},
	}
	
	tInputConnMapByName = {
		--index:  Input Connection Name
		--ID: value of Input Connection id
		--["INPUT HDMI 1"] = {ID = 0,BindingID = AVSWITCH_PROXY_BINDINGID,},
		[""] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,},
	}

end	

function PROTOCOL_DECLARATIONS.PowerCommandsTableInit_Serial()
	LogTrace("PROTOCOL_DECLARATIONS.PowerCommandsTableInit_Serial()")
	
	tPowerCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Power)
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "",
	}
end

function PROTOCOL_DECLARATIONS.VolumeCommandsTableInit_Serial()
	LogTrace("PROTOCOL_DECLARATIONS.VolumeCommandsTableInit_Serial()")
	
	tVolumeCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Pulse Volume - command prefix/suffix)
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "",	
	}

	tVolumeSetCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Discreet Volume - command prefix/suffix)	
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "", 
	}
	
	tVolumeQueryMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Volume Query)		
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "", 	
	}	

	tMuteCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Mute - command prefix/suffix)		
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "",
	}	
	
end

function ReverseTable(a)
	local b = {}
	for k,v in pairs(a) do b[v] = k end
	return b
end

