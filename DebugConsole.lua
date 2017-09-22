
local loadstring = vm and vm.loadstring or (base and base.loadstring or loadstring)
local pcall = vm and vm.pcall or (base and base.pcall or pcall)

DebugConsole = DebugConsole or class()

DebugConsole.MAX_OUTPUTS = 100
DebugConsole.MAX_HISTORY = 50
DebugConsole.LINES_HEIGHT = 24
DebugConsole.MARGIN = 2

function DebugConsole:init()
	self._open = false
	self._outputs = {}
	self._outputs_scroll = 0
	self._history = {}
	self._history_scroll = -1
	self._esc_callback = callback(self, self, "_esc_key_callback")
	self._blt_callback = callback(self, self, "_blt_key_callback")
	self:_setup()
end

function DebugConsole:_setup()
	if not self._reschanged_clbk_id then
		self._reschanged_clbk_id = managers.viewport:add_resolution_changed_func(callback(self, self, "_setup"))
	end
	if not alive(self._ws) then
		self._ws = managers.gui_data:create_fullscreen_workspace()
		self._panel = self._ws:panel()
	else
		self._panel:clear()
	end
	if self._open then
		self._ws:show()
	else
		self._ws:hide()
	end

	local console_panel = self._panel:panel({
		name = "console_panel",
		layer = 1000000,
		x = 0,
		y = 0,
		w = self._panel:w() * 0.75,
		h = self._panel:h() * 0.5,
		valign = "top"
	})
	console_panel:set_center_x(self._panel:w() * 0.5)

	console_panel:bitmap({
		name = "console_blur",
		layer = -1,
		x = 0,
		y = 0,
		w = console_panel:w(),
		h = console_panel:h(),
		valign = "grow",
		halign = "grow",
		render_template = "VertexColorTexturedBlur3D",
		texture = "guis/textures/test_blur_df"
	})

	console_panel:rect({
		name = "console_bg",
		layer = -2,
		x = 0,
		y = 0,
		w = console_panel:w(),
		h = console_panel:h(),
		color = Color.black,
		alpha = 0.7
	})

	self._input_panel = console_panel:panel({
		name = "input_panel",
		layer = 0,
		x = 0,
		y = 0,
		w = console_panel:w(),
		h = DebugConsole.LINES_HEIGHT + DebugConsole.MARGIN * 2,
		valign = "bottom"
	})
	self._input_panel:set_bottom(console_panel:h())
	BoxGuiObject:new(self._input_panel, {sides = {2, 2, 2, 2}})

	self._input_panel:text({
		name = "input_text",
		layer = 1,
		text = "",
		x = DebugConsole.MARGIN,
		y = DebugConsole.MARGIN,
		w = self._input_panel:w() - DebugConsole.MARGIN * 2,
		h = self._input_panel:h() - DebugConsole.MARGIN * 2,
		align = "left",
		vertical = "center",
		halign = "left",
		hvertical = "center",
		wrap = true,
		word_wrap = false,
		blend_mode = "normal",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		color = Color.white
	})

	self._input_panel:rect({
		name = "caret",
		y = DebugConsole.MARGIN,
		x = DebugConsole.MARGIN,
		h = 0,
		w = 0,
		layer = 2,
		color = Color(0.05, 1, 1, 1)
	})

	self._output_panel = console_panel:panel({
		name = "output_panel",
		x = 0,
		y = 0,
		w = console_panel:w(),
		h = console_panel:h() - self._input_panel:h()
	})
	BoxGuiObject:new(self._output_panel, {sides = {2, 2, 0, 0}})

	self._output_panel:panel({
		name = "output_text_panel",
		x = DebugConsole.MARGIN,
		y = 0,
		w = self._output_panel:w() - DebugConsole.MARGIN * 2,
		h = self._output_panel:h()
	})

	self:_layout_output_text_panel()
end

