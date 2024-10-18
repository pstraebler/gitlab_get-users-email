# gitlab_get-users-email

Retrieve the email addresses of GitLab users who were last active in a specific year.

## Requirements

You need to install `curl` and `jq` 

You need to generate an Access Token with 'api' rights.

Fill *$PRIVATE_TOKEN* and *$GITLAB_URL* in *gitlab_get-users-email.sh* file.

## Usage

`./gitlab_get-users-emails.sh [YEAR]`

