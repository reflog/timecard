app = angular.module('ProjectsApp', ['ngResource']).config ($interpolateProvider) ->
    $interpolateProvider.startSymbol('[[')
    $interpolateProvider.endSymbol(']]')


app.controller "ProjectsController", ($scope,  $resource) ->
  $scope.projects = objects: []
  $scope.currentProject = id: 0 , entries: []
  $scope.newProject = name: `undefined`, hourPrice :  `undefined`, archived: false
  $scope.newEntry = text: `undefined`, timeSpent :  `undefined`
  $scope.projectToDelete = `undefined`
  $scope.currentEntriesByMonth = {}
  $scope.ProjectApi = $resource '/api/project/:project_id', project_id:'@project_id' ,
                          delete:{method:'DELETE'},
                          list:{method:'GET'},
                          add:{method:'POST'}

  $scope.ProjectEntryApi = $resource '/api/project/:project_id/entry/:entry_id',
                                     {
                                      project_id:'@project_id'
                                      entry_id:'@entry_id'
                                     },
                                     {
                                      delete:{method:'DELETE'},
                                      add:{method:'POST'}
                                     }

  $scope.getProjects = ->
    $scope.ProjectApi.list {}, {} , (result) ->
      $scope.projects = result
      $scope.selectProject ( $scope.projects.objects[0] if $scope.projects.objects.length>0 and  $scope.currentProject.id is 0 )

  $scope.addProject = ->
    data = name:$scope.newProject.name, hourPrice: $scope.newProject.hourPrice, archived: false
    $scope.ProjectApi.add {}, data , (result) =>
      data.id = result.id
      $scope.projects.objects.push(data)
      $scope.newProject = name: `undefined`, hourPrice :  `undefined`, archived: false
    $("#project_add_dialog").modal('hide')

  $scope.deleteProject = ->
    $scope.ProjectApi.delete project_id: $scope.projectToDelete.id, {} , ->
      $scope.projects.objects.remove($scope.projectToDelete)
    $("#project_delete_dialog").modal('hide')


  $scope.toggleArchived = (p) -> p.archived = !p.archived

  $scope.doShowAddDialog = -> $("#project_add_dialog").modal()

  $scope.doShowDeleteDialog = (p) ->
    $scope.projectToDelete = p
    $("#project_delete_dialog").modal()

  $scope.selectProject = (p) ->
    $scope.currentProject = p
    # todo, update cookie/server state
    $scope.currentEntriesByMonth = {}
    $scope.addEntriesByMonth p.entries

  $scope.addEntriesByMonth = (entries) ->
    for entry in entries
      do (entry) =>
        date = new Date(Date.parse(entry.createdAt))
        if not Object.has $scope.currentEntriesByMonth, date.getMonth()
          $scope.currentEntriesByMonth[date.getMonth()] = []
        $scope.currentEntriesByMonth[date.getMonth()].push(entry)


  $scope.monthNames = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ]

  $scope.addEntry = ->
    data = text: $scope.newEntry.text, timeSpent: $scope.newEntry.timeSpent
    $scope.ProjectEntryApi.add project_id:$scope.currentProject.id, data, (result) =>
      $scope.currentProject.entries.push(result)
      $scope.addEntriesByMonth [result]
      $scope.newEntry = text: `undefined`, timeSpent :  `undefined`

  $scope.getProjects()

