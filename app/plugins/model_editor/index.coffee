supported_field = window.app_config.supported_field
supported_field_setting = window.app_config.supported_field_setting
common_fields = window.app_config.common_fields
define('model_editor', ()->
	user_plugin = 	
		name : 'model_editor'
		anchor : '#/model_editor'
		title : 'Model Editor'
		type : 'plugin'
		icon : 'icon-pencil'
		# initialize plugin,
		init : ()->
			self = @
			console.log 'init'
			fields_num = Object.keys(supported_field).length
			for field, attrs of supported_field
				foundry.model field, attrs.concat(common_fields), () ->
					if fields_num-- is 1
						foundry.initialized(self.name)
						define_controller()
)
define_controller = ()->
	angular.module('foundry').controller('ModelEditorController', ['$scope', '$foundry', ($scope, $foundry)->
		# only for debug
		window.scope = $scope

		# util func
		$scope.encodeURI = 	window.encodeURI
		$scope.$safeApply = (fn) ->
		  phase = this.$root.$$phase;
		  if phase is '$apply' or phase is '$digest'
		    if fn and (typeof(fn) is 'function')
		      fn()
		  else 
		    this.$apply(fn);
		  
		$scope.fields_in_new_model = []
		$scope.supported_field_setting = supported_field_setting

		supported_field_models = {}
		for field_name in Object.keys(supported_field)
			supported_field_models[field_name] = foundry.load_model(field_name) 

		$scope.push_field_to_new_model = (type) ->
			for field in $scope.fields_in_new_model
				if field.name is $scope.field_name_to_add
					sweetAlert("Oops...", "Field name #{field.name} already exists.", "error");
					return;
			to_push = {
				name: $scope.field_name_to_add
				type: type
				setting: null
			}
			setting = {}
			supported_field[type].map (attr) -> 
				s = "#{type}_#{attr}"
				setting[attr] = $scope[s]
			to_push.setting = setting
			$scope.fields_in_new_model.push(to_push)
		
		$scope.delete_field_from_new_model = (index) ->
			$scope.fields_in_new_model.splice(index, 1)	

		$scope.add_model = () ->
			for name, model of foundry._models
				if name is $scope.new_model_name
					sweetAlert("Oops...", "Model #{$scope.new_model_name} already exists.", "error");
					return
			foundry.model $scope.new_model_name, $scope.fields_in_new_model.map((field)->field.name), (user_model) ->
				
				# store each field's setting
				for field in $scope.fields_in_new_model
					field_model = supported_field_models[field.type]
					field.setting.model_belonged_to = $scope.new_model_name
					field.setting.field_name = field.name
					field_model.create(field.setting)
				$scope.load()
				$scope.selected_model = $scope.new_model_name
				$scope.$safeApply()

		$scope.del_model = (name) ->
			swal {   
				title: "Are you sure?",   
				text: "The model will be deleted as well as the data stored in it!",   
				type: "warning",   
				showCancelButton: true,   
				confirmButtonColor: "#DD6B55",   
				confirmButtonText: "Yes, delete it!",   
				cancelButtonText: "No, cancel plx!",   
				closeOnConfirm: false,   
				closeOnCancel: false 
			}, (isConfirm) ->
				if isConfirm
					# delete all data
					model_to_del = $scope.user_models[name]
					if model_to_del
						model_to_del.all().map (data) -> data.destroy()
					# delete model info
					for field in $scope.generated_models[name]
						field.setting.destroy()
					$scope.load()
					new_model_name_list = Object.keys($scope.generated_models)
					$scope.selected_model = new_model_name_list[0]
					$scope.$safeApply()
					swal("Deleted!", "Your model and data has been deleted.", "success")
				else
					swal("Cancelled", "Your model and data are safe :)", "error")
					

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
			for name, model_info_list of $scope.generated_models
				attrs = model_info_list.map (model_info) -> model_info.name
				foundry.model name, attrs, (loaded_model) ->
					$scope.user_models[name] = loaded_model

		$scope.load()

	])