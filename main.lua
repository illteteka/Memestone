-- Global paths to Subreddit data
Subreddit_A_Deckname = "dankmemes.csv"
Subreddit_B_Deckname = "CoronavirusMemes.csv"

Subreddit_A_Cards = "dm_cards.csv"
Subreddit_B_Cards = "cm_cards.csv"

-- Game code start

local lg = love.graphics
input = require "input"

screen_width = 1696
screen_height = 960

font_size = 32

game_state = 0

STATE_LOAD = 0
STATE_FIGHT = 1

battle_state = 0
battle_counter = 0
battle_process = false
battle_poison = false
battle_end = false
battle_kill_monsters = {}

battle_text = {}

BATTLE_IDLE = 0
BATTLE_ATTACK = 1

c_white = {1,1,1,1}
c_black = {0,0,0,1}
c_red = {215/255, 43/255, 80/255, 1}

player = {}
player.hp = 100
player.max_hp = 100
player.deck = {}
player.hand = {}
player.discard = {}
player.play_area = {}
player.select = {}
player.monsters = {}
player.shield = 0
player.mana = 6
player.max_mana = 6
player.poison = 0
player.bonus = {}

enemy = {}
enemy.hp = 100
enemy.max_hp = 100
enemy.deck = {}
enemy.hand = {}
enemy.discard = {}
enemy.play_area = {}
enemy.select = {}
enemy.monsters = {}
enemy.shield = 0
enemy.mana = 6
enemy.max_mana = 6
enemy.poison = 0
enemy.bonus = {}

templates = {}
templates.attack  = {}
templates.poison  = {}
templates.defense = {}
templates.monster_att  = {}
templates.monster_psn  = {}
templates.monster_heal = {}
templates.special = {}

CARD_ATTACK  = 0
CARD_POISON  = 1
CARD_SHIELD  = 2
CARD_MONSTER = 3
CARD_SPECIAL = 4
CARD_HEAL    = 5

SPECIAL_HEAL_POISON = 1
SPECIAL_DRAW_TWO = 2
SPECIAL_DISCARD_ALL_MONSTERS = 3
SPECIAL_BREAK_SHIELD = 4
SPECIAL_DISCARD = 5
SPECIAL_DISCARD_ALL = 6
SPECIAL_UPVOTE = 7

card_scroll_bar = 0
card_scroll_resize = false

active_card = -1
held_card = -1
held_x = -1
held_y = -1
active_bonus = -1
held_bonus = -1
bonus_in_play_area = false
bonus_attached = -1
temp_num_cards_to_draw = 0

current_user = player
user_id = 1

outline = nil

ris = {
"https://www.bing.com/images/search?view=detailv2&iss=sbi&form=SBIANS&sbisrc=UrlPaste&q=imgurl:",
"&idpbck=1&selectedindex=0&id=",
"&ccid=jUB63Tgt&simid=146573524367&thid=OIF.P596kNk%2FCsSTg8WEGLo1%2FQ&mediaurl=",
"&exph=",
"&expw=",
"&vt=2&sim=11"}

function game_init()

	player.hp = player.max_hp
	player.hp = 100
	player.max_hp = 100
	player.deck = {}
	player.hand = {}
	player.discard = {}
	player.play_area = {}
	player.select = {}
	player.monsters = {}
	player.shield = 0
	player.mana = player.max_mana
	player.poison = 0
	player.bonus = {}
	
	enemy.hp = enemy.max_hp
	enemy.deck = {}
	enemy.hand = {}
	enemy.discard = {}
	enemy.play_area = {}
	enemy.select = {}
	enemy.monsters = {}
	enemy.shield = 0
	enemy.mana = enemy.max_mana
	enemy.poison = 0
	enemy.bonus = {}
	
	cardTemplates()
	
	generateStandardDeck(1)
	generateStandardDeck(2)
	
	player.deck = randomizeDeck(1)
	drawNewHand(player, 1)
	
	enemy.deck = randomizeDeck(2)
	drawNewHand(enemy, 2)
	
	generateBonus(player)
	generateBonus(enemy)

end

function generateStandardDeck(user)

	local j
	for j = 1, 16 do
		generateCard(CARD_ATTACK, user)
	end
	
	for j = 1, 8 do
		generateCard(CARD_SHIELD, user)
	end
	
	for j = 1, 8 do
		generateCard(CARD_MONSTER, user)
	end
	
	for j = 1, 4 do
		generateCard(CARD_SPECIAL, user)
	end

end

function cardTemplates()

	addTemplate(CARD_ATTACK, CARD_ATTACK, 2, "Do 2 damage.", 2, (1/2))
	addTemplate(CARD_ATTACK, CARD_ATTACK, 2, "Do 3 damage.", 3, (2/3))
	addTemplate(CARD_ATTACK, CARD_ATTACK, 2, "Do 4 damage.", 4, 1)
	
	addTemplate(CARD_SHIELD, CARD_SHIELD, 2, "Shield 2 times.", 2, (1/5))
	addTemplate(CARD_SHIELD, CARD_SHIELD, 2, "Shield 3 times.", 3, (1/3))
	addTemplate(CARD_SHIELD, CARD_SHIELD, 2, "Shield 4 times.", 4, (1/2))
	
	addTemplate(CARD_POISON, CARD_POISON, 2, "Poison 3 times.", 3, (1/10))
	addTemplate(CARD_POISON, CARD_POISON, 2, "Poison 5 times.", 5, (1/6))
	addTemplate(CARD_POISON, CARD_POISON, 2, "Poison 8 times.", 8, (1/3))
	
	addTemplate(CARD_SPECIAL, SPECIAL_HEAL_POISON,          4, "Recover from poison.")
	addTemplate(CARD_SPECIAL, SPECIAL_DRAW_TWO,             3, "Draw 2 cards.")
	addTemplate(CARD_SPECIAL, SPECIAL_DISCARD_ALL_MONSTERS, 5, "Discard all active enemy helpers.")
	addTemplate(CARD_SPECIAL, SPECIAL_BREAK_SHIELD,         5, "Break the enemy's shield.")
	addTemplate(CARD_SPECIAL, SPECIAL_DISCARD,              4, "Discard your current hand and redraw.")
	addTemplate(CARD_SPECIAL, SPECIAL_DISCARD_ALL,          4, "Discard the hands of both players and redraw.")
	addTemplate(CARD_SPECIAL, SPECIAL_UPVOTE,               0, "Multiply status card by upvotes.")
	
	addTemplate(CARD_MONSTER, CARD_ATTACK, 3, "Do 1 damage.", 1, 0, 3, 6)
	addTemplate(CARD_MONSTER, CARD_ATTACK, 3, "Do 2 damage.", 2, 0, 3, 6)
	addTemplate(CARD_MONSTER, CARD_ATTACK, 3, "Do 3 damage.", 3, 0, 4, 5)
	addTemplate(CARD_MONSTER, CARD_POISON, 3, "Poison 2 times. Do 1 damage.", 2, 0, 1, 3, 1)
	addTemplate(CARD_MONSTER, CARD_POISON, 3, "Poison 4 times. Do 2 damage.", 4, 0, 1, 3, 2)
	addTemplate(CARD_MONSTER, CARD_POISON, 3, "Poison 3 times. Do 3 damage.", 3, 0, 2, 4, 3)
	addTemplate(CARD_MONSTER, CARD_HEAL,   3, "Heal 1 HP.", 1, 0, 4, 6)
	addTemplate(CARD_MONSTER, CARD_HEAL,   3, "Heal 2 HP.", 2, 0, 4, 7)
	addTemplate(CARD_MONSTER, CARD_HEAL,   3, "Heal 3 HP.", 3, 0, 4, 8)

