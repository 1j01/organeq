
# Organeq
# An organically growing equation

# NOTE: name should really be Organex or Organexp at this point
# although not to be confused with http://arxiv.org/abs/1608.03000
# ("Neural Generation of Regular Expressions from Natural Language with Minimal Domain Knowledge")

# TODO: bounding box (&etc.) system(s/z)
# maybe use MathJax? it's supposed to have modular input/output

debug_draw_checkbox = document.getElementById("debug-draw")
debug_draw_checkbox_label = debug_draw_checkbox.parentElement
debug_draw_enabled = no
do debug_draw_checkbox.onchange = ->
	debug_draw_enabled = debug_draw_checkbox.checked
debug_draw_checkbox_label.onselectstart = (e)->
	e.preventDefault()

time = 0

class MathNode
	debug_id_counter = 1
	debug_colors = [
		"red"
		"orange"
		"yellow"
		"lime"
		"green"
		"aqua"
		"blue"
		"fuchsia"
	]
	constructor: ->
		@debug_id = debug_id_counter++
		@bb_left = 0
		@bb_top = 0
		@bb_right = 0
		@bb_bottom = 0
		@children = []
		@parent = null
	update: ->
		child.update() for child in @children
	draw: ->
		if @draw is MathNode::draw
			console.warn "draw() not implemented for #{@constructor.name}"
		if debug_draw_enabled
			@debugDraw()
	debugDraw: ->
		width = @bb_left + @bb_right
		height = @bb_top + @bb_bottom
		# ctx.shadowBlur = 11
		# ctx.shadowColor = "white"
		# ctx.translate(cos(@debug_id*time/100)/10, sin(@debug_id*time/100)/10)
		# ctx.scale(1+cos(@debug_id+time/100)/10, 1+sin(@debug_id+time/100)/10)
		# ctx.transform(1, cos(time/100)/100, sin(time/100)/100, 1, 0, 0)
		for i in [0..10]
			ctx.translate(cos(time/100)/100, sin(time/100)/100)
			ctx.save()
			ctx.beginPath()
			ctx.rect(-@bb_left, -@bb_top, width, height)
			ctx.fillStyle = debug_colors[@debug_id] ? "rgba(255, 0, 125, 0.3)"
			ctx.strokeStyle = debug_colors[@debug_id] ? "rgba(255, 125, 200, 0.7)"
			ctx.lineWidth = 0.03
			ctx.globalAlpha = 0.3 / if i is 10 then 1 else 10
			ctx.fill()
			ctx.globalAlpha = 0.8 / if i is 10 then 3 else 5
			ctx.stroke()
			ctx.restore()

class Parenthetical extends MathNode
	constructor: (@expression)->
		super()
		@children.push(@expression)
		@padding_for_parentheses = 0.7
		@vertical_padding = 0.1

	Object.defineProperties @prototype,
		children:
			get: -> [@expression]
			set: ([@expression])->
	
	update: ->
		super()
		@bb_left = @expression.bb_left + @padding_for_parentheses
		@bb_right = @expression.bb_right + @padding_for_parentheses
		@bb_top = @expression.bb_top + @vertical_padding
		@bb_bottom = @expression.bb_bottom + @vertical_padding

	draw: ->
		super()
		width = @bb_left + @bb_right
		height = @bb_top + @bb_bottom
		ctx.save()
		ctx.rect(-@bb_left, -@bb_top, width, height)
		ctx.clip()
		ctx.beginPath()
		curve_amount = 0.5 # TODO: base on height
		curve_control_points_inset = height * 0.3
		# TODO: use fill instead of stroke, and taper the bow
		# get rid of the clip() and do that geometry more directly
		draw_paren = (x, is_left)=>
			ctx.save()
			if is_left
				ctx.scale(-1, 1)
			ctx.translate(-@bb_left + @padding_for_parentheses, 0)
			ctx.moveTo(0, -@bb_top)
			ctx.bezierCurveTo(
				-curve_amount, -height/2+curve_control_points_inset,
				-curve_amount, height/2-curve_control_points_inset
				0, height/2,
			)
			ctx.restore()
		draw_paren(-@bb_left, true)
		draw_paren(-@bb_right, false)
		ctx.lineWidth = 0.1
		ctx.lineCap = "square" # extend further to get cut off by clip
		ctx.stroke()
		ctx.restore()
		@expression.draw()

