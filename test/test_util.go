package test

import (
	"sort"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// NetworkingModuleTestCase is a struct that defines a test case for the terraform-aws-networking module
type NetworkingModuleTestCase struct {
	tfDir            string
	testName         string
	vars             map[string]interface{}
	expectApplyError bool
}

// validateNetwork validates the outputs of the terraform module by doing few different checks:
// Creation of VPC, subnets, and availability zones.
func validateNetwork(t *testing.T, terraformOptions *terraform.Options, awsRegion string, expectedVpcName string, testCaseVars map[string]interface{}) {
	outputs := terraform.OutputAll(t, terraformOptions)

	t.Run("outputs_ok", func(t *testing.T) {
		// checks outputs are not nil
		for _, o := range outputs {
			require.NotNil(t, o)
		}
	})

	logger.Log(t, outputs)

	t.Run("check_vpc", func(t *testing.T) {
		// checks VPC exists by calling DescribeVPC
		vpcObj, err := aws.GetVpcByIdE(t, outputs["vpc_id"].(string), awsRegion)
		require.NoError(t, err, "Error trying to Describe VPC")
		assert.Equal(t, expectedVpcName, vpcObj.Name)
	})

	allSubnetsOutput := getAllSubnetsOutput(outputs)
	subnets := aws.GetSubnetsForVpc(t, outputs["vpc_id"].(string), awsRegion)

	t.Run("check_subnets_id", func(t *testing.T) {
		for _, s := range subnets {
			assert.Contains(t, allSubnetsOutput, s.Id)
		}
	})

	t.Run("check_subnets_azs", func(t *testing.T) {
		for _, subnet := range subnets {
			assert.Contains(t, outputs["tamr_ec2_availability_zone"], subnet.AvailabilityZone)
		}
	})

	if outputs["load_balancing_subnet_ids"] != nil {
		t.Run("check_loadbalancer_is_not_public", func(t *testing.T) {
			for _, subnet := range outputs["load_balancing_subnet_ids"].([]interface{}) {
				assert.False(t, aws.IsPublicSubnet(t, subnet.(string), awsRegion))
			}
		})
	}
}

// getAllSubnetsOutput receives the outputs map and appends all values of subnet_id into one sorted list of strings
func getAllSubnetsOutput(outputs map[string]interface{}) []string {
	var retVal []string
	retVal = append(retVal, outputs["compute_subnet_id"].(string))
	retVal = append(retVal, outputs["application_subnet_id"].(string))

	for _, i := range outputs["data_subnet_ids"].([]interface{}) {
		retVal = append(retVal, i.(string))
	}

	for _, i := range outputs["public_subnet_ids"].([]interface{}) {
		retVal = append(retVal, i.(string))
	}

	for _, i := range outputs["load_balancing_subnet_ids"].([]interface{}) {
		retVal = append(retVal, i.(string))
	}

	sort.Strings(retVal)

	return retVal
}
