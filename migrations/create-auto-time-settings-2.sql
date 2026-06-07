-- Crear tabla auto_time_settings_2 para segunda configuración independiente
CREATE TABLE IF NOT EXISTS auto_time_settings_2 (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  enabled BOOLEAN DEFAULT false,
  monday BOOLEAN DEFAULT false,
  tuesday BOOLEAN DEFAULT false,
  wednesday BOOLEAN DEFAULT false,
  thursday BOOLEAN DEFAULT false,
  friday BOOLEAN DEFAULT false,
  saturday BOOLEAN DEFAULT false,
  sunday BOOLEAN DEFAULT false,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  auto_register_time TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Verificar que la tabla se creó correctamente
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'auto_time_settings_2';
