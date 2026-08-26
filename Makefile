.PHONY: all test build staging clean

all: staging

test:
	swift test

build:
	swift build -c release

staging:
	./scripts/build-staging.sh

clean:
	rm -rf .build dist
