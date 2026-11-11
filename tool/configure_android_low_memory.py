#!/usr/bin/env python3
"""Opt-in low-memory profile for generated Android builds in constrained hosts.
Disables Java shrinking and native release lint, not Flutter analysis/tests.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def main():
    properties = ROOT / "android/gradle.properties"
    settings = {
        "org.gradle.jvmargs": "-Xmx768m -XX:MaxMetaspaceSize=384m -XX:ReservedCodeCacheSize=128m -XX:+HeapDumpOnOutOfMemoryError",
        "org.gradle.workers.max": "1",
        "org.gradle.daemon": "false",
        "org.gradle.parallel": "false",
        "org.gradle.internal.instrumentation.agent": "false",
        "kotlin.compiler.execution.strategy": "in-process",
        "kotlin.daemon.jvmargs": "-Xmx384m",
    }
    lines = properties.read_text().splitlines()
    lines = [line for line in lines if line.partition("=")[0] not in settings]
    properties.write_text("\n".join(lines + [f"{k}={v}" for k, v in settings.items()]) + "\n")
    app = ROOT / "android/app/build.gradle.kts"
    text = app.read_text()
    if "checkReleaseBuilds = false" not in text:
        if "    buildTypes {" not in text:
            raise ValueError("Unsupported generated Android build script")
        text = text.replace("    buildTypes {", "    lint {\n        checkReleaseBuilds = false\n    }\n\n    buildTypes {", 1)
    if "isMinifyEnabled = false" not in text:
        if "        release {" not in text:
            raise ValueError("Missing Android release build type")
        text = text.replace("        release {", "        release {\n            isMinifyEnabled = false\n            isShrinkResources = false", 1)
    app.write_text(text)
    print("Low-memory Android profile: heap 768 MiB, one worker, native lint and Java shrinking disabled")

if __name__ == "__main__":
    main()
