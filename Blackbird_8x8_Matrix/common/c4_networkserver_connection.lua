--[[=============================================================================
    Base for a network server connection driver

    Copyright 2017 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_device_connection_base"
require "lib.c4_log"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_networkserver_connection = "2017.12.06"
end

DEFAULT_POLLING_INTERVAL_SECONDS = 30

gNetworkKeepAliveInterval = DEFAULT_POLLING_INTERVAL_SECONDS

NetworkServerConnectionBase = inheritsFrom(DeviceConnectionBase)


function NetworkServerConnectionBase:construct()
	self.superClass():construct()

	self._Port = 0
	self._Handle = 0
end

function NetworkServerConnectionBase:Initialize(ExpectAck, DelayInterval, WaitInterval)
	print("NetworkServerConnectionBase:Initialize")
	gControlMethod = "NetworkServer"
	self:superClass():Initialize(ExpectAck, DelayInterval, WaitInterval, self)

end

function NetworkServerConnectionBase:ControlMethod()
	return "NetworkServer"
end

function NetworkServerConnectionBase:SendCommand(sCommand, ...)
	if(self._IsConnected) then
		if(self._IsOnline) then
			local command_delay = select(1, ...)
			local delay_units = select(2, ...)
			local command_name = select(3, ...)

			C4:SendToNetwork(self._BindingID, self._Port, sCommand)
			self:StartCommandTimer(command_delay, delay_units, command_name)
		else
			self:CheckNetworkConnectionStatus()
		end
	else
		LogWarn("Not connected to network. Command not sent.")
	end
end


function NetworkServerConnectionBase:SendRaw(sData)
--	LogTrace("Sending raw: %s", HexToString(sData))
	C4:ServerSend(self._Handle, sData, #sData)
end


function NetworkServerConnectionBase:ReceivedFromNetworkServer(nHandle, sData)
	self._Handle = nHandle
	self:ReceivedFromCom(sData)
end


function NetworkServerConnectionBase:StartListening()
	LogTrace("Creating Listener on Port %d", self._Port)
	self._Port = C4:CreateServer(self._Port)
	return self._Port
end


function NetworkServerConnectionBase:StopListening()
	LogTrace("Closing Listener on Port %d", self._Port)
	C4:DestroyServer(self._Port)
end


function NetworkServerConnectionBase:SetPort(PortID)
	LogTrace("NetworkServerConnectionBase:SetPort %s", tostring(PortID))
	self._Port = tonumber(PortID)
end


function NetworkServerConnectionBase:GetPort()
	LogTrace("NetworkServerConnectionBase:GetPort")
	return self._Port
end

