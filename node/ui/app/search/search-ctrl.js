(function () {
  'use strict';

  angular.module('geonames.search')
    .controller('SearchCtrl', ['$scope', 'MLRest', '$location', '$sce', '$filter', function ($scope, mlRest, $location, $sce, $filter) {
      var model = {
        selected: [],
        text: '',
        code: '',
        feature: { name: ''},
        countries: [],
        features: [],
        search: []
      };

      function updateSearchResults(data) {
        model.search = data;
      }

      (function init() {
        //mlRest.enrich(model.text, model.code).then(updateSearchResults);
        mlRest.countries('true').then(function(data) {
          model.countries = data.countries.country;
          model.countries.unshift({Country: 'World', ISO: ''});
        });
        mlRest.features('true').then(function(data) {
          model.features = data.features['feature-code'];
        });
      })();

      angular.extend($scope, {
        model: model,
        search: function() {
          mlRest.enrich(model.text, model.code, model.feature.name).then(updateSearchResults);
          $location.path('/');
        },
        renderQuery: function() {
          return model.search.summary ? $sce.trustAsHtml(model.search.summary.query) : '';
        },
        getCountryByCode: function(code) {
          var found = $filter('filter')(model.countries, {ISO: code});
          if (found.length) {
            return found[0].Country;
          } else { return '';}
        },
        getMain: function(names) {
          var found = $filter('filter')(names, {tag: 'main'});
          if (found.length) {
            return found[0]._value;
          } else {return '';}
        },
        getCountryGeonamesIdByCode: function(code) {
          var found = $filter('filter')(model.countries, {ISO: code});
          if (found.length) {
            return found[0].geonameid;
          } else { return '';}
        }
      });

    }]);
}());
