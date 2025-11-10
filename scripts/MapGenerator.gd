extends Node

# Map structure
class MapNode:
	var id: int
	var node_type: String
	var position: Vector2
	var connections: Array[int] = []
	var incoming_connections: int = 0
	var is_visited: bool = false
	var is_current: bool = false
	var is_available: bool = false

# Pre-designed map layouts
var map_layouts = []

func _ready():
	setup_map_layouts()

func setup_map_layouts():
	"""Create several pre-designed map structures - 9 columns"""
	
	# Layout 1: Extended Diamond pattern (9 columns)
	map_layouts.append({
		"name": "Extended Diamond",
		"nodes": [
			# Column 0 (Start)
			{"id": 0, "col": 0, "row": 3},
			
			# Column 1
			{"id": 1, "col": 1, "row": 2},
			{"id": 2, "col": 1, "row": 3},
			{"id": 3, "col": 1, "row": 4},
			
			# Column 2
			{"id": 4, "col": 2, "row": 1},
			{"id": 5, "col": 2, "row": 2},
			{"id": 6, "col": 2, "row": 4},
			{"id": 7, "col": 2, "row": 5},
			
			# Column 3
			{"id": 8, "col": 3, "row": 0},
			{"id": 9, "col": 3, "row": 2},
			{"id": 10, "col": 3, "row": 3},
			{"id": 11, "col": 3, "row": 4},
			{"id": 12, "col": 3, "row": 6},
			
			# Column 4 (middle)
			{"id": 13, "col": 4, "row": 1},
			{"id": 14, "col": 4, "row": 2},
			{"id": 15, "col": 4, "row": 4},
			{"id": 16, "col": 4, "row": 5},
			
			# Column 5
			{"id": 17, "col": 5, "row": 0},
			{"id": 18, "col": 5, "row": 2},
			{"id": 19, "col": 5, "row": 3},
			{"id": 20, "col": 5, "row": 4},
			{"id": 21, "col": 5, "row": 6},
			
			# Column 6
			{"id": 22, "col": 6, "row": 1},
			{"id": 23, "col": 6, "row": 2},
			{"id": 24, "col": 6, "row": 4},
			{"id": 25, "col": 6, "row": 5},
			
			# Column 7
			{"id": 26, "col": 7, "row": 2},
			{"id": 27, "col": 7, "row": 3},
			{"id": 28, "col": 7, "row": 4},
			
			# Column 8 (Boss)
			{"id": 29, "col": 8, "row": 3}
		],
		"connections": [
			# Start to col 1
			[0, 1], [0, 2], [0, 3],
			# Col 1 to 2
			[1, 4], [1, 5], [2, 5], [2, 6], [3, 6], [3, 7],
			# Col 2 to 3
			[4, 8], [4, 9], [5, 9], [5, 10], [6, 10], [6, 11], [7, 11], [7, 12],
			# Col 3 to 4
			[8, 13], [9, 13], [9, 14], [10, 14], [10, 15], [11, 15], [11, 16], [12, 16],
			# Col 4 to 5
			[13, 17], [13, 18], [14, 18], [14, 19], [15, 19], [15, 20], [16, 20], [16, 21],
			# Col 5 to 6
			[17, 22], [18, 22], [18, 23], [19, 23], [19, 24], [20, 24], [20, 25], [21, 25],
			# Col 6 to 7
			[22, 26], [23, 26], [23, 27], [24, 27], [24, 28], [25, 28],
			# Col 7 to Boss
			[26, 29], [27, 29], [28, 29]
		]
	})
	
	# Layout 2: Wide spread (9 columns)
	map_layouts.append({
		"name": "Wide Spread",
		"nodes": [
			{"id": 0, "col": 0, "row": 3},
			
			{"id": 1, "col": 1, "row": 1},
			{"id": 2, "col": 1, "row": 3},
			{"id": 3, "col": 1, "row": 5},
			
			{"id": 4, "col": 2, "row": 0},
			{"id": 5, "col": 2, "row": 2},
			{"id": 6, "col": 2, "row": 4},
			{"id": 7, "col": 2, "row": 6},
			
			{"id": 8, "col": 3, "row": 1},
			{"id": 9, "col": 3, "row": 3},
			{"id": 10, "col": 3, "row": 5},
			
			{"id": 11, "col": 4, "row": 0},
			{"id": 12, "col": 4, "row": 2},
			{"id": 13, "col": 4, "row": 4},
			{"id": 14, "col": 4, "row": 6},
			
			{"id": 15, "col": 5, "row": 1},
			{"id": 16, "col": 5, "row": 3},
			{"id": 17, "col": 5, "row": 5},
			
			{"id": 18, "col": 6, "row": 0},
			{"id": 19, "col": 6, "row": 2},
			{"id": 20, "col": 6, "row": 4},
			{"id": 21, "col": 6, "row": 6},
			
			{"id": 22, "col": 7, "row": 1},
			{"id": 23, "col": 7, "row": 3},
			{"id": 24, "col": 7, "row": 5},
			
			{"id": 25, "col": 8, "row": 3}
		],
		"connections": [
			[0, 1], [0, 2], [0, 3],
			[1, 4], [1, 5], [2, 5], [2, 6], [3, 6], [3, 7],
			[4, 8], [5, 8], [5, 9], [6, 9], [6, 10], [7, 10],
			[8, 11], [8, 12], [9, 12], [9, 13], [10, 13], [10, 14],
			[11, 15], [12, 15], [12, 16], [13, 16], [13, 17], [14, 17],
			[15, 18], [15, 19], [16, 19], [16, 20], [17, 20], [17, 21],
			[18, 22], [19, 22], [19, 23], [20, 23], [20, 24], [21, 24],
			[22, 25], [23, 25], [24, 25]
		]
	})
	
	# Layout 3: Complex web (9 columns)
	map_layouts.append({
		"name": "Complex Web",
		"nodes": [
			{"id": 0, "col": 0, "row": 3},
			
			{"id": 1, "col": 1, "row": 2},
			{"id": 2, "col": 1, "row": 4},
			
			{"id": 3, "col": 2, "row": 1},
			{"id": 4, "col": 2, "row": 3},
			{"id": 5, "col": 2, "row": 5},
			
			{"id": 6, "col": 3, "row": 0},
			{"id": 7, "col": 3, "row": 2},
			{"id": 8, "col": 3, "row": 4},
			{"id": 9, "col": 3, "row": 6},
			
			{"id": 10, "col": 4, "row": 1},
			{"id": 11, "col": 4, "row": 3},
			{"id": 12, "col": 4, "row": 5},
			
			{"id": 13, "col": 5, "row": 0},
			{"id": 14, "col": 5, "row": 2},
			{"id": 15, "col": 5, "row": 4},
			{"id": 16, "col": 5, "row": 6},
			
			{"id": 17, "col": 6, "row": 1},
			{"id": 18, "col": 6, "row": 3},
			{"id": 19, "col": 6, "row": 5},
			
			{"id": 20, "col": 7, "row": 2},
			{"id": 21, "col": 7, "row": 4},
			
			{"id": 22, "col": 8, "row": 3}
		],
		"connections": [
			[0, 1], [0, 2],
			[1, 3], [1, 4], [2, 4], [2, 5],
			[3, 6], [3, 7], [4, 7], [4, 8], [5, 8], [5, 9],
			[6, 10], [7, 10], [7, 11], [8, 11], [8, 12], [9, 12],
			[10, 13], [10, 14], [11, 14], [11, 15], [12, 15], [12, 16],
			[13, 17], [14, 17], [14, 18], [15, 18], [15, 19], [16, 19],
			[17, 20], [18, 20], [18, 21], [19, 21],
			[20, 22], [21, 22]
		]
	})

