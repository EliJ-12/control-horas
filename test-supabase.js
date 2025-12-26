import { supabase } from '../server/supabase-storage.js';

async function testSupabaseConnection() {
  try {
    const { data, error } = await supabase.storage.listBuckets();
    
    if (error) {
      console.error('Supabase connection error:', error);
      return false;
    }
    
    console.log('Connected to Supabase. Available buckets:', data);
    return true;
  } catch (error) {
    console.error('Failed to connect to Supabase:', error);
    return false;
  }
}

testSupabaseConnection();
