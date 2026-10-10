--creacion de base de datos para proyecto
CREATE DATABASE agenda;

CREATE SCHEMA prototipo;

-- Configurar el search_path para que las tablas se creen dentro de ese esquema
-- y se busquen ahí automáticamente
SET search_path TO prototipo, public;

-- 1. Usuarios
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_registro DATE DEFAULT CURRENT_DATE NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

-- 2. Contactos (RF02, RE02, RN02)
CREATE TABLE usuario_telefonos (
    id_usuario INT REFERENCES usuarios(id_usuario),
    telefono VARCHAR(20),
    PRIMARY KEY (id_usuario, telefono)
);

CREATE TABLE usuario_emails (
    id_usuario INT REFERENCES usuarios(id_usuario),
    email VARCHAR(100),
    PRIMARY KEY (id_usuario, email)
);

-- 3. Categorías (RF03, RE05, RN04)
CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    id_categoria_padre INT REFERENCES categorias(id_categoria)
    -- NOTA: La raíz tendría id_categoria_padre NULL
);

create table UBICACIONES (
	id_ubicacion SERIAL primary key,
	nombre varchar(40) not null unique,
	ciudad varchar(60) not null,
	--este atributo no es unico, pues sino no se cumple lo de gestionar varias salas que pueden estar en la misma ciudad
	direccion varchar(120) not null,
	capacidad int not null
	--poner capacidad not null responde al requerimiento funcional #10 acerca de los reportes
);

create table SERIES_EVENTOS (
    id_serie SERIAL primary key,
    id_usuario_propietario int not null REFERENCES usuarios(id_usuario),
    --esta es la llave foranea de esta tabla
    titulo_serie varchar(90) not null,
    --lo que aparece en pantalla de la aplicacion no puede ser nulo, es un titulo especifico para la serie del evento

    fecha_inicio date not null,
    fecha_fin date not null,
    clase_periodicidad varchar(21) not null,
    --debe ser diaria,semanal, mensual o personalizada, pero nunca nula, luego se le agregará un check
    intervalo_en_dias_eventos int,
    --este es el campo que se debe llenar en caso de que sea personalizado, de lo contrario es nulo, pues se sobre entiende
    --por la clase de periodicidad
    reserva_dias_especificos varchar(50)
    --si la periodicidad es semanal, se debe especificar valores,sino es nula
);

-- 4. Eventos (RF04, RE04)
CREATE TABLE eventos (
    id_evento SERIAL PRIMARY KEY,
    id_usuario_propietario INT NOT NULL REFERENCES usuarios(id_usuario),
    id_categoria INT NOT NULL REFERENCES categorias(id_categoria),
    titulo VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP NOT NULL,
    CONSTRAINT check_fechas CHECK (fecha_fin > fecha_inicio)
);


ALTER TABLE eventos
ADD COLUMN id_ubicacion int  REFERENCES UBICACIONES(id_ubicacion),
--un evento no necesariamente tendrá desde el inicio una ubicación definida, por lo que puede ser nullable
ADD COLUMN id_serie int REFERENCES SERIES_EVENTOS(id_serie);
--lo mismo con esto

-- 5. Participación (RF05, RE01, RN01, RN05)
CREATE TABLE participaciones (
    id_evento INT REFERENCES eventos(id_evento) ON DELETE CASCADE,
    id_invitado INT REFERENCES usuarios(id_usuario),
    rol VARCHAR(50),
    estado_confirmacion VARCHAR(20) DEFAULT 'pendiente',
    PRIMARY KEY (id_evento, id_invitado)
);

