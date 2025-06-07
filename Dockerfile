# ベースイメージとしてopensuse/tumbleweedを使用
FROM opensuse/tumbleweed

# メンテナ情報を設定（任意）
# LABEL maintainer="your_email@example.com"

# システムを最新の状態に更新し、Hyprlandに必要なパッケージをインストール
# GUIなしでの起動試行でも、グラフィック関連の最小限の依存パッケージは含めておく
RUN zypper --non-interactive ref && \
    zypper --non-interactive dup -y && \
    zypper --non-interactive install -y hyprland pciutils && \
    zypper clean --all

# 新しい非rootユーザーを作成
ARG USER_NAME=hypruser
ARG USER_ID=1000
RUN useradd -m -s /bin/bash -u ${USER_ID} ${USER_NAME}

# Hyprlandの設定ファイルを配置するディレクトリを作成
ENV HYPRLAND_CONFIG_DIR=/home/${USER_NAME}/.config/hypr
RUN mkdir -p ${HYPRLAND_CONFIG_DIR}

# ホストからテストしたいhyprland.confをコピーする
COPY hyprland.conf ${HYPRLAND_CONFIG_DIR}/hyprland.conf
RUN chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# 以降のコマンドを非rootユーザーで実行する
USER ${USER_NAME}

# コンテナ起動時に実行するスクリプト
CMD ["/bin/bash", "-c", " \
    echo 'Attempting Hyprland config syntax check without full GUI environment...'; \
    export XDG_RUNTIME_DIR=$(mktemp -d); \
    export HYPRLAND_LOG_LEVEL=0; \
    export HYPRLAND_LOG_FILE=${XDG_RUNTIME_DIR}/hyprland.log; \
    \
    # Hyprlandを起動し、バックグラウンドでクラッシュしても良いようにする
    # SIGTERM (15) を送って、プロセスが正常に終了するようにする
    /usr/bin/Hyprland & HYPRLAND_PID=$!; \
    sleep 5; \
    \
    # Hyprlandプロセスが存在すれば終了させる (クラッシュしていなければ)
    if kill -0 $HYPRLAND_PID 2>/dev/null; then \
        kill $HYPRLAND_PID; \
        wait $HYPRLAND_PID 2>/dev/null; \
    fi; \
    \
    echo ''; \
    echo '--- Hyprland Config Check Log ---'; \
    if [ -f \"${HYPRLAND_LOG_FILE}\" ]; then \
        cat \"${HYPRLAND_LOG_FILE}\"; \
        if grep -q -iE 'error|warning|unknown command|invalid argument' \"${HYPRLAND_LOG_FILE}\"; then \
            echo '!!! Config check detected potential errors/warnings in hyprland.conf. !!!'; \
            RESULT=1; \
        else \
            echo 'No critical errors or warnings detected in hyprland.conf.'; \
            RESULT=0; \
        fi; \
    else \
        echo 'Hyprland log file not found. Hyprland might have crashed too early.'; \
        RESULT=1; \
    fi; \
    echo '---------------------------------'; \
    \
    rm -rf $XDG_RUNTIME_DIR; \
    exit $RESULT; \
"]