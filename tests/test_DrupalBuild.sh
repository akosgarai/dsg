#!/bin/bash

# Get the directory of the script. It is used for the source commands.
CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
APP="${CUR_DIR}/../scripts.sh"

# setup default parameters
# --project-base-path
TEST_PROJECT_BASE_PATH="${PROJECT_BASE_PATH:-".."}"
TEST_SITE_NAME=${SITE_NAME:-"testsite.com"}
TEST_DB_NAME=${DB_NAME:-"drupaltests"}
TEST_DB_USER=${DB_USER:-"root"}
TEST_ROOT_DB_USER_PW=${MYSQL_DB_PASS:-"root"}
TEST_SITE_ADMIN_NAME=${SITE_ADMIN_NAME:-"drupal"}
TEST_SITE_ADMIN_PW=${SITE_ADMIN_PW:-"drupal"}
TEST_APACHE_CONF_DIR=${APACHE_CONF_DIR:-"/etc/apache2"}
TEST_DB_HOST=${DB_HOST:-"localhost"}
TEST_DB_PORT=${DB_PORT:-3308}
TEST_LOCAL_DEPLOY_TARGET=${LOCAL_DEPLOY_TARGET:-"/var/www/html"}
TEST_COMPOSER_APP=${COMPOSER_APP:-"composer1"}

