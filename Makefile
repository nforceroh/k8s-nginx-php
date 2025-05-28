#!/usr/bin/make -f

SHELL := /bin/bash
IMG_NAME := alpine-nginx
IMG_REPO := nforceroh
DOCKERCMD := docker
VERSION := php83

#oc get route default-route -n openshift-image-registry
#podman login -u sylvain -p $(oc whoami -t) default-route-openshift-image-registry.apps.ocp.nf.lab

.PHONY: all build push gitcommit gitpush create
all: build push 
git: gitcommit gitpush 

build: 
	@echo "Building $(IMG_NAME) image"
	$(DOCKERCMD) build \
		--tag $(IMG_REPO)/$(IMG_NAME) . --no-cache

push: 
	@echo "Tagging and Pushing $(IMG_NAME):$(VERSION) image"
	$(DOCKERCMD) tag $(IMG_REPO)/$(IMG_NAME) docker.io/$(IMG_REPO)/$(IMG_NAME):$(VERSION)
	$(DOCKERCMD) tag $(IMG_REPO)/$(IMG_NAME) docker.io/$(IMG_REPO)/$(IMG_NAME):latest
	$(DOCKERCMD) push docker.io/$(IMG_REPO)/$(IMG_NAME):$(VERSION)
	$(DOCKERCMD) push docker.io/$(IMG_REPO)/$(IMG_NAME):latest

end:
	@echo "Done!"