class_name CharPositionRecorder
extends RichTextEffect

var bbcode := "reclocpos"

## segment_id -> { relative_index -> Vector2 position }
## Keyed by segment because relative_index only makes sense per tag instance.
var positions_by_segment: Dictionary = {}

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var seg_id: int = int(char_fx.env.get("id", -1))
	if seg_id < 0:
		return true  # untagged content (shouldn't happen, but stay safe)

	if not positions_by_segment.has(seg_id):
		positions_by_segment[seg_id] = {}
	positions_by_segment[seg_id][char_fx.relative_index] = char_fx.transform.get_origin()
	return true
