class Build
  @interval: null

  constructor: (build_url, build_status) ->
    Build.styleResults()
    clearInterval(Build.interval)

    if build_status == "running" || build_status == "pending"
      #
      # Bind autoscroll button to follow build output
      #
      $("#autoscroll-button").bind "click", ->
        state = $(this).data("state")
        if "enabled" is state
          $(this).data "state", "disabled"
          $(this).text "enable autoscroll"
        else
          $(this).data "state", "enabled"
          $(this).text "disable autoscroll"

      #
      # Bind autoupdate button to follow build output
      #
      $("#autoupdate-button").bind "click", ->
        state = $(this).data("state")
        if "enabled" is state
          $(this).data "state", "disabled"
          $(this).text "enable autoupdate"
        else
          $(this).data "state", "enabled"
          $(this).text "disable autoupdate"

      #
      # Check for new build output if user still watching build page
      # Only valid for runnig build when output changes during time
      #
      Build.interval = setInterval =>
        if window.location.href is build_url and "enabled" is $("#autoupdate-button").data("state")
          $.ajax
            url: build_url
            dataType: "json"
            success: (build) =>
              if build.status == "running"
                $('#build-trace code').html build.trace_html
                $('#build-trace code').append '<i class="icon-refresh icon-spin"/>'
                $('#build-report .results').html build.report_html
                $('#build-report .results').append '<i class="icon-refresh icon-spin"/>'
                Build.styleResults()
                Build.updateInfo()
                Build.checkAutoscroll()
              else
                Turbolinks.visit build_url
      , 4000

    #
    # Bind fails only button to show only failed examples
    #
    $("#fails-button").bind "click", ->
      state = $(this).data("state")
      if "enabled" is state
        $(this).data "state", "disabled"
        $(this).text "fails only"
      else
        $(this).data "state", "enabled"
        $(this).text "all examples"
      Build.styleResults()

  Build.checkAutoscroll = () ->
    if "enabled" is $("#autoscroll-button").data("state")
      if $("#reports_tab").hasClass("active")
        $("html,body").scrollTop $("#build-report").height()
      else if $("#trace_tab").hasClass("active")
        $("html,body").scrollTop $("#build-trace").height()

  Build.styleResults = () ->
    $fails = $('#build-report .results .example.failed')
    $fails.parents(".example_group").attr("class","example_group failed")
    $('.example_group, .example', '#build-report .results').addClass("bs-callout")
    $('*', '#build-report .results').removeAttr("style")
    $('#build-report .results .example_group').addClass("bs-callout")
    $('.example_group.passed, .example.passed', '#build-report .results').addClass("bs-callout-success")
    $('.example_group.failed, .example.failed', '#build-report .results').addClass("bs-callout-danger")
    if "enabled" is $("#fails-button").data("state")
      $('#build-report .example_group.passed').hide()
      $('#build-report .example_group.pending').hide()
      $fails.siblings(".example.passed").hide()
    else
      $('#build-report .example_group.passed').show()
      $('#build-report .example_group.pending').show()
      $fails.siblings(".example.passed").show()

  Build.updateInfo = () ->
    if $('.build-widget p.specs_run').length == 1
      $('.build-widget > .specs_run > .attr-value').text($('.example').length)
      $('.build-widget > .specs_run > .attr-value').text($('.example.failed').length)
    else
      $('.build-widget').first.append('<p class="specs_run"><span class="attr-name"></span><span class="attr-value"></span></p>')
      $('.build-widget').first.append('<p class="specs_failed"><span class="attr-name"></span><span class="attr-value"></span></p>')
      Build.updateInfo()


@Build = Build
