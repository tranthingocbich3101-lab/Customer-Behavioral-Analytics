-- SQL — User Behavioral Analytics
-- Mô tả: Toàn bộ truy vấn chạy trên SQL Server 2022, 
--        nguồn dữ liệu gốc là bảng bang_hanh_vi (cấp độ 1 dòng = 1 event trong phiên truy cập)
--============================================================
thứ tự chạy tổng quát:
-- 01_data_cleaning_validation.sql
-- Mục đích: Kiểm tra tổng quan bảng gốc trước khi phân tích — 	Kiểm tra phạm vi dữ liệu, giá trị bất thường, missing value trên bảng gốc
-- Output: Không tạo bảng — chỉ để xác nhận dữ liệu sạch trước khi đi tiếp vào phân tích

--02_session_table_view.sql
-- Mục đích: Gộp dữ liệu về cấp session, gắn nhãn price_tier, speed_tier, phan_khuc_KH
-- Output: View session_table — nguồn chính cho toàn bộ measure DAX trong Power BI

--03_gate_ztest_inputs.sql
-- Mục đích: Tính n (cỡ mẫu)/x (số sự kiện)/rate (tỷ lệ) theo Gate 1 (thêm giỏ hàng) và Gate 2 (chốt đơn) 
--           cho 4 biến: device_type, traffic_source, channel, price_tier
--Output: Kết quả n/x/rate — đưa sang Excel (file Z-test_inputs.xlsx) để tính z-score và p-value

-- Lưu ý: z-score và p-value của two-proportion z-test không được tính trong SQL
--        bước tính z/p-value được thực hiện trên Excel,
--        sau đó kết quả tổng hợp (bao gồm cả spread và kết luận Sig./Not Sig.) 
--        được nhập vào Power BI làm bảng Bang_Ztest
