#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import brotli
import json
import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path


def parse_godot_settings(project_path: Path) -> dict[str, dict[str, str]]:
    sections: dict[str, dict[str, str]] = {}
    current = ""
    for raw_line in project_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith(";"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1].strip()
            sections.setdefault(current, {})
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        sections.setdefault(current, {})[key.strip()] = value.strip()
    return sections


def unquote(value: str, fallback: str = "") -> str:
    text = value.strip()
    if not text:
        return fallback
    if text.startswith('"') and text.endswith('"'):
        return text[1:-1]
    return text


def replace_or_fail(source: str, needle: str, replacement: str) -> str:
    if needle not in source:
        raise SystemExit(f"wechat postprocess: missing pattern: {needle[:80]}")
    return source.replace(needle, replacement, 1)


def replace_all_or_fail(source: str, needle: str, replacement: str) -> str:
    if needle not in source:
        raise SystemExit(f"wechat postprocess: missing pattern: {needle[:80]}")
    return source.replace(needle, replacement)


def regex_replace_or_fail(source: str, pattern: str, replacement: str) -> str:
    updated, count = re.subn(pattern, replacement, source, count=1, flags=re.S)
    if count == 0:
        raise SystemExit(f"wechat postprocess: missing regex pattern: {pattern[:80]}")
    return updated


