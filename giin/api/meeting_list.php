<?php
// CORS対応
header("Access-Control-Allow-Origin: 'https://tiger4th.com'");

// APIのURLを構築
$params = http_build_query($_GET);
$url = "https://kokkai.ndl.go.jp/api/meeting_list?" . $params;

// cURLで取得
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, true); // ヘッダーも含めて取得
$response = curl_exec($ch);

if (curl_errno($ch)) {
    http_response_code(500);
    echo json_encode(["error" => "Curl error: " . curl_error($ch)]);
    exit;
}

// ヘッダーとボディを分割
$header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$headers = substr($response, 0, $header_size);
$body = substr($response, $header_size);
$content_type = 'application/json; charset=utf-8'; // デフォルト

// ヘッダーからContent-Typeを取得（あれば上書き）
foreach (explode("\r\n", $headers) as $header_line) {
    if (stripos($header_line, 'Content-Type:') === 0) {
        $content_type = trim(substr($header_line, strlen('Content-Type:')));
        break;
    }
}

curl_close($ch);

// 文字コードをUTF-8に変換（必要に応じて）
$encoding = mb_detect_encoding($body, ['UTF-8', 'SJIS', 'EUC-JP', 'ISO-2022-JP'], true);
if ($encoding !== 'UTF-8') {
    $body = mb_convert_encoding($body, 'UTF-8', $encoding);
    $content_type = 'application/json; charset=utf-8'; // 明示的に指定
}

// ヘッダー出力
header("Content-Type: $content_type");

// レスポンス出力
echo $body;
