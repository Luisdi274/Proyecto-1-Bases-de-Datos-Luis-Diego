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

insert into series_eventos (id_usuario_propietario,titulo_serie,fecha_inicio,fecha_fin,clase_periodicidad,intervalo_en_dias_eventos,reserva_dias_especificos)
values (1,'Clase de yoga','2026-09-17','2026-12-17','semanal',null,'martes,jueves');
--prueba usando un caso válido de los constraints check


insert into series_eventos (id_usuario_propietario,titulo_serie,fecha_inicio,fecha_fin,clase_periodicidad,intervalo_en_dias_eventos,reserva_dias_especificos)
values (1,'Clase de yoga','2026-09-17','2026-12-17','semanal',null,null);



alter table tareas add constraint fijacion_entradas_estado_tareas check(
estado in('pendiente','en progreso','completada','cancelada')
);
--igual que en el primer constraint, el modulo de tareas para esta tabla solo permite 4 posibles valores para su columna estado

alter table ubicaciones add constraint dominio_capacidad check(capacidad >0);
--revision de dominio

create view vista_para_ocupacion_ubicacion as
--una vista de resumen, es como una consulta o un reporte 
--se genera con los datos que haya en el momento
select ubi.id_ubicacion, ubi.nombre,ubi.ciudad,
--esto es para decir las columnas de la tabla que se verán en el reporte. con una "variable" ubi
count(e.id_evento) as numero_eventos,
--cuenta cuantos eventos hay
coalesce(sum(extract(epoch from(e.fecha_fin - e.fecha_inicio))/60),0) as minutos_reservados_totales
--e.fecha_fin -e.fecha_inicio, resta fechas para ver cuanto duró
--extract(epoch....), es una funcion para convertir a segundos totales, luego se divide entre 60 para tenerlo en minutos
--sum(....), suma los minutos de los eventos
--coalesce(....) devuelve 0 si el resultado de todo lo q esta antes de la coma es nulo
from ubicaciones ubi
left join eventos e on e.id_ubicacion=ubi.id_ubicacion
--esto es para unir 2 tablas
group by ubi.id_ubicacion, ubi.nombre, ubi.ciudad
order by numero_eventos desc;


create view usuarios_y_sus_respevctivas_tareas as
select usu.id_usuario,us.nombre,us.apellido,
count(*) filter (where pTarea.estado in('pendiente','en progreso'))
--aqui va a contar las instancias o tuplas pero solo las que cumplen la condicion del where
count(*) filter(
where pTarea.estado not in ('completada', 'cancelada') and pTarea.fecha_limite< current_date
)as tareas_Vencidas
--current date es palabra reservada de sql para la fecha actual
from usuarios as usu
left join tareas pTarea on pTarea.id_usuario_a_cargo=usu.id_usuario
--recordar que este join basicamente hace que se presenten las filas o registros de la tabla de ubicaciones, tenga relacion o no con la tabla derecha
--y si no lo hay, pone null en la segunda tabla
group by usu.id_usuario,usu.nombre,usu.apellido
order by tareas_Vencidas desc, tareas_activas desc;
--presenta las tareas vencidas, pero de cada usuario, no como tal esas tareas

create view  vista_tareas_vencidas_en_evento as 
select distinct pEvento.id_evento,pEvento.titulo,pEvento.fecha_inicio,pEvento.fecha_fin
--el distinct es para que no se repitan resultados iguales, en este caso para un mismo evento





