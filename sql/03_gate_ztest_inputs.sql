-- ============================================================
-- 03_gate_ztest_inputs.sql
-- Mục đích: Tính n (cỡ mẫu), x (số sự kiện), rate (tỷ lệ) cho
--           từng nhóm của 4 biến (device_type, traffic_source,
--           channel, price_tier), tách riêng theo Gate 1
--           (tỷ lệ thêm giỏ hàng) và Gate 2 (tỷ lệ chốt đơn trong số đã thêm giỏ hàng).
--
-- Lưu ý: z-score và p-value không tính trong SQL —
--   3 cột n/x/rate mỗi khối dưới đây được đưa sang Excel để
--   tính two-proportion z-test (xem file Z-test_inputs.xlsx trong Excel)
--   File này chỉ cung cấp nguyên liệu đầu vào, không phải kết
--   quả kiểm định cuối cùng.
-- ============================================================

-- ===================== DEVICE_TYPE =====================

-- Gate 1: tỷ lệ thêm giỏ hàng theo device_type
WITH session_level AS (
    SELECT 
        session_id,
        MAX(device_type) AS device_type,
        MAX(CASE WHEN user_action = 'add_to_cart' THEN 1 ELSE 0 END) AS has_atc,
        MAX(CAST(is_conversion AS INT)) AS is_conversion
    FROM bang_hanh_vi
    GROUP BY session_id
)
SELECT 
    device_type,
    COUNT(*)                                AS n,
    SUM(has_atc)                            AS x_atc,
    CAST(SUM(has_atc) AS FLOAT) / COUNT(*)  AS atc_rate
FROM session_level
GROUP BY device_type
ORDER BY atc_rate DESC;

-- Gate 2: tỷ lệ chốt đơn trong số đã thêm giỏ hàng, theo device_type
WITH session_level AS (
    SELECT 
        session_id,
        MAX(device_type) AS device_type,
        MAX(CASE WHEN user_action = 'add_to_cart' THEN 1 ELSE 0 END) AS has_atc,
        MAX(CAST(is_conversion AS INT)) AS is_conversion
    FROM bang_hanh_vi
    GROUP BY session_id
)
SELECT 
    device_type,
    COUNT(*)                                       AS n,
    SUM(is_conversion)                             AS x_convert,
    CAST(SUM(is_conversion) AS FLOAT) / COUNT(*)   AS convert_rate
FROM session_level
WHERE has_atc = 1
GROUP BY device_type
ORDER BY convert_rate DESC;


-- ===================== TRAFFIC_SOURCE =====================

-- Gate 1
WITH session_level AS (
    SELECT 
        session_id,
        MAX(traffic_source) AS traffic_source,
        MAX(CASE WHEN user_action = 'add_to_cart' THEN 1 ELSE 0 END) AS has_atc,
        MAX(CAST(is_conversion AS INT)) AS is_conversion
    FROM bang_hanh_vi
    GROUP BY session_id
)
SELECT 
    traffic_source,
    COUNT(*)                                AS n,
    SUM(has_atc)                            AS x_atc,
    CAST(SUM(has_atc) AS FLOAT) / COUNT(*)  AS atc_rate
FROM session_level
GROUP BY traffic_source
ORDER BY atc_rate DESC;

-- Gate 2
WITH session_level AS (
    SELECT 
        session_id,
        MAX(traffic_source) AS traffic_source,
        MAX(CASE WHEN user_action = 'add_to_cart' THEN 1 ELSE 0 END) AS has_atc,
        MAX(CAST(is_conversion AS INT)) AS is_conversion
    FROM bang_hanh_vi
    GROUP BY session_id
)
SELECT 
    traffic_source,
    COUNT(*)                                       AS n,
    SUM(is_conversion)                             AS x_convert,
    CAST(SUM(is_conversion) AS FLOAT) / COUNT(*)   AS convert_rate
FROM session_level
WHERE has_atc = 1
GROUP BY traffic_source
ORDER BY convert_rate DESC;


-- ===================== CHANNEL =====================