func generate_map(seed_value: int = 0) -> Dictionary:
	"""Generate a complete map with random node types and safely pruned connections"""
	if seed_value != 0:
		seed(seed_value)
	
	# Pick random layout
	var layout = map_layouts[randi() % map_layouts.size()]
	
	# Prune connections while ensuring all nodes reach the boss
	var pruned_connections = prune_connections_safe(layout["connections"], layout["nodes"].size())
	
	# Create map nodes with proper positioning
	var nodes = []
	var node_counts = {}
	
	# Spacing
	var col_spacing = 140
	var row_spacing = 90
	
	# Center the map
	var map_width = 8 * col_spacing
	var map_height = 6 * row_spacing
	var offset_x = (1280 - map_width) / 2
	var offset_y = (720 - map_height) / 2
	
	# Determine which nodes are in column 1 (first column after start)
	var column_1_nodes = []
	for i in range(layout["nodes"].size()):
		if layout["nodes"][i]["col"] == 1:
			column_1_nodes.append(i)
	
	for i in range(layout["nodes"].size()):
		var node_data = layout["nodes"][i]
		var map_node = MapNode.new()
		map_node.id = node_data["id"]
		
		map_node.position = Vector2(
			node_data["col"] * col_spacing + offset_x,
			node_data["row"] * row_spacing + offset_y
		)
		
		# Assign node type
		if i == 0:
			# Start node
			map_node.node_type = "start"
			map_node.is_current = true
			map_node.is_available = true
		elif i == layout["nodes"].size() - 1:
			# Boss node
			map_node.node_type = "boss"
		elif i in column_1_nodes:
			# First column after start - always battle
			map_node.node_type = "battle"
		else:
			# All other nodes - random
			map_node.node_type = MissionDatabase.get_random_node_type()
			
			if not node_counts.has(map_node.node_type):
				node_counts[map_node.node_type] = 0
			node_counts[map_node.node_type] += 1
			
			var node_type_data = MissionDatabase.get_node_type(map_node.node_type)
			if node_type_data and node_counts[map_node.node_type] > node_type_data.max_per_map:
				map_node.node_type = "battle"
		
		nodes.append(map_node)
	
	# Add pruned connections
	for conn in pruned_connections:
		var from_id = conn[0]
		var to_id = conn[1]
		nodes[from_id].connections.append(to_id)
		nodes[to_id].incoming_connections += 1
	
	return {
		"layout_name": layout["name"],
		"nodes": nodes,
		"current_node_id": 0
	}

