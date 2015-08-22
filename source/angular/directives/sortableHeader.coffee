module.exports = (app) ->
  app.directive 'sortable', () ->
    return {
      templateUrl: 'templates/sortableHeader.html',
      scope: {
        config: '='
        click: '&onClick'
      },
      replace: true,
      transclude: true,
      link: (scope, elem, attrs) ->
        scope.headers = _.keys(scope.config)
        scope.source = _.values(scope.config)
        scope.message = {
          order: ''
        }

        # to mark the sorted value. Initializes as the first element
        scope.ascending = new Array(scope.headers.length + 1).join(0).split('').map (val) ->
          return val == "1"

        scope.preprocess = (index) ->
          scope.selected = index
          scope.ascending[index] = !scope.ascending[index]
          scope.message.order = if scope.ascending[index] then '+' else '-'
          scope.message.order += scope.source[index]

          scope.click(scope.message)
    }