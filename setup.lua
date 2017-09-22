dofile(ModPath .. "DebugConsole.lua")

local init_managers_original = Setup.init_managers

function Setup:init_managers(managers, ...)
	init_managers_original(self, managers, ...)
	con = DebugConsole:new()
end
