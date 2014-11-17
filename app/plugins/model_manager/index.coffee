supported_field = window.app_config.supported_field
supported_field_setting = window.app_config.supported_field_setting
common_fields = window.app_config.common_fields
# show_in_table = Object.keys(supported_field).filter (field) ->
# 	if Object.keys(window.app.show_in_detail).indexOf(field) is -1 then true
define('model_manager', ()->
	user_plugin = 	
		name : 'model_manager'
		anchor : '#/model_manager'
		title : 'Model Management'
		type : 'plugin'
		icon : 'icon-list'
		# initialize plugin,
		init : ()->
			self = @
			console.log 'init'
			fields_num = Object.keys(supported_field).length
			for field_model_name, attrs of supported_field
				foundry.model field_model_name, attrs.concat(common_fields), () ->
					if fields_num-- is 1
						foundry.initialized(self.name)
						define_controller()
)

define_controller = ()->	    
	angular.module('foundry').controller('ModelController', ['$scope', '$foundry', ($scope, $foundry)->
		# only for debug
		window.scope = $scope

		# util func
		$scope.make_range = (start, end, step) ->
			result = []
			v = start
			while (if end>start then v<=end else v>= end)
				result.push v
				v += step
			result
		$scope.encodeURI = 	window.encodeURI
		$scope.keys = Object.keys
		$scope.safeApply = (fn) ->
		  phase = this.$root.$$phase;
		  if phase is '$apply' or phase is '$digest'
		    if fn and (typeof(fn) is 'function')
		      fn()
		  else 
		    this.$apply(fn);
		$scope.is_field_hidden = (type) ->
			idx = Object.keys(window.app_config.show_in_detail).indexOf(type)
			if idx is -1 then false else true
		# store info to add model
		$scope.current = {}
		# TODO support multiple choosed_file
		# $scope.choosed_files = {}
		$scope.show_in_detail = window.app_config.show_in_detail
		# hide as row details
		$scope.hide_in_left = []
		$scope.hide_in_right = []
		for name, position of $scope.show_in_detail
			if position is 'left' 
				$scope.hide_in_left.push name
			else
				$scope.hide_in_right.push name
		supported_field_models = {}
		for field_name in Object.keys(supported_field)
			supported_field_models[field_name] = foundry.load_model(field_name) 

		file_module = foundry.load('document')
		$scope.change_selected = (name) ->
			$scope.selected_model = name
		# TODO multi image field upload
		$scope.upload = (field_name)->
			spinner = $foundry.spinner(
				type : 'loading'
				text : 'Uploading '
			)
			Nimbus.Binary.upload_file($scope.choosed_file,(file)->
				# push this into documents
				file_module.set(file._file.id, file._file)

				$scope.uploaded = {
					thumb: file._file.thumbnailLink
					name: file.name
					link: file.directlink
				}
				$scope.current[field_name] = $scope.uploaded.link
				$scope.current[field_name+"_thumb_"] = $scope.uploaded.thumb
				$scope.choosed_file = null
				spinner.hide()
				$scope.$safeApply()
			)
			return
		$scope.add = () ->

		$scope.load = () ->
			$scope.generated_models = {}
			for name, model of supported_field_models
				for field in model.all()
					if !$scope.generated_models[field.model_belonged_to]
						$scope.generated_models[field.model_belonged_to] = []
					field_info = {
						name: field.field_name
						type: name
						setting: field
					}
					$scope.generated_models[field.model_belonged_to].push(field_info)
			$scope.user_models = {}
			$scope.user_records = {}
			user_models_num = Object.keys($scope.generated_models).length
			for name, model_info_list of $scope.generated_models
				attrs = model_info_list.map (model_info) -> model_info.name
				foundry.model name, attrs, (loaded_model) ->
					$scope.user_models[name] = loaded_model
					$scope.user_records[name] = loaded_model.all()
					if user_models_num-- is 1
						# all user models are created
						$scope.selected_model = Object.keys($scope.generated_models)[0]

		$scope.load()
	])