function Test_DrupalBuildOnlyAction {
    local msg="With only drupal-build action name the script should return error. "
    local code=0
    local actionName=drupal-build
    local result
    result=$("${APP}" "${actionName}")
    if [ ! "${result}" == "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags." ]; then
        msg="${msg}- FAILED"
        code=1
    else
        msg="${msg}- OK"
    fi
    echo "${msg}"
    return ${code}
}
function Test_DrupalBuildActionPath {
    local msg="With drupal-build action name and --project-base-path flag the script should return error. "
    local code=0
    local actionName=drupal-build
    local result
    result=$("${APP}" "${actionName}" --project-base-path "${TEST_PROJECT_BASE_PATH}")
    if [ ! "${result}" == "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags." ]; then
        msg="${msg}- FAILED"
        code=1
    else
        msg="${msg}- OK"
    fi
    echo "${msg}"
    return ${code}
}
function Test_DrupalBuildActionName {
    local msg="With drupal-build action name and --project-name flag the script should return error. "
    local code=0
    local actionName=drupal-build
    local result
    result=$("${APP}" "${actionName}" --project-name "${TEST_SITE_NAME}")
    if [ ! "${result}" == "You have to set both the project base path (--project-base-path) and the project name (--project-name) flags." ]; then
        msg="${msg}- FAILED"
        code=1
    else
        msg="${msg}- OK"
    fi
    echo "${msg}"
    return ${code}
}
function Test_DrupalBuildWithoutSudoFlag {
    local msg="Without the sudo flag the drupal-build action should return error. "
    local code=0
    local actionName=drupal-build
    local result
    result=$("${APP}" "${actionName}" --project-base-path "${TEST_PROJECT_BASE_PATH}" --project-name "${TEST_SITE_NAME}" \
        --db-name "${TEST_DB_NAME}" --db-user-name "${TEST_DB_USER}" --site-admin-user-name "${TEST_SITE_ADMIN_NAME}" \
        --site-admin-password "${TEST_SITE_ADMIN_PW}" --apache-conf-dir "${TEST_APACHE_CONF_DIR}" --db-host "${TEST_DB_HOST}" \
        --db-port "${TEST_DB_PORT}" --root-db-user-pw "${TEST_ROOT_DB_USER_PW}" --local-deploy-target "${TEST_LOCAL_DEPLOY_TARGET}" \
        --composer-app "${TEST_COMPOSER_APP}")
    if [ ! "${result}" == "You have to set the sudo (-s or --sudo) to be able to run drupal-build process." ]; then
        msg="${msg}- FAILED"
        code=1
    else
        msg="${msg}- OK"
    fi
    echo "${msg}"
    return ${code}
}
function Test_DrupalBuildActionPathName {
    local msg="With drupal-build action valid setup, a composer project has to be created."
    local code=0
    local actionName=drupal-build
    if [ ! -d "${TEST_PROJECT_BASE_PATH}" ]; then
        mkdir -p "${TEST_PROJECT_BASE_PATH}"
    fi
    result=$("${APP}" "${actionName}" --project-base-path "${TEST_PROJECT_BASE_PATH}" --project-name "${TEST_SITE_NAME}" \
        --db-name "${TEST_DB_NAME}" --db-user-name "${TEST_DB_USER}" --site-admin-user-name "${TEST_SITE_ADMIN_NAME}" \
        --site-admin-password "${TEST_SITE_ADMIN_PW}" --apache-conf-dir "${TEST_APACHE_CONF_DIR}" --db-host "${TEST_DB_HOST}" \
        --db-port "${TEST_DB_PORT}" --root-db-user-pw "${TEST_ROOT_DB_USER_PW}" --local-deploy-target "${TEST_LOCAL_DEPLOY_TARGET}" \
        -s --composer-app "${TEST_COMPOSER_APP}")
    if [ ! -d "${TEST_LOCAL_DEPLOY_TARGET}/${TEST_SITE_NAME}" ]; then
        msg="${msg}- FAILED\n\tMissing '${TEST_LOCAL_DEPLOY_TARGET}/${TEST_SITE_NAME}' directory."
        code=1
    else
        msg="${msg}- OK\n\tThe '${TEST_LOCAL_DEPLOY_TARGET}/${TEST_SITE_NAME}' directory exists."
    fi
    if [ ! "${code}" == 0 ]; then
        echo -e "${msg}"
        echo "${result}"
        return ${code}
    fi
    # check the site is reachable with curl.
    local url="http://localhost/${TEST_SITE_NAME}/web/"
    local curlCode
    curlCode=$(curl -o /dev/null -w "%{http_code}\n" -s -XGET "${url}")
    if [ ! "${curlCode}" == "200" ]; then
        msg="${msg}\n\tStatus code '${url}' (${curlCode}) not 200. - FAILED"
        code=1
    else
        msg="${msg}\n\tStatus code '${url}' (${curlCode}). - OK"
    fi
    curlCode=0
    curlCode=$(curl -o /dev/null -w "%{http_code}\n" -s -XGET "${url}notvalidpath")
    if [ ! "${curlCode}" == "404" ]; then
        msg="${msg}\n\tStatus code not existing path '${url}notvalidpath' (${curlCode}) not 404. - FAILED"
        code=1
    else
        msg="${msg}\n\tStatus code not existing path '${url}notvalidpath' (${curlCode}). - OK"
    fi
    curlCode=0
    curlCode=$(curl -o /dev/null -w "%{http_code}\n" -s -XGET "${url}civicrm/")
    if [ ! "${curlCode}" == "403" ]; then
        msg="${msg}\n\tStatus code w/o login '${url}civicrm/' (${curlCode}) not 403. - FAILED"
        code=1
    else
        msg="${msg}\n\tStatus code w/o login '${url}civicrm/' (${curlCode}). - OK"
    fi
    # redirect to civicrm page with the drush otp.
    local otp
    otp=$("${TEST_LOCAL_DEPLOY_TARGET}/${TEST_SITE_NAME}"/vendor/drush/drush/drush uli --uri="${url}" --uid=1 civicrm --no-browser)
    # the cookies has to be passed to the redirects.
    curlCode=0
    curlCode=$(curl -o /dev/null -w "%{http_code}\n" -s -L -c cookies.txt -b cookies.txt -XGET "${otp}")
    if [ ! "${curlCode}" == "200" ]; then
        msg="${msg}\n\tStatus code with login '${url}civicrm/' (${curlCode}) not 200. - FAILED"
        code=1
    else
        msg="${msg}\n\tStatus code with login '${url}civicrm/' (${curlCode}). - OK"
    fi
    echo -e "${msg}"
    # cleanup
    sudo rm -rf "${TEST_LOCAL_DEPLOY_TARGET:?}/${TEST_SITE_NAME}"
    return ${code}
}

# Define the test cases
TEST_CASES=(
    Test_DrupalBuildOnlyAction
    Test_DrupalBuildActionPath
    Test_DrupalBuildActionName
    Test_DrupalBuildWithoutSudoFlag
    Test_DrupalBuildActionPathName
)

# Run test cases
for testCase in "${!TEST_CASES[@]}"; do
    if ! "${TEST_CASES[${testCase}]}"; then
        echo "FAILING TEST: ${TEST_CASES[${testCase}]}"
        exit 1
    fi
done
