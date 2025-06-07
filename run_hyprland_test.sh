#!/bin/bash

echo '--- Starting Hyprland Config Test ---'
RESULT=0

# --- Hyprland Config Test (with Headless Output) ---
echo ''
echo '--- Running Hyprland Config Test ---'
export XDG_RUNTIME_DIR=$(mktemp -d)
export HYPRLAND_LOG_LEVEL=0
export HYPRLAND_LOG_FILE=${XDG_RUNTIME_DIR}/hyprland.log

# Hyprlandをバックグラウンドで起動
/usr/bin/Hyprland & HYPRLAND_PID=$!

# Hyprlandが起動するのを少し待つ
echo 'Waiting for Hyprland to start...'
sleep 3

# ヘッドレスモニターを作成するコマンドを実行
echo 'Attempting to create headless monitor...'
if hyprctl output create headless; then
    echo 'Headless monitor created successfully.'
    hyprctl monitors
    HYPRLAND_START_SUCCESS=0
else
    echo '!!! Failed to create headless monitor with hyprctl. Hyprland may still crash. !!!'
    HYPRLAND_START_SUCCESS=1
fi

# Hyprlandが正常に起動し、ヘッドレスモニターを作成できたか確認
if [ $HYPRLAND_START_SUCCESS -ne 0 ]; then
    echo '!!! Hyprland failed to start or create headless monitor. Further config checks will be unreliable. !!!'
    RESULT=1
else
    echo 'Hyprland appears to have started in a functional (headless) state.'
    # Hyprlandが起動したので、ここで `hyprctl reload` を実行して設定を再読み込みしてみる
    echo 'Attempting hyprctl reload...'
    if hyprctl reload; then
        echo 'Hyprland config reload successful.'
    else
        echo '!!! Hyprland config reload failed. Review hyprland.log for errors. !!!'
        RESULT=1
    fi
fi

# Hyprlandプロセスを終了させる
if kill -0 $HYPRLAND_PID 2>/dev/null; then
    kill $HYPRLAND_PID
    wait $HYPRLAND_PID 2>/dev/null
fi

echo ''
echo '--- Hyprland Log Output (for debugging) ---'
if [ -f "${HYPRLAND_LOG_FILE}" ]; then
    cat "${HYPRLAND_LOG_FILE}"
    if grep -q -iE 'error|warning|unknown command|invalid argument|failed to parse' "${HYPRLAND_LOG_FILE}"; then
        echo '!!! Hyprland log contains potential errors/warnings in config. !!!'
        RESULT=1
    else
        echo 'No critical errors or warnings detected in hyprland.log regarding config.'
    fi
else
    echo 'Hyprland log file not found or empty. Hyprland might have crashed too early.'
    RESULT=1 # ログがない場合はエラーとみなす
fi
echo '---------------------------------------------'
rm -rf $XDG_RUNTIME_DIR

echo ''
echo '--- All Checks Complete ---'
exit $RESULT