use std::collections::HashSet;
use std::path::Path;
use std::sync::Mutex;
use std::time::Instant;
use tauri::Emitter;

// 单个下载任务（含完整状态）
#[derive(Clone, Debug)]
struct DownloadTask {
    url: String,
    file_path: String,
    download_id: String,
    paused: bool,
    cancelled: bool,
    // 是否为 AI 站（决定下载 i.iwara.tv 图片时携带的 Referer/X-Site 头）
    is_ai: bool,
}

// 单一有序队列：位置决定优先级
// 前 max_concurrent 个非暂停、非取消的项为活跃下载
static DOWNLOAD_QUEUE: once_cell::sync::Lazy<Mutex<Vec<DownloadTask>>> =
    once_cell::sync::Lazy::new(|| Mutex::new(Vec::new()));

// 已生成 execute_download 任务的 download_id 集合（避免重复启动）
static ACTIVE_DOWNLOADS: once_cell::sync::Lazy<Mutex<HashSet<String>>> =
    once_cell::sync::Lazy::new(|| Mutex::new(HashSet::new()));


/// 下载视频/图片文件到本地（支持队列）
/// is_ai: 可选参数，用于 i.iwara.tv 图片下载时区分主站(www.iwara.tv)与AI站(www.iwara.ai)的 Referer/X-Site
#[tauri::command]
async fn download_video(
    app: tauri::AppHandle,
    url: String,
    file_path: String,
    download_id: String,
    max_concurrent: usize,
    is_ai: Option<bool>,
) -> Result<String, String> {
    // 1. 检查是否已在队列中（防重复入队）
    {
        let queue = DOWNLOAD_QUEUE.lock().unwrap();
        if queue.iter().any(|t| t.download_id == download_id) {
            // 已在队列中：返回当前状态
            let active = ACTIVE_DOWNLOADS.lock().unwrap();
            return if active.contains(&download_id) {
                Ok("downloading".to_string())
            } else {
                // 更新 url、file_path 和 is_ai（可能前台传了更新的路径/站点）
                drop(active);
                drop(queue);
                let mut queue = DOWNLOAD_QUEUE.lock().unwrap();
                if let Some(task) = queue.iter_mut().find(|t| t.download_id == download_id) {
                    task.url = url;
                    task.file_path = file_path;
                    task.is_ai = is_ai.unwrap_or(false);
                }
                Ok("queued".to_string())
            };
        }
    }

    // 2. 加入队列末尾
    {
        let mut queue = DOWNLOAD_QUEUE.lock().unwrap();
        queue.push(DownloadTask {
            url: url.clone(),
            file_path: file_path.clone(),
            download_id: download_id.clone(),
            paused: false,
            cancelled: false,
            is_ai: is_ai.unwrap_or(false),
        });
    }

    // 3. 尝试启动下载（若该任务在活跃区域内）
    let should_start = {
        let queue = DOWNLOAD_QUEUE.lock().unwrap();
        let mut non_paused_count = 0usize;
        for task in queue.iter() {
            if task.download_id == download_id {
                break; // 找到自己，当前计数即前面的非暂停项数
            }
            if !task.paused && !task.cancelled {
                non_paused_count += 1;
            }
        }
        non_paused_count < max_concurrent
    };

    if should_start {
        let mut active = ACTIVE_DOWNLOADS.lock().unwrap();
        if !active.contains(&download_id) {
            active.insert(download_id.clone());
            drop(active);
            let app_clone = app.clone();
            let d_id = download_id.clone();
            tokio::task::spawn(async move {
                let _ = execute_download(app_clone, d_id, max_concurrent).await;
            });
        }
        Ok("downloading".to_string())
    } else {
        let _ = app.emit("download-queued", serde_json::json!({
            "download_id": download_id
        }));
        Ok("queued".to_string())
    }
}

/// 处理队列：启动前 max_concurrent 个非暂停/非取消且尚未启动的任务
fn process_queue(app: &tauri::AppHandle, max_concurrent: usize) {
    let mut to_start: Vec<String> = Vec::new();
    {
        let queue = DOWNLOAD_QUEUE.lock().unwrap();
        let active = ACTIVE_DOWNLOADS.lock().unwrap();
        let mut slot = 0usize;
        for task in queue.iter() {
            if task.cancelled { continue; }
            if task.paused { continue; }
            if slot >= max_concurrent { break; }
            if !active.contains(&task.download_id) {
                to_start.push(task.download_id.clone());
            }
            slot += 1;
        }
    }

    for id in to_start {
        let mut active = ACTIVE_DOWNLOADS.lock().unwrap();
        if active.contains(&id) { continue; }
        active.insert(id.clone());
        drop(active);
        let app_clone = app.clone();
        tokio::task::spawn(async move {
            let _ = execute_download(app_clone, id, max_concurrent).await;
        });
    }
}

