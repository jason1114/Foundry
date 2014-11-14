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
			supported_field = {
				'_field_switch': ["on_value", "off_value", "default_value"]
				'_field_text_input': ["default_value", "required"]
				'_field_text_area': ["default_value", "required"]
				'_field_rate': ["default_value", "max_rate"]
				'_field_number_input': ["default_value", "max_value", "min_value", "required"]
				'_field_image': ["required"]
			}
			common_fields = ["model_belonged_to", "field_name"]
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
		$scope.push_field_to_new_model = (type) ->
			to_push = {
				type: type
				setting: null
			}
			switch type
				when '_field_switch' then break;
				when '_field_text_input' then break;
				when '_field_text_area' then break;
				when '_field_rate' then break;
				when '_field_number_input' then break;
				when '_field_image' then break;
		for name, model of foundry._models
			if name.indexOf(generated_prefix) isnt -1
				$scope.generated_models[name.substr(generated_prefix.length)] = model

	])