function DebugConsole:_layout_output_text_panel()
	local output_text_panel = self._output_panel:child("output_text_panel")
	output_text_panel:clear()
	local bottom = output_text_panel:h()
	local current = self._outputs_scroll
	while bottom >= 0 and current < #self._outputs do
		local text_data = self._outputs[#self._outputs - current]
		local text = text_data.text ~= "" and text_data.text or " " -- prevent zero height at text_rect()
		local line = output_text_panel:text({
			layer = 0,
			w = output_text_panel:w(),
			align = "left",
			vertical = "top",
			halign = "left",
			hvertical = "top",
			wrap = true,
			word_wrap = true,
			blend_mode = "normal",
			text = (text_data.time and text_data.time .. " > " or "") .. text,
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			color = text_data.color
		})
		local _, _, _, h = line:text_rect()
		line:set_h(h)
		line:set_bottom(bottom)
		bottom = line:y()
		current = current + 1
	end
end

function DebugConsole:destroy()
	if self._reschanged_clbk_id then
		managers.viewport:remove_resolution_changed_func(self._reschanged_clbk_id)
		self._reschanged_clbk_id = nil
	end
	if alive(self._ws) then
		managers.gui_data:destroy_workspace(self._ws)
		self._ws = nil
		self._panel = nil
	end
end

function DebugConsole:open()
	if self._open then
		return
	end
	self._open = true
	self._ws:connect_keyboard(Input:keyboard())
	self._input_panel:key_press(callback(self, self, "_key_press"))
	self._input_panel:key_release(callback(self, self, "_key_release"))
	self._enter_text_set = false
	local console_panel = self._panel:child("console_panel")
	console_panel:stop()
	console_panel:animate(callback(self, self, "_open_anim"))
	self:_update_caret()
end

function DebugConsole:_open_anim(panel)
	panel:set_bottom(0)
	self._ws:show()
	local t = 0
	while t < 0.25 do
		t = t + coroutine.yield()
		panel:set_bottom(self._panel:h() * t * 2)
	end
	panel:set_bottom(self._panel:h() * 0.5)
end

function DebugConsole:close()
	if not self._open then
		return
	end
	self._open = false
	self._ws:disconnect_keyboard()
	self._input_panel:key_press(nil)
	self._input_panel:enter_text(nil)
	self._input_panel:key_release(nil)
	self._input_panel:child("input_text"):stop()
	local console_panel = self._panel:child("console_panel")
	console_panel:stop()
	console_panel:animate(callback(self, self, "_close_anim"))
	return true
end

function DebugConsole:_close_anim(panel)
	panel:set_bottom(self._panel:h() * 0.5)
	local t = 0.25
	while t > 0 do
		t = t - coroutine.yield()
		panel:set_bottom(self._panel:h() * t * 2)
	end
	panel:set_bottom(0)
	self._ws:hide()
end

function DebugConsole:_enter_text(o, s)
	local text = self._input_panel:child("input_text")
	text:replace_text(s)
	local lbs = text:line_breaks()
	if #lbs > 1 then
		local s = lbs[2]
		local e = utf8.len(text:text())
		text:set_selection(s, e)
		text:replace_text("")
	end
	self:_update_caret()
end

function DebugConsole:_key_release(o, k)
	if self._key_pressed == k then
		self._key_pressed = false
	end
end

function DebugConsole:_key_press(o, k)
	if not self._enter_text_set then
		self._input_panel:enter_text(callback(self, self, "_enter_text"))
		self._enter_text_set = true
	end
	self._key_pressed = k
	local text = self._input_panel:child("input_text")
	local s, e = text:selection()
	local n = utf8.len(text:text())
	local d = math.abs(e - s)
	text:stop()
	text:animate(callback(self, self, "_update_key_down"), k)
	local blt_keybind = BLT.Keybinds and BLT.Keybinds:get_keybind("console_toggle")
	local blt_key = blt_keybind and blt_keybind:Key()
	if not self:_handle_reapeat_key(text, s, e, n, d) then
		if self._key_pressed == Idstring("end") then
			text:set_selection(n, n)
		elseif self._key_pressed == Idstring("home") then
			text:set_selection(0, 0)
		elseif self._key_pressed == Idstring("enter") or k == Idstring("num enter") then
			local message = text:text()
			if string.len(message) > 0 then
				self:_add_text(message, nil, true)
				self:_execute_command(message)
			end
			text:set_text("")
			text:set_selection(0, 0)
		elseif self._key_pressed == Idstring("esc") and type(self._esc_callback) ~= "number" then
			text:set_text("")
			text:set_selection(0, 0)
			self._esc_callback()
		elseif (blt_key ~= nil and self._key_pressed == Idstring(blt_key)) and type(self._blt_callback) ~= "number" then
			text:set_text("")
			text:set_selection(0, 0)
			self._blt_callback()
		end
	end
	self:_update_caret()
end

function DebugConsole:_update_key_down(o, k)
	wait(0.5)
	local text = self._input_panel:child("input_text")
	while self._key_pressed == k do
		local s, e = text:selection()
		local n = utf8.len(text:text())
		local d = math.abs(e - s)
		if not self:_handle_reapeat_key(text, s, e, n, d) then
			self._key_pressed = false
		end
		self:_update_caret()
		wait(0.05)
	end
end

function DebugConsole:_handle_reapeat_key(text, s, e, n, d)
	local handled = false
	if self._key_pressed == Idstring("backspace") then
		if s == e and s > 0 then
			text:set_selection(s - 1, e)
		end
		text:replace_text("")
		handled = true
	elseif self._key_pressed == Idstring("delete") then
		if s == e and s < n then
			text:set_selection(s, e + 1)
		end
		text:replace_text("")
		handled = true
	elseif self._key_pressed == Idstring("insert") then
		local clipboard = Application:get_clipboard() or ""
		text:replace_text(clipboard)
		local lbs = text:line_breaks()
		if #lbs > 1 then
			local s = lbs[2]
			local e = utf8.len(text:text())
			text:set_selection(s, e)
			text:replace_text("")
		end
		handled = true
	elseif self._key_pressed == Idstring("left") then
		if s < e then
			text:set_selection(s, s)
		elseif s > 0 then
			text:set_selection(s - 1, s - 1)
		end
		handled = true
	elseif self._key_pressed == Idstring("right") then
		if s < e then
			text:set_selection(e, e)
		elseif s < n then
			text:set_selection(s + 1, s + 1)
		end
		handled = true
	elseif self._key_pressed == Idstring("up") then
		if self._history_scroll < #self._history - 1 then
			self._history_scroll = self._history_scroll + 1
			local history = self._history[#self._history - self._history_scroll]
			local len = history:len()
			text:set_text(history)
			text:set_selection(len, len)
		end
		handled = true
	elseif self._key_pressed == Idstring("down") then
		if self._history_scroll > 0 then
			self._history_scroll = self._history_scroll - 1
			local history = self._history[#self._history - self._history_scroll]
			local len = history:len()
			text:set_text(history)
			text:set_selection(len, len)
		elseif self._history_scroll == 0 then
			self._history_scroll = -1
			text:set_text("")
			text:set_selection(0, 0)
		end
		handled = true
	end
	return handled
end

function DebugConsole:_update_caret()
	local text = self._input_panel:child("input_text")
	local caret = self._input_panel:child("caret")
	local s, e = text:selection()
	local x, y, w, h = text:selection_rect()
	if s == 0 and e == 0 then
		x = text:align() == "center" and text:world_x() + text:w() / 2 or text:world_x()
		y = text:world_y()
	end
	h = text:h()
	if w < 3 then
		w = 3
	end
	if not self._open then
		w = 0
		h = 0
	end
	caret:set_world_shape(x, y + 2, w, h - 4)
	self:_set_blinking(s == e and self._open)
end

function DebugConsole:_set_blinking(b)
	local caret = self._input_panel:child("caret")
	if b == self._blinking then
		return
	end
	if b then
		caret:animate(self._blink)
	else
		caret:stop()
	end
	self._blinking = b
	if not self._blinking then
		caret:set_color(Color.white)
	end
end

function DebugConsole._blink(o)
	while o do
		o:set_color(Color(0, 1, 1, 1))
		wait(0.25)
		o:set_color(Color.white)
		wait(0.25)
	end
end

function DebugConsole:_esc_key_callback()
	if not self._open then
		return
	end
	self._esc_focus_delay = true
	self:close()
end

function DebugConsole:_blt_key_callback()
	if not self._open then
		return
	end
	self._blt_focus_delay = 10 -- 7 was enough on my machine, but lets be safe
	self:close()
end

function DebugConsole:input_focus()
	if self._esc_focus_delay then
		self._esc_focus_delay = nil
		return 1
	end
	if self._blt_focus_delay and self._blt_focus_delay > 0 then
		self._blt_focus_delay = self._blt_focus_delay - 1
		return 1
	end
	return self._open
end

function DebugConsole:_execute_command(command)
	if not table.contains(self._history, command) then
		table.insert(self._history, command)
		if #self._history >= DebugConsole.MAX_HISTORY then
			table.remove(self._history, 1)
		end
	end
	self._history_scroll = -1
	local r, e = loadstring(command)
	if r then
		r, e = pcall(r)
		if r then
			e = nil
		else
			e = (e and "Execution Error: " .. tostring(e) or "< Can't show error message here as of pcall() not being implemented correctly in the BLT you are currently using. Look in your log file instead. >")
		end
	else
		e = "Parser Error: " .. tostring(e)
	end
	if e then
		self:error(e)
	end
end

function DebugConsole:_add_text(text, color, show_time)
	if not alive(self._ws) then
		self:_setup()
	end
	local texts = text:split("\n", true)
	local n = #texts
	for i = 1, n do
		local formatted_text = texts[i]:gsub("\t", "    ")
		local text_data = {
			time = show_time and os.date("%X") or nil,
			text = formatted_text,
			color = color and color or Color.white:with_alpha(0.6)
		}
		show_time = nil -- only show time in first line
		table.insert(self._outputs, text_data)
		while #self._outputs >= DebugConsole.MAX_OUTPUTS do
			table.remove(self._outputs, 1)
		end
	end
	self._outputs_scroll = 0
	self:_layout_output_text_panel()
end

function DebugConsole:error(message)
	self:_add_text(message, Color.red, false)
end

function DebugConsole:print(...)
	local r
	local n = select("#", ...)
	for i = 1, n do
		local v = select(i, ...)
		local t = v and tostring(v) or "[nil]"
		if r and v and t ~= "\n" and t ~= "\t" then
			r = r .. "\t" .. t
		elseif r then
			r = r .. t
		else
			r = t
		end
	end
	self:_add_text(r, Color.white, false)
end

function DebugConsole:printf(str, ...)
	self:print(str:format(...))
end
