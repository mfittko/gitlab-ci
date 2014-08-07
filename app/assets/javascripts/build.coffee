class Build
  @interval: null

  constructor: (build_url, build_status) ->
    @styleResults()
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
      # Bind fails only button to show only failed examples
      #
      $("#fails-button").bind "click", ->
        state = $(this).data("state")
        if "enabled" is state
          $(this).data "state", "disabled"
          $(this).text "all examples"
          $('#build-report .example.passed').hide()
          $('#build-report .example.pending').hide()
        else
          $(this).data "state", "enabled"
          $(this).text "fails only"
          $('#build-report .example.passed').show()
          $('#build-report .example.pending').show()

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
                @styleResults()
                @checkAutoscroll()
              else
                Turbolinks.visit build_url
      , 4000

  checkAutoscroll: ->
    if "enabled" is $("#autoscroll-button").data("state")
      if $("#reports_tab").hasClass("active")
        $("html,body").scrollTop $("#build-report").height()
      else if $("#trace_tab").hasClass("active")
        $("html,body").scrollTop $("#build-trace").height()

  styleResults: ->
    $('#build-report .results .example_group').addClass("bs-example")
    $('#build-report .results .example').addClass("bs-callout")
    $('#build-report .results .example.passed').addClass("bs-callout-success")
    $('#build-report .results .example.failed').addClass("bs-callout-danger")
    if "enabled" is $("#fails-button").data("state")
      $('#build-report .example.passed').hide()
      $('#build-report .example.pending').hide()
    else
      $('#build-report .example.passed').show()
      $('#build-report .example.pending').show()


@Build = Build