class InfixBinaryOperator extends MathNode
	constructor: (@lhs, @rhs)->
		super()
		@operand_angle = 0.2
		@operand_angle_to = @operand_angle
		@operand_separation_factor = 0
		@operand_separation_factor_to = 1
		@operand_separation_padding = 0
		@operand_separation_padding_to = @operand_separation_padding

		@symbol_angle = 0
		@symbol_angle_to = @operand_angle

	Object.defineProperties @prototype,
		children:
			get: -> [@lhs, @rhs]
			set: ([@lhs, @rhs])->
				# @lhs.parent = @
				# @rhs.parent = @
	
	update: ->
		super()

		# TODO: restore external configurability of these now-computed properties?
		# I could have vertical_X and horizontal_X for each, but maybe there's something better to do
		@operand_separation_factor_to = if @vertical then 0.5 else 1
		@operand_separation_padding_to = if @vertical then 0 else 0.3 # more for horizontal is for fraction slash
		@symbol_angle_to = if @vertical then Math.PI / 2 else 0.2
		@operand_angle_to = if @vertical then Math.PI / 2 else 0

		# TODO: a better/cleaner way of handling this animation stuff
		# and, maybe bring in some spring while you're at it
		# if it's abstracted properly, adding velocity shouldn't be a problem :)
		# @operand_separation_factor += (@operand_separation_factor_to - @operand_separation_factor) / 20
		# @operand_separation_padding += (@operand_separation_padding_to - @operand_separation_padding) / 20
		# @operand_angle += (@operand_angle_to - @operand_angle) / 20
		# @symbol_angle += (@symbol_angle_to - @symbol_angle) / 20
		# faster, arbitrarily (thoughtlessly/carelessly) but nicely varied transition speeds (divisors here):
		@operand_separation_factor += (@operand_separation_factor_to - @operand_separation_factor) / 5
		@operand_separation_padding += (@operand_separation_padding_to - @operand_separation_padding) / 8
		@operand_angle += (@operand_angle_to - @operand_angle) / 5
		@symbol_angle += (@symbol_angle_to - @symbol_angle) / 3

		# @width = lerp(
		# 	Math.max(@lhs.width, @rhs.width)
		# 	@lhs.width + @rhs.width
			
		# )
		# TODO: smooth
		if @vertical
			@bb_left = Math.max(@lhs.bb_left, @rhs.bb_left)
			@bb_right = Math.max(@lhs.bb_right, @rhs.bb_right)
			@bb_top = Math.max(@lhs.bb_top, @rhs.bb_top) * 2 + @operand_separation_padding
			@bb_bottom = Math.max(@lhs.bb_bottom, @rhs.bb_bottom) * 2 + @operand_separation_padding
		else
			@bb_left = Math.max(@lhs.bb_left, @rhs.bb_left) * 2 + @operand_separation_padding
			@bb_right = Math.max(@lhs.bb_right, @rhs.bb_right) * 2 + @operand_separation_padding
			@bb_top = Math.max(@lhs.bb_top, @rhs.bb_top)
			@bb_bottom = Math.max(@lhs.bb_bottom, @rhs.bb_bottom)

	draw: ->
		super()
		
		@drawOperator()

		
		ctx.save()
		#ctx.translate(-@operand_separation_factor/2, 0)
		ctx.rotate(@operand_angle)
		# TODO: smooth
		operand_dimension = if @vertical then @lhs.bb_top + @lhs.bb_bottom else (@lhs.bb_left + @lhs.bb_right)/2 # TODO: why /2?
		ctx.translate(-operand_dimension * @operand_separation_factor - @operand_separation_padding/2, 0)
		ctx.rotate(-@operand_angle)
		@lhs.draw()
		ctx.restore()
		
		ctx.save()
		#ctx.translate(@operand_separation_factor/2, 0)
		ctx.rotate(@operand_angle)
		# TODO: smooth
		operand_dimension = if @vertical then @rhs.bb_top + @rhs.bb_bottom else (@rhs.bb_left + @rhs.bb_right)/2 # TODO: why /2?
		ctx.translate(operand_dimension * @operand_separation_factor + @operand_separation_padding/2, 0)
		ctx.rotate(-@operand_angle)
		@rhs.draw()
		ctx.restore()


class Fraction extends InfixBinaryOperator
	constructor: (@divisor, @denominator)->
		super()
		
		@lhs_stroke_length = 0
		@lhs_stroke_length_to = @lhs_stroke_length
		@rhs_stroke_length = 0
		@rhs_stroke_length_to = @rhs_stroke_length

	Object.defineProperties @prototype,
		divisor:
			get: -> @lhs
			set: (@lhs)->
		denominator:
			get: -> @rhs
			set: (@rhs)->

	update: ->
		super()
		if @vertical
			@lhs_stroke_length_to = Math.max(@denominator.bb_left, @divisor.bb_left, 1/2) + .9/2
			@rhs_stroke_length_to = Math.max(@denominator.bb_right, @divisor.bb_right, 1/2) + .9/2
		else
			@lhs_stroke_length_to =
			@rhs_stroke_length_to =
				(
					Math.max(
						@denominator.bb_top + @denominator.bb_bottom
						@divisor.bb_top + @divisor.bb_bottom
						1
					) + .9
				) / 2
	
		slowness = 9 # 20
		@lhs_stroke_length += (@lhs_stroke_length_to - @lhs_stroke_length) / slowness
		@rhs_stroke_length += (@rhs_stroke_length_to - @rhs_stroke_length) / slowness

		# TODO: smooth
		# if Math.random() < 0.5
		if @vertical
			@bb_left = Math.max(@bb_left, @lhs_stroke_length)
			@bb_right = Math.max(@bb_right, @rhs_stroke_length)
		else
			@bb_top = Math.max(@bb_top, @lhs_stroke_length)
			@bb_bottom = Math.max(@bb_bottom, @rhs_stroke_length)

	drawOperator: ->
		ctx.save()
		stroke_width = 0.1
		#ctx.fillRect(-stroke_width/2, -1, stroke_width, 1.5)
		ctx.lineWidth = stroke_width
		ctx.beginPath()
		ctx.rotate(@symbol_angle)
		ctx.moveTo(0, -@lhs_stroke_length)
		ctx.lineTo(0, @rhs_stroke_length)
		ctx.stroke()
		ctx.restore()


