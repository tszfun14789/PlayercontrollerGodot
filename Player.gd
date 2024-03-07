extends CharacterBody2D

const up = Vector2(0, -1)
const gravity = 20
const speed = 80

const whitenduration = 0.2
@export var whitenmaterial: ShaderMaterial


const jumpspeed = -350
var pparryeffect := preload("res://parryeffect.tscn")
var hhiteffect := preload("res://hiteffect.tscn")
var ddusteffect := preload("res://dusteffect.tscn")
var ddangereffect := preload("res://danger.tscn")
var sshame := preload("res://shame.tscn")
var bblackbars := preload("res://blackbars.tscn")
var mmeiyo := preload("res://meiyo.tscn")
var ffocus := preload("res://focus.tscn")
var wwind := preload("res://wind.tscn")
var facingright = false
var motion = Vector2()
var destination
var attacktimes = 0
var difficultmodeon = true

var health = 5
var dashbar = 240
var attackagain = false
var duringattack  = false
var parrysuccess = false
var duringparry  = false
var timercreated = false
var attackafterdashtimercreated = false
var attackafterdash 

enum { move, dash, jump, attack1, attack2, parry, gethit, knockback, die, idle, walk, rest, challenge, transition }
var state = rest

@onready var sprite = $Sprite2D
@onready var  animationplayer = $AnimationPlayer

func _ready():
	whitenmaterial.set_shader_parameter("whiten", false)
	difficultmodeon = get_tree().current_scene.get_node("/root/Scnemanager").isdifficultmodeon()
	
func _physics_process(delta):
	motion.y += gravity
	match state:
		move:
			movestate(delta)
		jump:
			jumpstate(delta)
		dash:
			dashstate(delta)	
		attack1:
			attack1state(delta)
		attack2:
			attack2state(delta)
		parry:
			parrystate(delta)
		gethit:
			gethitstate(delta)	
		knockback:
			knockbackstate(delta)	
		die:
			diestate(delta)	
		walk:
			walkstate(delta)	
		challenge:
			challengestate(delta)		
		idle:
			idlestate(delta)	
		rest:
			reststate(delta)
		transition:
			transitionstate(delta)		
	if state != attack1:
		disablehitboxes()		
	if  dashbar < 240:
		dashbar += 1
	else:
		 dashbar = 240			
	set_velocity(motion)
	set_up_direction(up)
	move_and_slide()
	motion = velocity


func movestate(delta):
	
	if Input.is_action_pressed("ui_right"):
		motion.x = speed
		if facingright == false:
			scale.x = -1
			facingright = true
		
	elif Input.is_action_pressed("ui_left"):		
		motion.x = -speed
		if facingright == true:
			scale.x = -1
			facingright = false
		
	else:
		motion.x = 0
				
	if is_on_floor():
		if Input.is_action_just_pressed("ui_up"):					
			pass	
		if Input.is_action_just_pressed("attack"):
			attacktimes += 1
			state = attack1
			
		if Input.is_action_just_pressed("parry"):		
			state = parry	

		if Input.is_action_just_pressed("dash") && dashbar > 120:
			dashbar -= 120
			state = dash
			$sounds/swordwhoosh.play()
			dusteffect(false,6 ,5)
			dusteffect(false,5 ,4)
			dusteffect(false,5 ,6)
			if facingright == true:
				motion.x = 150
			else:
				motion.x = -150	
			#yield(get_tree().create_timer(2), "timeout")	
			#dashbar += 1
				
	if health <= 0:
		animationplayer.play("die")
		state = die		
	else:
		animationupdate()	

func jumpstate(delta):
	animationplayer.play("jump")
	if Input.is_action_pressed("ui_right"):
		motion.x = speed
		if facingright == false:
			scale.x = -1
			facingright = true
		
	elif Input.is_action_pressed("ui_left"):		
		motion.x = -speed
		if facingright == true:
			scale.x = -1
			facingright = false
	else:
		motion.x = 0
	if is_on_floor():
		state = move	
func dashstate(delta):
	animationplayer.play("dash")
	await get_tree().create_timer(0.15).timeout
	if state == dash:	
		state = move

func move():
	if Input.is_action_pressed("ui_right"):
		motion.x = speed
		if facingright == false:
			scale.x = -1
			facingright = true
		
	elif Input.is_action_pressed("ui_left"):		
		motion.x = -speed
		if facingright == true:
			scale.x = -1
			facingright = false		
					
