#!/bin/sh

function die {
  echo "$@"
  exit 1
}

#
# Step 1: Encode consumer key and secret
#

echo -n "API key: "; read API_KEY
echo -n "API secret: "; read API_SECRET

function urlencode {
  echo "$1"  # TODO
}

# Note: base64 comes with coreutils on Debian
credentials64=$(echo -n "$(urlencode "$API_KEY"):$(urlencode "$API_SECRET")" | base64 --wrap=0)

#
# Step 2: Obtain a bearer token
#

request="POST /oauth2/token HTTP/1.1
Host: api.twitter.com
User-Agent: test_auth.sh
Authorization: Basic $credentials64
Content-Type: application/x-www-form-urlencoded;charset=UTF-8
Content-Length: 29

grant_type=client_credentials
"
# Accept-Encoding: gzip

# Where to find Verisign certificates (Debian likes):
CA_PATH="/usr/share/ca-certificates/mozilla"

token=$(
  echo "$request" |
    timeout 2s openssl s_client -quiet -CApath "$CA_PATH" -connect api.twitter.com:443 |
    sed -n -e 's/^{"token_type":"bearer","access_token":"\(.*\)"}/\1/p'
)

if test -z "$token"; then
  die "Cannot get token"
fi

echo "token: $token"

#
# Step 3: Retrieve tweets
# Caveat: "Before getting involved, it’s important to know that the Search API
# is focused on relevance and not completeness. This means that some Tweets and
# users may be missing from search results. If you want to match for
# completeness you should consider using a Streaming API instead."
#
# Note: make use of geocode query parameter to filter by region?
# Note: despite the doc says the bearer token must be base64 encoded it's
# actually not the case. Sending the token we received verbatim (which seems
# to be URL encoded already) is all that's required.
# TODO: remember max tweet id received and use since_id to search only newer.

filterURL="%23feowl%20OR%20to%3Afeowl%20OR%20%40feowl"
request="GET /1.1/search/tweets.json?result_type=recent&count=100&q=$filterURL HTTP/1.1
Host: api.twitter.com
User-Agent: test_auth.sh
Authorization: Bearer $token

"

echo "$request" |
  timeout 15s openssl s_client -quiet -CApath "$CA_PATH" -connect api.twitter.com:443

