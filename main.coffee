
# Organeq
# An organically growing equation

# NOTE: name should really be Organex or Organexp (at this point at least)
# although not to be confused with http://arxiv.org/abs/1608.03000
# ("Neural Generation of Regular Expressions from Natural Language with Minimal Domain Knowledge")

# TODO: bounding box (&etc.) system(s/z)
# maybe use MathJax? it's supposed to have modular input/output

# TODO: dynamically ever-expanding and ever-complicating expressions or equations

class MathNode
	constructor: ->
		@x = 0
		@y = 0

class Fraction extends MathNode
	constructor: (@divisor, @denominator)->
		super()
		@angle = 0.2
		@separation = 0
		@separation_padding = 0.4
		@separation_to = 1
		@stroke_length = 1.9
	draw: ->
		# TODO: at horizontal angle, draw line at max width of sub-mathnodes
		
		ctx.save()
		#ctx.translate(-@separation/2, 0)
		ctx.translate(-(@divisor.width/2 + @separation_padding/2) * @separation, 0)
		@divisor.draw()
		ctx.restore()
		
		ctx.save()
		stroke_width = 0.1
		#ctx.fillRect(-stroke_width/2, -1, stroke_width, 1.5)
		ctx.lineWidth = stroke_width
		ctx.beginPath()
		ctx.rotate(@angle)
		ctx.moveTo(0, -@stroke_length/2)
		ctx.lineTo(0, @stroke_length/2)
		ctx.stroke()
		ctx.restore()
		
		ctx.save()
		#ctx.translate(@separation/2, 0)
		ctx.translate((@denominator.width/2 + @separation_padding/2) * @separation, 0)
		@denominator.draw()
		ctx.restore()
		
		@separation += (@separation_to - @separation) / 20

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

