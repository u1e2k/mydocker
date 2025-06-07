# ベースイメージとしてopensuse/tumbleweedを使用
FROM opensuse/tumbleweed

# LABEL maintainer="your_email@example.com"

# システムを最新の状態に更新し、Hyprlandに必要なパッケージをインストール
# mesa-dri, mesa-vulkan-drivers は描画バックエンドの依存として含めておく
RUN zypper --non-interactive ref && \
    zypper --non-interactive dup -y && \
    zypper --non-interactive install -y \
        hyprland \
    && zypper clean --all

# 新しい非rootユーザーを作成
ARG USER_NAME=hypruser
ARG USER_ID=1000
RUN useradd -m -s /bin/bash -u ${USER_ID} ${USER_NAME}

# Hyprlandの設定ファイルを配置するディレクトリを作成
ENV HOME=/home/${USER_NAME}
# Hyprlandの設定ディレクトリ
ENV HYPRLAND_CONFIG_DIR=${HOME}/.config/hypr 
RUN mkdir -p ${HYPRLAND_CONFIG_DIR}
RUN chown -R ${USER_NAME}:${USER_NAME} ${HOME}

# --- ホストからテストしたいhyprland.confを直接コピーする ---
COPY hyprland.conf ${HYPRLAND_CONFIG_DIR}/hyprland.conf
RUN chown ${USER_NAME}:${USER_NAME} ${HYPRLAND_CONFIG_DIR}/hyprland.conf

# --- テストスクリプトをコピーして実行可能にする ---
COPY run_hyprland_test.sh /usr/local/bin/run_hyprland_test.sh
RUN chmod +x /usr/local/bin/run_hyprland_test.sh

# --- 以降のコマンドを非rootユーザーで実行する ---
USER ${USER_NAME}

# --- コンテナ起動時に実行するスクリプト ---
CMD ["/usr/local/bin/run_hyprland_test.sh"]