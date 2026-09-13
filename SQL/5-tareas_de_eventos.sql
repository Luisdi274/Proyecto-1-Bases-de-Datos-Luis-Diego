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