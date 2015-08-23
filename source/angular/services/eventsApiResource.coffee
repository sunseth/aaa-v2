module.exports = () ->
  angular.module("eventsApiResource", [])
    .service 'eventsApi', ($resource) ->
      class Resource
        constructor: () ->
        toMultipartForm: (data, headersGetter) ->
          if (data == undefined)
            return data;

          fd = new FormData
          angular.forEach data, (value, key) ->
            if value instanceof FileList
              if value.length == 1
                fd.append(key, value[0]);
              else
                angular.forEach value, (file, index) -> 
                  fd.append(key + '_' + index, file)
            else
              fd.append(key, value);

          return fd;

        events: (eventsPath) ->
          return $resource eventsPath, '',
            'create': {
              method: 'POST',
              isArray: false,
              url: eventsPath,
              headers: {
                'Content-Type': undefined
              },
              transformRequest: this.toMultipartForm
            }

        event: (eventPath) ->
          return $resource eventPath,
            {id: '@_id'}, 
            {
              'put': {
                method: 'PUT',
                url: eventPath,
                isArray: false,
                headers: {
                  'Content-Type': undefined
                }
                transformRequest: this.toMultipartForm
              },
            }

      return Resource