/// 执行单个下载任务（由 tokio::spawn 异步运行）
async fn execute_download(
    app: tauri::AppHandle,
    download_id: String,
    max_concurrent: usize,
) -> Result<String, String> {
    // 从队列中获取下载参数
    let (url, file_path, is_ai) = {
        let queue = DOWNLOAD_QUEUE.lock().unwrap();
        let task = queue.iter().find(|t| t.download_id == download_id);
        match task {
            Some(t) => (t.url.clone(), t.file_path.clone(), t.is_ai),
            // cancel_download 已移除队列项，视为已取消
            None => return Err("下载已取消_从队列移除".to_string()),
        }
    };

    let result = download_inner(&app, &url, &file_path, &download_id, is_ai).await;

    // 根据结果处理队列和事件
    match &result {
        Ok(final_path) => {
            // 下载完成 → 从队列移除
            remove_from_queue(&download_id);
            let _ = app.emit("download-progress", serde_json::json!({
                "download_id": download_id,
                "downloaded": 0, "total": 0,
                "speed": 0, "percentage": 100,
                "status": "completed", "file_path": final_path
            }));
        }
        Err(e) => {
            if e == "暂停让出" {
                // 暂停让出：不移除队列，由 pause_download 已移至位置 max_concurrent
                let _ = app.emit("download-paused", serde_json::json!({
                    "download_id": download_id
                }));
            } else {
                // 失败或取消 → 从队列移除
                remove_from_queue(&download_id);
                let status = if e.contains("已取消") { "cancelled" } else { "failed" };
                let _ = app.emit("download-failed", serde_json::json!({
                    "download_id": download_id, "error": e, "status": status
                }));
            }
        }
    }

    // 清理活跃标记
    {
        let mut active = ACTIVE_DOWNLOADS.lock().unwrap();
        active.remove(&download_id);
    }

    // 启动队列中下一个待下载任务
    process_queue(&app, max_concurrent);

    result
}

/// 从队列中移除指定下载
fn remove_from_queue(download_id: &str) {
    let mut queue = DOWNLOAD_QUEUE.lock().unwrap();
    queue.retain(|d| d.download_id != download_id);
}

