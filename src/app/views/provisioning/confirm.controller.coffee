@App.controller('ProvisioningConfirmCtrl', ($scope, $q, $state, $stateParams, MnoeOrganizations, MnoeProvisioning, MnoeAdminConfig, PRICING_TYPES, EDIT_ACTIONS) ->
  vm = this

  vm.isLoading = true
  orgPromise = MnoeOrganizations.get($stateParams.orgId)
  vm.subscription = MnoeProvisioning.getSubscription()
  vm.singleBilling = vm.subscription.product.single_billing_enabled
  vm.billedLocally = vm.subscription.product.billed_locally

  vm.orderTypeText = (editAction) ->
    EDIT_ACTIONS[editAction]

  vm.editOrder = () ->
    params = {
      nid: $stateParams.nid,
      orgId: $stateParams.orgId
      id: $stateParams.id,
      editAction: $stateParams.editAction
    }

    switch $stateParams.editAction
      when 'CHANGE', 'NEW', null
        $state.go('dashboard.provisioning.order', params)
      else
        $state.go('dashboard.provisioning.additional_details', params)

  # Happen when the user reload the browser during the provisioning
  if _.isEmpty(vm.subscription)
    # Redirect the user to the first provisioning screen
    vm.editOrder()

  vm.subscription.edit_action = $stateParams.editAction

  $q.all({organization: orgPromise}).then(
    (response) ->
      vm.orgCurrency = response.organization.data.billing_currency || MnoeAdminConfig.marketplaceCurrency()
  ).finally(-> vm.isLoading = false)

  vm.validate = () ->
    vm.isLoading = true
    MnoeProvisioning.saveSubscription(vm.subscription).then(
      (subscription) ->
        $state.go('dashboard.provisioning.order_summary', {orgId: $stateParams.orgId, subscriptionId: subscription.id})
    ).finally(-> vm.isLoading = false)

  # Return true if the plan has a dollar value
  vm.pricedPlan = ProvisioningHelper.pricedPlan

  vm.editOrder = () ->
    $state.go('dashboard.provisioning.order', {nid: $stateParams.nid, orgId: $stateParams.orgId, id: $stateParams.id})

  # Delete the cached subscription when we are leaving the subscription workflow.
  $scope.$on('$stateChangeStart', (event, toState) ->
    switch toState.name
      when "dashboard.provisioning.order", "dashboard.provisioning.order_summary", "dashboard.provisioning.additional_details"
        null
      else
        MnoeProvisioning.setSubscription({})
  )

  return
)
