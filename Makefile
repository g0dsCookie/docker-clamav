MAJOR	?= 0
MINOR	?= 103
PATCH	?= 3

TAG	= g0dscookie/clamav
TAGLIST = -t ${TAG}:${MAJOR} -t ${TAG}:${MAJOR}.${MINOR} -t ${TAG}:${MAJOR}.${MINOR}.${PATCH}
BUILDARGS = --build-arg MAJOR=${MAJOR} --build-arg MINOR=${MINOR} --build-arg PATCH=${PATCH}
PUSH ?= --push

PLATFORM_FLAGS	= --platform linux/amd64 --platform linux/arm64

build:
	docker buildx build ${PUSH} ${PLATFORM_FLAGS} ${BUILDARGS} ${TAGLIST} .

latest: TAGLIST := -t ${TAG}:latest ${TAGLIST}
latest: build
.PHONY: build latest

amd64: PLATFORM_FLAGS := --platform linux/amd64
amd64: build
amd64-latest: TAGLIST := -t ${TAG}:latest ${TAGLIST}
amd64-latest: amd64
.PHONY: amd64 amd64-latest

arm64: PLATFORM_FLAGS := --platform linux/arm64
arm64: build
arm64-latest: TAGLIST := -t ${TAG}:latest ${TAGLIST}
arm64-latest: arm64
.PHONY: arm64 arm64-latest