docker-pull:
	docker pull rocker/tidyverse:4.3.1

.PHONY: build-image
build-image: docker-pull \
             $(call print-help,build, "Build the docker image.")
	docker build -t reactome/statistics-generator:1.0.0 .

.PHONY: run-image
run-image: $(call print-help,run, "Run the docker image.")
	docker run reactome/statistics-generator:1.0.0 -v $(pwd)/output:/output --net=host
