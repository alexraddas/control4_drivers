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
		--Switching
		["CONNECT_OUTPUT"] = "@OUT",
		["DISCONNECT_OUTPUT"] = "$OUT",
		["SET_INPUT"] = "OUT"
	}
	
	CMDS[AVSWITCH_PROXY_BINDINGID] = {}
	
end

function PROTOCOL_DECLARATIONS.InputOutputTableInit()
	LogTrace("PROTOCOL_DECLARATIONS.InputOutputTableInit()")
	----------------------------------------- [*COMMAND/RESPONSE HELPER TABLES*] -----------------------------------------
	
	tOutputCommandMap = {
		--index:  value of Output Connection id
		--value:  Protocol Command Data
		[2000] = "01",
		[2001] = "02",
		[2002] = "03",
		[2003] = "04",
		[2004] = "05",
		[2005] = "06",
		[2006] = "07",
		[2007] = "08"
	}
	
	tInputCommandMap = {
		--index:  Connection Name
		--value:  Protocol Command Data	
		--["ADAPTER PORT"] = "33", 
		["HDMI 1"] = "01",
		["HDMI 2"] = "02",
		["HDMI 3"] = "03",
		["HDMI 4"] = "04",
		["HDMI 5"] = "05",
		["HDMI 6"] = "06",
		["HDMI 7"] = "07",
		["HDMI 8"] = "08",

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
		[2000] = "HDBT 1",
		[2001] = "HDBT 2",
		[2002] = "HDBT 3",
		[2003] = "HDBT 4",
		[2004] = "HDBT 5",
		[2005] = "HDBT 6",
		[2006] = "HDBT 7",
		[2007] = "HDBT 8"
	}

	tInputConnMapByID = {
		--index:  value of Input Connection id
		--[1000] = {Name = "INPUT HDMI 1",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1000] = {Name = "HDMI 1",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1001] = {Name = "HDMI 2",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1002] = {Name = "HDMI 3",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1003] = {Name = "HDMI 4",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1004] = {Name = "HDMI 5",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1005] = {Name = "HDMI 6",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1006] = {Name = "HDMI 7",BindingID = AVSWITCH_PROXY_BINDINGID,},
		[1007] = {Name = "HDMI 8",BindingID = AVSWITCH_PROXY_BINDINGID,}
	}
	
	tInputConnMapByName = {
		--index:  Input Connection Name
		--ID: value of Input Connection id
		--["INPUT HDMI 1"] = {ID = 0,BindingID = AVSWITCH_PROXY_BINDINGID,},
		["HDMI 1"] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,},
		["HDMI 2"] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,},
		["HDMI 3"] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,},
		["HDMI 4"] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,},
		["HDMI 5"] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,},
		["HDMI 6"] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,},
		["HDMI 7"] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,},
		["HDMI 8"] = {ID = 1000,BindingID = AVSWITCH_PROXY_BINDINGID,}
	}

end	

function PROTOCOL_DECLARATIONS.PowerCommandsTableInit_Serial()
	LogTrace("PROTOCOL_DECLARATIONS.PowerCommandsTableInit_Serial()")
	
	tPowerCommandMap = {
		--index:  mod 1000 value of Output Connection id
		--value:  Protocol Command Data (Power)
		[0] = "01",
		[1] = "02",
		[2] = "03",
		[3] = "04",
		[4] = "05",
		[5] = "06",
		[6] = "07",
		[7] = "08",
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

