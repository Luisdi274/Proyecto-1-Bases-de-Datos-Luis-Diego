
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
			RAISE EXCEPTION 'Imposible guardar esta categoria como padre, provocaría cico jerarquico';
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
		if usuario activo is false then 
			raise exception 'no se puede crear o cambiar un evento si el usuario no está activo';
		end if;
end

	













CREATE TRIGGER trg_evitar_ciclo
BEFORE INSERT OR UPDATE ON categorias
FOR EACH ROW EXECUTE FUNCTION evitar_ciclo_categorias();

