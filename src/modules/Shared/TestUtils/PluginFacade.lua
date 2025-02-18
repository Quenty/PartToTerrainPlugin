--[=[
	Facades the plugin interface

	@class PluginFacade
]=]

local Players = game:GetService("Players")

local PluginFacade = {}
PluginFacade.__index = PluginFacade

function PluginFacade.new(oldPlugin)
	local self = setmetatable({}, PluginFacade)

	self._settings = {}
	self._oldPlugin = oldPlugin -- may be nil

	return self
end

function PluginFacade:__index(index)
	local result = rawget(PluginFacade, index)
	if result then
		return result
	end

	return self._oldPlugin[index]
end

function PluginFacade:GetMouse()
	return Players.LocalPlayer:GetMouse()
end

function PluginFacade:GetSetting(Key)
	return self._settings[Key]
end

function PluginFacade:SetSetting(Key, Value)
	self._settings[Key] = Value
end

return PluginFacade