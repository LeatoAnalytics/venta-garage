-- Crear tabla de productos
CREATE TABLE productos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre_producto VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio_original DECIMAL(10,2),
    precio_rebajado DECIMAL(10,2),
    categoria VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Disponible' CHECK (status IN ('Disponible', 'Reservado', 'Vendido')),
    activo BOOLEAN DEFAULT true,
    imagenes_s3 TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX idx_productos_activo ON productos(activo);
CREATE INDEX idx_productos_categoria ON productos(categoria);
CREATE INDEX idx_productos_status ON productos(status);
CREATE INDEX idx_productos_created_at ON productos(created_at);

-- Crear función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Crear trigger para actualizar updated_at
CREATE TRIGGER update_productos_updated_at 
    BEFORE UPDATE ON productos 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Habilitar Row Level Security (RLS)
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;

-- Crear política para permitir lectura pública (para la aplicación web)
CREATE POLICY "Permitir lectura pública de productos activos" ON productos
    FOR SELECT USING (activo = true);

-- Crear política para permitir todas las operaciones con API key (para administración)
CREATE POLICY "Permitir todas las operaciones con service role" ON productos
    FOR ALL USING (auth.role() = 'service_role');

-- Insertar algunos datos de ejemplo (opcional)
INSERT INTO productos (nombre_producto, descripcion, precio_original, categoria, status, activo, imagenes_s3) VALUES
('Producto de ejemplo', 'Descripción del producto de ejemplo', 100.00, 'Electrónicos', 'Disponible', true, 'https://tu-bucket.s3.amazonaws.com/ejemplo/');

-- Crear vista para productos activos (optimización)
CREATE VIEW productos_activos AS
SELECT * FROM productos 
WHERE activo = true 
ORDER BY created_at DESC; 