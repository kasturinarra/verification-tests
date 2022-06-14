Feature: ServiceAccount and Policy Managerment

  # @author anli@redhat.com
  # @case_id OCP-10642
  @4.11 @4.10 @4.9 @4.8 @4.7 @4.6
  @vsphere-ipi @openstack-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi
  @vsphere-upi @openstack-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi
  @upgrade-sanity
  @singlenode
  @proxy @noproxy @connected
  @network-ovnkubernetes @network-openshiftsdn
  @heterogeneous @arm64 @amd64
  Scenario: OCP-10642 Could grant admin permission for the service account username to access to its own project
    Given I have a project
    When I create a new application with:
      | image_stream | ruby         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp         |
    # TODO: anli, this is a work around for AEP, please add step `the step should succeed` according to latest good solution
    Then I wait for the "myapp" service to be created
    Given I create the serviceaccount "demo"
    And I give project admin role to the demo service account
    When I run the :get client command with:
      | resource      | rolebinding |
      | resource_name | admin       |
      | o             | wide        |
    Then the output should match:
      | admin.*(demo)? |
    Given I find a bearer token of the demo service account
    And I switch to the demo service account
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all |
    Then the output should contain:
      | myapp   |
    """

  # @author xiaocwan@redhat.com
  # @case_id OCP-11494
  @proxy
  @4.11 @4.10 @4.9 @4.8 @4.7 @4.6
  @vsphere-ipi @openstack-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi
  @vsphere-upi @openstack-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi
  @upgrade-sanity
  @singlenode
  @connected
  @network-ovnkubernetes @network-openshiftsdn
  @heterogeneous @arm64 @amd64
  Scenario: OCP-11494 Could grant admin permission for the service account group to access to its own project
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | quay.io/openshifttest/hello-openshift:multiarch |
    Then the step should succeed
    When I run the :policy_add_role_to_group client command with:
      | role       | admin                                     |
      | group_name | system:serviceaccounts:<%= project.name %> |
    Then the step should succeed
    Given I find a bearer token of the system:serviceaccount:<%= project.name %>:default service account
    Given I switch to the system:serviceaccount:<%= project.name %>:default service account

    When I get project services
    Then the output should contain:
      | hello-openshift |
    # Verify the permission of various operations
    When I run the :new_app client command with:
      | app_repo | quay.io/openshifttest/hello-openshift:multiarch |
      | name     | app2                                            |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | svc             |
      | object_name_or_id | hello-openshift |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                  |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    When I run the :policy_remove_role_from_user client command with:
      | role      | admin                                  |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed

  # @author wjiang@redhat.com
  # @case_id OCP-11249
  # There is no oc create token command below version 4.11, this case is not critical feature, so need to remove versions below 4.11
  @4.11
  @vsphere-ipi @openstack-ipi @gcp-ipi @baremetal-ipi @azure-ipi @aws-ipi
  @vsphere-upi @openstack-upi @gcp-upi @baremetal-upi @azure-upi @aws-upi
  @upgrade-sanity
  @singlenode
  @network-ovnkubernetes @network-openshiftsdn
  @proxy @noproxy
  @heterogeneous @arm64 @amd64
  Scenario: OCP-11249 User can get the serviceaccount token via client
    Given I have a project
    When I run the :create_token client command with:
      | serviceaccount | default |
    Then the step should succeed
    When I run the :create_token client command with:
      | serviceaccount | builder |
    Then the step should succeed
    When I run the :create_token client command with:
      | serviceaccount | deployer |
    Then the step should succeed
    Given an 8 characters random string of type :dns is stored into the :serviceaccount_name clipboard
    When I run the :create_serviceaccount client command with:
      | serviceaccount_name | <%= cb.serviceaccount_name %> |
    Then the step should succeed
    When I run the :create_token client command with:
      | serviceaccount | <%= cb.serviceaccount_name %> |
    Then the step should succeed
