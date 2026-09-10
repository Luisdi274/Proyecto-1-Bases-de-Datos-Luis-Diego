create table SERIES_EVENTOS (
    id_serie SERIAL primary key,
    id_usuario_propietario int not null REFERENCES usuarios(id_usuario)
    --esta es la llave foranea de esta tabla
    titulo_serie varchar(90) not null,
    --lo que aparece en pantalla de la aplicacion no puede ser nulo, es un titulo especifico para la serie del evento

    fecha_inicio date not null,
    fecha_fin date not null,
    clase_periodicidad varchar(15) not null,
    --debe ser diaria,semanal, mensual o personalizada, pero nunca nula, luego se le agregará un check
    intervalo_en_dias_eventos int,
    --este es el campo que se debe llenar en caso de que sea personalizado, de lo contrario es nulo, pues se sobre entiende
    --por la clase de periodicidad
    reserva_dias_especificos varchar(50)
    --si la periodicidad es semanal, se debe especificar valores,sino es nula
);