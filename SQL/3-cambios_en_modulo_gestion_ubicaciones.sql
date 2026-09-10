create table UBICACIONES (
	id_ubicacion SERIAL primary key,
	nombre varchar(40) not null unique,
	ciudad varchar(60) not null,
	--este atributo no es unico, pues sino no se cumple lo de gestionar varias salas que pueden estar en la misma ciudad
	direccion varchar(120) not null,
	capacidad int not null
	--poner capacidad not null responde al requerimiento funcional #10 acerca de los reportes
);

