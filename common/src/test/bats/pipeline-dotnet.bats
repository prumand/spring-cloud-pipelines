#!/usr/bin/env bats

load 'test_helper'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
	export TEMP_DIR="$( mktemp -d )"
	export ENVIRONMENT="TEST"
	export PAAS_TYPE="dummy"
	ln -s "${FIXTURES_DIR}/pipeline-dummy.sh" "${SOURCE_DIR}"
	cp -a "${FIXTURES_DIR}/generic/" "${TEMP_DIR}"
}

teardown() {
	rm -f "${SOURCE_DIR}/pipeline-dummy.sh"
	rm -rf "${TEMP_DIR}"
}

function dotnet {
	if [[ "${*}" == *"AppName"* ]]; then
		echo "   my-project   "
	elif [[ "${*}" == *"GroupId"* ]]; then
		echo "    com.example   "
	elif [[ "${*}" == *"StubIds"*	 ]]; then
		echo "    com.example:foo:1.0.0.RELEASE:stubs:1234    "
	else
		echo "dotnet $*"
	fi
}

function unzip {
	echo "unzip $*"
}

function curl {
	echo "curl $*"
}

export -f dotnet

@test "should build the project when msbuild and php are installed [Dotnet]" {
	export PIPELINE_VERSION=1.0.0.M8
	export M2_SETTINGS_REPO_USERNAME="foo"
	export M2_SETTINGS_REPO_PASSWORD="bar"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	run build

	# App
	assert_output --partial "msbuild /nologo /t:CFPUnitTests"
	assert_output --partial "msbuild /nologo /t:CFPPublish"
	# We don't want exception on jq parsing
	refute_output --partial "Cannot iterate over null (null)"
	assert_success
}

@test "should return fixed project name if differs from the default one [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="bar"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( retrieveAppName )" "foo"
	assert_success
}

@test "should call msbuild to get the app name if it's equal to the default one [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="foo"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( retrieveAppName )" "my-project"
	assert_success
}

@test "should call msbuild to get the stubrunner ids [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="foo"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( retrieveStubRunnerIds )" "com.example:foo:1.0.0.RELEASE:stubs:1234"
	assert_success
}

@test "should call msbuild to get the group id [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="foo"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( retrieveGroupId )" "com.example"
	assert_success
}

@test "should call run api-compatibility-check task [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="foo"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( executeApiCompatibilityCheck )" "dotnet msbuild /nologo /t:CFPApiCompatibilityTest"
	assert_success
}

@test "should call run smoke tests task [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="foo"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( runSmokeTests )" "dotnet msbuild /nologo /t:CFPSmokeTests"
	assert_success
}

@test "should call run e2e task [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="foo"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( runE2eTests )" "dotnet msbuild /nologo /t:CFPE2eTests"
	assert_success
}

@test "should return MSBUILD project type [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="foo"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( projectType )" "MSBUILD"
	assert_success
}

@test "should return target as output folder [Dotnet]" {
	export PROJECT_NAME="foo"
	export DEFAULT_PROJECT_NAME="foo"
	source "${SOURCE_DIR}/projectType/pipeline-dotnet.sh"

	assert_equal "$( outputFolder )" "target"
	assert_success
}