func prune_connections_safe(connections: Array, node_count: int) -> Array:
	"""Prune connections while ensuring every node can be reached from start"""
	var pruned = []
	var incoming_count = []
	var outgoing_count = []
	
	# Initialize counts
	for i in range(node_count):
		incoming_count.append(0)
		outgoing_count.append(0)
	
	# Count incoming and outgoing connections
	for conn in connections:
		outgoing_count[conn[0]] += 1
		incoming_count[conn[1]] += 1
	
	# Prune connections
	for conn in connections:
		var from_id = conn[0]
		var to_id = conn[1]
		
		# Always keep if target node would have no incoming connections
		if incoming_count[to_id] <= 1:
			pruned.append(conn)
		# Always keep if source node would have no outgoing connections
		elif outgoing_count[from_id] <= 1:
			pruned.append(conn)
		else:
			# 50% chance to keep if both nodes have multiple connections
			if randf() < 0.5:
				pruned.append(conn)
			else:
				# Removing this connection
				outgoing_count[from_id] -= 1
				incoming_count[to_id] -= 1
	
	# Verify all nodes can be reached from start AND can reach boss
	if not verify_all_nodes_reachable(pruned, node_count):
		return connections
	
	return pruned

func verify_all_nodes_reachable(connections: Array, node_count: int) -> bool:
	"""Verify that all nodes can be reached from start (0) and can reach boss (last)"""
	var start_id = 0
	var boss_id = node_count - 1
	
	# Build adjacency lists (forward and backward)
	var forward_adj = {}
	var backward_adj = {}
	
	for i in range(node_count):
		forward_adj[i] = []
		backward_adj[i] = []
	
	for conn in connections:
		forward_adj[conn[0]].append(conn[1])
		backward_adj[conn[1]].append(conn[0])
	
	# Check all nodes can be reached from start
	var reachable_from_start = get_reachable_nodes(start_id, forward_adj)
	if reachable_from_start.size() != node_count:
		return false
	
	# Check all nodes can reach boss
	var can_reach_boss_list = get_reachable_nodes(boss_id, backward_adj)
	if can_reach_boss_list.size() != node_count:
		return false
	
	return true

func get_reachable_nodes(start_id: int, adj_list: Dictionary) -> Array:
	"""Get all nodes reachable from start_id using BFS"""
	var reachable = []
	var visited = {}
	var queue = [start_id]
	visited[start_id] = true
	reachable.append(start_id)
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		for neighbor in adj_list[current]:
			if not visited.has(neighbor):
				visited[neighbor] = true
				reachable.append(neighbor)
				queue.append(neighbor)
	
	return reachable

func verify_all_paths_reach_boss(connections: Array, node_count: int) -> bool:
	"""Verify that every node can reach the boss (last node)"""
	var boss_id = node_count - 1
	
	# Build adjacency list
	var adj_list = {}
	for i in range(node_count):
		adj_list[i] = []
	
	for conn in connections:
		adj_list[conn[0]].append(conn[1])
	
	# For each node, check if it can reach the boss
	for node_id in range(node_count):
		if not can_reach_boss(node_id, boss_id, adj_list):
			return false
	
	return true

func can_reach_boss(start_id: int, boss_id: int, adj_list: Dictionary) -> bool:
	"""Check if a node can reach the boss using BFS"""
	if start_id == boss_id:
		return true
	
	var visited = {}
	var queue = [start_id]
	visited[start_id] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		for neighbor in adj_list[current]:
			if neighbor == boss_id:
				return true
			
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	
	return false