/// 实际下载逻辑，返回实际写入的文件路径
async fn download_inner(
    app: &tauri::AppHandle,
    url: &str,
    file_path: &str,
    download_id: &str,
    is_ai: bool,
) -> Result<String, String> {
    let original_path = Path::new(file_path);

    // 检查是否存在可续传的局部文件
    let existing_size = if original_path.exists() {
        std::fs::metadata(original_path).map(|m| m.len()).unwrap_or(0)
    } else {
        0
    };

    // 构建 HTTP 请求（续传时加 Range 头）
    let client = reqwest::Client::builder()
        .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        .build()
        .map_err(|e| format!("创建HTTP客户端失败: {}", e))?;

    let mut request = client.get(url);
    let try_resume = existing_size > 0;
    if try_resume {
        request = request.header("Range", format!("bytes={}-", existing_size));
    }

    // i.iwara.tv 图片存在防盗链，需携带 Referer/X-Site 头（与前端 getImageIwara 保持一致），
    // 否则服务器返回 403，导致插画离线缓存失败。
    // 主站与 AI 站的 Referer/X-Site 不同，需根据 is_ai 区分（is_ai=true → www.iwara.ai）。
    if url.contains("i.iwara.tv") || url.contains("www.iwara.tv") || url.contains("iwara.ai") {
        let (referer, x_site) = if is_ai {
            ("https://www.iwara.ai/", "www.iwara.ai")
        } else {
            ("https://www.iwara.tv/", "www.iwara.tv")
        };
        request = request.header("Referer", referer);
        request = request.header("X-Site", x_site);
    }

    let response = request
        .send()
        .await
        .map_err(|e| format!("请求失败: {}", e))?;

    // 检查响应状态码：非 2xx（如 403 防盗链、404 不存在）直接报错，
    // 避免把错误页面内容当作图片写入本地文件。
    let status = response.status();
    if !status.is_success() {
        return Err(format!("下载失败: 服务器返回 HTTP {}", status.as_u16()));
    }

    // 判断服务器是否支持续传（206 Partial Content，属 2xx 范围）
    let is_partial = status == reqwest::StatusCode::PARTIAL_CONTENT;

    // 确定最终文件名和初始偏移量
    let (final_path, initial_offset) = if try_resume && is_partial {
        // 续传：使用原路径，从已有大小处继续
        (file_path.to_string(), existing_size)
    } else {
        // 新下载或服务器不支持续传 → 用 resolve_file_path 避免覆盖
        (resolve_file_path(file_path), 0u64)
    };

    let path = Path::new(&final_path);
    let total_size = if is_partial {
        existing_size + response.content_length().unwrap_or(0)
    } else {
        response.content_length().unwrap_or(0)
    };
    let mut downloaded: u64 = initial_offset;
    let mut last_emit_time = Instant::now();
    let start_time = Instant::now();

    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).map_err(|e| format!("创建目录失败: {}", e))?;
    }

    // 续传用追加模式，新下载用创建模式
    let mut file: std::fs::File = if is_partial {
        std::fs::OpenOptions::new()
            .write(true)
            .append(true)
            .open(path)
            .map_err(|e| format!("打开文件失败: {}", e))?
    } else {
        std::fs::File::create(path).map_err(|e| format!("创建文件失败: {}", e))?
    };

    let mut stream = response.bytes_stream();
    use futures_util::StreamExt;

    while let Some(chunk_result) = stream.next().await {
        // 从单一队列检查当前任务的暂停/取消状态
        {
            let queue = DOWNLOAD_QUEUE.lock().unwrap();
            if let Some(task) = queue.iter().find(|t| t.download_id == download_id) {
                if task.cancelled {
                    let _ = std::fs::remove_file(path);
                    return Err("下载已取消".to_string());
                }
                if task.paused {
                    // 暂停让出：不删除文件，返回特殊标记
                    return Err("暂停让出".to_string());
                }
            } else {
                // 队列中找不到该任务（如 cancel_download 已将其移除）→ 视为取消
                let _ = std::fs::remove_file(path);
                return Err("下载已取消".to_string());
            }
        }

        let chunk = chunk_result.map_err(|e| format!("读取数据失败: {}", e))?;
        use std::io::Write;
        file.write_all(&chunk).map_err(|e| format!("写入文件失败: {}", e))?;

        downloaded += chunk.len() as u64;

        let elapsed = last_emit_time.elapsed();
        if elapsed.as_millis() >= 500 || downloaded == chunk.len() as u64 {
            let total_elapsed = start_time.elapsed().as_secs_f64();
            let speed = if total_elapsed > 0.0 {
                (downloaded as f64 / total_elapsed) as u64
            } else {
                0
            };

            let _ = app.emit("download-progress", serde_json::json!({
                "download_id": download_id,
                "downloaded": downloaded,
                "total": total_size,
                "speed": speed,
                "percentage": if total_size > 0 {
                    (downloaded as f64 / total_size as f64 * 100.0) as u32
                } else { 0 },
                "file_path": final_path
            }));
            last_emit_time = Instant::now();
        }
    }

    Ok(final_path)
}

/// 处理文件名冲突：若文件已存在，追加 .1 .2 ...
fn resolve_file_path(original: &str) -> String {
    let path = Path::new(original);
    if !path.exists() {
        return original.to_string();
    }

    let parent = path.parent().unwrap_or(Path::new(""));
    let stem = path.file_stem().and_then(|s| s.to_str()).unwrap_or("file");
    let ext = path.extension().and_then(|s| s.to_str()).map(|e| format!(".{}", e)).unwrap_or_default();

    for i in 1..1000 {
        let new_name = format!("{}.{}{}", stem, i, ext);
        let new_path = parent.join(&new_name);
        if !new_path.exists() {
            return new_path.to_string_lossy().to_string();
        }
    }
    original.to_string() // 兜底
}

/// 暂停下载：标记暂停，并将该任务移至队列第 max_concurrent 位（若在活跃区）
#[tauri::command]
fn pause_download(download_id: String, max_concurrent: usize) {
    let mut queue = DOWNLOAD_QUEUE.lock().unwrap();
    if let Some(pos) = queue.iter().position(|d| d.download_id == download_id) {
        // 标记暂停
        queue[pos].paused = true;
        // 若在活跃区（前 max_concurrent 位），移至第 max_concurrent 位
        let target = max_concurrent.min(queue.len().saturating_sub(1));
        if pos < target {
            let task = queue.remove(pos);
            queue.insert(target, task);
        }
    }
}

/// 取消暂停信号（用于下载循环尚未让出时的快速取消暂停）
#[tauri::command]
fn unpause_download(download_id: String) {
    let mut queue = DOWNLOAD_QUEUE.lock().unwrap();
    if let Some(task) = queue.iter_mut().find(|d| d.download_id == download_id) {
        task.paused = false;
    }
}

