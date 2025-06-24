#!/bin/bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
else
    OS="linux"
fi

BASE_CONTAINER_NAME="nexus-node"
IMAGE_NAME="nexus-node:latest"
LOG_DIR="$HOME/nexus_logs"

# 通用提示等待
function press_any_key() {
    echo "按任意键继续..."
    read -r _
}

# 检查 Docker 是否安装
function check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "请先安装 Docker，macOS 建议安装 Docker Desktop"
        exit 1
    fi
}

# 检查 Node.js/npm/pm2 是否安装
function check_pm2() {
    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        echo "请先安装 Node.js 和 npm，macOS 推荐使用 brew 安装：brew install node"
        exit 1
    fi
    if ! command -v pm2 >/dev/null 2>&1; then
        echo "请先安装 pm2：npm install -g pm2"
        exit 1
    fi
}

# sed 替换兼容
function sed_replace() {
    if [[ "$OS" == "mac" ]]; then
        sed -i '' "$1" "$2"
    else
        sed -i "$1" "$2"
    fi
}

# 清屏兼容
function safe_clear() {
    if command -v clear >/dev/null 2>&1; then
        clear
    fi
}

# 其余函数请保持不变，注意把所有的 read -p 全部替换为 press_any_key 调用

# 示例：替换 read -p
# 原写法：read -p "按任意键返回菜单"
# 改成：press_any_key

# 示例：sed 使用
# 原写法：sed -i 's/xxx/yyy/g' filename
# 改成：sed_replace 's/xxx/yyy/g' filename

# 定时任务兼容
function setup_log_cleanup_cron() {
    local cron_job="0 3 */2 * * find $LOG_DIR -type f -name 'nexus-*.log' -mtime +2 -delete"
    (crontab -l 2>/dev/null | grep -v -F "$cron_job"; echo "$cron_job") | crontab -
    echo "已设置每2天自动清理日志任务。"
}

# 脚本入口
setup_log_cleanup_cron

while true; do
    safe_clear
    echo "脚本由哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
    echo "如有问题，可联系推特，仅此只有一个号"
    echo "========== Nexus 多节点管理 =========="
    echo "1. 安装并启动新节点"
    echo "2. 显示所有节点状态"
    echo "3. 批量停止并卸载指定节点"
    echo "4. 查看指定节点日志"
    echo "5. 批量节点轮换启动"
    echo "6. 删除全部节点"
    echo "7. 退出"
    echo "==================================="

    read -rp "请输入选项(1-7): " choice

    case $choice in
        1)
            check_docker
            read -rp "请输入您的 node-id: " NODE_ID
            if [ -z "$NODE_ID" ]; then
                echo "node-id 不能为空，请重新选择。"
                press_any_key
                continue
            fi
            echo "开始构建镜像并启动容器..."
            build_image
            run_container "$NODE_ID"
            press_any_key
            ;;
        2)
            list_nodes
            ;;
        3)
            batch_uninstall_nodes
            ;;
        4)
            select_node_to_view
            ;;
        5)
            check_docker
            batch_rotate_nodes
            ;;
        6)
            uninstall_all_nodes
            ;;
        7)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效选项，请重新输入。"
            press_any_key
            ;;
    esac

    # 适配所有子菜单也请把 read -p 全部换成 press_any_key
    # 其余函数逻辑无需变，只需兼容上面几个关键点

done
