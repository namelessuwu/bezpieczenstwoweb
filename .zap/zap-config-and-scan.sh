#!/usr/bin/env bash
set -euo pipefail

: "${ZAP_HOST:=127.0.0.1}"
: "${ZAP_PORT:=8080}"
: "${ZAP_API_KEY:?ZAP_API_KEY must be set}"
: "${TARGET_URL:?TARGET_URL must be set}"
: "${LOGIN_URL:?LOGIN_URL must be set}"
: "${LOGIN_POST_DATA:?LOGIN_POST_DATA must be set}"
: "${ZAP_USER:?ZAP_USER must be set}"
: "${ZAP_PASS:?ZAP_PASS must be set}"

BASE="http://${ZAP_HOST}:${ZAP_PORT}"
API="?apikey=${ZAP_API_KEY}"

echo "[*] Using ZAP API at ${BASE}"

# 1) Create new context
CONTEXT_NAME="ci-auth-context"
echo "[*] Creating context: ${CONTEXT_NAME}"
curl -s "${BASE}/JSON/context/action/newContext/${API}&contextName=${CONTEXT_NAME}" | jq .

# 2) Include target in context (regex)
# Adjust the regex to match your site. This includes entire host.
TARGET_HOST_REGEX=$(echo "${TARGET_URL}" | sed -E 's#^https?://##' | sed 's#/$##')
REGEX="^https?://${TARGET_HOST_REGEX}.*"
echo "[*] Including regex in context: ${REGEX}"
curl -s "${BASE}/JSON/context/action/includeInContext/${API}&contextName=${CONTEXT_NAME}&regex=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "${REGEX}")" | jq .

# 3) Set session management method: cookie based (common)
echo "[*] Setting session management to cookie-based"
curl -s "${BASE}/JSON/sessionManagement/action/setSessionManagementMethod/${API}&contextName=${CONTEXT_NAME}&methodName=cookieBasedSessionManagement" | jq .

# 4) Configure form-based authentication
# ZAP expects loginUrl and loginRequestData joined with '&'
# loginRequestData should contain placeholders {%username%} and {%password%}
FORM_CONF="loginUrl=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "${LOGIN_URL}")&loginRequestData=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "${LOGIN_POST_DATA}")"
echo "[*] Setting authentication method (formBasedAuthentication)"
# Need context id -> get context list and then find id
CONTEXT_LIST_JSON=$(curl -s "${BASE}/JSON/context/view/contextList/${API}")
CONTEXT_ID=$(curl -s "${BASE}/JSON/context/view/context/${API}&contextName=${CONTEXT_NAME}" | jq -r '.context.contextId')
if [ -z "${CONTEXT_ID}" ] || [ "${CONTEXT_ID}" = "null" ]; then
  echo "Could not get context ID"
  exit 1
fi
curl -s "${BASE}/JSON/authentication/action/setAuthenticationMethod/${API}&contextId=${CONTEXT_ID}&authMethodName=formBasedAuthentication&authMethodConfig=${FORM_CONF}" | jq .

# 5) Set logged-in indicator (very important so ZAP knows login succeeded)
# Adjust the indicator to something present on post-login pages (e.g., "Logout" or username)
LOGGED_IN_INDICATOR="Logout"
echo "[*] Setting logged-in indicator: ${LOGGED_IN_INDICATOR}"
curl -s "${BASE}/JSON/authentication/action/setLoggedInIndicator/${API}&contextId=${CONTEXT_ID}&loggedInIndicator=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "${LOGGED_IN_INDICATOR}")" | jq .

# 6) Create a user and set credentials
echo "[*] Creating user for context"
NEWUSER_JSON=$(curl -s "${BASE}/JSON/users/action/newUser/${API}&contextId=${CONTEXT_ID}&name=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "ci-user")")
USER_ID=$(echo "${NEWUSER_JSON}" | jq -r '.userId // ._id // .userId')
if [ -z "${USER_ID}" ] || [ "${USER_ID}" = "null" ]; then
  # sometimes nested differently - try list
  USER_ID=$(curl -s "${BASE}/JSON/users/view/users/${API}&contextId=${CONTEXT_ID}" | jq -r '.users[0].id')
fi
echo "[*] User id: ${USER_ID}"

# Provide credentials - the param is authCredentialsConfig=username=<user>&password=<pass>
CREDS="username=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "${ZAP_USER}")&password=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "${ZAP_PASS}")"
curl -s "${BASE}/JSON/users/action/setAuthenticationCredentials/${API}&contextId=${CONTEXT_ID}&userId=${USER_ID}&authCredentialsConfig=${CREDS}" | jq .

# Enable the user
curl -s "${BASE}/JSON/users/action/setUserEnabled/${API}&contextId=${CONTEXT_ID}&userId=${USER_ID}&enabled=true" | jq .

# 7) Optionally: force user (force all spider/ascan requests to authenticate as the user)
echo "[*] Enabling 'force user' for the context"
curl -s "${BASE}/JSON/forcedUser/action/setForcedUser/${API}&contextId=${CONTEXT_ID}&userId=${USER_ID}" | jq .
curl -s "${BASE}/JSON/forcedUser/action/setForcedUserModeEnabled/${API}&boolean=true" | jq .

# 8) Spider the site under context as the user (seed with TARGET_URL)
echo "[*] Starting spider (as user) on ${TARGET_URL}"
SPIDER_RESP=$(curl -s "${BASE}/JSON/spider/action/scan/${API}&url=$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))' "${TARGET_URL}")&contextName=${CONTEXT_NAME}&userId=${USER_ID}")
SCAN_ID=$(echo "${SPIDER_RESP}" | jq -r '.scan')
echo "[*] Spider scan id: ${SCAN_ID}"

# Wait for spider to finish
while true; do
  PROG=$(curl -s "${BASE}/JSON/spider/view/status/${API}&scanId=${SCAN_ID}" | jq -r '.status // .status')
  echo "[*] Spider status: ${PROG}%"
  if [ "${PROG}" = "100" ] || [ "${PROG}" = "100.0" ]; then break; fi
  sleep 3
done

# 9) Start authenticated active scan (as user)
echo "[*] Starting active scan (as user)"
ASCAN_RESP=$(curl -s "${BASE}/JSON/ascan/action/scan/${API}&url=$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))' "${TARGET_URL}")&recurse=true&inScopeOnly=true&contextId=${CONTEXT_ID}&method=&postData=")
AS_ID=$(echo "${ASCAN_RESP}" | jq -r '.scan')
echo "[*] Active scan id: ${AS_ID}"

# Wait for ascan to finish
while true; do
  PROG=$(curl -s "${BASE}/JSON/ascan/view/status/${API}&scanId=${AS_ID}" | jq -r '.status')
  echo "[*] Active scan status: ${PROG}%"
  if [ "${PROG}" = "100" ] || [ "${PROG}" = "100.0" ]; then break; fi
  sleep 10
done

# 10) Save HTML report
echo "[*] Generating ZAP HTML report"
curl -s "${BASE}/OTHER/core/other/htmlreport/${API}" -o zap-report.html
echo "[*] Done. Report: zap-report.html"

# 11) Export alerts as JSON (optional)
curl -s "${BASE}/JSON/core/view/alerts/${API}" -o zap-alerts.json
echo "[*] Saved alerts to zap-alerts.json"

echo "[*] Scan finished"
