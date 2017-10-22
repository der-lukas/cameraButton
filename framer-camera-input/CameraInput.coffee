class exports.CameraInput extends TextLayer
	constructor: (@options={}) ->
		_.defaults @options,
			ignoreEvents: false
		super @options

		@changeHandler = (event) ->
			if(@options.callback)
				file = @_element.files[0]
				url = URL.createObjectURL(file)
				@options.callback(url, file.type)

		@changeHandler = @changeHandler.bind @
		Events.wrap(@_element).addEventListener "change", @changeHandler

	_createElement: ->
		return if @_element?
		@_element = document.createElement "input"
		@_element.type = "file"
		@_element.capture = true
		@_element.classList.add("framerLayer")
		@_element.style["-webkit-appearance"] = "none"
		@_element.style["-webkit-text-size-adjust"] = "none"
		@_element.style["outline"] = "none"
		switch @options.accept
			when "image" then @_element.accept = "image/*"
			when "video" then @_element.accept = "video/*"
			else @_element.accept = "image/*,video/*"

	@define "accept",
		get: ->
			@_element.accept
		set: (value) ->
			switch value
				when "image" then @_element.accept = "image/*"
				when "video" then @_element.accept = "video/*"
				else @_element.accept = "image/*,video/*"