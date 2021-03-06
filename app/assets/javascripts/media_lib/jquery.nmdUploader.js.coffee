#= require jquery
#= require underscore
#= require media_lib/jquery.md5
#= require media_lib/inserter_factory

$(window).on "message", (e) ->
  data = e.originalEvent.data
  if data?
    switch data.type
      when 'select'
        $uploader = $("##{data.model.uploaderId}")
        uploader = $uploader.data()

        results = $uploader.nmdUploader 'select',
          model: data.model
          uploader: uploader
          host: data.host

        isClose = not _.contains results, MediaLib.INSERT_RESULT_PREVENT_CLOSE
        if isClose
          # Закрытие модального окна при интеграции с модалками
          $('div[id^="nmdUploaderModal"]').modal('hide') if $.fn.modal? and not uploader.multiselect

$ ->
  methods =
    init: (options) ->
      settings = $.extend true,
        iframeSelector: '.js-uploader-iframe'
        openSelector: '.js-uploader-open'
        params: {}
      , options

      throw new Error("host isn't defined") unless settings.host
      throw new Error("tenant isn't defined") unless settings.tenant

      @each ->
        $uploader = $ @

        # сохраняем кастомные параметры
        $uploader.data 'params', settings.params

        $uploader.attr('id', $.md5(Math.random())[0..3]) unless $uploader.attr('id')
        uploaderId = $uploader.attr('id')

        getUrl = ->
          prefix = settings.prefix ? $uploader.data('prefix')
          throw new Error("prefix isn't defined") unless prefix

          multiselect = settings.multiselect ? $uploader.data('multiselect')
          type = settings.type ? $uploader.data('type')

          "#{settings.host}/#
            tenant/#{settings.tenant}/
            #{if uploaderId then "uid/#{uploaderId}/" else ''}
            #{if multiselect then 's/multiselect/' else ''}
            #{if type then "t/#{type}/" else ''}
            prefix/#{prefix}
          ".replace /\ /g, ''

        getIframe = ->
          modalId = settings.modalId ? $uploader.data('modalId')
          if modalId
            $uploaderIframe = $("##{modalId}").find(settings.iframeSelector)
          else
            $uploaderIframe = $uploader.find(settings.iframeSelector)
          $uploaderIframe.first()

        initIframe = ->
          $iframe = getIframe()
          if $iframe.length
            iframeTemplate = _.template '''
              <iframe width='<%= width %>' height='<%= height %>' src='<%= src %>' frameborder='0'></iframe>
            '''

            $iframe.html iframeTemplate $.extend
              src: getUrl()
              width: '100%'
              height: 500
            , $iframe.data()

        openUploader = ->
          $iframe = getIframe()
          if $iframe.length
            $iframe.closest('div.modal').modal('show') if $.fn.modal?
            initIframe()
          else
            popupWindow = open getUrl(), 'NMD Media Lib', 'scrollbars=1, width=800, height=500'
            popupWindow.focus()

        if settings.open ? $uploader.data('open')
          openUploader()
        else
          $uploader.find(settings.openSelector).on 'click.uploader', (e) ->
            e.preventDefault()
            e.stopPropagation()
            openUploader()

    select: (options) ->
      settings = $.extend true, {}, options

      results = []
      @each ->
        $uploader = $ @

        # загружаем кастомные параметры
        settings.params = $uploader.data 'params'

        factory = new MediaLib.InserterFactory(settings)
        inserter = factory.createInserter()

        results.push inserter.insert($uploader)

      results

    destroy: (options) ->
      settings = $.extend true,
        iframeSelector: '.js-uploader-iframe'
        openSelector: '.js-uploader-open'
      , options

      $uploader.find(settings.openSelector).off '.uploader'

      modalId = settings.modalId ? $uploader.data('modalId')
      if modalId
        $uploaderIframe = $("##{modalId}").find(settings.iframeSelector)
      else
        $uploaderIframe = $uploader.find(settings.iframeSelector)

      $uploaderIframe.empty()

  $.fn.nmdUploader = (method) ->
    if methods[method] then methods[method].apply @, Array::slice.call(arguments, 1)
    else if typeof method is "object" or not method then methods.init.apply @, arguments
    else throw new Error("Метод с именем #{method} не существует для jQuery.nmdUploader")
