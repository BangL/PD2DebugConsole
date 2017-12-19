
-- cancel if chatting in lobby (the blt does not cover this case yet)
if managers.menu_component and managers.menu_component:input_focut_game_chat_gui() then -- focut is not a typo on our side
	return
end

if con then
	con:open()
end
