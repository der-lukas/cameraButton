CameraLayer = require "CameraLayer"

# Method for getting the average color of an image
Layer::getAverageColor = (completion) ->
	# https://codepen.io/influxweb/pen/LpoXba
	img = new Image
	img.onload = ->
		defaultRGB = r: 0, g: 0, b: 0
		rgb = defaultRGB
		canvas = document.createElement("canvas")
		ctx = canvas.getContext and canvas.getContext("2d")
		if not ctx then return defaultRGB

		width = canvas.width = this.width
		height = canvas.height = this.height

		ctx.drawImage(this, 0, 0, width, height)
		try data = ctx.getImageData(0, 0, width, height)
		catch e then return defaultRGB

		length = data.data.length
		blockSize = 5
		count = 0

		for i in [0...length] by blockSize * 4
			count++
			rgb.r += data.data[i]
			rgb.g += data.data[i+1]
			rgb.b += data.data[i+2]

		rgb.r = ~~(rgb.r/count)
		rgb.g = ~~(rgb.g/count)
		rgb.b = ~~(rgb.b/count)

		completion(new Color(rgb))

	img.src = this.image


class CameraButton extends Layer
  constructor: (@options = {}) ->

    @options.interval ?= 0.3
    @options.valueGap ?= 5

    super(@options)

    interval = @options.interval
    valueGap = @options.valueGap
    target = @

    # Hide the layer, since it should only emit the event
    @visible = false

    # Set initial referenceLuminocity to false
    referenceLuminocity = false

    # Define the cameraButtonTap eventname (maybe: "CameraTap", "CamTap", "Cap")
    customEventName = "Cap"

    # Create Layer that holds the image for further processing
    # Most probably a better way to do this...
    imageView = new Layer
    	width: false
    	height: false
    	opacity: 0

    # Create the CameraLayer, that takes the shots
    # Currently the complete "CameraLayer" module is being imported
    # Should probably just get stripped down to the functions we need
    camera = new CameraLayer
    	width: 1
    	height: 1
    	opacity: 0

    # Start capturing
    camera.start()

    # Capture an image every "x" seconds
    Utils.interval interval, ->
	     camera.capture()

    # Function for debouncing the cameraTap-events
    debouncedEmitter = Utils.debounce interval, (emitTarget, cb) ->
      emitTarget.emit customEventName, cb

    # Hands action to emitter, when a cameraTap is registered
    actionHandler = (triggered, imageLuminocity, referenceLuminocity, target) ->
      cb = {triggered, imageLuminocity, referenceLuminocity}
      debouncedEmitter(target, cb)

    # Shorthand for target.on "Cap"
    Layer::onCap = (callback) ->
      target.on customEventName, (callback)

    # Once the image is captured...
    camera.onCapture (imageURL) ->
    	imageView.image = imageURL

      # .. get the image's average color
    	imageView.getAverageColor (color) ->
        # convert the color to HUSL and just save the luminocity
    		imageLuminocity = Utils.round(color.toHusl().l, 0)

        # If the imageLuminocity-value is 0
        # the camera most probably wasn't ready yet
    		if (imageLuminocity > 0)

          # Set the referenceLuminocity if it's not set yet
          # or if the luminocity values change within the valueGap-range
          # update the referenceLuminocity, to balance ambient light changes
    			if (referenceLuminocity is false) or (imageLuminocity - valueGap <= referenceLuminocity <= imageLuminocity + valueGap)
    				referenceLuminocity = imageLuminocity

          # If the luminocity is below the valueGap,
          # trigger the event
    			else if imageLuminocity < referenceLuminocity - valueGap
            actionHandler(true, imageLuminocity, referenceLuminocity, target)

module.exports = CameraButton if module?
Framer.CameraButton = CameraButton
