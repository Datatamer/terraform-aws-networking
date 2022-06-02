package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	terratestutils "github.com/Datatamer/go-terratest-functions/pkg/terratest_utils"
	"github.com/Datatamer/go-terratest-functions/pkg/types"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

// initTestCases initializes a list of NetworkingModuleTestCase
func initTestCases() []NetworkingModuleTestCase {
	return []NetworkingModuleTestCase{
		{
			testName:         "Minimal",
			tfDir:            "test_examples/minimal",
			expectApplyError: false,
			vars: map[string]interface{}{
				"name_prefix":                   "minimal_terratest",
				"vpc_cidr_block":                "172.38.0.0/20",
				"ingress_cidr_blocks":           []string{"0.0.0.0/0"},
				"data_subnet_cidr_blocks":       []string{"172.38.0.0/24", "172.38.1.0/24"},
				"application_subnet_cidr_block": "172.38.2.0/24",
				"compute_subnet_cidr_block":     "172.38.3.0/24",
				"public_subnets_cidr_blocks":    []string{"172.38.4.0/24", "172.38.5.0/24"},
				"create_public_subnets":         false,
				"create_load_balancing_subnets": false,
				"enable_nat_gateway":            false,
				"tags":                          make(map[string]string),
			},
		},
		{
			testName:         "CreateAllSubnets",
			tfDir:            "test_examples/minimal",
			expectApplyError: false,
			vars: map[string]interface{}{
				"name_prefix":                        "all_subnets_terratest",
				"vpc_cidr_block":                     "172.38.0.0/20",
				"ingress_cidr_blocks":                []string{"0.0.0.0/0"},
				"data_subnet_cidr_blocks":            []string{"172.38.0.0/24", "172.38.1.0/24"},
				"application_subnet_cidr_block":      "172.38.2.0/24",
				"compute_subnet_cidr_block":          "172.38.3.0/24",
				"public_subnets_cidr_blocks":         []string{"172.38.4.0/24", "172.38.5.0/24"},
				"load_balancing_subnets_cidr_blocks": []string{"172.38.6.0/24", "172.38.7.0/24"},
				"create_public_subnets":              true,
				"create_load_balancing_subnets":      true,
				"enable_nat_gateway":                 true,
				"tags":                               make(map[string]string),
			},
		},
		{
			testName:         "InvalidCIDR",
			tfDir:            "test_examples/minimal",
			expectApplyError: true,
			vars: map[string]interface{}{
				"name_prefix":                   "this-should-fail",
				"vpc_cidr_block":                "0.0.0.0/0",
				"ingress_cidr_blocks":           []string{"0.0.0.0/0"},
				"data_subnet_cidr_blocks":       []string{"172.38.0.0/24", "172.38.1.0/24"},
				"application_subnet_cidr_block": "172.38.2.0/24",
				"compute_subnet_cidr_block":     "172.38.3.0/24",
				"create_public_subnets":         false,
				"create_load_balancing_subnets": false,
				"enable_nat_gateway":            false,
				"tags":                          make(map[string]string),
			},
		},
	}
}

// TestMinimalTamrNetwork runs all testCases
func TestTamrNetwork(t *testing.T) {
	const MODULE_NAME = "terraform-aws-networking"
	// os.Setenv("TERRATEST_REGION", "us-east-1")

	// list of different buckets that will be created to be tested
	testCases := initTestCases()
	// Generate file containing GCS URL to be used on Jenkins.
	// TERRATEST_BACKEND_BUCKET_NAME and TERRATEST_URL_FILE_NAME are both set on Jenkins declaration.
	gcsTestExamplesURL := terratestutils.GenerateUrlFile(t, MODULE_NAME, os.Getenv("TERRATEST_BACKEND_BUCKET_NAME"), os.Getenv("TERRATEST_URL_FILE_NAME"))
	for _, testCase := range testCases {
		// The following is necessary to make sure testCase's values don't
		// get updated due to concurrency within the scope of t.Run(..) below
		testCase := testCase

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()
			awsRegion := aws.GetRandomStableRegion(t, []string{"us-east-1", "us-east-2", "us-west-1", "us-west-2"}, nil)
			// this creates a tempTestFolder for each testCase
			tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "..", testCase.tfDir)

			expectedName := fmt.Sprintf("terratest-vpc-%s", strings.ToLower(random.UniqueId()))
			testCase.vars["tags"].(map[string]string)["Name"] = expectedName

			test_structure.RunTestStage(t, "pick_new_randoms", func() {

				test_structure.SaveString(t, tempTestFolder, "region", awsRegion)

			})

			test_structure.RunTestStage(t, "setup_options", func() {
				awsRegion := test_structure.LoadString(t, tempTestFolder, "region")
				backendConfig := terratestutils.ParseBackendConfig(t, gcsTestExamplesURL, testCase.testName, testCase.tfDir)
				terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
					TerraformDir: tempTestFolder,
					Vars:         testCase.vars,
					EnvVars: map[string]string{
						"AWS_REGION": awsRegion,
					},
					BackendConfig: backendConfig,
					MaxRetries:    2,
				})

				test_structure.SaveTerraformOptions(t, tempTestFolder, terraformOptions)
			})

			test_structure.RunTestStage(t, "create_network", func() {
				terraformOptions := test_structure.LoadTerraformOptions(t, tempTestFolder)
				terraformConfig := &types.TerraformData{
					TerraformBackendConfig: terraformOptions.BackendConfig,
					TerraformVars:          terraformOptions.Vars,
					TerraformEnvVars:       terraformOptions.EnvVars,
				}
				if !testCase.expectApplyError {
					if _, err := terratestutils.UploadFilesE(t, terraformConfig); err != nil {
						logger.Log(t, err)
					}
				}

				_, err := terraform.InitAndApplyE(t, terraformOptions)

				if testCase.expectApplyError {
					require.Error(t, err)
					// If it failed as expected, we should skip the rest (validate function).
					t.SkipNow()
				}

				require.NoError(t, err)
			})

			defer test_structure.RunTestStage(t, "teardown", func() {
				terraformOptions := test_structure.LoadTerraformOptions(t, tempTestFolder)
				terraformOptions.MaxRetries = 5

				_, err := terraform.DestroyE(t, terraformOptions)
				if err != nil {
					// If there is an error on destroy, it will be logged.
					logger.Log(t, err)
				}
			})

			test_structure.RunTestStage(t, "validate_network", func() {
				terraformOptions := test_structure.LoadTerraformOptions(t, tempTestFolder)
				validateNetwork(
					t,
					terraformOptions,
					awsRegion,
					expectedName,
					testCase.vars,
				)
			})

		})
	}
}
