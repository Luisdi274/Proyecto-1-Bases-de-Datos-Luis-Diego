ALTER TABLE eventos
ADD COLUMN id_ubicacion int  REFERENCES UBICACIONES(id_ubicacion),
--un evento no necesariamente tendrá desde el inicio una ubicación definida, por lo que puede ser nullable
ADD COLUMN id_serie int REFERENCES SERIES_EVENTOS(id_serie);
--lo mismo con esto



alter table series_eventos  add constraint entradas_clase_periodicidad check(clase_periodicidad  in('diario','semanal','mensual','personalizado'));
--ya habiamos creado la tabla de series_eventos, ahora se le pone la restricción de que solo permita 4 posibles valores
--se va a registrar todo en minuscula, hay diferencia entre mayusucla y minuscula