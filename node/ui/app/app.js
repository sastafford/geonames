
angular.module('geonames', [
  'ngRoute', 'ngCkeditor', 'geonames.search', 'geonames.common', 'geonames.detail',
  'ui.bootstrap','ngSanitize'
])
  .config(['$routeProvider', '$locationProvider', function ($routeProvider, $locationProvider) {

    'use strict';

    $locationProvider.html5Mode(true);

    $routeProvider
      .when('/', {
        templateUrl: '/search/search.html'
      })
      .when('/detail', {
        templateUrl: '/detail/detail.html',
        controller: 'DetailCtrl'
      })
      .otherwise({
        redirectTo: '/'
      });
  }]);
