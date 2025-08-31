extends Node


func sanitize_string(s: String) -> String:
	return s.strip_edges().replace("\r", "").replace("\n", "")

func is_digits_only(s: String) -> bool:
	if s.is_empty(): return false
	for ch in s:
		var c := ch.unicode_at(0)
		if c < 48 or c > 57:
			return false
	return true

func is_alnum(s: String) -> bool:
	s = s.to_upper()
	for ch in s:
		var c := ch.unicode_at(0)
		var ok := (c >= 48 and c <= 57) or (c >= 65 and c <= 90) \
			or ch == " " or ch == "$" or ch == "%" or ch == "*" \
			or ch == "+" or ch == "-" or ch == "." or ch == "/" or ch == ":"
		if not ok:
			return false
	return true
