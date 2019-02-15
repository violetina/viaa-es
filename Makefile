PROJECT=sc-avo2
APP_NAME=es
WD=/tmp
REPO_URI=https://github.com/violetina/viaa-es.git
GIT_NAME=viaa-es.git
TAG=${ENV}
#compose.yaml  data-persistentvolumeclaim.yaml  solr-deploymentconfig.yaml  solr-imagestream.yaml  solr-service.yaml
#slaafje=`oc get pods | grep slaafje | cut -d ' ' -f 1 `
podname=`oc get pods | grep solr | cut -d ' ' -f 1 |grep -v deploy`
#set_policy=set_policy ha-fed ".*" '{"ha-mode":"all"}' --priority 1 --apply-to queues
TOKEN=`oc whoami -t`
path_to_oc=`which oc`
oc_registry=docker-registry-default.apps.do-prd-okp-m0.do.viaa.be
.ONESHELL:
SHELL = /bin/bash
.PHONY:	all
check-env:
ifndef ENV
  ENV=prd
endif
OC_PROJECT=sc-avo2
ifndef BRANCH
  BRANCH=master
endif
commit:
	git add .
	git commit -a
	git push
checkTools:
	if [ -x "${path_to_executable}" ]; then  echo "OC tools found here: ${path_to_executable}"; else echo please install the oc tools: https://github.com/openshiftorigin/releases/tag/v3.9.0; fi; uname && netstat | grep docker| grep -e CONNECTED  1> /dev/null || echo docker not running or not using linux
login:	check-env
	oc login do-prd-okp-m0.do.viaa.be:8443
	oc project "${OC_PROJECT}" ||  oc new-project "${OC_PROJECT}"
	#oc adm policy add-scc-to-user anyuid system:serviceaccount:${OC_PROJECT}:default --as system:admin --as-group system:admins -n ${APP_NAME}
	#openshift.io/sa.scc.uid-range: 8983/1
	#oc edit namespace solr-${ENV}
	oc adm policy add-scc-to-user privileged -n ${OC_PROJECT} -z default
	docker login -p "${TOKEN}" -u unused ${oc_registry}
#	oc get imagestream  "${OC_PROJECT}" || oc create imagestream  "${OC_PROJECT}"

clone:
	cd /tmp && git clone  --single-branch -b ${BRANCH} "${REPO_URI}" 
buildimage:
	cd /tmp/${GIT_NAME}
	docker build -t ${oc_registry}/${OC_PROJECT}/${APP_NAME}:${TAG} .
push:
	docker push ${oc_registry}/${OC_PROJECT}/${APP_NAME}:${TAG}
deploy:
	oc create -f openshift/es-cluster-tmpl.yaml
clean:
	rm -rf /tmp/${GIT_NAME}
podshell:
	oc exec -ti `oc get pods | grep solr | cut -d ' ' -f 1 |grep -v deplo`  bash
delete:
	oc delete dc/solr-${ENV}
all:	clean login commit clone buildimage push deploy clean


