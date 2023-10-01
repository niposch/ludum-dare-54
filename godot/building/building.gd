class_name Building extends Node

@export var floor_height = 3

@export var min_width : int = 2
@export var max_width : int = 10
@export var floor_width_distribution = [0, 0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.8, 0.9, 0.96, 1]
@export var floor_number_distribution = [0, 0.3, 0.4, 1]
@export var border_probability = 0.3
@export var border_skew_probability = 0.5
@export var adjusted_expanding_distribution = [0.05, 0.22, 0.68, 0.98, 1]
@export var no_tshape_probability = 0.2
@export var border_window_probability = 0.4

var grid = []
var size = Vector2i.ZERO

var is_left_border = false
var is_right_border = false

func generate_building() -> void:
	var floor_number := randomize_floor_number()
	var upper_height := randomize_upper_height(floor_number)
	
	randomize_border()
	
	var lower_width := randomize_size()
	
	var upper_width := randomize_size()
	if (floor_number == 1):
		upper_width = lower_width
	
	var max_width: int = max(lower_width, upper_width)
	
	size.y = floor_number*floor_height
	size.x = max(upper_width, lower_width)
	
	var offset := randomize_offset(lower_width, upper_width)
	
	
	
	initialize_grid()
	
	for i in floor_height * upper_height:
		for j in upper_width:
			grid[i][-offset+j].set_brick()
	
	for i in floor_height * (floor_number - upper_height):
		for j in lower_width:
			grid[i+floor_height*upper_height][offset+j].set_brick()
	
	
	var shrink_size: int = 0
	if is_left_border or is_right_border:
		shrink_size = randomize_shrink_size(lower_width, upper_width)
		if shrink_size > 0:
			if is_left_border:
				for i in shrink_size:
					for j in shrink_size - i:
						grid[i][j].unset_brick()
						if i+j == shrink_size - 1:
							grid[i][j].set_slope(1)
			else:
				for i in shrink_size:
					for j in shrink_size - i:
						grid[i][max_width-1-j].unset_brick()
						if i+j == shrink_size - 1:
							grid[i][max_width-1-j].set_slope(2)
		if shrink_size < 0:
			if is_left_border:
				for i in -shrink_size:
					for j in -shrink_size - i:
						grid[floor_height*floor_number-1-i][j].unset_brick()
						if i+j == -shrink_size - 1:
							grid[floor_height*floor_number-1-i][j].set_slope(3)
			else:
				for i in -shrink_size:
					for j in -shrink_size - i:
						grid[floor_height*floor_number-1-i][max_width-1-j].unset_brick()
						if i+j == -shrink_size - 1:
							grid[floor_height*floor_number-1-i][max_width-1-j].set_slope(4)
	
	generate_decorations()
	
	generate_windows()
	
	update_edges()

func randomize_floor_number() -> int:
	var random := randf()
	var floor_number: int = 0
	while floor_number_distribution[floor_number] < random:
		floor_number += 1
	return floor_number

func randomize_upper_height(floor_number) -> int:
	if floor_number <= 2:
		return 1
	return randi_range(1, floor_number - 1)
	

func randomize_border() -> void:
	is_left_border = false
	is_right_border = false
	if randf() >= border_probability:
		return
	if randf() < border_skew_probability:
		is_left_border = true
	else:
		is_right_border = true
	return
	
func randomize_size() -> int:
	var random = randf()
	var floor_width = 0
	while floor_width_distribution[floor_width] < random:
		floor_width += 1
	return floor_width

func randomize_offset(lower_width, upper_width) -> int:
	if is_left_border:
		return 0
	if is_right_border:
		return upper_width-lower_width
	if randf() < no_tshape_probability:
		if randf() < 0.5:
			return max(upper_width-lower_width, 0)
		else:
			return min(upper_width-lower_width, 0)
	var max_offset = max(upper_width-lower_width, 0)
	var min_offset = min(upper_width-lower_width, 0)
	return randi_range(min_offset, max_offset)

func randomize_shrink_size(lower_width, upper_width) -> int:
	var random := randf()
	var adjusted_shrink_size: int = 0
	while adjusted_expanding_distribution[adjusted_shrink_size] < random:
		adjusted_shrink_size += 1
	var shrink_size: int = adjusted_shrink_size - 2
	
	shrink_size = max(shrink_size, min_width - lower_width, min_width - upper_width)
	shrink_size = min(shrink_size, lower_width - min_width, upper_width - min_width)
	
	return shrink_size

func update_edges() -> void:
	for i in size.y:
		for j in size.x:
			if not grid[i][j].is_empty:
				if i==0 or (i!=0 and grid[i-1][j].is_empty and not grid[i-1][j].slope):
					grid[i][j].set_top() # upper edge
				if i==size.y-1 or (i!=size.y-1 and grid[i+1][j].is_empty and not grid[i+1][j].slope):
					grid[i][j].set_bottom() # lower edge
				if j==0 or (j!=0 and grid[i][j-1].is_empty and not grid[i][j-1].slope):
					grid[i][j].set_left_right_edge(1) # left edge
				if j==size.x-1 or (j!=size.x-1 and grid[i][j+1].is_empty and not grid[i][j+1].slope):
					grid[i][j].set_left_right_edge(2) # right edge

func initialize_grid() -> void:
	for i in size.y:
		grid.append([])
		for j in size.x:
			var tile_instance = Building_Tile.new()
			grid[i].append(tile_instance)

func generate_decorations() -> void:
	pass

func generate_windows() -> void:
	if not is_left_border and not is_right_border:
		return
	
	var j = 0
	if is_right_border:
		j = size.x - 1
	
	for i in size.y:
		if i%floor_height == 1:
			if randf() < border_window_probability:
				grid[i][j].set_window()
	