end

function love.load()
	math.randomseed(os.time())
	font = lg.newFont("assets/fonts/font.ttf",font_size)
	font_small = lg.newFont("assets/fonts/font.ttf",20)
	font_tiny = lg.newFont("assets/fonts/font.ttf",16)
	font_mini = lg.newFont("assets/fonts/font.ttf",14)
	card_font = lg.newFont("assets/fonts/interui.ttf",20)
	lg.setFont(font)
	lg.setLineWidth(1)
	love.window.setMode(screen_width, screen_height, {resizable=true, vsync=false, minwidth=1280, minheight=784, fullscreen=false})
	
	c_cards = {}
	table.insert(c_cards, {HSL(0,255,100,1)})
	table.insert(c_cards, {HSL(197,255,100,1)})
	table.insert(c_cards, {HSL(170,255,100,1)})
	table.insert(c_cards, {HSL(95,255,89,1)})
	table.insert(c_cards, {HSL(20,230,89,1)})
	table.insert(c_cards, {HSL(35,255,100,1)})
	
	h_outline = lg.newShader("assets/shaders/h_outline.frag")
	h_outline:send("_mod",20)
	h_outline:send("_lt",10)
	h_outline:send("_off",10)
	
	v_outline = lg.newShader("assets/shaders/v_outline.frag")
	v_outline:send("_mod",20)
	v_outline:send("_lt",10)
	v_outline:send("_off",10)

	cards = {}
	cards.raw = {newRaw(Subreddit_B_Deckname), newRaw(Subreddit_A_Deckname)}
	cards.calc = {newCalc(Subreddit_B_Cards), newCalc(Subreddit_A_Cards)}
	sortPolarity()
	cards.global_deck = {}
	table.insert(cards.global_deck, {})
	table.insert(cards.global_deck, {})
	
	icon_heart = lg.newImage("assets/art/icon_heart.png")
	icon_sword = lg.newImage("assets/art/icon_sword.png")
	icon_shield = lg.newImage("assets/art/icon_shield.png")
	icon_mana = lg.newImage("assets/art/icon_mana.png")
	icon_poison = lg.newImage("assets/art/icon_poison.png")
	icon_cancel = lg.newImage("assets/art/icon_cancel.png")
	icon_light = lg.newImage("assets/art/icon_light.png")
	icon_card = lg.newImage("assets/art/icon_card.png")
	card_template = lg.newImage("assets/art/card.png")
	card_top = lg.newImage("assets/art/card_top.png")
	card_mana = lg.newImage("assets/art/card_mana.png")
	bg_slice = lg.newImage("assets/art/slice.png")
	bg_fade = lg.newImage("assets/art/fade.png")
	bg_tile = lg.newImage("assets/art/tile.png")
	
	pol_left = lg.newImage("assets/art/pol_left.png")
	pol_right = lg.newImage("assets/art/pol_right.png")
	pol_bg = lg.newImage("assets/art/pol_bg.png")
	pol_red = lg.newImage("assets/art/pol_red.png")
	pol_white = lg.newImage("assets/art/pol_white.png")
	pol_green = lg.newImage("assets/art/pol_green.png")
	
	game_init()
	game_state = STATE_FIGHT
end

