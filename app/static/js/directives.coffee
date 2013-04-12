window.app.directive "ngEnter", ->
  (scope, elm, attrs) ->
    elm.bind "keypress", (e) ->
      if e.charCode is 13
        scope.$apply attrs.ngEnter

window.app.directive "inlineEdit", ->
  restrict: "E"
  templateUrl: "componentTpl.html"
  scope:
    model: "="



appServices = window.app.provider("appBusy", ->
  # initialize
  @msg = "Loading ..."
  @timeout = 10
  @clazz = "appBusy"
  body = angular.element(window.document.body)
  domEl = null
  @show = (msg) ->
    msg = msg or @msg

    # if not already busy
    unless domEl
      domEl = angular.element("<div></div>").addClass(@clazz)
      domEl.text msg
      setTimeout (->

        # if still busy add it to body.
        body.append domEl  if domEl
      ), @timeout
    else

      # update busy message
      domEl.text msg

  @hide = ->
    if domEl
      domEl.remove()
      domEl = null

  @$get = ->
    self = this
    set: (msg) ->
      if typeof msg is "boolean"
        (if msg is true then self.show() else self.hide())
      else
        self.show msg

  @setMsg = (val) ->
    @msg = val

  @setTimeout = (val) ->
    @timeout = val

  @setClazz = (val) ->
    @clazz = val
)