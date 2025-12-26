const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = process.env.SUPABASE_URL
const supabaseKey = process.env.SUPABASE_ANON_KEY

const storageClient = createClient(supabaseUrl, supabaseKey)

async function subirArchivo(file, fileName) {
  const { data, error } = await storageClient.storage
    .from('absence-files')
    .upload(fileName, file.buffer)
  
  if (error) throw error
  
  const { data: urlData } = storageClient.storage
    .from('absence-files')
    .getPublicUrl(fileName)
  
  return urlData.publicUrl
}

module.exports = { subirArchivo }
