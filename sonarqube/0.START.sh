#!/bin/bash



# Sonarqube
helm upgrade -i sonarqube sonarqube/sonarqube \
	-n sonarqube \
	--create-namespace \
	--debug \
	-f values.yaml