/// 取消指定下载：标记取消并从队列移除
#[tauri::command]
fn cancel_download(download_id: String) {
    {
        let mut queue = DOWNLOAD_QUEUE.lock().unwrap();
        if let Some(task) = queue.iter_mut().find(|d| d.download_id == download_id) {
            task.cancelled = true;
        }
    }
    remove_from_queue(&download_id);
}

/// 恢复下载（用于前端从暂停态恢复）：设为非暂停，触发队列处理
#[tauri::command]
async fn resume_download(
    app: tauri::AppHandle,
    download_id: String,
    max_concurrent: usize,
) -> Result<String, String> {
    {
        let mut queue = DOWNLOAD_QUEUE.lock().unwrap();
        if let Some(task) = queue.iter_mut().find(|d| d.download_id == download_id) {
            task.paused = false;
        }
    }
    process_queue(&app, max_concurrent);
    // 检查是否已在活跃区启动
    let active = ACTIVE_DOWNLOADS.lock().unwrap();
    if active.contains(&download_id) {
        Ok("downloading".to_string())
    } else {
        Ok("queued".to_string())
    }
}

/// 检查指定下载是否正有活跃任务（在 DOWNLOADS 中）
#[tauri::command]
fn is_downloading(download_id: String) -> bool {
    let active = ACTIVE_DOWNLOADS.lock().unwrap();
    active.contains(&download_id)
}

/// 检查指定下载是否已暂停
#[tauri::command]
fn is_paused(download_id: String) -> bool {
    let queue = DOWNLOAD_QUEUE.lock().unwrap();
    queue.iter().find(|d| d.download_id == download_id).map(|t| t.paused).unwrap_or(false)
}

/// 获取所有活跃下载（即有 execute_download 任务运行的）
#[tauri::command]
fn get_active_downloads() -> Vec<serde_json::Value> {
    let active = ACTIVE_DOWNLOADS.lock().unwrap();
    let queue = DOWNLOAD_QUEUE.lock().unwrap();
    active.iter().map(|id| {
        let paused = queue.iter().find(|t| t.download_id == *id).map(|t| t.paused).unwrap_or(false);
        serde_json::json!({
            "download_id": id,
            "paused": paused,
            "cancelled": false,
        })
    }).collect()
}

/// 获取当前活跃下载数量（ACTIVE_DOWNLOADS 集合大小）
#[tauri::command]
fn get_download_count() -> usize {
    let active = ACTIVE_DOWNLOADS.lock().unwrap();
    active.len()
}

/// 获取队列长度（含所有状态的任务）
#[tauri::command]
fn get_queue_length() -> usize {
    let queue = DOWNLOAD_QUEUE.lock().unwrap();
    queue.len()
}

/// 获取指定下载在队列中的位置（1-indexed，0=不在队列）
#[tauri::command]
fn get_queue_position(download_id: String) -> usize {
    let queue = DOWNLOAD_QUEUE.lock().unwrap();
    for (i, item) in queue.iter().enumerate() {
        if item.download_id == download_id {
            return i + 1;
        }
    }
    0
}

/// 删除指定路径的文件（用于清理应用重启后残留的未完成下载文件）
#[tauri::command]
fn remove_file(file_path: String) -> Result<(), String> {
    let path = std::path::Path::new(&file_path);
    if path.exists() {
        std::fs::remove_file(path).map_err(|e| format!("删除文件失败: {}", e))
    } else {
        Ok(())
    }
}

/// 检查队列中是否有指定下载
#[tauri::command]
fn is_in_queue(download_id: String) -> bool {
    let queue = DOWNLOAD_QUEUE.lock().unwrap();
    queue.iter().any(|d| d.download_id == download_id)
}

mod network;
use network::{
    delete_https_request, get_https_request, post_https_request, send_https_request,
    send_https_request_binary,
};

mod webview;
use webview::{inject_webview_script, inject_webview_initialization_script};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_http::init())
        .plugin(tauri_plugin_sql::Builder::new().build())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_device::init())
        .plugin(tauri_plugin_mwebview::init())
        .invoke_handler(tauri::generate_handler![
            greet,
            test,
            download_video,
            cancel_download,
            pause_download,
            resume_download,
            unpause_download,
            is_downloading,
            is_paused,
            get_active_downloads,
            get_download_count,
            get_queue_length,
            get_queue_position,
            remove_file,
            is_in_queue,
            send_https_request,
            get_https_request,
            post_https_request,
            delete_https_request,
            send_https_request_binary,
            inject_webview_script,
            inject_webview_initialization_script
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[tauri::command]
fn test() -> String {
    "RUST\u{4ee3}\u{7801}\u{6d4b}\u{8bd5}".to_string()
}
