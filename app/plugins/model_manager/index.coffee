supported_field = window.app_config.supported_field
supported_field_setting = window.app_config.supported_field_setting
common_fields = window.app_config.common_fields
# show_in_table = Object.keys(supported_field).filter (field) ->
# 	if Object.keys(window.app.show_in_detail).indexOf(field) is -1 then true
define('model_manager', ()->
	user_plugin = 	
		name : 'model_manager'
		anchor : '#/model_manager'
		title : 'SimpleBase'
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
	angular.module('foundry').controller('ModelController', ['$scope', '$foundry', '$filter', ($scope, $foundry, $filter)->
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
		$scope.$safeApply = (fn) ->
		  phase = this.$root.$$phase;
		  if phase is '$apply' or phase is '$digest'
		    if fn and (typeof(fn) is 'function')
		      fn()
		  else 
		    this.$apply(fn);
		$scope.is_field_hidden = (type) ->
			idx = Object.keys(window.app_config.show_in_detail).indexOf(type)
			if idx is -1 then false else true

		$scope.choose_a_model = "--Choose a model--"
		$scope.tab_to_add = $scope.choose_a_model
		if window.localStorage and window.localStorage.recent_tabs
			$scope.tabs = JSON.parse(window.localStorage.recent_tabs)
		else
			$scope.tabs = []
		save_recent_tabs = () ->
			if window.localStorage and $scope.tabs
				window.localStorage.recent_tabs = JSON.stringify($scope.tabs)
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

		# for edit model instance
		$scope.model_to_edit = {}
		$scope.instance_in_edit = {}
		$scope.init_edit_model = (record) ->
			$scope.model_to_edit[record.id] = angular.copy(record)
		$scope.change_selected = (name) ->
			$scope.selected_model = name
			$scope.reset_pagination()
		# TODO multi image field upload
		$scope.fileNameChanged = () ->
			field_name = event.target.dataset.field
			uuid = event.target.dataset.uuid
			instance = if uuid then $scope.model_to_edit[uuid] else $scope.current[$scope.selected_model]
			instance[field_name+"_choosed_file_"] = event.target.files[0]
			$scope.$safeApply()
			
		$scope.upload = (field_name, uuid)->
			spinner = $foundry.spinner(
				type : 'loading'
				text : 'Uploading '
			)
			instance = if uuid then $scope.model_to_edit[uuid] else $scope.current[$scope.selected_model]
			Nimbus.Binary.upload_file(instance[field_name+'_choosed_file_'], (file)->
				# push this into documents
				file_module.set(file._file.id, file._file)

				instance[field_name+"_uploaded_"] = {
					thumb: file._file.thumbnailLink
					name: file.name
					link: file.directlink
				}
				instance[field_name] = instance[field_name+"_uploaded_"].link
				instance[field_name+"_thumb_"] = instance[field_name+"_uploaded_"].thumb
				instance[field_name+"_choosed_file_"] = null
				spinner.hide()
				$scope.$safeApply()
			)
			return

		$scope.enter_edit = (record) ->
			$scope.instance_in_edit[record.id] = true

		$scope.submit_edit = (record) ->
			$scope.model_to_edit[record.id].save()
			$scope.instance_in_edit[record.id] = false
			$scope.load()
		$scope.cancel_edit = (record) ->
			$scope.instance_in_edit[record.id] = false			

		$scope.add = () ->
			field_info_list = $scope.generated_models[$scope.selected_model]
			data = {}
			current_data = $scope.current[$scope.selected_model]
			for field_info in field_info_list
				is_required = field_info.setting.required
				if is_required && (current_data[field_info.name] is null or current_data[field_info.name] is undefined)
					data[field_info.name] = field_info.setting.default_value
				else
					data[field_info.name] = current_data[field_info.name]
			$scope.user_models[$scope.selected_model].create(data)
			$scope.load()
			# $scope.recalculate_total()
		$scope.del = (record, $index) ->
			swal {   
				title: "Are you sure?",   
				text: "This record will be deleted and it can't be recovered!",   
				type: "warning",   
				showCancelButton: true,   
				confirmButtonColor: "#DD6B55",   
				confirmButtonText: "Yes, delete it!",   
				cancelButtonText: "No, cancel plx!",   
				closeOnConfirm: false,   
				closeOnCancel: false 
			}, (isConfirm) ->
				if isConfirm
					record.destroy()
					$scope.user_records[$scope.selected_model].splice($index, 1)
					$scope.$safeApply()
					# $scope.recalculate_total()
					swal("Deleted!", "The record has been deleted.", "success")
				else
					swal("Cancelled", "Your data is safe :)", "error")
		$scope.reset = () ->
			event.preventDefault()
			field_info_list = $scope.generated_models[$scope.selected_model]
			current_data = $scope.current[$scope.selected_model]
			for field_info in field_info_list
				if "default_value" of field_info.setting 
					if field_info.type is "_field_switch"
						if field_info.setting.default_value
							current_data[field_info.name] = field_info.setting.on_value 
						else 
							current_data[field_info.name] = field_info.setting.off_value
					else 
						current_data[field_info.name] = field_info.setting.default_value
		# for order
		$scope.field_to_order = undefined
		$scope.order = undefined
		# for search
		$scope.keyword = undefined
		$scope.search = () ->
			if $scope.keyword_to_search
				$scope.keyword = $scope.keyword_to_search
				$scope.current_page = 1
		# for pagination
		$scope.page_size = 10
		$scope.reset_pagination = () ->
			$scope.current_page = 1
			if $scope.selected_model and $scope.user_records[$scope.selected_model]
				$scope.recalculate_total()
			else
				$scope.total_page = 1
		$scope.recalculate_total = () ->
			$scope.total_page = Math.ceil($scope.user_records[$scope.selected_model].length/+($scope.page_size))
			$scope.total_page++ if $scope.total_page is 0
			$scope.current_page = $scope.total_page if $scope.current_page>$scope.total_page
		$scope.go_page = () ->
			if $scope.page_to_go>0 and $scope.page_to_go<= $scope.total_page
				$scope.current_page = $scope.page_to_go
		$scope.next_page = () ->
			$scope.current_page++ if $scope.current_page<$scope.total_page
		$scope.previous_page = () ->
			$scope.current_page-- if $scope.current_page>1
		$scope.change_page_size = () ->
			$scope.reset_pagination()
		$scope.paginate = (records) ->
			# search
			results = records
			if $scope.keyword
				results = $filter('filter')(records, $scope.keyword)
			# order
			if $scope.field_to_order
				results = $filter('orderBy')(results, $scope.field_to_order, $scope.order)
			# paginate
			$scope.total_page = Math.ceil($scope.user_records[$scope.selected_model].length/+($scope.page_size))
			$scope.current_page = $scope.total_page if $scope.current_page>$scope.total_page
			$scope.current_page = 1 if $scope.current_page<1
			start = ($scope.current_page-1)*(+$scope.page_size)
			end = start + (+$scope.page_size)
			results.slice(start, end)
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
						if !$scope.selected_model and $scope.tabs.length>0
							$scope.selected_model = $scope.tabs[0]
			$scope.current[name] = {} for name in Object.keys($scope.generated_models)
		$scope.load()
		$scope.reset_pagination()
	])