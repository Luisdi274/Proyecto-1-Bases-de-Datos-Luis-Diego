ALTER TABLE eventos
ADD COLUMN id_ubicacion int  REFERENCES UBICACIONES(id_ubicacion),
--un evento no necesariamente tendrá desde el inicio una ubicación definida, por lo que puede ser nullable
ADD COLUMN id_serie int REFERENCES SERIES_EVENTOS(id_serie);
--lo mismo con esto



alter table series_eventos  add constraint entradas_clase_periodicidad check(clase_periodicidad  in('diario','semanal','mensual','personalizado'));
--ya habiamos creado la tabla de series_eventos, ahora se le pone la restricción de que solo permita 4 posibles valores
--se va a registrar todo en minuscula, hay diferencia entre mayusucla y minuscula

alter table series_eventos add constraint tipo_entrada_intervalo_dias check(
(clase_periodicidad ='personalizado' and intervalo_en_dias_eventos is not null) or
(clase_periodicidad <>'personalizado' and intervalo_en_dias_eventos is null)
);
--recordemos que el intervalo de dias de una serie de eventos solo se usa si su periodicidad es personalizada


alter table series_eventos add constraint valores_para_dias_especificos_serie_evento check (
(reserva_dias_especificos is null and clase_periodicidad ='personalizado' ) or (reserva_dias_especificos is not null and clase_periodicidad ='semanal') or
(reserva_dias_especificos is null and clase_periodicidad = 'diario') or (reserva_dias_especificos is null and clase_periodicidad='mensual')

);


insert into usuarios(nombre,apellido)
values ('Ana','Rodriguez')


select *from usuarios 