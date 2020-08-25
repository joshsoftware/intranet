@FilterJSInitialize = ->
  page = 1
  batch_size = 100
  query_string = window.location.search
  severity = {'critical': 'red', 'major': 'orange', 'minor': 'gold'}


  if typeof data isnt 'undefined' and data isnt null
    template = Mustache.compile($.trim($('#' + @repo_name + '_issues_template').html()))
    view = (record, index) ->
      record.color = severity[record.attributes.severity]
      template
        record: record
        index: index + 1

    options =
      template: '#' + @repo_name + '_issues_template'
      view: view
      search:
        ele: '#searchbox'
        fields: ['attributes.description', 'attributes.severity', 'attributes.categories']
      pagination:
        container: '#repo_issues_pagination'
        visiblePages: 5
        perPage:
          values: [10, 25, 100]
          container: '#issues_per_page'
      params:
        page: ++page

    window.fjs = FilterJS(data, '#' + @repo_name + '_issues_table tbody', options)
    fjs.addCallback 'afterAddRecords', (records) ->
      this.opts.params['page'] = ++page
    fjs.setStreaming
      data_url:  '/repositories/get_repo_issues' + query_string
      stream_after: 1
      batch_size: batch_size
