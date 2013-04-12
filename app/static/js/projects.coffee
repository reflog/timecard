app = angular.module('ProjectsApp', ['ngResource']).config ($interpolateProvider) ->
    $interpolateProvider.startSymbol('[[')
    $interpolateProvider.endSymbol(']]')

window.app = app

app.controller "ProjectsController", ($scope,  $resource, appBusy) ->
  $scope.projects = []
  $scope.currentProjectId = 0
  $scope.newProject = name: `undefined`, hourPrice :  `undefined`, archived: false
  $scope.newEntry = text: `undefined`, timeSpent :  `undefined`
  $scope.projectToDelete = `undefined`
  $scope.currentEntriesByMonth = {}

  Project = $resource '/api/project/:project_id', project_id:'@id'
  Entry = $resource '/api/project/:project_id/entry/:entry_id', {project_id:'@project_id',entry_id:'@id' }

  $scope.getProjects = ->
    Project.get (result) ->
      $scope.projects = []
      for p in result.objects
        do (p) ->
          p.entries = (new Entry(o) for o in p.entries)
          $scope.projects.push(new Project(p))
      $scope.selectProject ( $scope.projects[0] if $scope.projects.length>0 and  $scope.currentProjectId is 0 )
      appBusy.set false

  $scope.addProject = ->
    data = name:$scope.newProject.name, hourPrice: $scope.newProject.hourPrice, archived: false
    p = new Project(data)
    p.$save ->
      $scope.newProject = name: `undefined`, hourPrice :  `undefined`, archived: false
      $("#project_add_dialog").modal('hide')
      $scope.projects.push(p)

  $scope.deleteProject = ->
    $scope.projectToDelete.$delete ->
      $scope.projects.remove($scope.projectToDelete)
      $("#project_delete_dialog").modal('hide')


  $scope.toggleArchived = (p) ->
    p.archived = !p.archived
    p.$save =>
      $scope.safeApply()

  $scope.doShowAddDialog = -> $("#project_add_dialog").modal()

  $scope.doShowDeleteDialog = (p) ->
    $scope.projectToDelete = p
    $("#project_delete_dialog").modal()

  $scope.selectProject = (p) ->
    $scope.currentProjectId = p.id
    # todo, update cookie/server state
    $scope.currentEntriesByMonth = {}
    $scope.addEntriesByMonth p.entries


  $scope.addEntriesByMonth = (entries) ->
    for entry in entries
      do (entry) =>
        month = moment(entry.createdAt).month()
        if not Object.has $scope.currentEntriesByMonth, month
          $scope.currentEntriesByMonth[month] = []
        $scope.currentEntriesByMonth[month].push(entry)


  $scope.monthNames = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ]

  $scope.prettyDate = (d) =>
    moment(d).calendar()

  $scope.addEntry = ->
    e = new Entry text: $scope.newEntry.text, timeSpent: $scope.newEntry.timeSpent
    e.$save project_id:$scope.currentProjectId, =>
      $scope.currentProject().entries.push(e)
      $scope.addEntriesByMonth [e]
      $scope.newEntry = text: `undefined`, timeSpent :  `undefined`

  $scope.safeApply = (fn) ->
    phase = @$root.$$phase
    if phase is "$apply" or phase is "$digest"
      fn()  if fn and (typeof (fn) is "function")
    else
      @$apply fn

  $scope.currentProject = =>
    $scope.projects.find (e) => e.id is $scope.currentProjectId

  $scope.deleteEntry = (e) =>
    p = $scope.currentProject()
    idx = p.entries.indexOf(e)
    Entry.delete project_id:p.id,entry_id:e.id, =>
      p.entries.splice idx,1
      date = new Date(Date.parse(e.createdAt))
      $scope.currentEntriesByMonth[date.getMonth()].remove(e)


  $scope.$root.$on 'entryChanged', (state,event) =>
    event.e.$save project_id:$scope.currentProjectId

  appBusy.set "Getting projects..."
  $scope.getProjects()