-- Gate 1
WITH session_level AS (
    SELECT 
        session_id,
        MAX(channel) AS channel,
        MAX(CASE WHEN user_action = 'add_to_cart' THEN 1 ELSE 0 END) AS has_atc,
        MAX(CAST(is_conversion AS INT)) AS is_conversion
    FROM bang_hanh_vi
    GROUP BY session_id
)
SELECT 
    channel,
    COUNT(*)                                AS n,
    SUM(has_atc)                            AS x_atc,
    CAST(SUM(has_atc) AS FLOAT) / COUNT(*)  AS atc_rate
FROM session_level
GROUP BY channel
ORDER BY atc_rate DESC;

-- Gate 2
WITH session_level AS (
    SELECT 
        session_id,
        MAX(channel) AS channel,
        MAX(CASE WHEN user_action = 'add_to_cart' THEN 1 ELSE 0 END) AS has_atc,
        MAX(CAST(is_conversion AS INT)) AS is_conversion
    FROM bang_hanh_vi
    GROUP BY session_id
)
SELECT 
    channel,
    COUNT(*)                                       AS n,
    SUM(is_conversion)                             AS x_convert,
    CAST(SUM(is_conversion) AS FLOAT) / COUNT(*)   AS convert_rate
FROM session_level
WHERE has_atc = 1
GROUP BY channel
ORDER BY convert_rate DESC;


-- ===================== PRICE_TIER =====================
-- Riêng price cần thêm bước tính ngưỡng percentile (p33/p67)
-- để chia thành 3 nhóm gia_thap/gia_trung/gia_cao trước khi đếm.

-- Gate 1
WITH bang_tam AS (
    SELECT 
        session_id,
        MAX(price) AS price,
        MAX(CASE WHEN user_action = 'add_to_cart' THEN 1 ELSE 0 END) AS has_atc,
        MAX(CAST(is_conversion AS INT)) AS is_conversion
    FROM bang_hanh_vi
    GROUP BY session_id
),
gia_threshold AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY price) OVER() AS p33,
        PERCENTILE_CONT(0.67) WITHIN GROUP (ORDER BY price) OVER() AS p67
    FROM bang_tam
),
session_level AS (
    SELECT 
        b.session_id,
        b.has_atc,
        b.is_conversion,
        CASE 
            WHEN b.price <= T.p33 THEN 'gia_thap'
            WHEN b.price <= T.p67 THEN 'gia_trung'
            ELSE 'gia_cao'
        END AS nhom_gia
    FROM bang_tam b
    CROSS JOIN (SELECT TOP 1 * FROM gia_threshold) T
)
SELECT 
    nhom_gia,
    COUNT(*)                                AS n,
    SUM(has_atc)                            AS x_atc,
    CAST(SUM(has_atc) AS FLOAT) / COUNT(*)  AS atc_rate
FROM session_level
GROUP BY nhom_gia
ORDER BY atc_rate DESC;

-- Gate 2
WITH bang_tam AS (
    SELECT 
        session_id,
        MAX(price) AS price,
        MAX(CASE WHEN user_action = 'add_to_cart' THEN 1 ELSE 0 END) AS has_atc,
        MAX(CAST(is_conversion AS INT)) AS is_conversion
    FROM bang_hanh_vi
    GROUP BY session_id
),
gia_threshold AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY price) OVER() AS p33,
        PERCENTILE_CONT(0.67) WITHIN GROUP (ORDER BY price) OVER() AS p67
    FROM bang_tam
),
session_level AS (
    SELECT 
        b.session_id,
        b.has_atc,
        b.is_conversion,
        CASE 
            WHEN b.price <= T.p33 THEN 'gia_thap'
            WHEN b.price <= T.p67 THEN 'gia_trung'
            ELSE 'gia_cao'
        END AS nhom_gia
    FROM bang_tam b
    CROSS JOIN (SELECT TOP 1 * FROM gia_threshold) T
)
SELECT 
    nhom_gia,
    COUNT(*)                                       AS n,
    SUM(is_conversion)                             AS x_convert,
    CAST(SUM(is_conversion) AS FLOAT) / COUNT(*)   AS convert_rate
FROM session_level
WHERE has_atc = 1
GROUP BY nhom_gia
ORDER BY convert_rate DESC;
