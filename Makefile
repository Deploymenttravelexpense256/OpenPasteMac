.PHONY: build run app dmg install uninstall clean

build:
	swift build

run: build
	.build/debug/OpenPasteMac

app:
	./scripts/build-app.sh

dmg: app
	./scripts/create-dmg.sh

install: app
	cp -r dist/OpenPasteMac.app /Applications/
	open /Applications/OpenPasteMac.app
	@echo "✓ Installed to /Applications/OpenPasteMac.app"

uninstall:
	rm -rf /Applications/OpenPasteMac.app
	@echo "✓ Removed from /Applications"

clean:
	rm -rf .build dist
