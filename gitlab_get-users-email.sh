#!/bin/bash

#Find all emails from Gitlab users whose last activity date dates back to the year in parameter, using the Gitlab API
#$1 : year to check

PRIVATE_TOKEN=""
GITLAB_URL=""

function checkParameters(){
    if [ -z "$1" ] ; then
        echo "Usage : $0 [YEAR]"
        return 1
    elif [ -z "$GITLAB_URL" ] ; then
        echo "Missing \$GITLAB_URL."
        return 1
    elif [ -z "$PRIVATE_TOKEN" ] ; then
        echo "Missing \$PRIVATE_TOKEN."
        return 1
    else
        return 0
    fi
}

function checkToken(){
    local returnCode
    returnCode=$(curl --write-out "%{http_code}" --output /dev/null --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/api/v4/user")
    case "$returnCode" in
        "200")
            return 0
            ;;
        "401")
            echo "Invalid token."
            return 1
            ;;
        "403")
            echo "Token has insufficient permissions."
            return 1
            ;;
        *)
            echo "Unknown error with token (curl returned $returnCode code)."
            return 1
            ;;
    esac
}

#get all active users pages. All pages will be browsed using the getUsersActiveEmail() function
function getPages(){
    currentPage="1"
    totalPages=""
    if ! totalPages=$(curl --silent --head --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/api/v4/users?per_page=100&active=true&page=$currentPage" \
        | grep -i 'x-total-pages:' | awk -F' ' '{print $2}' | tr -d '\r') ; then #le tr permet de supprimer le caractère de retour chariot ; 
        return 1
    elif [ -z "$totalPages" ] ; then
        return 1
    else
        return 0
    fi
}

function getUsersActiveEmail(){
    while [[ $currentPage -le $totalPages ]]; do
        curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_URL/api/v4/users?per_page=100&active=true&page=$currentPage" |\
            jq -r 'map(select(.last_activity_on | tostring | startswith('\""$1"\"')) | [.email] | @tsv) | .[]'
        currentPage=$((currentPage + 1))
    done
}

function main(){
    if ! checkParameters "$1" ; then
        return 1
    fi
    if ! checkToken ; then
        return 1
    fi
    if ! getPages ; then
        echo "Cannot fetch all Gitlab users. Is your token valid ?"
        return 1
    fi
    getUsersActiveEmail "$1"
}

if ! main "$1" ; then
    exit 1
else
    exit 0
fi
