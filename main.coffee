
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

# TODO: maybe have a BinaryOperator class
# with symbol_angle and angle (or operand_angle)

class Fraction extends MathNode
	constructor: (@divisor, @denominator)->
		super()

		@angle = 0.2
		@angle_to = @angle
		@separation = 0
		@separation_padding = 0
		@separation_padding_to = @separation_padding
		@separation_to = 1

		@stroke_length = 0
		@stroke_length_to = @stroke_length
		@stroke_angle = 0
		@stroke_angle_to = @angle

	draw: ->
		
		ctx.save()
		stroke_width = 0.1
		#ctx.fillRect(-stroke_width/2, -1, stroke_width, 1.5)
		ctx.lineWidth = stroke_width
		ctx.beginPath()
		ctx.rotate(@stroke_angle)
		ctx.moveTo(0, -@stroke_length/2)
		ctx.lineTo(0, @stroke_length/2)
		ctx.stroke()
		ctx.restore()
		
		ctx.save()
		#ctx.translate(-@separation/2, 0)
		ctx.rotate(@angle)
		ctx.translate(-@divisor.width/2 * @separation - @separation_padding/2, 0)
		ctx.rotate(-@angle)
		@divisor.draw()
		ctx.restore()
		
		ctx.save()
		#ctx.translate(@separation/2, 0)
		ctx.rotate(@angle)
		ctx.translate(@denominator.width/2 * @separation + @separation_padding/2, 0)
		ctx.rotate(-@angle)
		@denominator.draw()
		ctx.restore()
		
		# TODO: restore external configurability of these now-computed properties?
		# I could have vertical_X and horizontal_X for each, but maybe there's something better to do
		@separation_to = if @vertical then 0.5 else 1
		@separation_padding_to = if @vertical then 0.1 else 1
		@stroke_length_to = if @vertical then Math.max(@denominator.width, @divisor.width) else 1.9
		@stroke_angle_to = if @vertical then Math.PI / 2 else 0.2
		@angle_to = if @vertical then Math.PI / 2 else 0

		# TODO: a better/cleaner way of handling this animation stuff
		# and, maybe bring in some spring while you're at it
		# if it's abstracted properly, adding velocity shouldn't be a problem :)
		@separation += (@separation_to - @separation) / 20
		@separation_padding += (@separation_padding_to - @separation_padding) / 20
		@angle += (@angle_to - @angle) / 20
		@stroke_length += (@stroke_length_to - @stroke_length) / 20
		@stroke_angle += (@stroke_angle_to - @stroke_angle) / 20
		# faster, arbitrarily (thoughtlessly/carelessly) but nicely varied transition speeds (divisors here):
		# @separation += (@separation_to - @separation) / 5
		# @separation_padding += (@separation_padding_to - @separation_padding) / 8
		# @angle += (@angle_to - @angle) / 5
		# @stroke_length += (@stroke_length_to - @stroke_length) / 9
		# @stroke_angle += (@stroke_angle_to - @stroke_angle) / 3


class Literal extends MathNode
	constructor: (@value)->
		super()
		@width = 0
	draw: ->
		font_size = 100
		ctx.textAlign = "center"
		ctx.textBaseline = "middle"
		ctx.font = "#{font_size}px sans-serif"
		ctx.save()
		ctx.scale(1/font_size, 1/font_size)
		ctx.fillText(@value, 0, 0)
		@width = ctx.measureText(@value).width / font_size
		ctx.restore()

root = new Fraction(new Literal("1−1+1"), new Literal("1+1−1"))

mutate = (node = root, levelsProcessed = 0)->
	if node instanceof Fraction
		# node.angle_to = if levelsProcessed % 2 is 1 then 0.2 else Math.PI / 2
		# node.angle_to = if Math.random() < 0.5 then 0.2 else Math.PI / 2
		node.vertical = Math.random() < 0.5
	for subnode in node.children
		mutate subnode, levelsProcessed + 1
	

setInterval mutate, 500

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
	root.draw()
	ctx.restore()