func attack1state(delta):
	motion.x = 0	
	duringattack = true
	if attacktimes == 1: 
		animationplayer.play("attack1")
	elif attacktimes == 2:
		attacktimes = 0
		animationplayer.play("attack2")
		
func attack2state(delta):
	motion.x = 0
	duringattack = true
	animationplayer.play("attack2")
	
func parrystate(delta):
	motion.x = 0
	duringparry = true
	animationplayer.play("parry")	
	if difficultmodeon == false:
		if Input.is_action_just_released("parry"):
			state = move
	else:
		pass		


func exitparrystate():
	if difficultmodeon == false:
		pass
	else:	
		duringparry = false
		if state != knockback:
			state = move
	
func exitattack1state():
	if attackagain == true:
		state = attack2
	else:
		duringattack = false
		state = move
	disablehitboxes()	
func exitattack2state():
	attackagain = false
	duringattack = false
	state = move
	disablehitboxes()
	
func gethitstate(delta):
	animationplayer.play("gethit")
	if is_on_floor():
		state = move
		
func knockbackstate(delta):
	if facingright == true:
		motion.x = motion.x + 6
	else:
		motion.x = motion.x - 6
	if timercreated == false:
		timercreated = true
		await get_tree().create_timer(0.15).timeout
		exitknockbackstate()	

func exitknockbackstate():
	timercreated = false
	state = move						
func playswordwhooshsound():
	$sounds/swordwhoosh.play()
							
func animationupdate():
	if motion.x != 0:
		animationplayer.play("run")

	else:
		animationplayer.play("idle")
		
func diestate(delta):
	motion.x = 0

func reststate(delta):
	animationplayer.play("rest")
	if Input.is_action_pressed("ui_right") ||  Input.is_action_pressed("ui_left"):	
		state = transition
		animationplayer.play("getup")
		
func entermovestate():
	state = move
	
func transitionstate(delta):
	pass				
			
func _on_hurtbox_area_entered(area):
	disablehitboxes()
	var attacker = area.get_parent().attackparent
	var attackerdistance = attacker.global_position.x - global_position.x
	if state != parry || state == parry && facingright == true && attackerdistance < 0 || state == parry && facingright == false && attackerdistance > 0:	
		#hiteffect
		$sounds/hitsound.play()
		var hiteffect = hhiteffect.instantiate()
		get_parent().add_child(hiteffect)
		if attackerdistance < 0:
			hiteffect.position = Vector2(global_position.x+6, global_position.y)
		else:
			hiteffect.flip_h = true
			hiteffect.position = Vector2(global_position.x-6, global_position.y)	
		motion.y = -200	
		shakescreen(3, 0.2)
		await get_tree().create_timer(0.05).timeout
		if attackerdistance > 0:
			motion.x = -speed	
			if facingright == false:
				scale.x = -1
				facingright = true
		else:
			motion.x = speed
			if facingright == true:
				scale.x = -1
				facingright = false		
		state = gethit	
		whitenmaterial.set_shader_parameter("whiten", true)
		await get_tree().create_timer(whitenduration).timeout
		whitenmaterial.set_shader_parameter("whiten", false)
		health -=1
		get_tree().current_scene.get_node("backbackground/UI/healthbar").reducehealth()
		if health == 0:	
			var shame = sshame.instantiate()
			get_parent().add_child(shame)
			await get_tree().create_timer(0.3).timeout	
			get_tree().current_scene.get_node("/root/Scnemanager").changescene(get_tree().current_scene.filename)	

	else:
		parrysuccess = true
		dashbar+=120
		$sounds/parrysound.play()
		shakescreen(1.5,0.2)
		var parryeffect = pparryeffect.instantiate()
		get_parent().add_child(parryeffect)
		if facingright == true:
			parryeffect.position = Vector2(global_position.x+6, global_position.y)
		else:
			parryeffect.position = Vector2(global_position.x-6, global_position.y)	
		attacker.playerparried()
		animationplayer.play("parrysuccess")	
		knockback()

func knockback():
	if facingright == true:
		motion.x = -110
	else:
		motion.x = 110
	state = knockback						

func gotparried():
#	knockback()
	pass

func disablehitboxes():	
	$hitbox/CollisionShape2D.set_deferred("disabled", true)
func dusteffect(needflip,positionx,positiony):
	var dusteffect = ddusteffect.instantiate()
	#get_tree().current_scene.add_child(dusteffect)
	get_parent().add_child(dusteffect)
	if facingright != needflip:
		dusteffect.flip_h = true
		dusteffect.position = Vector2(global_position.x-positionx, global_position.y -positiony)
	else:
		dusteffect.position = Vector2(global_position.x+positionx, global_position.y -positiony)	
		
