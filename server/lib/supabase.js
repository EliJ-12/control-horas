const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = process.env.SUPABASE_URL || 'https://rbvgwwviufuyunohmjhk.supabase.co'
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJidmd3d3ZpdWZ1eXVub2htamhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1ODgzNzQsImV4cCI6MjA4MjE2NDM3NH0.AftikClnGloSnBvRJskUifDoaCQ7K8zPW_83aZvu7o4'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

module.exports = { supabase }