function processTurn(step)

	local is_over = false
	
	local get_enemy = enemy
	if (user_id == 2) then get_enemy = player end
	
	if bonus_in_play_area then
		
		if bonus_attached == #current_user.play_area then
			bonus_attached = -1
			bonus_in_play_area = false
		end
	
	end

	if step <= #current_user.play_area then
		local i = step
		
		battle_text = {}
		
		local cur_card = cards.global_deck[user_id][current_user.play_area[i]]
		local cur_type = cur_card._type
		
		if (cur_type == CARD_ATTACK) then
			
			table.insert(battle_text, "Player drew")
			table.insert(battle_text, "BASE_CARD")
			
			local value = cur_card.template.att
			if bonus_in_play_area and i == bonus_attached + 1 then
				value = value * math.floor(cur_card.template.ratio * cur_card.upvotes)
				table.insert(battle_text, "...and applied an UPVOTE BONUS!")
				table.insert(battle_text, "SECRET_CARD")
				table.insert(battle_text, "Using the power of " .. cur_card.upvotes .. " upvotes...")
			end
			
			if get_enemy.shield > 0 then
				get_enemy.shield = get_enemy.shield - value
				value = 0
				if get_enemy.shield <= 0 then
					value = get_enemy.shield * -1
					get_enemy.shield = 0
					table.insert(battle_text, "Broke the opponent's shield!")
				end
			end
			
			if value > 0 then
			table.insert(battle_text, "Does " .. value .. " damage to opponent!")
			end
			table.insert(battle_text, "Click to continue")
			get_enemy.hp = get_enemy.hp - value
			
		elseif (cur_type == CARD_POISON) then
		
			table.insert(battle_text, "Player drew")
			table.insert(battle_text, "BASE_CARD")
			
			local value = cur_card.template.psn
			if bonus_in_play_area and i == bonus_attached + 1 then
				value = value + math.floor(cur_card.template.ratio * cur_card.upvotes)
				table.insert(battle_text, "...and applied an UPVOTE BONUS!")
				table.insert(battle_text, "SECRET_CARD")
				table.insert(battle_text, "Using the power of " .. cur_card.upvotes .. " upvotes...")
			end
			
			table.insert(battle_text, "Stacked " .. value .. " poison damage onto the opponent!")
			table.insert(battle_text, "Click to continue")
			get_enemy.poison = get_enemy.poison + value
		
		elseif (cur_type == CARD_SHIELD) then
		
			table.insert(battle_text, "Player drew")
			table.insert(battle_text, "BASE_CARD")
			
			local value = cur_card.template.def
			if bonus_in_play_area and i == bonus_attached + 1 then
				value = value * math.floor(cur_card.template.ratio * cur_card.upvotes)
				table.insert(battle_text, "...and snuck an UPVOTE BONUS!")
				table.insert(battle_text, "SECRET_CARD")
				table.insert(battle_text, "Using the power of " .. cur_card.upvotes .. " upvotes...")
			end
			
			table.insert(battle_text, "Applied the strength of " .. value .. " armor!")
			table.insert(battle_text, "Click to continue")
			current_user.shield = current_user.shield + value
		
		elseif (cur_type == CARD_MONSTER) then
		
			table.insert(battle_text, "Player drew")
			table.insert(battle_text, "BASE_CARD")
			table.insert(current_user.monsters, cur_card)
			table.insert(battle_text, "Click to continue")
		
		elseif (cur_type == CARD_SPECIAL) then
			
			table.insert(battle_text, "Player drew")
			table.insert(battle_text, "BASE_CARD")
			
			if (cur_card.special_type == SPECIAL_HEAL_POISON) then
				current_user.poison = 0
			elseif (cur_card.special_type == SPECIAL_DRAW_TWO) then
				temp_num_cards_to_draw = temp_num_cards_to_draw + 2
			elseif (cur_card.special_type == SPECIAL_DISCARD_ALL_MONSTERS) then
			
				local j = 1
				for j = 1, #get_enemy.monsters do
					table.insert(current_user.discard,get_enemy.monsters[i].id)
				end
				
				get_enemy.monsters = {}
			
			elseif (cur_card.special_type == SPECIAL_BREAK_SHIELD) then
			
				get_enemy.shield = 0
			
			elseif (cur_card.special_type == SPECIAL_DISCARD) then
			
				local j = 1
				for j = 1, #current_user.hand do
					table.insert(current_user.discard,current_user.hand[j])
				end
				
				current_user.hand = {}
			
			elseif (cur_card.special_type == SPECIAL_DISCARD_ALL) then
			
				local j = 1
				for j = 1, #current_user.hand do
					table.insert(current_user.discard,current_user.hand[j])
				end
				
				current_user.hand = {}
				
				local j = 1
				for j = 1, #get_enemy.hand do
					table.insert(get_enemy.discard,get_enemy.hand[j])
				end
				
				get_enemy.hand = {}
				
				local not_id = 2
				if user_id == not_id then not_id = 1 end
				drawNewHand(get_enemy, not_id)
			
			end
			
			table.insert(battle_text, "Click to continue")
		
		end
		
	end
	
	-- Process active monsters
	
	if #current_user.monsters > 0 and step <= #current_user.play_area + #current_user.monsters and step > #current_user.play_area then
		local i = step - #current_user.play_area
		
		battle_text = {}
	
		local cur_card = current_user.monsters[i]
		local cur_type = current_user.monsters[i].monster_type
		
		if (cur_type == CARD_HEAL) then
		
			table.insert(battle_text, "Support card")
			table.insert(battle_text, i)
			current_user.hp = current_user.hp + cur_card.template.heal
			table.insert(battle_text, "Healed " .. cur_card.template.heal .. " HP!")
			table.insert(battle_text, "Click to continue")
		
		elseif (cur_type == CARD_ATTACK) then
		
			local value = cur_card.template.att
			
			table.insert(battle_text, "Support card")
			table.insert(battle_text, i)
			
			if get_enemy.shield > 0 then
				get_enemy.shield = get_enemy.shield - value
				value = 0
				if get_enemy.shield <= 0 then
					value = get_enemy.shield * -1
					get_enemy.shield = 0
					table.insert(battle_text, "Broke the opponent's shield!")
				end
			end
			
			if value > 0 then
			table.insert(battle_text, "Does " .. value .. " damage to opponent!")
			end
			get_enemy.hp = get_enemy.hp - value
			
			table.insert(battle_text, "Click to continue")
		
		elseif (cur_type == CARD_POISON) then
		
			table.insert(battle_text, "Support card")
			table.insert(battle_text, i)
			
			local value = cur_card.template.att
			
			if get_enemy.shield > 0 then
				get_enemy.shield = get_enemy.shield - value
				value = 0
				if get_enemy.shield <= 0 then
					value = get_enemy.shield * -1
					get_enemy.shield = 0
					table.insert(battle_text, "Broke the opponent's shield!")
				end
			end
			
			get_enemy.hp = get_enemy.hp - value
			if value > 0 then
			table.insert(battle_text, "Does " .. value .. " damage to opponent!")
			end
			
			local psn_value = cur_card.template.psn
			get_enemy.poison = get_enemy.poison + psn_value
			table.insert(battle_text, "Stacked " .. value .. " poison damage onto the opponent!")
			table.insert(battle_text, "Click to continue")
		
		end
		
		current_user.monsters[i].hp = current_user.monsters[i].hp - 1
		if current_user.monsters[i].hp == 0 then
			table.insert(battle_kill_monsters, current_user.monsters[i])
			current_user.monsters[i].hp = current_user.monsters[i].max_hp
		end
		
	end
	
	if step == #current_user.play_area + #current_user.monsters then
		is_over = true
	end
	
	return is_over

end

function processPoisonDmg(e)

	battle_text = {}
	-- Take damage from poison
	if e.poison > 0 then
		
		table.insert(battle_text, "Opponent takes damage from the poison!")
		
		if e.shield > 0 then
			e.shield = e.shield - 1
			if e.shield <= 0 then
				e.shield = 0
				table.insert(battle_text, "Broke the opponent's shield!")
			end
		else
			e.hp = e.hp - 1
			e.poison = math.max(e.poison - 1, 0)
		end
		
		table.insert(battle_text, "Click to continue")
		
	end

end

function postProcessTurn()

	-- Kill inactive monsters
	local i = 1
	while i <= #battle_kill_monsters do
		
		table.insert(current_user.discard,battle_kill_monsters[i].id)
		
		local j = 1
		while j <= #current_user.monsters do
			if current_user.monsters[j].id ~= nil then
				if battle_kill_monsters[i].id ~= nil then
					if current_user.monsters[j].id == battle_kill_monsters[i].id then
						table.remove(current_user.monsters, j)
					end
				end
			end
			j = j + 1
		end
		
		i = i + 1
		
	end
	
	battle_kill_monsters = {}

	if bonus_in_play_area then
		current_user.bonus = nil
		generateBonus(current_user)
		bonus_attached = -1
		bonus_in_play_area = false
	end

	discardPlayArea(current_user)
	current_user.mana = current_user.max_mana
	
	if #current_user.hand == 0 then
		drawNewHand(current_user, user_id)
	else
		drawCard(current_user, user_id)
	end
	
	local m = 1
	for m = 1, temp_num_cards_to_draw do
		drawCard(current_user, user_id)
	end
	
	temp_num_cards_to_draw = 0
	
	if user_id == 1 then
		current_user = enemy
		user_id = 2
	else
		current_user = player
		user_id = 1
	end
	
	card_scroll_bar = 0
	
	battle_state = BATTLE_IDLE

end

