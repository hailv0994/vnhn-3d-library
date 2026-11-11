// js/config.js — cấu hình chung (CHỈ dùng anon key, KHÔNG BAO GIỜ đưa service_role key vào đây)

export const SUPABASE_URL = 'https://tdhdiudjsjtbhtqftwnv.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkaGRpdWRqc2p0Ymh0cWZ0d252Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQzODIzMTAsImV4cCI6MjEwOTk1ODMxMH0.Yc0mPPfuIukggf5_sgnkLzWJZ1JmJq4hMCXaExwOFvk';

export const BUCKET = 'models';
export const MAX_FILE_SIZE = 20 * 1024 * 1024; // 20 MB

// đuôi file gốc được phép → file_type lưu trong DB
export const EXT_TO_TYPE = {
  html: 'html',
  glb: 'glb',
  gltf: 'gltf', // chỉ nhận .gltf nhúng (embedded), không kèm .bin/texture rời
  step: 'step', stp: 'step',
  iges: 'iges', igs: 'iges',
  stl: 'stl',
  obj: 'obj',
};
export const ALLOWED_EXT = Object.keys(EXT_TO_TYPE);

// key danh mục (nhãn hiển thị nằm trong js/i18n.js)
export const CATEGORIES = [
  'cylinder',          // Xylanh khí nén
  'pneumatic_valve',   // Van & thiết bị khí nén
  'signal_light',      // Đèn báo / đèn tháp
  'switch',            // Nút bấm / công tắc
  'sensor',            // Cảm biến
  'motor',             // Motor / servo
  'robot',             // Robot / cobot
  'machine',           // Máy CNC / máy tiêu chuẩn
  'conveyor',          // Băng tải
  'aluminum_profile',  // Profile nhôm & phụ kiện
  'mechanical',        // Bulong / chi tiết cơ khí
  'jig',               // Đồ gá
  'other',             // Khác
];

// Đường dẫn file trong bucket — KHÔNG đổi sau khi phát hành (link nhúng phụ thuộc)
export const paths = {
  original: (id, ext) => `${id}/original.${ext}`,
  preview:  (id) => `${id}/preview.glb`,
  thumb:    (id, ext = 'webp') => `${id}/thumb.${ext}`,
};