def postprocess_engine_js(source_path: Path, output_path: Path) -> None:
    source = source_path.read_text(encoding="utf-8")

    webassembly_bridge = """var __godotWxHostWebAssembly = typeof globalThis !== "undefined" && typeof globalThis.WebAssembly !== "undefined" ? globalThis.WebAssembly : typeof GameGlobal !== "undefined" && typeof GameGlobal.WebAssembly !== "undefined" ? GameGlobal.WebAssembly : void 0;
var __godotWxPathWebAssembly = typeof WXWebAssembly !== "undefined" ? WXWebAssembly : void 0;
function __godotWxWasmPath(basePath) {
  if (typeof __godotWxHostWebAssembly === "undefined" && typeof __godotWxPathWebAssembly !== "undefined") {
    return `${basePath}.wasm.br`;
  }
  return `${basePath}.wasm`;
}
if (typeof __godotWxHostWebAssembly !== "undefined") {
  if (typeof globalThis !== "undefined" && typeof globalThis.WebAssembly === "undefined") {
    globalThis.WebAssembly = __godotWxHostWebAssembly;
  }
  if (typeof GameGlobal !== "undefined" && typeof GameGlobal.WebAssembly === "undefined") {
    GameGlobal.WebAssembly = __godotWxHostWebAssembly;
  }
}
var WebAssembly = __godotWxHostWebAssembly;"""
    if "var __defProp = Object.defineProperty;" in source:
        source = replace_or_fail(
            source,
            "var __defProp = Object.defineProperty;",
            webassembly_bridge + "\nvar __defProp = Object.defineProperty;",
        )
    elif "var Godot=(()=>{" in source:
        source = replace_or_fail(
            source,
            "var Godot=(()=>{",
            webassembly_bridge + "\nvar Godot=(()=>{",
        )
    else:
        raise SystemExit("wechat postprocess: missing a known engine header for WebAssembly bridge")

    source = replace_or_fail(
        source,
        "function _godot_js_display_window_title_set(p_data){document.title=GodotRuntime.parseString(p_data)}",
        "function _godot_js_display_window_title_set(p_data){}",
    )
    source = replace_or_fail(
        source,
        "function _godot_js_display_alert(p_text){window.alert(GodotRuntime.parseString(p_text))}",
        'function _godot_js_display_alert(p_text){GodotRuntime.error(GodotRuntime.parseString(p_text))}',
    )
    source = replace_or_fail(
        source,
        "function _godot_js_eval(p_js,p_use_global_ctx,p_union_ptr,p_byte_arr,p_byte_arr_write,p_callback){const js_code=GodotRuntime.parseString(p_js);let eval_ret=null;try{if(p_use_global_ctx){const global_eval=eval;eval_ret=global_eval(js_code)}else{eval_ret=eval(js_code)}}catch(e){GodotRuntime.error(e)}",
        'function _godot_js_eval(p_js,p_use_global_ctx,p_union_ptr,p_byte_arr,p_byte_arr_write,p_callback){const js_code=GodotRuntime.parseString(p_js);let eval_ret=null;try{if(p_use_global_ctx){if(typeof globalThis!=="undefined"&&typeof globalThis.eval==="function"){eval_ret=globalThis.eval(js_code)}else if(typeof eval==="function"){eval_ret=eval(js_code)}else{throw new TypeError("global eval unavailable")}}else if(typeof eval==="function"){eval_ret=eval(js_code)}else if(typeof globalThis!=="undefined"&&typeof globalThis.eval==="function"){eval_ret=globalThis.eval(js_code)}else{throw new TypeError("eval unavailable")}}catch(e){GodotRuntime.error(e)}',
    )
    source = replace_or_fail(
        source,
        'function _godot_js_display_cursor_set_custom_shape(p_shape,p_ptr,p_len,p_hotspot_x,p_hotspot_y){const shape=GodotRuntime.parseString(p_shape);const old_shape=GodotDisplayCursor.cursors[shape];if(p_len>0){const png=new Blob([GodotRuntime.heapSlice(HEAPU8,p_ptr,p_len)],{type:"image/png"});const url=URL.createObjectURL(png);GodotDisplayCursor.cursors[shape]={url,x:p_hotspot_x,y:p_hotspot_y}}else{delete GodotDisplayCursor.cursors[shape]}if(shape===GodotDisplayCursor.shape){GodotDisplayCursor.set_shape(GodotDisplayCursor.shape)}if(old_shape){URL.revokeObjectURL(old_shape.url)}}',
        'function _godot_js_display_cursor_set_custom_shape(p_shape,p_ptr,p_len,p_hotspot_x,p_hotspot_y){const shape=GodotRuntime.parseString(p_shape);const old_shape=GodotDisplayCursor.cursors[shape];if(typeof Blob==="undefined"||typeof URL==="undefined"||typeof URL.createObjectURL!=="function"){delete GodotDisplayCursor.cursors[shape];if(shape===GodotDisplayCursor.shape){GodotDisplayCursor.set_shape(GodotDisplayCursor.shape)}if(old_shape&&old_shape.url&&typeof URL!=="undefined"&&typeof URL.revokeObjectURL==="function"){URL.revokeObjectURL(old_shape.url)}return}if(p_len>0){const png=new Blob([GodotRuntime.heapSlice(HEAPU8,p_ptr,p_len)],{type:"image/png"});const url=URL.createObjectURL(png);GodotDisplayCursor.cursors[shape]={url,x:p_hotspot_x,y:p_hotspot_y}}else{delete GodotDisplayCursor.cursors[shape]}if(shape===GodotDisplayCursor.shape){GodotDisplayCursor.set_shape(GodotDisplayCursor.shape)}if(old_shape&&old_shape.url&&typeof URL.revokeObjectURL==="function"){URL.revokeObjectURL(old_shape.url)}}',
    )
    source = replace_or_fail(
        source,
        'function _godot_js_display_window_icon_set(p_ptr,p_len){let link=document.getElementById("-gd-engine-icon");const old_icon=GodotDisplay.window_icon;if(p_ptr){if(link===null){link=document.createElement("link");link.rel="icon";link.id="-gd-engine-icon";document.head.appendChild(link)}const png=new Blob([GodotRuntime.heapSlice(HEAPU8,p_ptr,p_len)],{type:"image/png"});GodotDisplay.window_icon=URL.createObjectURL(png);link.href=GodotDisplay.window_icon}else{if(link){link.remove()}GodotDisplay.window_icon=null}if(old_icon){URL.revokeObjectURL(old_icon)}}',
        'function _godot_js_display_window_icon_set(p_ptr,p_len){let link=document.getElementById("-gd-engine-icon");const old_icon=GodotDisplay.window_icon;if(typeof Blob==="undefined"||typeof URL==="undefined"||typeof URL.createObjectURL!=="function"){if(link){link.remove()}GodotDisplay.window_icon=null;if(old_icon&&typeof URL!=="undefined"&&typeof URL.revokeObjectURL==="function"){URL.revokeObjectURL(old_icon)}return}if(p_ptr){if(link===null){link=document.createElement("link");link.rel="icon";link.id="-gd-engine-icon";document.head.appendChild(link)}const png=new Blob([GodotRuntime.heapSlice(HEAPU8,p_ptr,p_len)],{type:"image/png"});GodotDisplay.window_icon=URL.createObjectURL(png);link.href=GodotDisplay.window_icon}else{if(link){link.remove()}GodotDisplay.window_icon=null}if(old_icon&&typeof URL.revokeObjectURL==="function"){URL.revokeObjectURL(old_icon)}}',
    )
    source = replace_or_fail(
        source,
        "GodotConfig.canvas.parentElement.appendChild(ime);",
        """const imeParent = GodotConfig.canvas && GodotConfig.canvas.parentElement;\n      if (imeParent && typeof imeParent.appendChild === "function") {\n        try {\n          imeParent.appendChild(ime);\n        } catch (_error) {\n          GodotRuntime.print("Skipping IME DOM attach in WeChat runtime");\n        }\n      }""",
    )
    source = replace_or_fail(
        source,
        "_emscripten_get_now=()=>performance.now()",
        "_emscripten_get_now=()=>globalThis.nowPolyfill?globalThis.nowPolyfill():performance.now()",
    )
    source = replace_or_fail(
        source,
        "FS.mount(IDBFS,{},path)",
        "FS.mount(MEMFS,{},path)",
    )
    source = replace_or_fail(
        source,
        'function _godot_js_os_download_buffer(p_ptr,p_size,p_name,p_mime){const buf=GodotRuntime.heapSlice(HEAP8,p_ptr,p_size);const name=GodotRuntime.parseString(p_name);const mime=GodotRuntime.parseString(p_mime);const blob=new Blob([buf],{type:mime});const url=window.URL.createObjectURL(blob);const a=document.createElement("a");a.href=url;a.download=name;a.style.display="none";document.body.appendChild(a);a.click();a.remove();window.URL.revokeObjectURL(url)}',
        'function _godot_js_os_download_buffer(p_ptr,p_size,p_name,p_mime){if(typeof Blob==="undefined"||typeof window==="undefined"||typeof window.URL==="undefined"||typeof window.URL.createObjectURL!=="function"){GodotRuntime.error("Download buffer not supported in WeChat runtime");return}const buf=GodotRuntime.heapSlice(HEAP8,p_ptr,p_size);const name=GodotRuntime.parseString(p_name);const mime=GodotRuntime.parseString(p_mime);const blob=new Blob([buf],{type:mime});const url=window.URL.createObjectURL(blob);const a=document.createElement("a");a.href=url;a.download=name;a.style.display="none";document.body.appendChild(a);a.click();a.remove();window.URL.revokeObjectURL(url)}',
    )
    source = replace_all_or_fail(
        source,
        "}else if(event.data instanceof Blob){",
        '}else if(typeof Blob !== "undefined" && event.data instanceof Blob){',
    )
    source = replace_or_fail(
        source,
        """\tfunction loadFetch(file, tracker, fileSize, raw) {\n\t\ttracker[file] = {\n\t\t\ttotal: fileSize || 0,\n\t\t\tloaded: 0,\n\t\t\tdone: false,\n\t\t};\n\t\treturn fetch(file).then(function (response) {\n\t\t\tif (!response.ok) {\n\t\t\t\treturn Promise.reject(new Error(`Failed loading file '${file}'`));\n\t\t\t}\n\t\t\tconst tr = getTrackedResponse(response, tracker[file]);\n\t\t\tif (raw) {\n\t\t\t\treturn Promise.resolve(tr);\n\t\t\t}\n\t\t\treturn tr.arrayBuffer();\n\t\t});\n\t}\n""",
        """\tfunction makeLocalResponse(file, buffer, trackerEntry) {\n\t\tconst view = buffer instanceof Uint8Array ? buffer : new Uint8Array(buffer);\n\t\ttrackerEntry.total = trackerEntry.total || view.byteLength;\n\t\ttrackerEntry.loaded = view.byteLength;\n\t\ttrackerEntry.done = true;\n\t\tfunction toArrayBuffer() {\n\t\t\treturn Promise.resolve(view.buffer.slice(view.byteOffset, view.byteOffset + view.byteLength));\n\t\t}\n\t\treturn {\n\t\t\tok: true,\n\t\t\turl: file,\n\t\t\tarrayBuffer: toArrayBuffer,\n\t\t\tclone: function () {\n\t\t\t\treturn {\n\t\t\t\t\tok: true,\n\t\t\t\t\turl: file,\n\t\t\t\t\tarrayBuffer: toArrayBuffer,\n\t\t\t\t};\n\t\t\t},\n\t\t};\n\t}\n\n\tfunction loadFetch(file, tracker, fileSize, raw) {\n\t\ttracker[file] = {\n\t\t\ttotal: fileSize || 0,\n\t\t\tloaded: 0,\n\t\t\tdone: false,\n\t\t};\n\t\tconst localFetch = globalThis.fsUtils && typeof globalThis.fsUtils.localFetch === 'function' ? globalThis.fsUtils.localFetch : null;\n\t\tconst decodeLocalBuffer = globalThis.fsUtils && typeof globalThis.fsUtils.decodeLocalBuffer === 'function' ? globalThis.fsUtils.decodeLocalBuffer : null;\n\t\tconst isRemote = /^[a-zA-Z][a-zA-Z\\d+.-]*:/.test(file) && !/^https?:\\/\\/usr\\//.test(file);\n\t\tif (localFetch && !isRemote) {\n\t\t\treturn localFetch(file).then(function (buffer) {\n\t\t\t\tif (decodeLocalBuffer) {\n\t\t\t\t\treturn Promise.resolve(decodeLocalBuffer(file, buffer));\n\t\t\t\t}\n\t\t\t\treturn Promise.resolve(buffer);\n\t\t\t}).then(function (decodedBuffer) {\n\t\t\t\tconst response = makeLocalResponse(file, decodedBuffer, tracker[file]);\n\t\t\t\tif (raw) {\n\t\t\t\t\treturn Promise.resolve(response);\n\t\t\t\t}\n\t\t\t\treturn response.arrayBuffer();\n\t\t\t});\n\t\t}\n\t\treturn fetch(file).then(function (response) {\n\t\t\tif (!response.ok) {\n\t\t\t\treturn Promise.reject(new Error(`Failed loading file '${file}'`));\n\t\t\t}\n\t\t\tconst tr = getTrackedResponse(response, tracker[file]);\n\t\t\tif (raw) {\n\t\t\t\treturn Promise.resolve(tr);\n\t\t\t}\n\t\t\treturn tr.arrayBuffer();\n\t\t});\n\t}\n""",
    )
    source = replace_or_fail(
        source,
        "const cloned = new Response(response.clone().body, { 'headers': [['content-type', 'application/wasm']] });",
        "const cloned = { arrayBuffer: function () { return response.arrayBuffer(); } };",
    )
    source = replace_or_fail(
        source,
        """\t\t\t'instantiateWasm': function (imports, onSuccess) {\n\t\t\t\tfunction done(result) {\n\t\t\t\t\tonSuccess(result['instance'], result['module']);\n\t\t\t\t}\n\t\t\t\tif (typeof (WebAssembly.instantiateStreaming) !== 'undefined') {\n\t\t\t\t\tWebAssembly.instantiateStreaming(Promise.resolve(r), imports).then(done);\n\t\t\t\t} else {\n\t\t\t\t\tr.arrayBuffer().then(function (buffer) {\n\t\t\t\t\t\tWebAssembly.instantiate(buffer, imports).then(done);\n\t\t\t\t\t});\n\t\t\t\t}\n\t\t\t\tr = null;\n\t\t\t\treturn {};\n\t\t\t},\n""",
        """\t\t\t'instantiateWasm': function (imports, onSuccess) {\n\t\t\t\tfunction done(result) {\n\t\t\t\t\tonSuccess(result['instance'], result['module']);\n\t\t\t\t}\n\t\t\t\tif (typeof __godotWxHostWebAssembly === 'undefined' && typeof __godotWxPathWebAssembly !== 'undefined') {\n\t\t\t\t\tPromise.resolve(__godotWxPathWebAssembly.instantiate(__godotWxWasmPath(loadPath), imports)).then(done);\n\t\t\t\t} else if (typeof (WebAssembly.instantiateStreaming) !== 'undefined') {\n\t\t\t\t\tWebAssembly.instantiateStreaming(Promise.resolve(r), imports).then(done);\n\t\t\t\t} else {\n\t\t\t\t\tr.arrayBuffer().then(function (buffer) {\n\t\t\t\t\t\tWebAssembly.instantiate(buffer, imports).then(done);\n\t\t\t\t\t});\n\t\t\t\t}\n\t\t\t\tr = null;\n\t\t\t\treturn {};\n\t\t\t},\n""",
    )
    source = replace_or_fail(
        source,
        "return `${loadPath}.wasm`;",
        "return __godotWxWasmPath(loadPath);",
    )
    source = replace_or_fail(
        source,
        "loadPromise = preloader.loadPromise(`${loadPath}.wasm`, size, true);",
        "const wasmPath = __godotWxWasmPath(loadPath); loadPromise = preloader.loadPromise(wasmPath, size, true);",
    )
    source = replace_or_fail(
        source,
        "Engine.load(basePath, this.config.fileSizes[`${basePath}.wasm`]);",
        "const wasmPath = __godotWxWasmPath(basePath); Engine.load(basePath, this.config.fileSizes[wasmPath] || this.config.fileSizes[`${basePath}.wasm`]);",
    )
    source = replace_or_fail(
        source,
        "if (typeof window !== 'undefined') {\n\twindow['Engine'] = Engine;\n}",
        "if (typeof window !== 'undefined') {\n\twindow['Engine'] = Engine;\n}\nglobalThis['Engine'] = Engine;",
    )

    output_path.write_text(source, encoding="utf-8")