class Literal extends MathNode
	constructor: (@value)->
		super()
	draw: ->
		super()

		font_size = 100
		ctx.textAlign = "center"
		ctx.textBaseline = "middle"
		ctx.font = "#{font_size}px sans-serif"
		ctx.save()
		ctx.scale(1/font_size, 1/font_size)
		ctx.fillText(@value, 0, 0)
		width = ctx.measureText(@value).width / font_size
		height = 1.2 # .2 = padding
		@bb_left = width / 2
		@bb_right = width / 2
		@bb_top = height / 2
		@bb_bottom = height / 2
		ctx.restore()

root =
	# new Parenthetical(
	# 	new Fraction(
	# 		new Fraction(new Literal("1−1+1"), new Literal("1+1−1"))
	# 		new Parenthetical(
	# 			new Fraction(
	# 				new Fraction(new Literal("1×1÷1"), new Literal("1÷1×1"))
	# 				new Fraction(new Literal("1÷1÷1"), new Literal("1×1×1"))
	# 			)
	# 		)
	# 	)
	# )
	new Literal 1

replace = (oldNode, newNode)->
	# console.log "replace", oldNode, "with", newNode
	if oldNode is root
		newNode.parent = null
		root = newNode
	else
		index = oldNode.parent.children.indexOf(oldNode)
		# console.log "-> replace oldNode.parent.children[#{index}]"
		oldNode.parent.children[index] = newNode
		for k, v of oldNode.parent when v is oldNode
			oldNode.parent[k] = newNode
			# console.log "set oldNode.parent.#{k} to", newNode
		newNode.parent = oldNode.parent
	oldNode.parent = null

# this is a hack. ideally the parent prop would always be consistent,
# and not need to be made consistent in a step
assignParents = (node)->
	for subnode in node.children
		assignParents subnode
		subnode.parent = node # must be after recursion for root parent nullification
	node.parent = null # for root; must be after assigning all children's parent props
	return

shuffleArrayInPlace = (array)->
    i = array.length
    while --i > 0
        j = ~~(Math.random() * (i + 1))
        temp = array[j]
        array[j] = array[i]
        array[i] = temp
    array

findAllNodes = (node)->
	array = [node]
	for subnode in node.children
		array = array.concat(findAllNodes(subnode))
	array

findAllNodesOfType = (Class, node)->
	node for node in findAllNodes(node) when node instanceof Class 

mutateTree = (root)->
	# mutate the abstract syntax tree while retaining equality/equivalence

	literals = findAllNodesOfType(Literal, root)

	shuffleArrayInPlace(literals)

	min = 1
	max = Math.min(5, literals.length)
	number_of_literals_to_mutate = Math.max(min, ~~(Math.random() * (max + 1)))
	# console.log("number_of_literals_to_mutate:", number_of_literals_to_mutate)
	literals = literals.slice(0, number_of_literals_to_mutate)

	for literal in literals
		new_fraction = new Fraction(
			literal
			new Literal(1)
		)
		new_parenthetical = new Parenthetical(new_fraction)
		new_fraction.parent = new_parenthetical
		replace(literal, new_parenthetical)


alternateAlignments = (node, fractionLevelsProcessed)->
	if node instanceof Fraction
		node.vertical = fractionLevelsProcessed % 2 is 0
	for subnode in node.children
		alternateAlignments subnode, fractionLevelsProcessed + (if node instanceof Fraction then 1 else 0)
	return

alternateAlignments(root, 0)

canvas.onclick = (e)->
	e.preventDefault()
	# console.group("ONCLICK EVENT")
	assignParents(root)
	mutateTree(root)
	# assignParents(root)
	alternateAlignments(root, 0)
	# console.log("the root is now", root)
	# console.groupEnd("ONCLICK EVENT")
canvas.onselectstart = (e)->
	e.preventDefault()

animate ->
	time += 1

	{width: w, height: h} = canvas
	
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, w, h

	ctx.fillStyle = "white"
	ctx.strokeStyle = "white"
	
	ctx.save()
	ctx.translate(w / 2, h / 2)
	scale = 100
	ctx.scale(scale, scale)
	root.update()
	root.draw()
	ctx.restore()

