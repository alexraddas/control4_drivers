--[[=============================================================================
    Base for a network connection driver

    Copyright 2017 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_device_connection_base"
require "lib.c4_log"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_network_connection = "2017.08.17"
end

DEFAULT_POLLING_INTERVAL_SECONDS = 30
DEFAULT_RECONNECT_INTERVAL_SECONDS = 5

gNetworkKeepAliveInterval = DEFAULT_POLLING_INTERVAL_SECONDS
gNetworkReconnectInterval = DEFAULT_RECONNECT_INTERVAL_SECONDS

NetworkConnectionBase = inheritsFrom(DeviceConnectionBase)

function NetworkConnectionBase:construct(BindingID, Port)
	self.superClass():construct()

	self._BindingID = BindingID
	self._Port = Port
	self._LastCheckin = 0
	self._IsOnline = false
	self._KeepAliveTimer = nil
	self._OfflineSendLastCommand = false
end

function NetworkConnectionBase:Initialize(ExpectAck, DelayInterval, WaitInterval)
	print("NetConBase:Initialize")
	gControlMethod = "Network"
	self:superClass():Initialize(ExpectAck, DelayInterval, WaitInterval, self)
	self._KeepAliveTimer = c4_timer:new("PollingTimer", gNetworkKeepAliveInterval, "SECONDS", NetworkConnectionBase.OnKeepAliveTimerExpired, false, self)
	self._NetworkReconnectTimer = c4_timer:new("NetworkReconnectTimer", gNetworkReconnectInterval, "SECONDS", NetworkConnectionBase.OnNetworkReconnectTimerExpired, false, self)
end

function NetworkConnectionBase:deconstruct()
	self.superClass():deconstruct()
	
	self._BindingID = nil
	self._Port = nil
	
	if (self._KeepAliveTimer ~= nil) then 
		self._KeepAliveTimer:KillTimer() 
		self._KeepAliveTimer = nil
	end
	
	if (self._NetworkReconnectTimer ~= nil) then 
		self._NetworkReconnectTimer:KillTimer() 
		self._NetworkReconnectTimer = nil
	end
end

function NetworkConnectionBase:ControlMethod()
	return "Network"
end

function NetworkConnectionBase:SendCommand(sCommand, ...)
	if(self._IsConnected) then
		if(self._IsOnline) then
			local command_delay = select(1, ...)
			local delay_units = select(2, ...)
			local command_name = select(3, ...)

			C4:SendToNetwork(self._BindingID, self._Port, sCommand)
			self:StartCommandTimer(command_delay, delay_units, command_name)
		else
			self:CheckNetworkConnectionStatus()
			if (self._OfflineSendLastCommand) then
				--need to re-queue Last Command so that it is not lost. Use QueuePriority1Command
				local tCommand = gCon._LastCommand
				if (tCommand.command ~= sCommand) then
					LogWarn("Network Offline during SendCommand. LastCommand does not equal sCommand! Adding LastCommand to Priority1 Queue to resend anyway!")
				else
					LogWarn("Network Offline during SendCommand. Adding LastCommand to Priority1 Queue to resend!")
				end
				gCon:QueuePriority1Command(tCommand.command, tCommand.command_delay, tCommand.delay_units,tCommand.command_name)
			end
		end
	else
		LogWarn("Not connected to network. Command not sent.")
	end
end

function NetworkConnectionBase:ReceivedFromNetwork(idBinding, nPort, sData)
	self._LastCheckin = 0
	self:ReceivedFromCom(sData)
end

--Class Modification to handle both Network & URL connections
function NetworkConnectionBase:SendCommandUrl(sCommand, url, sHeader, ignoreConnect)
	ignoreConnect = ignoreConnect or false

	local ticketId
	if(self._IsConnected or ignoreConnect) then
		if (sHeader ~= nil) then
			ticketId = C4:urlPost(url, sCommand, sHeader)
		else
			ticketId = C4:urlPost(url, sCommand)
		end
	else
		LogWarn("Not connected. Command not sent.")
	end
	
	return ticketId
end

function NetworkConnectionBase:ReceivedAsync(ticketId, sData, responseCode, tHeaders)
     self._LastCheckin = 0
	
	LogDebug("ReceivedAsync[" .. ticketId .. "]: Response Code: " .. responseCode .. " Length: " .. string.len(sData))
	LogDebug(tHeaders)
	local tMessage = {
		["ticketId"] = ticketId,
		["sData"] = sData,
		["responseCode"] = responseCode,
		["tHeaders"] = tHeaders
	}
	
	status, err = pcall(HandleMessage, tMessage)
	if (not status) then
		LogError("LUA_ERROR: " .. err)
	end
end

function NetworkConnectionBase:CheckNetworkConnectionStatus()
	if (self._IsConnected and (not self._IsOnline) and NetworkCheck()) then
		LogWarn("Network status is OFFLINE. Trying to reconnect to the device's Control port...")
		C4:NetDisconnect(self._BindingID, self._Port)
		--C4:NetConnect(self._BindingID, self._Port)
		self._NetworkReconnectTimer:StartTimer(gNetworkReconnectInterval)
	end
end

function NetworkConnectionBase.OnKeepAliveTimerExpired(Instance)
	Instance._LastCheckin = Instance._LastCheckin + 1

	if(Instance._LastCheckin == 3) then
		LogWarn("Failed to receive poll responses... initiating network recovery mode...")
		C4:NetDisconnect(Instance._BindingID, Instance._Port)
		Instance._NetworkReconnectTimer:StartTimer(gNetworkReconnectInterval)
		return
	elseif(Instance._LastCheckin > 4) then	
		Instance._LastCheckin = 4
	end

	if (SendKeepAlivePollingCommand ~= nil and type(SendKeepAlivePollingCommand) == "function" and Instance._IsOnline) then
		SendKeepAlivePollingCommand()
	end

	Instance._KeepAliveTimer:StartTimer(gNetworkKeepAliveInterval)
end

function NetworkConnectionBase.OnNetworkReconnectTimerExpired(Instance)
	if (Instance._IsConnected) then
		LogWarn("OnNetworkReconnectTimerExpired: Attempting to reactivate network connection...")
		C4:NetDisconnect(Instance._BindingID, Instance._Port)
		C4:NetConnect(Instance._BindingID, Instance._Port)
		Instance._NetworkReconnectTimer:StartTimer(gNetworkReconnectInterval)
	else
		LogWarn("Cannot attempt to reactivate, the network connection is not bound")
	end
end

function NetworkConnectionBase:SetOnlineStatus(IsOnline)
	self._IsOnline = IsOnline

	if(IsOnline) then
		self._KeepAliveTimer:StartTimer(gNetworkKeepAliveInterval)
		self._NetworkReconnectTimer:KillTimer()
		self._LastCheckin = 0
		if (UpdateProperty ~= nil and type(UpdateProperty) == "function") then
			UpdateProperty("Connected To Network", "true")
		end

		self:SendNextCommand()
	else
		self._KeepAliveTimer:KillTimer()
		self._NetworkReconnectTimer:StartTimer(gNetworkReconnectInterval)
		if (UpdateProperty ~= nil and type(UpdateProperty) == "function") then
			UpdateProperty("Connected To Network", "false")
		end
	end
end

function NetworkConnectionBase:SetOfflineSendLastCommand(OfflineSendLastCommand)
	self._OfflineSendLastCommand = OfflineSendLastCommand
end

function ON_DRIVER_LATEINIT.c4_network_connection()
	-- Ensure existing connection is taken into consideration (useful on Driver Update)
	if (gIsNetworkConnected) then
		if (gCon ~= nil and gCon._BindingID ~= nil) then
			local tmp = C4:GetBindingAddress(gCon._BindingID)
			if (tmp ~= nil and string.len(tmp) > 0) then 
				OnNetworkBindingChanged(gCon._BindingID, true) 
			end
		end
	end
end
