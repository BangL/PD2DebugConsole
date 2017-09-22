
local chat_focus_original = HUDManager.chat_focus

function HUDManager:chat_focus()
	local input_focus = con and con:input_focus()
	return chat_focus_original(self) or input_focus == true or input_focus == 1
end
