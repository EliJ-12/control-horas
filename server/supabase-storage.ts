import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseKey);

// Multer file interface
export interface MulterFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  size: number;
  destination: string;
  filename: string;
  path: string;
  buffer: Buffer;
}

export async function uploadAbsenceFile(userId: number, file: MulterFile): Promise<string> {
  try {
    const fileName = `${Date.now()}-${file.originalname}`;
    const filePath = `absence-files/${userId}/${fileName}`;
    
    // Convert buffer to Uint8Array for Blob constructor
    const uint8Array = new Uint8Array(file.buffer);
    const fileBlob = new Blob([uint8Array], { type: file.mimetype });
    
    const { error } = await supabase.storage
      .from('absence-files')
      .upload(filePath, fileBlob, {
        cacheControl: '3600',
        upsert: false
      });

    if (error) {
      throw error;
    }

    const { data } = supabase.storage
      .from('absence-files')
      .getPublicUrl(filePath);

    return data.publicUrl;
  } catch (error) {
    console.error('Upload error:', error);
    throw error;
  }
}

export function getPublicUrl(filePath: string): string {
  const { data } = supabase.storage
    .from('absence-files')
    .getPublicUrl(filePath);
  
  return data.publicUrl;
}
