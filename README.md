# PD2DebugConsole
a Lua debug console for Payday 2 as BLT mod
## Public functions

### `class:new()`
the constructor. usually you dont need to call this, as there is a default instance in the global variable '`con`'
#### example:
*`con = DebugConsole:new()`*

---
### `instance:destroy()`
the destructor
#### example:
*`con:destroy()`*

---
### `instance:open()`
shows the console window
#### example:
*`con:open()`*

---
### `instance:close()`
hides the console window
#### example:
*`con:close()`*

---
### `instance:error(message)`
adds an error message to the console window
#### parameters:
- `message` : the error message to show. must be a string.
#### example:
*`con:error("This is an error message.")`*

---
### `instance:print(...)`
adds a generic output line to the console window
#### parameters:
- `...` : any amount of things to print out. will be seperated by 4 spaces. can be any type. nil values will be shown as '[nil]'
#### example:
*`con:print("string:", str, "table:", tbl, "bool:", bool, "number:", num)`*

---
### `instance:printf(format, ...)`
adds a formatted line to the console window, similar to the C function printf
#### parameters:
- `format` : a string with directives, as in [string.format()](https://www.gammon.com.au/scripts/doc.php?lua=string.format)
- `...` : the values that fill the placeholders of 'format'
#### example:
*`con:printf("string: %s number: %i", str, num)`*

---
## Known Issues / Planned
- Ingame keybinds are not ignored while the console is focused yet.
- Scolling via PageUp/PageDown
- Cut/Copy/Paste via Ctrl+X/C/V
- Mouse click/Scroll events
- Link clicking
- Range Selection via mouse or Shift+arrow keys
