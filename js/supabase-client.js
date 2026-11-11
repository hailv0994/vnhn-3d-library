// js/supabase-client.js — khởi tạo Supabase client + helper dùng chung
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
import { SUPABASE_URL, SUPABASE_ANON_KEY, BUCKET } from './config.js';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true },
});

/** URL public của 1 file trong bucket */
export function publicUrl(path) {
  if (!path) return null;
  return supabase.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
}

/** User hiện tại có phải admin không */
export async function isAdmin() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return false;
  const { data, error } = await supabase.rpc('is_admin');
  return !error && data === true;
}

/** Tăng lượt tải (gọi trước khi tải file gốc) */
export async function incrementDownload(id) {
  await supabase.rpc('increment_download', { p_id: id });
}
