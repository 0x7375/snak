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

watch build_watch lsp_watch simu_watch: SCHEME       = SnakWatch
watch build_watch lsp_watch simu_watch: SIM          = Apple Watch Series 11 (46mm)
watch build_watch lsp_watch simu_watch: BUNDLE       = me.0xaa.Snak.watchkitapp
watch build_watch lsp_watch simu_watch: DEST_OS      = watchOS
watch build_watch lsp_watch simu_watch: PRODUCTS_DIR = Debug-watchsimulator
watch build_watch lsp_watch simu_watch: APP_NAME     = SnakWatch.app

.PHONY: ios watch build_ios build_watch lsp_ios lsp_watch simu_ios simu_watch run build lsp simu ipa clean release
.DEFAULT_GOAL := ios

ios watch:           	run
build_ios build_watch:  build
lsp_ios lsp_watch:   	lsp
simu_ios simu_watch: 	simu

run: simu build
	open -g -a "InjectionNext" || true
	xcrun simctl install "$(SIM)" $(APP_PATH)
	SIMCTL_CHILD_INJECTION_PROJECT_ROOT=$(PWD) xcrun simctl launch --console "$(SIM)" $(BUNDLE)

simu:
	xcrun simctl boot "$(SIM)" || true
	open -a Simulator

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	  -destination 'platform=$(DEST_OS) Simulator,name=$(SIM)' \
	  -derivedDataPath $(BUILD_DIR) EMIT_FRONTEND_COMMAND_LINES=YES build | xcbeautify

lsp:
	xcode-build-server config -project $(PROJECT) -scheme $(SCHEME)

release: PRODUCTS_DIR = Release-iphoneos

release:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
	  -destination 'generic/platform=iOS' -derivedDataPath $(BUILD_DIR) \
	  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO build | xcbeautify
	mkdir -p $(BUILD_DIR)/ipa/Payload
	cp -R $(BUILD_DIR)/Build/Products/$(PRODUCTS_DIR)/$(APP_NAME) $(BUILD_DIR)/ipa/Payload/
	cd $(BUILD_DIR)/ipa && zip -qr $(APP_NAME:.app=.ipa) Payload
	rm -rf $(BUILD_DIR)/ipa/Payload
	cp -f $(BUILD_DIR)/ipa/$(APP_NAME:.app=.ipa) .
	@echo "$(APP_NAME:.app=.ipa) created at ./$(APP_NAME:.app=.ipa)"

clean:
	rm -rf ./.build ./buildServer.json
