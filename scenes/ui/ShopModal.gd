extends CanvasLayer
class_name ShopModal

signal shop_closed()
signal upgrade_purchased(upgrade_id: String)

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var card_1_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/CardsContainer/Card1/Button
@onready var card_2_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/CardsContainer/Card2/Button
@onready var card_3_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/CardsContainer/Card3/Button
@onready var continue_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/ContinueButton
@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel

var upgrades: Array[Dictionary] = [
	{"id": "speed", "name": "[1] Overdrive Thrusters", "desc": "+20% Move Speed", "cost": 15},
	{"id": "health", "name": "[2] Nanite Mesh", "desc": "+30 Max HP and Full Repair", "cost": 20},
	{"id": "weapon_orbit", "name": "[3] Orbiting Blade", "desc": "Unlock Protective Orbiting Blade", "cost": 35}
]

func _ready() -> void:
	visible = false
	if card_1_btn:
		card_1_btn.pressed.connect(func(): select_option(0))
	if card_2_btn:
		card_2_btn.pressed.connect(func(): select_option(1))
	if card_3_btn:
		card_3_btn.pressed.connect(func(): select_option(2))
	if continue_btn:
		continue_btn.pressed.connect(close_shop)

func open_shop() -> void:
	visible = true
	_refresh_cards()
	if continue_btn:
		continue_btn.grab_focus()

func close_shop() -> void:
	visible = false
	shop_closed.emit()

func _refresh_cards() -> void:
	var gd = get_node_or_null("/root/GameData")
	var chips: int = gd.nano_chips if gd else 0
	if status_label:
		status_label.text = "Available Nano-Chips: %d" % chips
		
	var buttons = [card_1_btn, card_2_btn, card_3_btn]
	for i in range(min(upgrades.size(), buttons.size())):
		var btn = buttons[i]
		var up = upgrades[i]
		if btn:
			btn.text = "%s\n%s\nCost: %d Chips" % [up["name"], up["desc"], up["cost"]]
			btn.disabled = (chips < up["cost"])

func select_option(index: int) -> void:
	if index < 0 or index >= upgrades.size():
		return
	var up = upgrades[index]
	var gd = get_node_or_null("/root/GameData")
	if gd and gd.spend_chips(up["cost"]):
		_apply_upgrade(up["id"])
		upgrade_purchased.emit(up["id"])
		_refresh_cards()

func _apply_upgrade(id: String) -> void:
	var gd = get_node_or_null("/root/GameData")
	if not gd:
		return
	match id:
		"speed":
			gd.player_speed *= 1.2
		"health":
			gd.player_max_hp += 30
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				players[0].max_health = gd.player_max_hp
				players[0].heal(gd.player_max_hp)
		"weapon_orbit":
			if not gd.active_weapons.has("orbit"):
				gd.active_weapons.append("orbit")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				select_option(0)
			KEY_2:
				select_option(1)
			KEY_3:
				select_option(2)
			KEY_SPACE, KEY_ENTER:
				close_shop()