def write_brotli_bytes(source_path: Path, output_path: Path) -> tuple[int, int]:
    raw = source_path.read_bytes()
    compressed = brotli.compress(raw, quality=11)
    output_path.write_bytes(compressed)
    return len(raw), len(compressed)


def render_template(path: Path, replacements: dict[str, str]) -> None:
    content = path.read_text(encoding="utf-8")
    for key, value in replacements.items():
        content = content.replace(key, value)
    path.write_text(content, encoding="utf-8")


def write_inline_assets_module(output_path: Path, assets: dict[str, Path], build_stamp: str) -> None:
    chunk_size = 96 * 1024
    lines = [
        "'use strict'",
        "",
        "/* eslint-disable max-len */",
        f"// Generated by assemble_wechat.py at {build_stamp}.",
        ";(function installInlineAssets(globalObject) {",
        "  var root = globalObject",
        "  var inlineAssets = root.__godotWxInlineAssets || {}",
    ]
    for asset_name, asset_path in assets.items():
        encoded = base64.b64encode(asset_path.read_bytes()).decode("ascii")
        chunks = [encoded[index : index + chunk_size] for index in range(0, len(encoded), chunk_size)]
        lines.append(f"  inlineAssets[{json.dumps(asset_name)}] = [")
        for chunk in chunks:
            lines.append(f"    {json.dumps(chunk)},")
        lines.append("  ]")
    lines.extend(
        [
            "  root.__godotWxInlineAssets = inlineAssets",
            "})(typeof globalThis !== 'undefined' ? globalThis : this)",
            "",
        ]
    )
    output_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--web-dir", required=True)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()

    project_root = Path(args.project_root)
    web_dir = Path(args.web_dir)
    solution_root = Path(__file__).resolve().parents[1]
    template_dir = solution_root / "template"
    transpile_script = solution_root / "scripts" / "transpile_js.mjs"
    output_dir = Path(args.output_dir)
    minigame_dir = output_dir / "minigame"
    engine_dir = minigame_dir / "engine"

    if not web_dir.exists():
        raise SystemExit(f"wechat export: missing web dir: {web_dir}")
    if not template_dir.exists():
        raise SystemExit(f"wechat export: missing template dir: {template_dir}")
    if not transpile_script.exists():
        raise SystemExit(f"wechat export: missing transpile script: {transpile_script}")

    settings = parse_godot_settings(project_root / "project.godot")
    app_name = unquote(
        settings.get("application", {}).get("config/name", '"Godot Mini-game Prototype"'),
        "Godot Mini-game Prototype",
    )
    wechat_settings = settings.get("wechat", {})
    share_title = unquote(wechat_settings.get("share_title", f'"{app_name}"'), app_name)
    share_image_url = unquote(wechat_settings.get("share_image_url", '""'))
    app_id = unquote(wechat_settings.get("app_id", '""'))
    build_stamp = datetime.now().astimezone().isoformat(timespec="seconds")

    if minigame_dir.exists():
        shutil.rmtree(minigame_dir)
    shutil.copytree(template_dir, minigame_dir)
    engine_dir.mkdir(parents=True, exist_ok=True)

    postprocess_engine_js(web_dir / "index.js", engine_dir / "godot.js")
    subprocess.run(
        [
            "node",
            str(transpile_script),
            str(engine_dir / "godot.js"),
            str(engine_dir / "godot.js"),
        ],
        check=True,
        cwd=project_root,
    )

    raw_wasm_size, compressed_wasm_size = write_brotli_bytes(
        web_dir / "index.wasm",
        engine_dir / "godot.wasm.br",
    )
    shutil.copy2(web_dir / "index.pck", minigame_dir / "game.data.bin")
    shutil.copy2(web_dir / "index.audio.worklet.js", engine_dir / "godot.audio.worklet.js")
    shutil.copy2(web_dir / "index.audio.position.worklet.js", engine_dir / "godot.audio.position.worklet.js")
    (engine_dir / "game.js").write_text(
        "'use strict'\n\n// WeChat subpackage marker for the engine bundle.\n",
        encoding="utf-8",
    )
    write_inline_assets_module(
        minigame_dir / "js" / "inline-assets.js",
        {"game.data.bin": web_dir / "index.pck"},
        build_stamp,
    )

    replacements = {
        "__APP_ID__": app_id,
        "__PROJECT_NAME__": app_name.replace('"', "").replace("/", "-"),
        "__SHARE_TITLE__": share_title.replace("\\", "\\\\").replace("'", "\\'"),
        "__SHARE_IMAGE_URL__": share_image_url.replace("\\", "\\\\").replace("'", "\\'"),
        "__BUILD_STAMP__": build_stamp,
    }
    render_template(minigame_dir / "game.js", replacements)
    render_template(minigame_dir / "project.config.json", replacements)
    render_template(minigame_dir / "project.private.config.json", replacements)

    manifest = {
        "route": "wechat",
        "build_stamp": build_stamp,
        "app_id": app_id,
        "project_name": app_name,
        "template_source": str(template_dir.relative_to(project_root)),
        "wasm_raw_size": raw_wasm_size,
        "wasm_compressed_size": compressed_wasm_size,
        "main_files": sorted(str(path.relative_to(minigame_dir)) for path in minigame_dir.iterdir() if path.is_file()),
        "engine_files": sorted(str(path.relative_to(minigame_dir)) for path in engine_dir.rglob("*") if path.is_file()),
    }
    (minigame_dir / "wechat-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