-- 6. Log de Accesos (RF06)
CREATE TABLE log_accesos (
    id_log SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuarios(id_usuario),
    fecha_acceso TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE TAREAS(
    id_tarea SERIAL PRIMARY KEY,
    id_usuario_a_cargo int NOT NULL REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    id_evento int NOT NULL REFERENCES eventos(id_evento) ON DELETE CASCADE,
    --aqui tendrá sentido agregar un cascade, pues recordemos que si un evento se elimina, entonces invitaciones y lo relacionado con él también
    descripcion VARCHAR(150),
    --este valor no puede ser unico, porque al final pueden haber varias ocurrencias con la misma descripcion
    prioridad VARCHAR(25) NOT NULL,
    titulo VARCHAR(80) NOT NULL,
    fecha_limite DATE ,
    estado VARCHAR(25) NOT NULL 
    
);



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

alter table tareas add constraint fijacion_entradas_estado_tareas check(
estado in('pendiente','en progreso','completada','cancelada')
);
--igual que en el primer constraint, el modulo de tareas para esta tabla solo permite 4 posibles valores para su columna estado

alter table ubicaciones add constraint dominio_capacidad check(capacidad >0);
--revision de dominio







-- Implementación de Cálculos Dinámicos (RF07, RE03, RN03) mediante vistas

-- Vista para Antigüedad
CREATE VIEW vista_antiguedad_usuarios AS
SELECT 
    id_usuario, 
    nombre, 
    fecha_registro,
    age(CURRENT_DATE, fecha_registro) AS antiguedad
FROM usuarios;

-- Vista para Duración de eventos diarios
CREATE VIEW vista_duracion_eventos_diarios AS
SELECT 
    id_usuario_propietario,
    fecha_inicio::DATE AS dia,
    SUM(EXTRACT(EPOCH FROM (fecha_fin - fecha_inicio))/60) AS duracion_total_minutos
FROM eventos
GROUP BY id_usuario_propietario, fecha_inicio::DATE;


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
select usu.id_usuario,usu.nombre,usu.apellido,
count(*) filter (where pTarea.estado in('pendiente','en progreso')) as tareas_actuales,
--aqui va a contar las instancias o tuplas pero solo las que cumplen la condicion del where
count(*) filter(
where pTarea.estado not in ('completada', 'cancelada') and pTarea.fecha_limite<current_date
)as tareas_Vencidas
--current date es palabra reservada de sql para la fecha actual
from usuarios as usu
left join tareas pTarea on pTarea.id_usuario_a_cargo=usu.id_usuario
--recordar que este join basicamente hace que se presenten las filas o registros de la tabla de ubicaciones, tenga relacion o no con la tabla derecha
--y si no lo hay, pone null en la segunda tabla
group by usu.id_usuario,usu.nombre,usu.apellido
order by tareas_Vencidas desc, tareas_actuales desc;
--presenta las tareas vencidas, pero de cada usuario, no como tal esas tareas

create view  vista_tareas_vencidas_en_evento as 
select distinct pEvento.id_evento,pEvento.titulo,pEvento.fecha_inicio,pEvento.fecha_fin
--el distinct es para que no se repitan resultados iguales, en este caso para un mismo evento
from eventos pEvento
join tareas pTarea on pTarea.id_evento = pEvento.id_evento
--este join es el normal, pues debe haber coincidencia en las tareas vencidas
where pTarea.estado not in ('cancelada','completada') and pTarea.fecha_limite <current_date
order by pEvento.fecha_inicio;

--Integridad y Prevención de Ciclos (RE05)
--Para evitar ciclos en la jerarquía de categorías, podemos usar una función 
--que verifique el ancestro antes de insertar o actualizar:

CREATE OR REPLACE FUNCTION evitar_ciclo_categorias()
RETURNS TRIGGER AS $$
DECLARE
	existencia_ciclo BOOLEAN;
--para saber si existe ciclo o no 
BEGIN
	IF NEW.id_categoria_padre IS NULL THEN
		RETURN NEW;
	END IF;
--se agrega esta parte,pues si la categoria que se quiere registra no tiene un padre, pues se agrega sin problema, pues es la raiz general
    IF NEW.id_categoria_padre = NEW.id_categoria THEN
        RAISE EXCEPTION 'Una categoría no puede ser padre de sí misma.';
    END IF;

	WITH RECURSIVE tiene_ancestros AS (
--ancestros funciona como cuando en estructuras de datos usas una variable temporal para guardar info, aqui es una tabla para corroborar si hay ciclos o no
		SELECT id_categoria,id_categoria_padre
		FROM CATEGORIAS
		WHERE id_categoria = NEW.id_categoria_padre
--esto recorre todo el árbol para ver la cadena de padres y ver si hay algun ciclo, osea que una categoria sea su propio padre
--funciona con una lista, se recorre el padre que se quiera registrar y va buscando y repitiendo recursivamente hasta que se genera un conjunto
--si en ese conjunto uno de sus elementos es el propio padre que se quiere registrar, se rechaza la operación
		UNION ALL
		
		SELECT pCategoria.id_categoria,pCategoria.id_categoria_padre
		FROM categorias pCategoria

		INNER JOIN tiene_ancestros pAncestro on pCategoria.id_categoria = pAncestro.id_categoria_padre)
--aqui lo que buscamos es agarrar coincidencias de datos entre los ancestros , compara el id_categoria de la tabla de categorias 
--Recordemos que tanto id_categoria como id_categoria_padre estan en la misma tabla, simplemente que en el inner join lo que se hará es que una categoria pCategoria
--con cierto id_categoria_padre busca la fila q tenga ese mismo id, y así repetitivamente hasta que id_categoria_padre sea nulo
--es una busqueda de padres hasta que no haya
		
		SELECT EXISTS (
--exists va a convertir esta consulta en un valor booleano (TRUE/FALSE)
			SELECT * FROM tiene_ancestros WHERE id_categoria = NEW.id_categoria
			--esto quiere decir que va a preguntar si en esa tabla de tiene_ancestros hay una instancia que su id sea igual al id de la categoria a registrar(el "elemento" nuevo)
			--en caso afirmativo(TRUE) implica que hay un caso donde alguien es su propio ancestro o se registra un caso donde un elemento menor quiere ser ancestro de otro (y no es lógico)
			--osea que hay ciclo
		) INTO existencia_ciclo;

		IF existencia_ciclo THEN
			RAISE EXCEPTION 'Imposible guardar esta categoria como padre, provocaría ciclo jerarquico';
		END IF;

	-- Aquí se podría añadir una consulta recursiva para validar ancestros, 
    -- pero para Postgres 14 es altamente eficiente usar el camino (path) o este chequeo simple. 
	--aun asi se genera la consulta recursiva
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create or replace function comprobacion_actividad_usuario()
returns trigger as $$
declare
	usuario_activo BOOLEAN;
	--en este trigger vamos a declarar una variable booleana para confirmar que usuario está activo
begin
		select activo into usuario_activo from usuarios where id_usuario = new.id_usuario_propietario
		--esto se pone porque un usuario que sea propietario de un evento solo puede tener estado activo
		if usuario_activo is false then 
			raise exception 'no se puede crear o cambiar un evento si el usuario no está activo';
		end if;
		return new;
end;
$$ language plpgsql;



create or replace function anti_traslape_eventos()
returns trigger as $$
declare 
	hay_traslape BOOLEAN;
	-- para confirmar si hay traslape o no en los eventos
begin
	if new.id_ubicacion is not null then
		select exists (
			select * from eventos pEvento where pEvento.id_ubicacion= new.id_ubicacion
			and pEvento.id_evento <> coalesce(new.id_evento,-3) and (pEvento.fecha_inicio,pEvento.fecha_fin) overlaps (new.fecha_inicio,new.fecha_fin)) into hay_traslape
			--se pone coalesce, pues por un trigger ya existente, el id_evento es nulo en un insert, por lo que siempre devolverá el -1
		if hay_traslape then
		--coalesce devuelve el primer valor no nulo de una lista
			raise exception 'la ubicación deseada ya está reservada, es decir que choca en algun punto el horario';
		end if;
--estoy pensando la idea para este select exists, pero puedo usar un ejemplo como eventos pEvento y comparar si su id_ubicacion es el mismo al id_ubicacion del nuevo registro que se quiere hacer
		
			--el overlaps es para ver si un evento choca con el nuevo, por eso es una consulta select, y luego select exists para ver si hay true o false
	end if;
	
	return new;
	
end;
$$ language plpgsql;



	
CREATE TRIGGER trg_evitar_ciclo
BEFORE INSERT OR UPDATE ON categorias
FOR EACH ROW EXECUTE FUNCTION evitar_ciclo_categorias();

create trigger trg_analisis_estado_usuario
before insert or update on eventos
for each row execute function comprobacion_actividad_usuario();

create trigger trg_no_traslapes_en_eventos
before insert or update on eventos
for each row execute  function anti_traslape_eventos();

--CASOS DE PRUEBA

insert into usuarios(nombre,apellido)
values ('Ana','Rodriguez');

select *from usuarios 

insert into series_eventos (id_usuario_propietario,titulo_serie,fecha_inicio,fecha_fin,clase_periodicidad,intervalo_en_dias_eventos,reserva_dias_especificos)
values (1,'Clase de yoga','2026-09-17','2026-12-17','semanal',null,'martes,jueves');
--prueba usando un caso válido de los constraints check


insert into series_eventos (id_usuario_propietario,titulo_serie,fecha_inicio,fecha_fin,clase_periodicidad,intervalo_en_dias_eventos,reserva_dias_especificos)
values (1,'Clase de yoga','2026-09-17','2026-12-17','semanal',null,null);
--este es el caso inválido para comprobar que el check funciona bien









