// Generated by CoffeeScript 1.7.1
(function() {
  if (localStorage["version"] == null) {
    localStorage["version"] = "google";
    window.location.reload();
  }

  foundry.angular.dependency = [];

  define('config', function() {
    var config;
    config = {};
    config.appName = 'Foundry';
    config.plugins = {
      user: 'core/plugins/user',
      workspace: 'core/plugins/workspace',
      demo : 'app/plugins/demo'
    };
    return config;
  });

  foundry.load_plugins();

  Nimbus.Auth.setup({
    'GDrive': {
      'app_id' : '696230129324',
      'key': '696230129324-k4g89ugcu02k5obu9hs1u5tp3e54n02u.apps.googleusercontent.com',
      "scope": "openid https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/gmail.compose https://www.googleapis.com/auth/gmail.modify https://apps-apis.google.com/a/feeds/domain/"
    },
    "app_name": "Foundry",
    'synchronous': false
  });

  Nimbus.Auth.authorized_callback = function() {
    if (Nimbus.Auth.authorized()) {
      return $("#login_buttons").addClass("redirect");
    }
  };

  foundry.ready(function() {
    if (Nimbus.Auth.authorized()) {
      foundry.init(function() {
        $('#loading').addClass('loaded');
        return $("#login_buttons").removeClass("redirect");
      });
    }
  });

  $(document).ready(function() {
    $('#google_login').on('click', function(evt) {
      if (!(localStorage["version"] === "google")) {
        localStorage["version"] = "google";
        window.location.reload();
      }
      return Nimbus.Auth.authorize('GDrive');
    });
    $('.logout_btn').on('click', function(evt) {
      foundry.logout();
      return location.reload();
    });
  });

}).call(this);
