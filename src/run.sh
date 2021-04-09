#!/bin/bash


# ENV
# GIT_TOKEN
# REPO_USER
# REPO_NAME
# REPO_BRANCH
# CLEAN_BRANCH --- clean the existing branch
# MESSAGE --- git commit message
# USER_EMAIL
# USER_NAME


# functions
function check_branch () {
  git ls-remote -q --exit-code . origin/$1 > /dev/null
}

function clone_repo () {

#result=$(git clone ${GIT_URL}  -q 2>&1)
git clone ${GIT_URL}
if [[ $? -ne 0 ]]; then
    echo "$result"
    echo "failed to clone repo"
    exit 1
fi
}

function checkout_branch () {

echo "Checkout branch $1"
result=$(git checkout $1 -q 2>&1)
if [[ $? -ne 0 ]]; then
    echo "$result"
    echo "failed to checkout branch $1"
    exit 2
fi
}


function init_repo () {

echo "Init Repo"
cd ..
rm -rf ${REPO_NAME}
git init -q  ${REPO_NAME}
cd ${REPO_NAME}
}

function git_push (){
git add --all . > /dev/null
if git diff --cached --exit-code --quiet; then
  echo "Nothing changed."
else
  git commit -am "${MESSAGE}"  --allow-empty > /dev/null
  result="$(git push -q -f ${GIT_URL} ${LOCAL_BRANCH}:${REPO_BRANCH} 2>&1)"

  if [[ $? -ne 0 ]]; then
    echo "$result"
    echo "failed pushing to ${REPO_BRANCH}"
    exit 3
  else
    echo "pushed to ${REPO_BRANCH}"
  fi
fi
}

#end functions

BASE_DIR=$(pwd)
GIT_URL="https://${GIT_TOKEN}@github.com/${REPO_USER}/${REPO_NAME}.git"
USER_EMAIL=${USER_EMAIL:-"email@github.com"}
USER_NAME=${USER_NAME:-"githubactions-bot"}
if [[ ${SCM} == "gitlab" ]];then
  GIT_URL="https://gitlab-ci-token:${GIT_TOKEN}@gitlab.tremend.com/${REPO_USER}/${REPO_NAME}.git"
  USER_EMAIL=${USER_EMAIL:-"email@gitlab.com"}
  USER_NAME=${USER_NAME:-"gitlabci-bot"}
fi

MESSAGE=${MESSAGE:-"[ci skip] deploy from ${AUTHOR}"}


clone_repo


cd ${REPO_NAME}

if check_branch ${REPO_BRANCH}; then
   checkout_branch ${REPO_BRANCH}
   LOCAL_BRANCH=${REPO_BRANCH}
else
   init_repo ${REPO_BRANCH}
   LOCAL_BRANCH="master"
fi


if [[ "${CLEAN_BRANCH,,}" == "yes" ]];then
   ls -A | grep -v .git | grep -v .gitignore | xargs rm -rf
fi



git config user.email ${USER_EMAIL}
git config user.name ${USER_NAME}
#copy directory
cd ..
cp -rfa ${SOURCE_DIR} ${REPO_NAME}
cd ${REPO_NAME}
git_push
#clean up
cd ..
rm -rf ${REPO_NAME}