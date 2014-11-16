// Generated by CoffeeScript 1.8.0
(function() {
  var common_fields, define_controller, supported_field, supported_field_setting;

  supported_field = window.app_config.supported_field;

  supported_field_setting = window.app_config.supported_field_setting;

  common_fields = window.app_config.common_fields;

  define('model_editor', function() {
    var user_plugin;
    return user_plugin = {
      name: 'model_editor',
      anchor: '#/model_editor',
      title: 'Model Editor',
      type: 'plugin',
      icon: 'icon-pencil',
      init: function() {
        var attrs, field, fields_num, self, _results;
        self = this;
        console.log('init');
        fields_num = Object.keys(supported_field).length;
        _results = [];
        for (field in supported_field) {
          attrs = supported_field[field];
          _results.push(foundry.model(field, attrs.concat(common_fields), function() {
            if (fields_num-- === 1) {
              foundry.initialized(self.name);
              return define_controller();
            }
          }));
        }
        return _results;
      }
    };
  });

  define_controller = function() {
    return angular.module('foundry').controller('ModelEditorController', [
      '$scope', '$foundry', function($scope, $foundry) {
        var field_name, supported_field_models, _i, _len, _ref;
        window.scope = $scope;
        $scope.show_in;
        $scope.fields_in_new_model = [];
        $scope.supported_field_setting = supported_field_setting;
        supported_field_models = {};
        _ref = Object.keys(supported_field);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          field_name = _ref[_i];
          supported_field_models[field_name] = foundry.load_model(field_name);
        }
        $scope.push_field_to_new_model = function(type) {
          var field, setting, to_push, _j, _len1, _ref1;
          _ref1 = $scope.fields_in_new_model;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            field = _ref1[_j];
            if (field.name === $scope.field_name_to_add) {
              sweetAlert("Oops...", "Field name " + field.name + " already exists.", "error");
              return;
            }
          }
          to_push = {
            name: $scope.field_name_to_add,
            type: type,
            setting: null
          };
          setting = {};
          supported_field[type].map(function(attr) {
            var s;
            s = "" + type + "_" + attr;
            return setting[attr] = $scope[s];
          });
          to_push.setting = setting;
          return $scope.fields_in_new_model.push(to_push);
        };
        $scope.delete_field_from_new_model = function(index) {
          return $scope.fields_in_new_model.splice(index, 1);
        };
        $scope.add_model = function() {
          var model, name, _ref1;
          _ref1 = foundry._models;
          for (name in _ref1) {
            model = _ref1[name];
            if (name === $scope.new_model_name) {
              sweetAlert("Oops...", "Model " + $scope.new_model_name + " already exists.", "error");
              return;
            }
          }
          return foundry.model($scope.new_model_name, $scope.fields_in_new_model.map(function(field) {
            return field.name;
          }), function(user_model) {
            var field, field_model, _j, _len1, _ref2;
            _ref2 = $scope.fields_in_new_model;
            for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
              field = _ref2[_j];
              field_model = supported_field_models[field.type];
              field.setting.model_belonged_to = $scope.new_model_name;
              field.setting.field_name = field.name;
              field_model.create(field.setting);
            }
            $scope.load();
            $scope.selected_model = $scope.new_model_name;
            return $scope.$apply();
          });
        };
        $scope.del_model = function(name) {
          return swal({
            title: "Are you sure?",
            text: "The model will be deleted as well as the data stored in it!",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            confirmButtonText: "Yes, delete it!",
            cancelButtonText: "No, cancel plx!",
            closeOnConfirm: false,
            closeOnCancel: false
          }, function(isConfirm) {
            var field, model_to_del, new_model_name_list, _j, _len1, _ref1;
            if (isConfirm) {
              model_to_del = $scope.user_models[name];
              if (model_to_del) {
                model_to_del.all().map(function(data) {
                  return data.destroy();
                });
              }
              _ref1 = $scope.generated_models[name];
              for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                field = _ref1[_j];
                field.setting.destroy();
              }
              $scope.load();
              new_model_name_list = Object.keys($scope.generated_models);
              $scope.selected_model = new_model_name_list[0];
              $scope.$apply();
              return swal("Deleted!", "Your model and data has been deleted.", "success");
            } else {
              return swal("Cancelled", "Your model and data is safe :)", "error");
            }
          });
        };
        $scope.load = function() {
          var attrs, field, field_info, model, model_info_list, name, _j, _len1, _ref1, _ref2, _results;
          $scope.generated_models = {};
          for (name in supported_field_models) {
            model = supported_field_models[name];
            _ref1 = model.all();
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              field = _ref1[_j];
              if (!$scope.generated_models[field.model_belonged_to]) {
                $scope.generated_models[field.model_belonged_to] = [];
              }
              field_info = {
                name: field.field_name,
                type: name,
                setting: field
              };
              $scope.generated_models[field.model_belonged_to].push(field_info);
            }
          }
          $scope.user_models = {};
          _ref2 = $scope.generated_models;
          _results = [];
          for (name in _ref2) {
            model_info_list = _ref2[name];
            attrs = model_info_list.map(function(model_info) {
              return model_info.name;
            });
            _results.push(foundry.model(name, attrs, function(loaded_model) {
              return $scope.user_models[name] = loaded_model;
            }));
          }
          return _results;
        };
        return $scope.load();
      }
    ]);
  };

}).call(this);
