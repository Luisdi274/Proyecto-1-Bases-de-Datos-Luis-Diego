ALTER TABLE eventos
ADD COLUMN id_ubicacion int  REFERENCES UBICACIONES(id_ubicacion),
--un evento no necesariamente tendrá desde el inicio una ubicación definida, por lo que puede ser nullable
ADD COLUMN id_serie int REFERENCES SERIES_EVENTOS(id_serie);
--lo mismo con esto