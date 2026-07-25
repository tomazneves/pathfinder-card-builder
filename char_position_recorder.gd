## ------------------------------------------------------------------
## 1) A RichTextEffect that changes nothing visually — it just records
##    where each character ends up being drawn. Tag: [reclocpos]...[/reclocpos]
## ------------------------------------------------------------------
class_name CharPositionRecorder
extends RichTextEffect

var bbcode := "reclocpos"

## Absolute character index (matches get_parsed_text() indices) -> local
## position (relative to the RichTextLabel's top-left corner), captured
## fresh on every draw.
var char_positions: Dictionary = {}

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# .range.x is the character's ABSOLUTE index in the fully rendered
	# text — unaffected by where our own [reclocpos] tag starts, since
	# BBCode tags themselves don't count as characters. That's what lets
	# us wrap the ENTIRE text in one tag and still get real indices.
	char_positions[char_fx.range.x] = char_fx.transform.get_origin()
	return true  # true = character stays visible, unmodified