function love.update(dt)

	input.update(dt)
	local mx, my = love.mouse.getX(), love.mouse.getY()
	local sw, sh = screen_width, screen_height
	
	if game_state == STATE_FIGHT and battle_state == BATTLE_IDLE then
		
		local info_board_x = math.floor(screen_width * 3/4)
		local info_board_w = screen_width - info_board_x
		
		local deck_x_pos = 240
		local scroll_btn_size = 64
		local info_push_w = info_board_w - deck_x_pos + 32
		
		local width_of_cards = math.max(((#current_user.hand) * 232) - (screen_width - (deck_x_pos * 2) - (scroll_btn_size * 2) - info_push_w) - 29,0) + 232
		
		-- End turn button
		local fx, fy, fw, fh
		fx = deck_x_pos - 120 - 32
		fy = screen_height - 256 - 8 - 128 - 4 - 22
		fw = font_small:getWidth("END TURN") + 20
		fh = 32
		
		if current_user.mana ~= current_user.max_mana then
		
			if mx >= fx and mx <= fx + fw and my >= fy and my <= fy + fh then
				if mouse_switch == _PRESS then
				
					battle_state = BATTLE_ATTACK
					battle_counter = 0
					battle_process = false
					battle_poison = false
					battle_end = false
					
					active_card = -1
					active_bonus = -1
					
				end
			end
		
		end
		
		-- Left scroll button
		local bx, by, bw, bh
		bx = deck_x_pos
		by = screen_height - 256 - 8
		bw = scroll_btn_size
		bh = 257
		
		if mx >= bx and mx <= bx + bw and my >= by and my <= by + bh then
			if mouse_switch == _ON then
				card_scroll_bar = math.max(card_scroll_bar - (8 * 60 * dt), 0)
			end
		end
		
		-- Right scroll button
		bx = screen_width - deck_x_pos - scroll_btn_size - info_push_w
		by = screen_height - 256 - 8
		bw = scroll_btn_size
		bh = 257
		
		if mx >= bx and mx <= bx + bw and my >= by and my <= by + bh then
			if mouse_switch == _ON then
				card_scroll_bar = math.min(card_scroll_bar + (8 * 60 * dt), width_of_cards)
			end
		end
		
		if card_scroll_resize then
			card_scroll_bar = math.min(card_scroll_bar, width_of_cards)
			card_scroll_resize = false
		end
		
		-- Reverse Image Search button
		
		local rx, ry, rw, rh
		rx = info_board_x + 24
		ry = math.floor((3*screen_height)/4) + 12
		rw = info_board_w - 48
		rh = 48
		
		if mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh and (active_card ~= -1 or active_bonus ~= -1) then
		
			local card = nil
			if active_card ~= -1 then
				card = cards.global_deck[user_id][active_card]
			else
				card = current_user.bonus
			end
			local card_src = card.deck
			local get_img = cards.raw[card_src].img[card.id]
			if mouse_switch == _PRESS then
				local _url = cards.raw[card_src].url[card.id]
				_url = _url:gsub(":","%%3A")
				_url = _url:gsub("/","%%2F")
				local _iw, _ih = get_img:getWidth(), get_img:getHeight()
				love.system.openURL(ris[1].._url..ris[2].._url..ris[3].._url..ris[4].._ih..ris[5].._iw..ris[6])
			end
			
		end
		
		-- Player hand
		
		local sx, sy, sw, sh
		sx = deck_x_pos + scroll_btn_size
		sy = screen_height - 256 - 8
		sw = screen_width - (deck_x_pos * 2) - (scroll_btn_size * 2) - info_push_w
		sh = 256
		
		if mx >= sx and mx <= sx + sw and my >= sy and my <= sy + sh then
			
			local cx, cy, cw, ch
			local mouse_pos = (mx + card_scroll_bar) - (deck_x_pos + scroll_btn_size + 8) - 232
			
			cx = ((math.floor(mouse_pos/232)) * 232)
			local mouse_x_relative_to_card = mx-((cx - card_scroll_bar) + sx + 8) - 232
			local mouse_y_relative_to_card = my-sy
			
			local selected_card = (cx/232)+1
			
			if selected_card == 0 then
			
				if bonus_in_play_area == false and mouse_x_relative_to_card < 187 then
					
					active_bonus = 1
					active_card = -1
					
					if mouse_switch == _PRESS then
						held_bonus = 1
						held_x = mouse_x_relative_to_card
						held_y = mouse_y_relative_to_card
					end
					
				end
			
			else
			
				if held_card ~= -1 then selected_card = held_card end
				
				if selected_card > 0 and selected_card <= #current_user.hand then
					
					if mouse_x_relative_to_card < 187 then
					
						active_card = current_user.hand[selected_card]
						active_bonus = -1
						
						if mouse_switch == _PRESS then
							held_card = selected_card
							held_x = mouse_x_relative_to_card
							held_y = mouse_y_relative_to_card
						end
						
					end
					
				end
			
			end
			
		end
		
		local sx, sy, sw, sh
		sx = deck_x_pos
		sy = screen_height - 256 - 8 - 256 - 4
		sw = screen_width - (deck_x_pos * 2)+1 - info_push_w
		sh = 256
		
		if mx >= sx and mx <= sx + sw and my >= sy and my <= sy + sh then
		
			if held_card ~= -1 then

				if mouse_switch == _RELEASE then
				
					if bonus_in_play_area and #current_user.play_area == bonus_attached then
					
						local tp = cards.global_deck[user_id][current_user.hand[held_card]]._type
						
						if (tp == CARD_ATTACK) or (tp == CARD_POISON) or (tp == CARD_SHIELD) then
						
							local mn = cards.global_deck[user_id][current_user.hand[held_card]].template.mana
					
							if current_user.mana - mn >= 0 then
								current_user.mana = current_user.mana - mn
								
								table.insert(current_user.play_area, current_user.hand[held_card])
								table.remove(current_user.hand, held_card)
								
							end
						
						end
						
						held_card = -1
					
					else
				
						local mn = cards.global_deck[user_id][current_user.hand[held_card]].template.mana
					
						if current_user.mana - mn >= 0 then
							current_user.mana = current_user.mana - mn
							
							table.insert(current_user.play_area, current_user.hand[held_card])
							table.remove(current_user.hand, held_card)
							
						end
						held_card = -1
						
					end
				end
			
			end
			
			if held_bonus ~= -1 then
			
				if bonus_in_play_area == false and mouse_switch == _RELEASE then
					bonus_in_play_area = true
					bonus_attached = #current_user.play_area
					held_bonus = -1
				end
			
			end
			
			if (#current_user.play_area >= 1 or bonus_in_play_area) and rmb_switch == _PRESS then
			
				if bonus_attached == #current_user.play_area then
				
					bonus_in_play_area = false
					bonus_attached = -1
				
				else
			
					local last_card = current_user.play_area[#current_user.play_area]
					current_user.mana = current_user.mana + cards.global_deck[user_id][last_card].template.mana
					
					table.insert(current_user.hand, last_card)
					table.remove(current_user.play_area)
				
				end
				
			end
		
		else
		
			if held_card ~= -1 then

				if mouse_switch == _RELEASE then
					held_card = -1
				end
			
			end
			
			if held_bonus ~= -1 then
			
				if mouse_switch == _RELEASE then
					held_bonus = -1
				end
				
			end
		
		end
		
	end
	
	if battle_state == BATTLE_ATTACK then
	
		if mouse_switch == _PRESS then
		
			battle_counter = battle_counter + 1
			
			if (battle_process) then
			
				local get_enemy = enemy
				if (user_id == 2) then get_enemy = player end
				
					if get_enemy.poison == 0 then
						postProcessTurn()
					else
			
						if (not battle_end) and (battle_poison) then
							postProcessTurn()
						end
					
						if (not battle_poison) then
							processPoisonDmg(get_enemy)
							battle_poison = true
						end
				
					end
			
			else
			
				battle_process = processTurn(battle_counter)
				
			end
			
		end
	
	end

end

function generateBonus(user)

	local tbl = {}
	local pick_deck = math.random(#cards.raw)
	local raw = cards.raw[pick_deck]
	local pick_a_card = math.random(#cards.calc[pick_deck].pol)
	tbl.id = pick_a_card
	tbl.template = templates.special[SPECIAL_UPVOTE]
	tbl._type = CARD_SPECIAL
	tbl.color = c_cards[#c_cards]
	tbl.deck = pick_deck
	
	user.bonus = tbl

end

function generateCard(_type, user)

	local pick_deck = math.random(#cards.raw)
	local raw = cards.raw[pick_deck]
	local calc = cards.calc[pick_deck]
	
	local tbl = {}
	tbl.deck = pick_deck
	
	if (_type == CARD_ATTACK) then
		
		local rnd_psn = math.random(3)
		local is_psn = false
		if (rnd_psn == 1) then
			is_psn = true
		end
		
		local low = -1
		local high = -1
		
		local j
		for j = 1, #cards.calc[1].pos do
			local fl = math.floor(cards.calc[user].pol[j])
			if low == -1 and fl >= 3 then
				low = j
			end
			
			if fl <= 10 then
				high = j
			end
		end
		
		local pick_a_card = getPolarityIndex(cards.calc[user].pol[math.random(low,high)])
		local card_upvotes = raw.upvotes[pick_a_card]
		
		local tmpl = templates.attack
		if (is_psn) then tmpl = templates.poison end
		local pick_a_template = tmpl[math.random(#tmpl)]
		tbl.id = pick_a_card
		tbl.template = pick_a_template
		tbl.upvotes = card_upvotes
		
		if (is_psn) then _type = CARD_POISON end
		
		tbl._type = _type
		
	elseif (_type == CARD_SHIELD) then
	
		local low = -1
		local high = -1
		
		local j
		for j = 1, #cards.calc[1].pos do
			local fl = math.floor(cards.calc[user].pol[j])
			if low == -1 and fl >= 0 then
				low = j
			end
			
			if fl <= 2 then
				high = j
			end
		end
		
		local pick_a_card = getPolarityIndex(cards.calc[user].pol[math.random(low,high)])
		local card_upvotes = raw.upvotes[pick_a_card]
		local pick_a_template = templates.defense[math.random(#templates.defense)]
		tbl.id = pick_a_card
		tbl.template = pick_a_template
		tbl.upvotes = card_upvotes
		tbl._type = _type
		
	elseif (_type == CARD_MONSTER) then
	
		local low = -1
		local high = -1
		
		local j
		for j = 1, #cards.calc[1].pos do
			local fl = math.floor(cards.calc[user].pol[j])
			if low == -1 and fl >= 11 then
				low = j
			end
			
			if fl <= 30 then
				high = j
			end
		end
		
		local rnd_monster = math.random(30)
		local monst = 0
		if (rnd_monster == 1) then
			monst = templates.monster_heal
			tbl.monster_type = CARD_HEAL
		elseif (rnd_monster <= 23) then
			monst = templates.monster_att
			tbl.monster_type = CARD_ATTACK
		else
			monst = templates.monster_psn
			tbl.monster_type = CARD_POISON
		end
		
		local pick_a_card = getPolarityIndex(cards.calc[user].pol[math.random(low,high)])
		local pick_a_template = monst[math.random(#monst)]
		tbl.id = pick_a_card
		tbl.template = pick_a_template
		tbl.hp = math.random(pick_a_template.hp_low, pick_a_template.hp_high)
		tbl.max_hp = tbl.hp
		tbl._type = _type
		
	elseif (_type == CARD_SPECIAL) then
		
		local low = -1
		local high = -1
		
		local j
		for j = 1, #cards.calc[1].pos do
			local fl = math.floor(cards.calc[user].pol[j])
			if low == -1 and fl >= -30 then
				low = j
			end
			
			if fl <= -1 then
				high = j
			end
		end
		
		local pick_a_card = getPolarityIndex(cards.calc[user].pol[math.random(low,high)])
		
		local pick_a_template = {}
		local rnd_spe = math.random(60)
		if (rnd_spe <= 10) then
			pick_a_template = templates.special[SPECIAL_HEAL_POISON]
			tbl.special_type = SPECIAL_HEAL_POISON
		elseif (rnd_spe <= 40) then
			pick_a_template = templates.special[SPECIAL_DRAW_TWO]
			tbl.special_type = SPECIAL_DRAW_TWO
		elseif (rnd_spe <= 45) then
			pick_a_template = templates.special[SPECIAL_DISCARD_ALL_MONSTERS]
			tbl.special_type = SPECIAL_DISCARD_ALL_MONSTERS
		elseif (rnd_spe <= 50) then
			pick_a_template = templates.special[SPECIAL_BREAK_SHIELD]
			tbl.special_type = SPECIAL_BREAK_SHIELD
		elseif (rnd_spe <= 55) then
			pick_a_template = templates.special[SPECIAL_DISCARD]
			tbl.special_type = SPECIAL_DISCARD
		elseif (rnd_spe <= 60) then
			pick_a_template = templates.special[SPECIAL_DISCARD_ALL]
			tbl.special_type = SPECIAL_DISCARD_ALL
		end
		
		tbl.id = pick_a_card
		tbl.template = pick_a_template
		tbl._type = _type
		
	end
	
	tbl.color = c_cards[_type+1]
	
	if tbl.id == 0 then
		tbl.id = 1
	end
	
	table.insert(cards.global_deck[user], tbl)

end

function renderCard(tbl, x, y)
	
	lg.push()
	lg.translate(x,y)
	local c = cards.raw[tbl.deck]
	
	local card_img = c.img[tbl.id]
	
	local larger_bound = math.max(card_img:getWidth(), card_img:getHeight())
	local scale = 146/larger_bound
	lg.setColor(c_black)
	lg.rectangle("fill", 16, 32, 160, 120)
	lg.setColor(c_white)
	lg.draw(card_img, 21, 34, 0, scale)
	lg.setColor({tbl.color[1], tbl.color[2], tbl.color[3], 1})
	lg.draw(card_template, 0, 0)
	lg.setColor(c_white)
	lg.draw(card_top,0,0)
	
	lg.setFont(font_mini)
	lg.printf(tbl.template.desc, 19, 150, 146, "left")
	lg.draw(card_mana, -4, 0)
	lg.setColor(c_black)
	lg.print(tbl.template.mana, -4 + 13, 9+3)
	lg.setColor(c_white)
	lg.print(tbl.template.mana, -4 + 13, 9)
	
	if (tbl.hp ~= nil) then
		lg.draw(icon_heart, 180-26, -1, 0, 37/120)
		lg.setColor(c_black)
		lg.print(tbl.hp, 180-26 + 14, 9)
		lg.setColor(c_white)
		lg.print(tbl.hp, 180-26 + 14, 9)
	end
	
	lg.pop()
	
end

function love.draw()

	local mx, my = love.mouse.getX(), love.mouse.getY()
	
	if game_state == STATE_FIGHT then
	
		lg.setColor(c_white)
		for tx = 0, screen_width, 64 do
			for ty = 0, screen_height, 64 do
				lg.draw(bg_tile, tx, ty)
			end
		end
		
		local sw, sh = screen_width, screen_height
		
		lg.setFont(font_small)
		lg.setColor(c_white)
		
		local info_board_x = math.floor(screen_width * 3/4)
		local info_board_w = screen_width - info_board_x
		
		local deck_x_pos = 240
		local scroll_btn_size = 64
		local info_push_w = info_board_w - deck_x_pos + 32
		
		local smaller_bound = math.min(screen_width, screen_height)
		
		local max_size = math.floor(smaller_bound/4)
		
		-- Enemy play area
		lg.setColor({0.1,0.1,0.1,1})
		rect_thick(deck_x_pos, 0, screen_width - (deck_x_pos * 2)+1 - info_push_w, 256,4)
		
		local fx, fy, fw, fh
		fx = deck_x_pos - 120 - 32
		fy = screen_height - 256 - 8 - 128 - 4 - 22
		fw = font_small:getWidth("END TURN") + 20
		fh = 32
		
		if current_user.mana ~= current_user.max_mana and battle_state == BATTLE_IDLE then
		
			if mx >= fx and mx <= fx + fw and my >= fy and my <= fy + fh then
				lg.setColor({1,1,1,0.5})
				lg.rectangle("fill",fx,fy,fw,fh)
				lg.setColor(c_white)
			end
			
			lg.setColor({1,1,1,1})
		
		else
			lg.setColor({1,1,1,0.6})
		end
		
		lg.print("END TURN", deck_x_pos - 120 + 10 - 32, screen_height - 256 - 8 - 22 - 128)
		rect_thick_no_shader(fx, fy, fw, fh, 4)
		
		-- Player play area
		lg.setColor({1,1,1,1})
		rect_thick(deck_x_pos, screen_height - 256 - 8 - 256 - 4, screen_width - (deck_x_pos * 2)+1 - info_push_w, 256,4)
		
		if battle_state == BATTLE_IDLE then
			if #current_user.play_area == 0 and bonus_in_play_area then
			
				local xx, yy = screen_width - info_board_w - 256 + 32, screen_height - 256 - 8 - 256 - 4
				renderCard(current_user.bonus, xx, yy)
			
			else
			
				for i = 1, #current_user.play_area do
					local xx, yy = screen_width - info_board_w - 256 + 32, screen_height - 256 - 8 - 256 - 4
					renderCard(cards.global_deck[user_id][current_user.play_area[i]], xx, yy)
				end
				
				if #current_user.play_area == bonus_attached and bonus_in_play_area then
					local xx, yy = screen_width - info_board_w - 256 + 32, screen_height - 256 - 8 - 256 - 4
					renderCard(current_user.bonus, xx, yy)
				end
			
			end
		end
		
		local card_space = 0
		for i = 1, #current_user.monsters do
			local this_card = current_user.monsters[i]
			local xx, yy = deck_x_pos + card_space - 2, screen_height - 256 - 8 - 256 - 4
			renderCard(current_user.monsters[i], xx, yy)
			card_space = card_space + 56 + 150
		end
		
		local get_enemy = enemy
		if (user_id == 2) then get_enemy = player end
		card_space = 0
		for i = 1, #get_enemy.monsters do
			local this_card = get_enemy.monsters[i]
			local xx, yy = deck_x_pos + card_space - 2, 0
			renderCard(get_enemy.monsters[i], xx, yy)
			card_space = card_space + 56 + 150
		end
		
		lg.setColor(c_white)
		lg.draw(bg_slice, info_board_x, 0, 0, info_board_w, screen_height/1080)
		lg.draw(bg_fade, info_board_x-20, 0, 0, 1, screen_height)
		
		if active_card ~= -1 or active_bonus ~= -1 then
			lg.setColor(c_white)
			
			local card = nil
			if active_card ~= -1 then
				card = cards.global_deck[user_id][active_card]
			else
				card = current_user.bonus
			end
			local card_src = card.deck
			local get_title = cards.raw[card_src].title[card.id]
			local get_img = cards.raw[card_src].img[card.id]
			
			lg.setFont(font_tiny)
			lg.printf(get_title, info_board_x + 24, 24, info_board_w - 32)
			local calc_height = font_tiny:getWidth(get_title)/(info_board_w - 8)
			local guess_height = (calc_height*22)+48+16
			
			local smaller_img_bound = get_img:getWidth()
			
			lg.draw(get_img, info_board_x + 24, guess_height, 0, (info_board_w-48)/smaller_img_bound)
			
			lg.setColor(c_white)
			lg.setScissor(info_board_x, (7*screen_height)/10, info_board_w, ((3*screen_height)/10)+4)
			lg.draw(bg_slice, info_board_x, 0, 0, info_board_w, screen_height/1080)
			lg.setScissor()
			
			local pol = cards.calc[card_src].pol_raw[card.id]
			
			local rx, ry, rw, rh
			rx = info_board_x + 24
			ry = math.floor((3*screen_height)/4) + 12
			rw = info_board_w - 48
			rh = 48
			
			lg.setColor(c_white)
			lg.printf("Sentiment polarity:", rx, math.floor((3*screen_height)/4) + 26 - 48 - 24 + 8, rw, "center")
			
			lg.rectangle("fill", rx, ry - 24, rw, 12)
			lg.draw(pol_left, rx, ry - 24)
			lg.draw(pol_right, rx + rw - 16, ry - 24)
			lg.draw(pol_bg, rx+16, ry - 24, 0, rw - 32, 1)
			
			local pol_len = (rw/2)*math.min(math.abs(pol),30)/30
			
			if (pol > 0) then
				lg.draw(pol_green, rx + (rw/2), ry - 24, 0, pol_len, 1)
			elseif (pol < 0) then
				lg.draw(pol_red, rx + (rw/2) - pol_len, ry - 24, 0, pol_len, 1)
			elseif (pol == 0) then
				lg.draw(pol_white, rx + (rw/2) - 4, ry - 24, 0, 8, 1)
			end
			
			if mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh then
				lg.setColor({1,1,1,0.5})
				lg.rectangle("fill",rx,ry,rw,rh)
				lg.setColor(c_white)
			end
			
			lg.setColor(c_white)
			rect_thick_no_shader(rx, ry, rw, rh, 4)
			
			lg.printf("Search for this image online", rx, math.floor((3*screen_height)/4) + 26, rw, "center")
			
			local display_if_helper_offset = math.floor((3*screen_height)/4) + 26 + 48
			local show_hp = ""
			if card.hp ~= nil then
				lg.printf("HELPER", rx, display_if_helper_offset, rw, "left")
				display_if_helper_offset = display_if_helper_offset + 24
				show_hp = " | HP: " .. card.hp
			end
			lg.printf("MANA: " .. card.template.mana .. show_hp, rx, display_if_helper_offset, rw, "left")
			display_if_helper_offset = display_if_helper_offset + 24
			lg.printf(card.template.desc, rx, display_if_helper_offset, rw, "left")
			
			lg.setFont(font_small)
		end
		
		lg.setFont(font_small)
		
		drawPlayer(20, screen_height - 230, player.hp, player.shield, player.mana, player.poison)
		drawPlayer(20, 30, enemy.hp, enemy.shield, enemy.mana, enemy.poison)
		
		if game_state == STATE_FIGHT then
			
			-- Player Hand
			lg.setColor(c_white)
			rect(deck_x_pos, screen_height - 256 - 8, screen_width - (deck_x_pos * 2) - info_push_w, 257)
			
			-- Left scroll button
			local bx, by, bw, bh
			bx = deck_x_pos
			by = screen_height - 256 - 8
			bw = scroll_btn_size
			bh = 257
			
			if mx >= bx and mx <= bx + bw and my >= by and my <= by + bh then
				lg.setColor(c_red)
				lg.rectangle("fill",bx,by,bw,bh)
				lg.setColor(c_white)
			end
			
			rect(bx, by, bw, bh)
			lg.print("<", deck_x_pos + font_small:getWidth("<") + 10, screen_height - 256 - 8 + 128 - 13)
			
			-- Right scroll button
			bx = screen_width - deck_x_pos - scroll_btn_size - info_push_w
			by = screen_height - 256 - 8
			bw = scroll_btn_size
			bh = 257
			
			if mx >= bx and mx <= bx + bw and my >= by and my <= by + bh then
				lg.setColor(c_red)
				lg.rectangle("fill",bx,by,bw,bh)
				lg.setColor(c_white)
			end
			
			rect(bx, by, bw, bh)
			lg.print(">", screen_width - deck_x_pos - scroll_btn_size + font_small:getWidth(">") + 10 - info_push_w, screen_height - 256 - 8 + 128 - 13)
			
			local sx, sy, sw, sh
			sx = deck_x_pos + scroll_btn_size
			sy = screen_height - 256 - 8
			sw = screen_width - (deck_x_pos * 2) - (scroll_btn_size * 2) - info_push_w
			sh = 256
			
			lg.push()
			lg.setScissor(sx, sy, sw, sh)
			lg.translate(scroll_btn_size + 8 - card_scroll_bar,0)
			
			if bonus_in_play_area == false and held_bonus == -1 then
				local xx, yy = deck_x_pos, screen_height - 256 - 8
				renderCard(current_user.bonus, xx, yy)
			end
			
			local i = 1
			for i = 1, #current_user.hand do
				if i ~= held_card then
					local xx, yy = deck_x_pos + (232 * (i)), screen_height - 256 - 8
					renderCard(cards.global_deck[user_id][current_user.hand[i]], xx, yy)
				end
			end
			
			lg.setScissor()
			lg.pop()
			
			if held_card ~= -1 then
				renderCard(cards.global_deck[user_id][current_user.hand[held_card]], mx - held_x, my - held_y)
				
				local sx2, sy2, sw2, sh2
				sx2 = deck_x_pos
				sy2 = screen_height - 256 - 8 - 256 - 4
				sw2 = screen_width - (deck_x_pos * 2)+1 - info_push_w
				sh2 = 256
		
				if mx >= sx2 and mx <= sx2 + sw2 and my >= sy2 and my <= sy2 + sh2 then
				
					if bonus_in_play_area and #current_user.play_area == bonus_attached then
						local tp = cards.global_deck[user_id][current_user.hand[held_card]]._type
								
						if (tp ~= CARD_ATTACK) and (tp ~= CARD_POISON) and (tp ~= CARD_SHIELD) then
							lg.draw(icon_cancel, mx - held_x + 34, my - held_y + 68, 0, 1)
						end
					end
				
				end
				
			elseif held_bonus ~= -1 then
				renderCard(current_user.bonus, mx - held_x, my - held_y)
			else
			
				if mx >= sx and mx <= sx + sw and my >= sy and my <= sy + sh then
					
					local cx, cy, cw, ch
					local mouse_pos = (mx + card_scroll_bar) - (deck_x_pos + scroll_btn_size + 8)
					cx = ((math.floor(mouse_pos/232)) * 232)
					local mouse_x_relative_to_card = mx-((cx - card_scroll_bar) + sx + 8)
					
					local selected_card = (cx/232)+1
					
					if mouse_x_relative_to_card < 187 then
						lg.setColor({1,1,1,0.5})
						cy = sy
						cw = 187
						ch = 256
						lg.rectangle("fill",cx + (deck_x_pos + scroll_btn_size + 8) - card_scroll_bar,cy,cw,ch)
					end
					
				end
			
			end
			
		end
	
	end
	
	if battle_state == BATTLE_ATTACK then
	
		lg.setColor(c_white)
		lg.setFont(font_tiny)
		local info_board_x = math.floor(screen_width * 3/4)
		local info_board_w = screen_width - info_board_x
		
		local i
		local hh = 0
		for i = 1, #battle_text do
			if battle_text[i] == "BASE_CARD" then
				hh = hh + 14
				renderCard(cards.global_deck[user_id][current_user.play_area[battle_counter]], info_board_x + 12 + ((info_board_w - 32 + 12)/2) - 94, hh)
				lg.setFont(font_tiny)
				hh = hh + 256 - 8
			elseif battle_text[i] == "SECRET_CARD" then
				hh = hh + 14
				renderCard(current_user.bonus, info_board_x + 12 + ((info_board_w - 32 + 12)/2) - 94, hh)
				lg.setFont(font_tiny)
				hh = hh + 256 - 8
			elseif string.len(battle_text[i]) <= 3 then
				hh = hh + 14
				renderCard(current_user.monsters[battle_counter - #current_user.play_area], info_board_x + 12 + ((info_board_w - 32 + 12)/2) - 94, hh)
				lg.setFont(font_tiny)
				hh = hh + 256 - 8
			else
				lg.printf(battle_text[i], info_board_x + 12, 24 + hh, info_board_w - 32 + 12, "center")
				hh = hh + 40
			end
		end
	
	end

end

function drawCard(plyr, user)
	if #plyr.deck == 0 then
		local i
		for i = 1, #plyr.discard do
			table.insert(plyr.deck, plyr.discard[1])
			table.remove(plyr.discard, 1)
		end
		
		plyr.deck = nil
		plyr.deck = {}
		plyr.deck = randomizeDeck(user)
	end
	
	table.insert(plyr.hand, plyr.deck[1])
	table.remove(plyr.deck, 1)
end

function drawNewHand(plyr, user)
	local i
	for i = 1, 6 do
		drawCard(plyr, user)
	end
end

function discardPlayArea(plyr)
	local m
	for m = 1, #plyr.play_area do
		local cur_card = cards.global_deck[user_id][current_user.play_area[m]]
		local cur_type = cur_card._type
		if (cur_type ~= CARD_MONSTER) then
			table.insert(plyr.discard,plyr.play_area[m])
		end
	end
	
	plyr.play_area = nil
	plyr.play_area = {}
end

function randomizeDeck(user)

	local tbl = {}
	local i = 1
	for i = 1, #cards.global_deck[user] do
		table.insert(tbl,i)
	end
	
	for i = 1, #cards.global_deck[user] do
		local swap = math.random(#cards.global_deck[user])
		tbl[i], tbl[swap] = tbl[swap], tbl[i]
	end
	
	return tbl

end

function drawPlayer(x, y, hp, sh, mn, pn)
	lg.setColor(c_white)

	lg.draw(icon_shield, x - 2, y + 12 + 120, 0, 64/120)
	lg.draw(icon_heart, x + 200 - 48 - 6, y + 12, 0, 64/120)
	lg.draw(icon_mana, x, y + 14, 0, 62/120)
	lg.draw(icon_poison, x + 200 - 48 - 6, y + 12 + 120, 0, 64/120)
	lg.setColor(c_black)
	lg.printf(sh, x + 17 - 8 - 2, y + 12 + 120 + 15,48,"center")
	lg.printf(hp, x + 200 - 48 - 6 + 17 - 8, y + 12 + 15,48,"center")
	
	lg.setColor(c_black)
	lg.printf(mn, x - 6 + 17 - 4, y + 12 + 15 + 7 + 3,48,"center")
	lg.setColor(c_white)
	lg.printf(mn, x - 6 + 17 - 4, y + 12 + 15 + 7,48,"center")
	lg.printf(pn, x + 200 - 48 - 6 + 17 - 8,y + 12 + 120 + 15+13,48,"center")
end

function rect_thick_no_shader(x,y,w,h,t)
	lg.rectangle("fill",x,y,w-t,t)
	lg.rectangle("fill",x+t,y+h-t,w-t,t)
	lg.rectangle("fill",x,y+t,t,h-t)
	lg.rectangle("fill",x+w-t,y,t,h-t)
end

function rect_thick(x,y,w,h,t)
	lg.setShader(h_outline)
	lg.rectangle("fill",x,y,w-t,t)
	lg.rectangle("fill",x+t,y+h-t,w-t,t)
	lg.setShader(v_outline)
	lg.rectangle("fill",x,y+t,t,h-t)
	lg.rectangle("fill",x+w-t,y,t,h-t)
	lg.setShader()
end

function rect(x,y,w,h)
	lg.rectangle("fill",x,y,w-1,1)
	lg.rectangle("fill",x,y+1,1,h-1)
	lg.rectangle("fill",x+1,y+h-1,w-1,1)
	lg.rectangle("fill",x+w-1,y,1,h-1)
end

function love.resize(w, h)
	screen_width, screen_height = w, h
	card_scroll_resize = true
end

function getPolarityIndex(num)
	num = math.abs(num)
	local fl = math.floor(num)
	num = (num - fl) * 100
	return math.floor(num)
end

function sortPolarity()
	
	cards.calc[1].pol = {}
	cards.calc[2].pol = {}
	
	local i
	for i = 1, #cards.calc[1].pos do
		table.insert(cards.calc[1].pol, cards.calc[1].pol_raw[i])
		table.insert(cards.calc[2].pol, cards.calc[2].pol_raw[i])
	end
	
	for i = 1, #cards.calc[1].pos do
		local i_100 = i/100
		local a_neg = cards.calc[1].pol[i] < 0
		if (a_neg) then a_neg = -1 else a_neg = 1 end
		local b_neg = cards.calc[2].pol[i] < 0
		if (b_neg) then b_neg = -1 else b_neg = 1 end
		local aa = a_neg * i_100
		local bb = b_neg * i_100
		cards.calc[1].pol[i] = cards.calc[1].pol[i] + aa
		cards.calc[2].pol[i] = cards.calc[2].pol[i] + bb
	end
	
	quickSort(cards.calc[1].pol, 1, #cards.calc[1].pol)
	quickSort(cards.calc[2].pol, 1, #cards.calc[2].pol)

end

function quickSort(array, p, r)
    p = p or 1
    r = r or #array
    if p < r then
        q = partition(array, p, r)
        quickSort(array, p, q - 1)
        quickSort(array, q + 1, r)
    end
end

function partition(array, p, r)
    local x = array[r]
    local i = p - 1
    for j = p, r - 1 do
        if array[j] <= x then
            i = i + 1
            local temp = array[i]
            array[i] = array[j]
            array[j] = temp
        end
    end
    local temp = array[i + 1]
    array[i + 1] = array[r]
    array[r] = temp
    return i + 1
end

function addTemplate(_type, ability, mana, desc, power, ratio, hp_low, hp_high, power_2)

	local tbl = {}
	if (_type == CARD_ATTACK) then

		tbl.att = power
		tbl.ratio = ratio
		tbl.desc = desc
		tbl.mana = mana
		
		table.insert(templates.attack, tbl)
		
	elseif (_type == CARD_POISON) then
		
		tbl.psn = power
		tbl.ratio = ratio
		tbl.desc = desc
		tbl.mana = mana
		
		table.insert(templates.poison, tbl)
		
	elseif (_type == CARD_SHIELD) then
	
		tbl.def = power
		tbl.ratio = ratio
		tbl.desc = desc
		tbl.mana = mana
		
		table.insert(templates.defense, tbl)
		
	elseif (_type == CARD_MONSTER) then
	
		if (ability == CARD_ATTACK) then
			tbl.att = power
		elseif (ability == CARD_POISON) then
			tbl.psn = power
			tbl.att = power_2
		elseif (ability == CARD_HEAL) then
			tbl.heal = power
		end
		tbl.hp_low = hp_low
		tbl.hp_high = hp_high
		tbl.desc = desc
		tbl.mana = mana
		
		if (ability == CARD_ATTACK) then
			table.insert(templates.monster_att, tbl)
		elseif (ability == CARD_POISON) then
			table.insert(templates.monster_psn, tbl)
		elseif (ability == CARD_HEAL) then
			table.insert(templates.monster_heal, tbl)
		end
		
	elseif (_type == CARD_SPECIAL) then

		tbl.special = ability
		tbl.desc = desc
		tbl.mana = mana
		
		table.insert(templates.special, tbl)
		
	end

end

function newRaw(file)
	local tbl = {}
	tbl.img = {}
	tbl.upvotes = {}
	tbl.title = {}
	tbl.url = {}
	importRaw(file, tbl)
	return tbl
end

function newCalc(file)
	local tbl = {}
	tbl.id = {}
	tbl.pos = {}
	tbl.pos_raw = {}
	tbl.neg = {}
	tbl.neg_raw = {}
	tbl.pol_raw = {}
	importCalc(file, tbl)
	return tbl
end

function importRaw(file, tbl)

	local check_file = love.filesystem.getInfo(file)
	if check_file then
	
		local skip_first_line = false
		for line in love.filesystem.lines(file) do
			if not skip_first_line then
				skip_first_line = true
			else
				
				local a,b,c,d
				find_comma = string.find(line, ",")
				
				if find_comma ~= nil then
					a = line:sub(0, find_comma-1)
					line = line:sub(find_comma+1)
					
					find_comma = string.find(line, ",")
					b = line:sub(0, find_comma-1)
					line = line:sub(find_comma+1)
					
					find_comma = string.find(line, ",")
					c = line:sub(0, find_comma-1)
					line = line:sub(find_comma+1)
					
					d = line:sub(1)
					
					table.insert(tbl.img, lg.newImage("images/" .. a))
					table.insert(tbl.upvotes, b)
					table.insert(tbl.title, c)
					table.insert(tbl.url, d)
				end
				
			end
		end
	
	end

end

function importCalc(file, tbl)

	local check_file = love.filesystem.getInfo(file)
	if check_file then
	
		local skip_first_line = false
		for line in love.filesystem.lines(file) do
			if not skip_first_line then
				skip_first_line = true
			else
				
				local a,b,c,d
				find_comma = string.find(line, ",")
				
				if find_comma ~= nil then
					a = line:sub(0, find_comma-1)
					line = line:sub(find_comma+1)
					
					find_comma = string.find(line, ",")
					b = line:sub(0, find_comma-1)
					line = line:sub(find_comma+1)
					
					find_comma = string.find(line, ",")
					c = line:sub(0, find_comma-1)
					line = line:sub(find_comma+1)
					
					d = line:sub(1)
					
					table.insert(tbl.id, a)
					table.insert(tbl.pos, tonumber(b))
					table.insert(tbl.pos_raw, tonumber(b))
					table.insert(tbl.neg, tonumber(c))
					table.insert(tbl.neg_raw, tonumber(c))
					table.insert(tbl.pol_raw, tonumber(d))
				end
				
			end
		end
	
	end

end

-- Converts HSL to RGB
function HSL(h, s, l, a)
	if s<=0 then return l/255,l/255,l/255,a end
	h, s, l = h/256*6, s/255, l/255
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return (r+m),(g+m),(b+m),a
end