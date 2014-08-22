#!/bin/bash

: ${KEY?'missing github private key do deploy docker run -e KEY=XXXX'}

[ -n "$DEBUG" ] && echo debug on ... && set -x

: ${COMMIT_NAME:=jenkins}
: ${COMMIT_EMAIL:=jenkins@sequenceiq.com}
: ${USER_NAME:=sequenceiq}
: ${REPO:=test-docker}

# private github key comes from env variable KEY
# docker run -e KEY=XXXX
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# switch off debug to hide private key
set +x
echo $KEY|base64 -d> /root/.ssh/id_rsa
[ -n "$DEBUG" ] && echo debug on ... && set -x

chmod 600 /root/.ssh/id_rsa

# saves githubs host to known_hosts
ssh -T -o StrictHostKeyChecking=no  git@github.com

git config --global user.name "$COMMIT_NAME"
git config --global user.email "$COMMIT_EMAIL"

rm -rf $REPO

git clone https://github.com/$USER_NAME/$REPO.git

CLOUDBREAK_VERSION=$(curl -Ls http://maven.sequenceiq.com/releases/com/sequenceiq/cloudbreak/maven-metadata.xml|sed -n "s/.*<version>\([^<]*\).*/\1/p" |tail -1)
CLOUDBREAK_SHELL_VERSION=$(curl -Ls http://maven.sequenceiq.com/releases/com/sequenceiq/cloudbreak-shell/maven-metadata.xml|sed -n "s/.*<version>\([^<]*\).*/\1/p" |tail -1)

echo cloudbreak version will be $CLOUDBREAK_VERSION...
echo cloudbreak-shell version will be $CLOUDBREAK_SHELL_VERSION...

cat > $REPO/Dockerfile <<EOF
FROM dockerfile/java
MAINTAINER SequenceIQ

# install the cloudbreak app
ADD https://s3-eu-west-1.amazonaws.com/maven.sequenceiq.com/releases/com/sequenceiq/cloudbreak/$CLOUDBREAK_VERSION/cloudbreak-$CLOUDBREAK_VERSION.jar /cloudbreak.jar

# install the cloudbreak-shell app
ADD https://s3-eu-west-1.amazonaws.com/maven.sequenceiq.com/releases/com/sequenceiq/cloudbreak-shell/$CLOUDBREAK_SHELL_VERSION/cloudbreak-shell-$CLOUDBREAK_SHELL_VERSION.jar /cloudbreak-shell.jar

# Install starter script for the Cloudbreak application
ADD add/start_cloudbreak_app.sh /
ADD add/wait_for_cloudbreak_api.sh /

# Install starter script for the cloudbreak shell application
ADD add/start_cloudbreak_shell_app.sh /

# add ngrok
ADD add/ngrok.zip /ngrok.zip

# Install zip
RUN apt-get install zip

RUN sudo unzip /ngrok -d /bin

WORKDIR /

ENTRYPOINT ["/start_cloudbreak_app.sh"]
EOF

cd $REPO
git config --global user.name "$COMMIT_NAME"
git config --global user.email "$COMMIT_EMAIL"
git remote rm origin
git remote add origin git@github.com:$USER_NAME/$REPO.git
git checkout -b $RELEASE_VERSION
git add -A
git commit -m "preparing release: $RELEASE_VERSION"
git push origin $RELEASE_VERSION
git tag -a $RELEASE_VERSION -m "jenkins tag for release: $RELEASE_VERSION"
git push -f --tags
