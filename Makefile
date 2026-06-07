.PHONY: build run app dmg install uninstall clean

build:
	swift build

run: build
	.build/debug/ClipboardHistory

app:
	./scripts/build-app.sh

dmg: app
	./scripts/create-dmg.sh

install: app
	cp -r dist/ClipboardHistory.app /Applications/
	open /Applications/ClipboardHistory.app
	@echo "✓ Installed to /Applications/ClipboardHistory.app"

uninstall:
	rm -rf /Applications/ClipboardHistory.app
	@echo "✓ Removed from /Applications"

clean:
	rm -rf .build dist
