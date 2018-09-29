
# Organeq
# An organically growing equation

# NOTE: name should really be Organex or Organexp at this point
# although not to be confused with http://arxiv.org/abs/1608.03000
# ("Neural Generation of Regular Expressions from Natural Language with Minimal Domain Knowledge")

# TODO: bounding box (&etc.) system(s/z)
# maybe use MathJax? it's supposed to have modular input/output

debug_id_counter = 1

class MathNode
	constructor: ->
		@debug_id = debug_id_counter++
		# @x = 0
		# @y = 0
		@width = 0
		@height = 0
		@children = []
		@parent = null
	update: ->
		child.update() for child in @children
	# draw: ->
	# 	console.warn "draw() not implemented for #{@constructor.name}"

class Parenthetical extends MathNode
	constructor: (@expression)->
		super()
		@children.push(@expression)
		@padding_for_parentheses = 1.4

	Object.defineProperties @prototype,
		children:
			get: -> [@expression]
			set: ([@expression])->
	
	update: ->
		super()
		@width = @expression.width + @padding_for_parentheses
		@height = @expression.height

	draw: ->
		ctx.save()
		ctx.rect(-@width/2, -@height/2, @width, @height)
		ctx.clip()
		ctx.beginPath()
		curve_amount = 0.5 # TODO: base on height
		curve_control_points_inset = @height * 0.3
		# TODO: use fill instead of stroke, and taper the bow
		# get rid of the clip() and do that geometry more directly
		for i in [0..2]
			ctx.save()
			if i is 1
				ctx.scale(-1, 1)
			ctx.translate(-@width/2 + @padding_for_parentheses/2, 0)
			ctx.moveTo(0, -@height/2)
			ctx.bezierCurveTo(
				-curve_amount, -@height/2+curve_control_points_inset,
				-curve_amount, @height/2-curve_control_points_inset
				0, @height/2,
			)
			ctx.restore()
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

		@width = 0
		@height = 0

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
			@width = Math.max(@lhs.width, @rhs.width)
			# @height = @lhs.height + @rhs.height + @operand_separation_padding # except it's not centered; we'd have to calculate a bounding box x/y
			# TODO: we do want to have it be centered
			@height = Math.max(@lhs.height, @rhs.height) * 2 + @operand_separation_padding
		else
			# @width = @lhs.width + @rhs.width + @operand_separation_padding # except it's not centered; we'd have to calculate a bounding box x/y
			# TODO: we do want to have it be centered
			@width = Math.max(@lhs.width, @rhs.width) * 2 + @operand_separation_padding
			@height = Math.max(@lhs.height, @rhs.height)

	draw: ->
		
		@drawOperator()

		
		ctx.save()
		#ctx.translate(-@operand_separation_factor/2, 0)
		ctx.rotate(@operand_angle)
		# TODO: smooth
		operand_dimension = if @vertical then @lhs.height else @lhs.width/2 # TODO: why /2?
		ctx.translate(-operand_dimension * @operand_separation_factor - @operand_separation_padding/2, 0)
		ctx.rotate(-@operand_angle)
		@lhs.draw()
		ctx.restore()
		
		ctx.save()
		#ctx.translate(@operand_separation_factor/2, 0)
		ctx.rotate(@operand_angle)
		# TODO: smooth
		operand_dimension = if @vertical then @rhs.height else @rhs.width/2 # TODO: why /2?
		ctx.translate(operand_dimension * @operand_separation_factor + @operand_separation_padding/2, 0)
		ctx.rotate(-@operand_angle)
		@rhs.draw()
		ctx.restore()


class Fraction extends InfixBinaryOperator
	constructor: (@divisor, @denominator)->
		super()
		
		@stroke_length = 0
		@stroke_length_to = @stroke_length

	Object.defineProperties @prototype,
		divisor:
			get: -> @lhs
			set: (@lhs)->
		denominator:
			get: -> @rhs
			set: (@rhs)->

	update: ->
		super()

		@stroke_length_to =
			if @vertical
				Math.max(@denominator.width, @divisor.width, 1) + .9
			else
				Math.max(@denominator.height, @divisor.height, 1) + .9

		# @stroke_length += (@stroke_length_to - @stroke_length) / 20
		@stroke_length += (@stroke_length_to - @stroke_length) / 9

		# TODO: smooth
		# if Math.random() < 0.5
		if @vertical
			@width = Math.max(@width, @stroke_length)
		else
			@height = Math.max(@height, @stroke_length)

	draw: ->
		super()
		
		# debug
		# ctx.save()
		# ctx.fillStyle = "rgba(255, 125, 125, 0.3)"
		# ctx.fillRect(-@width/2, -@height/2, @width, @height)
		# ctx.restore()

	drawOperator: ->
		ctx.save()
		stroke_width = 0.1
		#ctx.fillRect(-stroke_width/2, -1, stroke_width, 1.5)
		ctx.lineWidth = stroke_width
		ctx.beginPath()
		ctx.rotate(@symbol_angle)
		ctx.moveTo(0, -@stroke_length/2)
		ctx.lineTo(0, @stroke_length/2)
		ctx.stroke()
		ctx.restore()


class Literal extends MathNode
	constructor: (@value)->
		super()
		@width = 0
		@height = 0
	draw: ->
		font_size = 100
		ctx.textAlign = "center"
		ctx.textBaseline = "middle"
		ctx.font = "#{font_size}px sans-serif"
		ctx.save()
		ctx.scale(1/font_size, 1/font_size)
		ctx.fillText(@value, 0, 0)
		@width = ctx.measureText(@value).width / font_size
		@height = 1.2 # .2 = padding
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
	console.log(number_of_literals_to_mutate)
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

