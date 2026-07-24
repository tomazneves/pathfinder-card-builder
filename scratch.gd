
var fixed_size: float = actions.get_rect().size.x + 38.0
var text_size: float = label.get_rect().size.x
var squeeze: float = 1.0

# No compromises
var target_text_size_0: float = right_bound - max_slope_x - slope_margin - fixed_size

# Compromise slope angle
var target_text_size_1: float = right_bound - min_slope_x - slope_margin - fixed_size

var squeeze_0: float = target_text_size_0 / text_size
var squeeze_1: float = target_text_size_1 / text_size

var min_squeezed_text_x: float = text_size * min_squeeze

# If can compress without compromise:
if min_squeezed_text_x <= target_text_size_0:
	# Compress text
	squeeze = squeeze_0
# Else:
else:
	# Compress slope as much as possible
	var slope_delta = right_bound - min_squeezed_text_x - slope_margin
	
	# Compress text to fit
	if slope_delta >= min_slope_x:
		squeeze = squeeze_0
		
	else:
		squeeze = squeeze_1
		
label.scale.x = squeeze
var bg_poly: PackedVector2Array = $Background.polygon
bg_poly[4].x = right_bound
bg_poly[5].x = 
