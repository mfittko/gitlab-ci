# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
# GO AFTER THE REQUIRES BELOW.
#
#= require jquery
#= require bootstrap
#= require bootstrap/affix
#= require jquery_ujs
#= require turbolinks
#= require jquery.turbolinks
#= require nprogress
#= require nprogress-turbolinks
#= require_tree .
#
#

$(document).on 'click', '.edit-runner-link', (event) ->
  event.preventDefault()

  descr = $(this).closest('.runner-description').first()
  descr.hide()
  form = descr.next('.runner-description-form')
  descrInput = form.find('input.description')
  originalValue = descrInput.val()
  form.show()
  form.find('.cancel').on 'click', (event) ->
    event.preventDefault()

    form.hide()
    descrInput.val(originalValue)
    descr.show()

$(document).on 'click', '.assign-all-runner', ->
  $(this).replaceWith('<i class="icon-refresh icon-spin"></i> Assign in progress..')

jQuery ($) ->
  buildWidget = $("body > .container-body .build-widget")
  if buildWidget.length > 0
    rightBar = buildWidget.parent()
    rightBar.affix
      offset:
        top: () => (this.top = rightBar.position().top)

window.unbindEvents = ->
  $(document).unbind('scroll')
  $(document).off('scroll')

document.addEventListener("page:fetch", unbindEvents)
