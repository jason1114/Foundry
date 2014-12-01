// Generated by CoffeeScript 1.8.0
(function() {
  var common_fields, define_controller, supported_field, supported_field_setting;

  supported_field = window.app_config.supported_field;

  supported_field_setting = window.app_config.supported_field_setting;

  common_fields = window.app_config.common_fields;

  define('model_manager', function() {
    var user_plugin;
    return user_plugin = {
      name: 'model_manager',
      anchor: '#/model_manager',
      title: 'Data',
      type: 'plugin',
      icon: 'icon-list',
      init: function() {
        var attrs, field_model_name, fields_num, self, _results;
        self = this;
        console.log('init');
        fields_num = Object.keys(supported_field).length;
        _results = [];
        for (field_model_name in supported_field) {
          attrs = supported_field[field_model_name];
          _results.push(foundry.model(field_model_name, attrs.concat(common_fields), function() {
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
    return angular.module('foundry').controller('ModelController', [
      '$scope', '$foundry', '$filter', function($scope, $foundry, $filter) {
        var field_name, file_module, name, position, save_recent_tabs, supported_field_models, _i, _len, _ref, _ref1;
        window.scope = $scope;
        $scope.make_range = function(start, end, step) {
          var result, v;
          result = [];
          v = start;
          while ((end > start ? v <= end : v >= end)) {
            result.push(v);
            v += step;
          }
          return result;
        };
        $scope.encodeURI = window.encodeURI;
        $scope.keys = Object.keys;
        $scope.$safeApply = function(fn) {
          var phase;
          phase = this.$root.$$phase;
          if (phase === '$apply' || phase === '$digest') {
            if (fn && (typeof fn === 'function')) {
              return fn();
            }
          } else {
            return this.$apply(fn);
          }
        };
        $scope.is_field_hidden = function(type) {
          var idx;
          idx = Object.keys(window.app_config.show_in_detail).indexOf(type);
          if (idx === -1) {
            return false;
          } else {
            return true;
          }
        };
        $scope.str_shorten = function(s, length) {
          if (typeof s === 'string') {
            if (s.length > length) {
              return "" + (s.substr(0, 10)) + "..." + (s.substr(-10, 10));
            } else {
              return s;
            }
          }
        };
        $scope.set_zoomed_text = function(text) {
          return $scope.zoomed_text = text;
        };
        $scope.choose_a_model = "--Choose a model--";
        $scope.tab_to_add = $scope.choose_a_model;
        if (window.localStorage && window.localStorage.recent_tabs) {
          $scope.tabs = JSON.parse(window.localStorage.recent_tabs);
        } else {
          $scope.tabs = [];
        }
        save_recent_tabs = function() {
          if (window.localStorage && $scope.tabs) {
            return window.localStorage.recent_tabs = JSON.stringify($scope.tabs);
          }
        };
        $scope.add_tab = function() {
          var tab_to_add;
          tab_to_add = $scope.tab_to_add;
          $scope.tab_to_add = $scope.choose_a_model;
          if (!tab_to_add) {
            return;
          }
          if ($scope.tabs.indexOf(tab_to_add) !== -1) {
            $scope.selected_model = tab_to_add;
            return;
          }
          if ($scope.tabs.length >= 10) {
            sweetAlert("Oops...", "You can only open 10 tabs at most.", "error");
            return;
          }
          $scope.tabs.push(tab_to_add);
          $scope.selected_model = tab_to_add;
          $scope.$safeApply();
          return save_recent_tabs();
        };
        $scope.del_tab = function($index) {
          if ($scope.tabs[$index] === $scope.selected_model) {
            if ($scope.tabs[$index - 1]) {
              $scope.selected_model = $scope.tabs[$index - 1];
            } else if ($scope.tabs[$index + 1]) {
              $scope.selected_model = $scope.tabs[$index + 1];
            } else {
              $scope.selected_model = null;
            }
          }
          $scope.tabs.splice($index, 1);
          $scope.$safeApply();
          return save_recent_tabs();
        };
        $scope.current = {};
        $scope.show_in_detail = window.app_config.show_in_detail;
        $scope.hide_in_left = [];
        $scope.hide_in_right = [];
        _ref = $scope.show_in_detail;
        for (name in _ref) {
          position = _ref[name];
          if (position === 'left') {
            $scope.hide_in_left.push(name);
          } else {
            $scope.hide_in_right.push(name);
          }
        }
        supported_field_models = {};
        _ref1 = Object.keys(supported_field);
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          field_name = _ref1[_i];
          supported_field_models[field_name] = foundry.load_model(field_name);
          supported_field_models[field_name].onUpdate(function() {
            $scope.load();
            return $scope.$safeApply();
          });
        }
        file_module = foundry.load('document');
        $scope.model_to_edit = {};
        $scope.instance_in_edit = {};
        $scope.init_edit_model = function(record) {
          return $scope.model_to_edit[record.id] = angular.copy(record);
        };
        $scope.change_selected = function(name) {
          $scope.selected_model = name;
          $scope.reset_pagination();
          delete $scope.keyword;
          delete $scope.keyword_to_search;
          delete $scope.field_to_order;
          return delete $scope.order;
        };
        $scope.fileNameChanged = function() {
          var instance, uuid;
          field_name = event.target.dataset.field;
          uuid = event.target.dataset.uuid;
          instance = uuid ? $scope.model_to_edit[uuid] : $scope.current[$scope.selected_model];
          instance[field_name + "_choosed_file_"] = event.target.files[0];
          return $scope.$safeApply();
        };
        $scope.upload = function(field_name, uuid) {
          var instance, spinner;
          spinner = $foundry.spinner({
            type: 'loading',
            text: 'Uploading '
          });
          instance = uuid ? $scope.model_to_edit[uuid] : $scope.current[$scope.selected_model];
          Nimbus.Binary.upload_file(instance[field_name + '_choosed_file_'], function(file) {
            file_module.set(file._file.id, file._file);
            instance[field_name + "_uploaded_"] = {
              thumb: file._file.thumbnailLink,
              name: file.name,
              link: file.directlink
            };
            instance[field_name] = instance[field_name + "_uploaded_"].link;
            instance[field_name + "_thumb_"] = instance[field_name + "_uploaded_"].thumb;
            instance[field_name + "_choosed_file_"] = null;
            spinner.hide();
            return $scope.$safeApply();
          });
        };
        $scope.enter_edit = function(record) {
          return $scope.instance_in_edit[record.id] = true;
        };
        $scope.submit_edit = function(record) {
          $scope.model_to_edit[record.id].save();
          $scope.instance_in_edit[record.id] = false;
          return $scope.load();
        };
        $scope.cancel_edit = function(record) {
          return $scope.instance_in_edit[record.id] = false;
        };
        $scope.add = function() {
          var current_data, data, field_info, field_info_list, is_required, _j, _len1;
          field_info_list = $scope.generated_models[$scope.selected_model];
          data = {};
          current_data = $scope.current[$scope.selected_model];
          for (_j = 0, _len1 = field_info_list.length; _j < _len1; _j++) {
            field_info = field_info_list[_j];
            is_required = field_info.setting.required;
            if (is_required && (current_data[field_info.name] === null || current_data[field_info.name] === void 0)) {
              data[field_info.name] = field_info.setting.default_value;
            } else {
              data[field_info.name] = current_data[field_info.name];
            }
          }
          $scope.user_models[$scope.selected_model].create(data);
          return $scope.load();
        };
        $scope.del = function(record) {
          return swal({
            title: "Are you sure?",
            text: "This record will be deleted and it can't be recovered!",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            confirmButtonText: "Yes, delete it!",
            cancelButtonText: "No, cancel plx!",
            closeOnConfirm: false,
            closeOnCancel: false
          }, function(isConfirm) {
            if (isConfirm) {
              record.destroy();
              $scope.load();
              $scope.$safeApply();
              return swal("Deleted!", "The record has been deleted.", "success");
            } else {
              return swal("Cancelled", "Your data is safe :)", "error");
            }
          });
        };
        $scope.reset = function() {
          var current_data, field_info, field_info_list, _j, _len1, _results;
          event.preventDefault();
          field_info_list = $scope.generated_models[$scope.selected_model];
          current_data = $scope.current[$scope.selected_model];
          _results = [];
          for (_j = 0, _len1 = field_info_list.length; _j < _len1; _j++) {
            field_info = field_info_list[_j];
            if ("default_value" in field_info.setting) {
              if (field_info.type === "_field_switch") {
                if (field_info.setting.default_value) {
                  _results.push(current_data[field_info.name] = field_info.setting.on_value);
                } else {
                  _results.push(current_data[field_info.name] = field_info.setting.off_value);
                }
              } else {
                _results.push(current_data[field_info.name] = field_info.setting.default_value);
              }
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        };
        $scope.field_to_order = void 0;
        $scope.order = void 0;
        $scope.is_sort = function(field_name, order) {
          if (field_name === $scope.field_to_order && $scope.order === order) {
            return true;
          } else {
            return false;
          }
        };
        $scope.set_sort = function(field_name, order) {
          if (field_name === $scope.field_to_order && $scope.order === order) {
            delete $scope.field_to_order;
            return delete $scope.order;
          } else {
            $scope.field_to_order = field_name;
            return $scope.order = order;
          }
        };
        $scope.keyword = void 0;
        $scope.search = function() {
          $scope.keyword = $scope.keyword_to_search;
          return $scope.current_page = 1;
        };
        $scope.$watch(function(scope) {
          return scope.keyword_to_search;
        }, function(newValue, oldValue) {
          if (!newValue && oldValue) {
            return $scope.search();
          }
        });
        $scope.page_size = 10;
        $scope.reset_pagination = function() {
          return $scope.current_page = 1;
        };
        $scope.go_page = function() {
          if ($scope.page_to_go > 0 && $scope.page_to_go <= $scope.total_page) {
            return $scope.current_page = $scope.page_to_go;
          }
        };
        $scope.next_page = function() {
          if ($scope.current_page < $scope.total_page) {
            return $scope.current_page++;
          }
        };
        $scope.previous_page = function() {
          if ($scope.current_page > 1) {
            return $scope.current_page--;
          }
        };
        $scope.change_page_size = function() {
          return $scope.reset_pagination();
        };
        $scope.paginate = function(records) {
          var end, expected, fields, results, start;
          results = records;
          if ($scope.keyword) {
            fields = $scope.generated_models[$scope.selected_model];
            expected = $scope.keyword;
            results = records.filter(function(actual) {
              var field_info, field_value, idx, _j, _len1;
              for (_j = 0, _len1 = fields.length; _j < _len1; _j++) {
                field_info = fields[_j];
                field_value = actual[field_info.name];
                if (field_value === null || typeof field_value === 'undefined') {
                  continue;
                } else {
                  idx = ("" + field_value).toLowerCase().indexOf(expected.toLowerCase());
                  if (idx === -1) {
                    continue;
                  } else {
                    return true;
                  }
                }
              }
              return false;
            });
          }
          if ($scope.field_to_order) {
            results = $filter('orderBy')(results, $scope.field_to_order, $scope.order);
          }
          $scope.total_page = Math.ceil(results.length / +$scope.page_size);
          if ($scope.total_page === 0) {
            $scope.total_page = 1;
          }
          if ($scope.current_page > $scope.total_page) {
            $scope.current_page = $scope.total_page;
          }
          if ($scope.current_page < 1) {
            $scope.current_page = 1;
          }
          start = ($scope.current_page - 1) * (+$scope.page_size);
          end = start + (+$scope.page_size);
          return results.slice(start, end);
        };
        $scope.load = function() {
          var attrs, field, field_info, generated_model_names, model, model_info_list, user_models_num, _j, _k, _len1, _len2, _ref2, _ref3, _ref4;
          $scope.generated_models = {};
          for (name in supported_field_models) {
            model = supported_field_models[name];
            _ref2 = model.all();
            for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
              field = _ref2[_j];
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
          $scope.user_records = {};
          user_models_num = Object.keys($scope.generated_models).length;
          _ref3 = $scope.generated_models;
          for (name in _ref3) {
            model_info_list = _ref3[name];
            attrs = model_info_list.map(function(model_info) {
              return model_info.name;
            });
            foundry.model(name, attrs, function(loaded_model) {
              $scope.user_models[name] = loaded_model;
              loaded_model.onUpdate(function() {
                $scope.load();
                return $scope.$safeApply();
              });
              $scope.user_records[name] = loaded_model.all();
              if (user_models_num-- === 1) {
                if (!$scope.selected_model && $scope.tabs.length > 0) {
                  return $scope.selected_model = $scope.tabs[0];
                }
              }
            });
          }
          _ref4 = Object.keys($scope.generated_models);
          for (_k = 0, _len2 = _ref4.length; _k < _len2; _k++) {
            name = _ref4[_k];
            $scope.current[name] = {};
          }
          generated_model_names = Object.keys($scope.generated_models);
          $scope.tabs = $scope.tabs.filter(function(tab) {
            if (generated_model_names.indexOf(tab) !== -1) {
              return true;
            } else {
              return false;
            }
          });
          save_recent_tabs();
          if (generated_model_names.indexOf($scope.selected_model) === -1) {
            if ($scope.tabs && $scope.tabs.length > 0) {
              return $scope.selected_model = $scope.tabs[0];
            } else {
              return delete $scope.selected_model;
            }
          }
        };
        $scope.load();
        return $scope.reset_pagination();
      }
    ]);
  };

}).call(this);
