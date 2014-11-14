define('cars', ()->
	user_plugin = 	
		name : 'cars'
		anchor : '#/cars'
		title : 'Cars Management'
		type : 'plugin'
		icon : 'icon-list'
		# initialize plugin,
		init : ()->
			self = @
			console.log 'init'
			foundry.model("Car",["name", "price", "car_type", "rate", "amount", "image", "thumb", "detail", "created_at", "modified_at"], ()->
				foundry.initialized(self.name)
				define_controller()
			)
)

define_controller = ()->
	angular.module('foundry').controller('CarsController', ['$scope', '$foundry', ($scope, $foundry)->
		# only for debug
		window.scope = $scope
		
		car_model = foundry.load_model("Car")
		file_module = foundry.load('document')
		$scope.current = {}
		$scope.upload = ()->
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
				$scope.current.image = $scope.uploaded.link
				$scope.current.thumb = $scope.uploaded.thumb
				$scope.choosed_file = null
				spinner.hide()
				$scope.$apply()
			)
			return
		$scope.add = () ->
			if $scope.current.name and 
				$scope.current.price and
				$scope.current.car_type and
				$scope.current.rate and
				$scope.current.amount and
				$scope.current.image and
				$scope.current.thumb and
				$scope.current.detail
					to_save = $scope.current
					now = new Date().getTime()
					to_save.created_at = now
					to_save.modified_at = now
					created = car_model.create(to_save)
					$scope.mode = true
					$scope.old = created
					$scope.load()
			else 
				alert "Please make sure every filed is filled."
		$scope.load = () ->
			$scope.cars = car_model.all()

		$scope.load()
	])