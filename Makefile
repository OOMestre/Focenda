.PHONY: all test build staging release-beta release-notes clean

all: staging

test:
	swift test

build:
	swift build -c release

staging:
	./scripts/build-staging.sh

release-beta:
	./scripts/release-staging-beta.sh

release-notes:
	./scripts/generate-release-notes.sh

clean:
	rm -rf .build dist
