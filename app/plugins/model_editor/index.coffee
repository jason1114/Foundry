supported_field = {
	'_field_switch': ["on_value", "off_value", "default_value"]
	'_field_text_input': ["default_value", "required"]
	'_field_text_area': ["default_value", "required"]
	'_field_rate': ["default_value", "max_rate", "required"]
	'_field_number_input': ["default_value", "max_value", "min_value", "required"]
	'_field_image': ["required"]
}
supported_field_setting = {
	'_field_switch': ["Switch"]
	'_field_text_input': ["Text Input"]
	'_field_text_area': ["Text Area"]
	'_field_rate': ["Rate"]
	'_field_number_input': ["Nimber Input"]
	'_field_image': ["Image"]
}
common_fields = ["model_belonged_to", "field_name"]
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

		generated_prefix = "_model_"
		$scope.generated_models = {}
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
			inner_model_name = generated_prefix+$scope.new_model_name
			for name, model of foundry._models
				if name is inner_model_name
					sweetAlert("Oops...", "Model #{$scope.new_model_name} already exists.", "error");
					return
			foundry.model inner_model_name, $scope.fields_in_new_model.map((field)->field.name), () ->
				# store each field's setting
				for field in $scope.fields_in_new_model
					field_model = supported_field_models[field.type]
					field.setting.model_belonged_to = $scope.new_model_name
					field.setting.field_name = field.name
					field_model.create(field.setting)
				$scope.load()
				$scope.$apply()


		$scope.load = () ->
			for name, model of foundry._models
				if name.indexOf(generated_prefix) isnt -1
					$scope.generated_models[name.substr(generated_prefix.length)] = model
		$scope.load()

	])