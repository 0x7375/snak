SHELL := /bin/bash -o pipefail

PROJECT      = Snak.xcodeproj
BUILD_DIR    = ./.build/Snak

SCHEME       = Snak
SIM          = iPhone 17
BUNDLE       = me.0xaa.Snak
DEST_OS      = iOS
PRODUCTS_DIR = Debug-iphonesimulator
APP_NAME     = Snak.app
APP_PATH     = $(BUILD_DIR)/Build/Products/$(PRODUCTS_DIR)/$(APP_NAME)

watch lsp_watch simu_watch: SCHEME       = SnakWatch
watch lsp_watch simu_watch: SIM          = Apple Watch Series 11 (46mm)
watch lsp_watch simu_watch: BUNDLE       = me.0xaa.Snak.watchkitapp
watch lsp_watch simu_watch: DEST_OS      = watchOS
watch lsp_watch simu_watch: PRODUCTS_DIR = Debug-watchsimulator
watch lsp_watch simu_watch: APP_NAME     = SnakWatch.app

.PHONY: ios watch lsp_ios lsp_watch simu_ios simu_watch run lsp simu ipa clean
.DEFAULT_GOAL := ios

ios watch:           run
lsp_ios lsp_watch:   lsp
simu_ios simu_watch: simu

run:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination 'platform=$(DEST_OS) Simulator,name=$(SIM)' \
	  -derivedDataPath $(BUILD_DIR) EMIT_FRONTEND_COMMAND_LINES=YES build | xcbeautify
	xcrun simctl install "$(SIM)" $(APP_PATH)
	SIMCTL_CHILD_INJECTION_PROJECT_ROOT=$(PWD) xcrun simctl launch --console "$(SIM)" $(BUNDLE)

lsp:
	xcode-build-server config -project $(PROJECT) -scheme $(SCHEME)

simu:
	xcrun simctl boot "$(SIM)" || true
	open -a Simulator


release: PRODUCTS_DIR = Release-iphoneos

release:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
	  -destination 'generic/platform=iOS' -derivedDataPath $(BUILD_DIR) \
	  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO build | xcbeautify
	mkdir -p $(BUILD_DIR)/ipa/Payload
	cp -R $(BUILD_DIR)/Build/Products/$(PRODUCTS_DIR)/$(APP_NAME) $(BUILD_DIR)/ipa/Payload/
	cd $(BUILD_DIR)/ipa && zip -qr $(APP_NAME:.app=.ipa) Payload
	rm -rf $(BUILD_DIR)/ipa/Payload
	@echo "$(APP_NAME:.app=.ipa) created at $(BUILD_DIR)/ipa/$(APP_NAME:.app=.ipa)"

clean:
	rm -rf ./.build ./buildServer.json
