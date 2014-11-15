supported_field = {
	'_field_switch': ["on_value", "off_value", "default_value"]
	'_field_text_input': ["default_value", "required"]
	'_field_text_area': ["default_value", "required"]
	'_field_rate': ["default_value", "max_rate"]
	'_field_number_input': ["default_value", "max_value", "min_value", "required"]
	'_field_image': ["required"]
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
		get_values_from_scope = (key_list) ->
			map = {}
			map[key] = $scope[key] for key in key_list
			map
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
			keys = supported_field[type].map((attr) -> "#{type}_#{attr}")
			to_push.setting = get_values_from_scope(keys)
			$scope.fields_in_new_model.push(to_push)
		$scope.delete_field_from_new_model = (index) ->
			$scope.fields_in_new_model.splice(index, 1)	
		for name, model of foundry._models
			if name.indexOf(generated_prefix) isnt -1
				$scope.generated_models[name.substr(generated_prefix.length)] = model

	])