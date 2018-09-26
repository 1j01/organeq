
# Organeq
# An organically growing equation

# NOTE: name should really be Organex or Organexp at this point
# although not to be confused with http://arxiv.org/abs/1608.03000
# ("Neural Generation of Regular Expressions from Natural Language with Minimal Domain Knowledge")

# TODO: bounding box (&etc.) system(s/z)
# maybe use MathJax? it's supposed to have modular input/output

# TODO: dynamically ever-expanding and ever-complicating expressions or equations

class MathNode
	constructor: ->
		# @x = 0
		# @y = 0
		# @width = 0
		# @height = 0
		@children = []
	update: ->
	# draw: ->

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

	update: ->
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

		@lhs.update()
		@rhs.update()

		# @width = lerp(
		# 	Math.max(@lhs.width, @rhs.width)
		# 	@lhs.width + @rhs.width
			
		# )
		# TODO: smooth
		if @vertical
			@width = Math.max(@lhs.width, @rhs.width)
			# @height = @lhs.height + @rhs.height + @operand_separation_padding # except it's not centered; we'd have to calculate a bounding box x/y
			@height = Math.max(@lhs.height, @rhs.height) * 2 + @operand_separation_padding
		else
			# @width = @lhs.width + @rhs.width + @operand_separation_padding # except it's not centered; we'd have to calculate a bounding box x/y
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
		@children.push(
			@lhs = @divisor
			@rhs = @denominator
		) # look how fancy i'm being
		# isn't it
		# totally worth it?
		(no)
		
		@stroke_length = 0
		@stroke_length_to = @stroke_length

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

root = new Fraction(
	new Fraction(new Literal("1−1+1"), new Literal("1+1−1"))
	new Fraction(new Literal("1−1+1"), new Literal("1+1−1"))
)

mutate = (node = root, levelsProcessed = 0)->
	if node instanceof Fraction
		# node.operand_angle_to = if levelsProcessed % 2 is 1 then 0.2 else Math.PI / 2
		# node.operand_angle_to = if Math.random() < 0.5 then 0.2 else Math.PI / 2
		node.vertical = Math.random() < 0.5
	for subnode in node.children
		mutate subnode, levelsProcessed + 1
	

setInterval mutate, 500
# canvas.onclick = -> mutate(root)

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

