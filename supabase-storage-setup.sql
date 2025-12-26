-- Create absence-files bucket for storing absence documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'absence-files',
  'absence-files',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- Set up Row Level Security policies
CREATE POLICY "Users can upload their own absence files" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'absence-files' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can view their own absence files" ON storage.objects
FOR SELECT USING (
  bucket_id = 'absence-files' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can update their own absence files" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'absence-files' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete their own absence files" ON storage.objects
FOR DELETE USING (
  bucket_id = 'absence-files' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
