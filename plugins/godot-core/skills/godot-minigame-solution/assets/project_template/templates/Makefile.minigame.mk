GODOT ?= godot
ROOT_DIR := $(CURDIR)

.PHONY: minigame-preflight export-wechat wechat-smoke prepare-douyin export-douyin export-douyin-raw douyin-smoke

minigame-preflight:
	python3 tools/minigame_preflight.py

export-wechat:
	GODOT=$(GODOT) bash tools/wechat/export_wechat.sh build/wechat-minigame

wechat-smoke:
	bash tools/wechat/smoke_test.sh build/wechat-minigame

prepare-douyin:
	python3 addons/minigame_solution/douyin/scripts/sync_ttsdk_overlay.py --project-root $(ROOT_DIR)

export-douyin:
	bash tools/douyin/export.sh build/tt-minigame $(GODOT)

export-douyin-raw: prepare-douyin
	$(GODOT) --headless --export-release Douyin build/tt-minigame/project.config.json --path .
	@printf 'Douyin raw artifact: %s\n' '$(ROOT_DIR)/build/tt-minigame'

douyin-smoke:
	bash tools/douyin_smoke_test.sh build/tt-minigame
