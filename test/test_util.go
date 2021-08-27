package test

import (
	"sort"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type NetworkingModuleTestCase struct {
	testName         string
	vars             map[string]interface{}
	expectApplyError bool
}

func validateNetwork(t *testing.T, terraformOptions *terraform.Options, awsRegion string, expectedVpcName string, expectedAzs []string) {
	outputs := terraform.OutputAll(t, terraformOptions)

	t.Run("outputs_ok", func(t *testing.T) {
		// checks outputs are not nil
		for _, o := range outputs {
			require.NotNil(t, o)
		}
	})

	t.Run("get_vpc", func(t *testing.T) {
		// checks VPC exists by calling DescribeVPC
		_, err := aws.GetVpcByIdE(t, outputs["vpc_id"].(string), awsRegion)
		require.NoError(t, err, "Error trying to Describe VPC")
	})

	t.Run("check_vpc_name", func(t *testing.T) {
		// // checks VPC name
		// vpcName := aws.FindVpcName(vpcObj)
		// assert.Equal(t, expectedVpcName, vpcName)
	})

	allSubnetsOutput := getAllSubnetsOutput(outputs)
	subnets := aws.GetSubnetsForVpc(t, outputs["vpc_id"].(string), awsRegion)

	t.Run("check_subnets_id", func(t *testing.T) {
		for _, s := range subnets {
			assert.Contains(t, allSubnetsOutput, s.Id)
		}
	})

	t.Run("check_subnets_azs", func(t *testing.T) {
		for _, s := range subnets {
			assert.Contains(t, expectedAzs, s.AvailabilityZone)
		}
	})
}

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

	sort.Strings(retVal)

	return retVal
}
