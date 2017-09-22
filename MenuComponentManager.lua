
CloneClass(MenuComponentManager)

function MenuComponentManager:input_focus_console()
	local input_focus = con and con:input_focus()
	return input_focus == true or input_focus == 1
end

function MenuComponentManager:input_focus(...)
	return con and con:input_focus() or self.orig.input_focus(self, ...)
end

function MenuComponentManager:input_focut_game_chat_gui(...)
	return self:input_focus_console() or self.orig.input_focut_game_chat_gui(self, ...)
end

function MenuComponentManager:scroll_up(...)
	return self:input_focus_console() or self.orig.scroll_up(self, ...)
end

function MenuComponentManager:scroll_down(...)
	return self:input_focus_console() or self.orig.scroll_down(self, ...)
end

function MenuComponentManager:move_up(...)
	return self:input_focus_console() or self.orig.move_up(self, ...)
end

function MenuComponentManager:move_down(...)
	return self:input_focus_console() or self.orig.move_down(self, ...)
end

function MenuComponentManager:move_left(...)
	return self:input_focus_console() or self.orig.move_left(self, ...)
end

function MenuComponentManager:move_right(...)
	return self:input_focus_console() or self.orig.move_right(self, ...)
end

function MenuComponentManager:next_page(...)
	return self:input_focus_console() or self.orig.next_page(self, ...)
end

function MenuComponentManager:previous_page(...)
	return self:input_focus_console() or self.orig.previous_page(self, ...)
end

function MenuComponentManager:confirm_pressed(...)
	return self:input_focus_console() or self.orig.confirm_pressed(self, ...)
end

function MenuComponentManager:back_pressed(...)
	return self:input_focus_console() or self.orig.back_pressed(self, ...)
end

function MenuComponentManager:special_btn_pressed(...)
	return self:input_focus_console() or self.orig.special_btn_pressed(self, ...)
end

function MenuComponentManager:special_btn_released(...)
	return self:input_focus_console() or self.orig.special_btn_released(self, ...)
end
