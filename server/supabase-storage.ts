import { createClient } from '@supabase/supabase-js';

// Configuración de Supabase Storage (solo para archivos)
const supabaseUrl = 'https://rbvgwwviufuyunohmjhk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJidmd3d3ZpdWZ1eXVub2htamhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1ODgzNzQsImV4cCI6MjA4MjE2NDM3NH0.AftikClnGloSnBvRJskUifDoaCQ7K8zPW_83aZvu7o4';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

export async function uploadFileToSupabase(
  file: Express.Multer.File,
  userId: number
): Promise<{ url: string; error?: string }> {
  try {
    const fileName = `${Date.now()}-${file.originalname}`;
    const filePath = `absence-files/${userId}/${fileName}`;

    // Subir archivo a Supabase Storage
    const { data, error } = await supabase.storage
      .from('absence-files')
      .upload(filePath, file.buffer, {
        contentType: file.mimetype,
        upsert: false
      });

    if (error) {
      console.error('Error uploading to Supabase:', error);
      return { url: '', error: error.message };
    }

    // Obtener URL pública del archivo
    const { data: { publicUrl } } = supabase.storage
      .from('absence-files')
      .getPublicUrl(filePath);

    return { url: publicUrl };
  } catch (error) {
    console.error('Unexpected error:', error);
    return { url: '', error: 'Error inesperado al subir archivo' };
  }
}