func shakescreen(intensity, duration):
	#var intensity = 3
	#var duration = 0.2
	
	Shake.shake(intensity, duration)



func _on_specialhurtbox_area_entered(area):
	disablehitboxes()
	var attacker = area.get_parent().attackparent
	var attackerdistance = attacker.global_position.x - global_position.x
	if duringattack != true || duringattack == true && facingright == true && attackerdistance < 0 || duringattack == true && facingright == false && attackerdistance > 0 || state == parry:	
		#hiteffect
		print("dmg2")
		$sounds/hitsound.play()
		var hiteffect = hhiteffect.instantiate()
		get_parent().add_child(hiteffect)
		if attackerdistance < 0:
			hiteffect.position = Vector2(global_position.x+6, global_position.y)
		else:
			hiteffect.flip_h = true
			hiteffect.position = Vector2(global_position.x-6, global_position.y)	
		motion.y = -200	
		shakescreen(3, 0.2)
		await get_tree().create_timer(0.05).timeout
		if attackerdistance > 0:
			motion.x = -speed	
			if facingright == false:
				scale.x = -1
				facingright = true
		else:
			motion.x = speed
			if facingright == true:
				scale.x = -1
				facingright = false		
		state = gethit	
		whitenmaterial.set_shader_parameter("whiten", true)
		await get_tree().create_timer(whitenduration).timeout
		whitenmaterial.set_shader_parameter("whiten", false)
		health -=2
		get_tree().current_scene.get_node("backbackground/UI/healthbar").reducehealth()
		if health == 0 || health == -1:	
			var shame = sshame.instantiate()
			get_parent().add_child(shame)
			await get_tree().create_timer(0.3).timeout	
			get_tree().current_scene.get_node("/root/Scnemanager").changescene(get_tree().current_scene.filename)	

	else:
		dashbar+=120
		$sounds/parrysound.play()
		shakescreen(1.5,0.2)
		var parryeffect = pparryeffect.instantiate()
		get_parent().add_child(parryeffect)
		if facingright == true:
			parryeffect.position = Vector2(global_position.x+6, global_position.y)
		else:
			parryeffect.position = Vector2(global_position.x-6, global_position.y)	
		attacker.playerparried()
		knockback()

func dangereffect():
	$sounds/dangersound.play()
	var dangereffect = ddangereffect.instantiate()
	get_parent().add_child(dangereffect)
	dangereffect.position = Vector2(global_position.x, global_position.y - 12)
	shakescreen(2, 0.05)
	get_tree().paused = true
	await get_tree().create_timer(0.05).timeout
	get_tree().paused = false
	
func challengestate(delta):
	motion.x = 0
	animationplayer.play("challenge")
func playchallengesound():
	$sounds/swordwhoosh.play()
func exitchallengestate():
	state = idle	
func cannotmove():
	state = idle
func canmove():
	state = move		
	

func idlestate(delta):
	motion.x = 0
	animationplayer.play("idle")	
func walkstate(delta):
	animationplayer.play("run")			
func callmeiyo(bosspositionx):
	var bossdistance =  bosspositionx - global_position.x
	var meiyo = mmeiyo.instantiate()
	var blackbars = bblackbars.instantiate()
	var wind = wwind.instantiate()
	$sounds/deathdrum.play()
	state = idle
	get_parent().add_child(blackbars)
	flip(bossdistance)
	await get_tree().create_timer(0.4).timeout
	state = idle
	await get_tree().create_timer(0.6).timeout
	get_parent().add_child(meiyo)
	await get_tree().create_timer(0.1).timeout
	state = challenge
	await get_tree().create_timer(0.7).timeout
	get_parent().add_child(wind)
	wind.position = Vector2(global_position.x + 20, global_position.y +5)
	await get_tree().create_timer(2.2).timeout
	state = move	
	
func flip(bossdistance):
	state = walk
	if bossdistance > 0:
		if facingright == true:
			scale.x = -1
			facingright = false	
		motion.x = -60	
	else:
		if facingright == false:
			scale.x = -1
			facingright = true
		motion.x = 60	

func triggerdifficultmode():
	$sounds/dangersound.play()
	difficultmodeon = !difficultmodeon
	get_tree().current_scene.get_node("/root/Scnemanager").setdifficultmodeon(difficultmodeon)	
