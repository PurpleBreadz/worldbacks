class_name WBUITheme
extends RefCounted

const INK: Color = Color("101c23")
const PAPER: Color = Color("e5ddbd")
const MUTED: Color = Color("9ca99a")
const GOLD: Color = Color("bdaa70")

static func box(fill: Color, border: Color = Color("46514a"), width: int = 1) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(width)
	result.content_margin_left = 10
	result.content_margin_right = 10
	result.content_margin_top = 5
	result.content_margin_bottom = 5
	return result

static func create_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 12
	result.set_color("font_color", "Label", PAPER)
	result.set_color("font_color", "Button", PAPER)
	result.set_color("font_hover_color", "Button", Color("fff0bc"))
	result.set_color("font_focus_color", "Button", Color("fff0bc"))
	result.set_color("font_disabled_color", "Button", Color("65716a"))
	result.set_stylebox("normal", "Button", box(Color("17282c")))
	result.set_stylebox("hover", "Button", box(Color("2c403c"), GOLD))
	result.set_stylebox("pressed", "Button", box(Color("3b4b3a"), Color("e5cf92")))
	result.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), GOLD))
	result.set_stylebox("disabled", "Button", box(Color("142126"), Color("26352e")))
	result.set_stylebox("panel", "Panel", box(INK, GOLD))
	result.set_stylebox("background", "ProgressBar", box(Color("172429"), Color("46514a")))
	result.set_stylebox("fill", "ProgressBar", box(Color("a3544b"), Color("c77964"), 0))
	return result
