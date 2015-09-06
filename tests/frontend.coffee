$controller = undefined
$httpBackend = undefined
$rootScope = undefined
$scope = undefined
expect = chai.expect
mockEvents = [{_id: 0, name: 'mock-event-1'}, {_id: 1, name: 'mock-event-2'}]

describe 'Sortableheader directive', () ->
  element = undefined

  beforeEach () ->
    module 'templates/sortableHeader.html'
    angular.mock.module 'aaa-website'
    inject (@$rootScope, $injector, $compile) =>
      scope = $rootScope
      scope.changeOrder = () -> {}

      scope.sortConfig = {
        Name: 'name',
        Description: 'description',
        Date: 'date',
        "Image Link": 'image'
      }
      $httpBackend = $injector.get('$httpBackend')

      html = angular.element '<thead sortable config="sortConfig" on-click=changeOrder(order)></thead>'
      element = $compile(html)(scope)
      scope.$digest()

      # console.log element.html()

  it 'whatever', () ->
    console.log 'whatever'

describe 'EventController', () ->
  beforeEach () ->
    angular.mock.module 'aaa-website'
    inject (@$controller, @$rootScope, $injector) =>
      $httpBackend = $injector.get('$httpBackend')
      $scope = $rootScope.$new()
      this.initController = () ->
        controller = $controller('AdminEventController', {$scope: $scope})
        return controller

  it 'should push events into scope after initialization', () ->
    $httpBackend.expectGET('/admin/api/events').respond(mockEvents)

    controller = this.initController()
    $httpBackend.flush()
    expect($scope.events.length).to.equal(mockEvents.length)

  describe 'already populated', () ->
    beforeEach (done) ->
      inject (@$controller, @$rootScope, $injector) =>
        $httpBackend = $injector.get('$httpBackend')
        $scope = $rootScope.$new()
        $httpBackend.expectGET('/admin/api/events').respond(mockEvents)
        controller = $controller('AdminEventController', {$scope: $scope})
        done()

    it 'should remove event after deletion', (done) ->
      spy = sinon.spy $scope, 'deleteEvent'
      fakeIndex = 1
      $httpBackend.expectDELETE('/admin/api/events/0').respond({status: 'OK'})
      $scope.deleteEvent(mockEvents[0], fakeIndex).then () ->
        expect(spy.calledOnce).to.be.true
        expect($scope.events.length).to.equal(1)
        done()

      $httpBackend.flush()
    
    it 'should sent a PUT on event edit', () ->
      changedItemIndex = 1
      spy = sinon.spy $scope, 'createOrEdit'
      $httpBackend.expectPUT('/admin/api/events/1').respond({_id: changedItemIndex, name: 'another_name'})
      $scope.selectedIndex = changedItemIndex

      $scope.createOrEdit(mockEvents[changedItemIndex]).then () ->
        expect(spy.calledOnce).to.be.true
        expect($scope.events[changedItemIndex].name).to.equal('another_name')

      $httpBackend.flush()

    it 'should send a POST on event create', () ->
      changedItemIndex = undefined
      spy = sinon.spy $scope, 'createOrEdit'
      testEvent = {_id: 2, name: 'another_item'}
      $httpBackend.expectPOST('/admin/api/events').respond(testEvent)
      $scope.selectedIndex = changedItemIndex

      $scope.createOrEdit(testEvent).then () ->
        expect(spy.calledOnce).to.be.true
        expect($scope.events.length).to.equal(3)

      $httpBackend.flush()

  afterEach () ->
    $httpBackend.verifyNoOutstandingRequest()
    $httpBackend.verifyNoOutstandingExpectation()