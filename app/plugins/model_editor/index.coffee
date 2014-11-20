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
		# for manage tabs
		$scope.choose_a_model = "--Choose a model--"
		$scope.tab_to_add = $scope.choose_a_model
		if window.localStorage and window.localStorage.recent_tabs_model
			$scope.tabs = JSON.parse(window.localStorage.recent_tabs_model)
		else
			$scope.tabs = []
		save_recent_tabs = () ->
			if window.localStorage and $scope.tabs
				window.localStorage.recent_tabs_model = JSON.stringify($scope.tabs)
		$scope.add_tab = () ->
			tab_to_add = $scope.tab_to_add
			$scope.tab_to_add = $scope.choose_a_model
			return if !tab_to_add
			if $scope.tabs.indexOf(tab_to_add) isnt -1
				$scope.selected_model = tab_to_add
				return
			if $scope.tabs.length >= 10
				# sweet alert
				sweetAlert("Oops...", "You can only open 10 tabs at most.", "error");
				return 
			$scope.tabs.push(tab_to_add)
			$scope.selected_model = tab_to_add
			$scope.$safeApply()
			save_recent_tabs()
		$scope.del_tab = ($index) ->
			if $scope.tabs[$index] is $scope.selected_model
				if $scope.tabs[$index-1]
					$scope.selected_model = $scope.tabs[$index-1]
				else if $scope.tabs[$index+1]
					$scope.selected_model = $scope.tabs[$index+1]
				else 
					$scope.selected_model = null
			$scope.tabs.splice($index,1)
			$scope.$safeApply()
			save_recent_tabs()


		$scope.fields_in_new_model = []
		$scope.supported_field_setting = supported_field_setting

		supported_field_models = {}
		for field_name in Object.keys(supported_field)
			supported_field_models[field_name] = foundry.load_model(field_name) 

		$scope.push_field_to_model = (type) ->
			target = if $scope.selected_model then $scope.generated_models[$scope.selected_model] else $scope.fields_in_new_model
			for field in target
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
			if $scope.selected_model
				field_to_create = angular.copy(setting)
				field_to_create.model_belonged_to = $scope.selected_model
				field_to_create.field_name = to_push.name
				field_model = supported_field_models[to_push.type]
				field_model.create(field_to_create)
				$scope.load()
			else 
				$scope.fields_in_new_model.push(to_push)
		
		$scope.delete_field_from_new_model = (index) ->
			$scope.fields_in_new_model.splice(index, 1)	
		
		$scope.model_rename = {}
		$scope.in_rename = {}
		$scope.enter_rename = (field_info) ->
			$scope.in_rename[field_info.setting.id] = true
			$scope.model_rename[field_info.setting.id] = field_info.setting.field_name
		
		$scope.cancel_rename = (field_info) ->
			$scope.in_rename[field_info.setting.id] = false
			delete $scope.model_rename[field_info.setting.id]
		
		$scope.rename_field = (field_info) ->
			old_fields = $scope.generated_models[field_info.setting.model_belonged_to].map (field_info) -> 
				field_info.name
			new_field_name = $scope.model_rename[field_info.setting.id]
			# check whether name is legal
			if !new_field_name
				sweetAlert("Oops...", "New field name can't be empty.", "error");
				return
			if old_fields.indexOf(new_field_name) isnt -1
				sweetAlert("Oops...", "Fild name #{new_field_name} already exists.", "error");
				return
			# create a new field in the user model
			new_fields = old_fields.concat new_field_name
			foundry.model field_info.setting.model_belonged_to, new_fields, (new_user_model) ->
				# assign the old value to the new field
				for record in new_user_model.all()
					record[new_field_name] = record[field_info.name] 
					record.save()
				# rename the old field
				field_info.setting.field_name = new_field_name
				field_info.setting.save()
				$scope.load()
				$scope.$safeApply()
				$scope.cancel_rename(field_info)
			
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
				$scope.tab_to_add = $scope.new_model_name
				$scope.add_tab()
				$scope.selected_model = $scope.new_model_name
				$scope.$safeApply()
		
		$scope.model_edit = {}

		$scope.enter_edit = (field) ->
			$scope.model_edit[field.id] = angular.copy(field)
		$scope.cancel_edit = (field) ->
			delete $scope.model_edit[field.id]
		$scope.edit_model = (field) ->
			field.save()
			$scope.$safeApply()
			$scope.cancel_edit(field)
		$scope.del_field = (field) ->
			swal {   
				title: "Are you sure?",   
				text: "The field will be deleted, and the data in this field will gone as well",   
				type: "warning",   
				showCancelButton: true,   
				confirmButtonColor: "#DD6B55",   
				confirmButtonText: "Yes, delete it!",   
				cancelButtonText: "No, cancel plx!",   
				closeOnConfirm: false,   
				closeOnCancel: false 
			}, (isConfirm) ->
				if isConfirm
					if $scope.generated_models[field.setting.model_belonged_to].length<=1
						swal("Cancelled", "Your can't delete the only field of a model :)", "error")
						return
					field.setting.destroy()
					$scope.load()
					$scope.$safeApply()
					swal("Deleted!", "Your model and data has been deleted.", "success")
				else
					swal("Cancelled", "Your model and data are safe :)", "error")
		
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
					
		$scope.change_selected = (name) ->
			$scope.selected_model = name
			
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