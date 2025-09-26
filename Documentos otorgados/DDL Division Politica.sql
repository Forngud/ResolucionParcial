CREATE DATABASE DivisionPolitica
GO

USE DivisionPolitica
GO

/*
-- Consulta para conocer la estructura de una tabla
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME='Pais'

-- Consulta para conocer la estructura de los indices de una tabla	
SELECT sys.indexes.name AS Indice, 
	INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME AS Campo,
	sys.indexes.is_primary_key 
	FROM INFORMATION_SCHEMA.COLUMNS INNER JOIN sys.indexes 
			ON OBJECT_ID(TABLE_NAME) = [object_id] 
		INNER JOIN sys.index_columns 
			ON sys.indexes.index_id = sys.index_columns.index_id
			AND sys.indexes.[object_id] = sys.index_columns.[object_id]
			AND ORDINAL_POSITION=column_id 
	WHERE sys.indexes.[object_id] = OBJECT_ID('Ciudad') 
	ORDER BY sys.indexes.name, 
		sys.index_columns.index_column_id,
		INFORMATION_SCHEMA.COLUMNS.COLUMN_NAME
*/

/* Crear tabla CONTINENTE */
CREATE TABLE Continente( 
	Id int IDENTITY(1,1) NOT NULL, 
	CONSTRAINT pkContinente_Id PRIMARY KEY (Id),
	Nombre nvarchar(50) NOT NULL
)

/* Crear tabla TIPOREGION */
CREATE TABLE TipoRegion( 
	Id int IDENTITY(1,1) NOT NULL, 
	CONSTRAINT pkTipoRegion_Id PRIMARY KEY (Id),
	TipoRegion nvarchar(50) NOT NULL
)

/* Crear tabla PAIS */
CREATE TABLE Pais( 
	Id int IDENTITY(1,1) NOT NULL, 
	CONSTRAINT pkPais_Id PRIMARY KEY (Id),
	Nombre nvarchar(50) NOT NULL, 
	IdContinente int NOT NULL, 
	CONSTRAINT fkPais_IdContinente FOREIGN KEY (IdContinente)
		REFERENCES Continente(Id),
	IdTipoRegion int NOT NULL,
	CONSTRAINT fkPais_IdTipoRegion FOREIGN KEY (IdTipoRegion)
		REFERENCES TipoRegion(Id),
	Moneda nvarchar(30) NULL
)

/* Crear tabla REGION */
CREATE TABLE Region( 
	Id int IDENTITY(1,1) NOT NULL, 
	CONSTRAINT pkRegion_Id PRIMARY KEY (Id),
	Nombre nvarchar(50) NOT NULL, 
	IdPais int NOT NULL, 
	CONSTRAINT fkRegion_IdPais FOREIGN KEY (IdPais)
		REFERENCES Pais(Id),
	Area float NULL, 
	Poblacion int NULL
)

/* Crear tabla REGION */
CREATE TABLE Ciudad( 
	Id int IDENTITY(1,1) NOT NULL, 
	CONSTRAINT pkCiudad_Id PRIMARY KEY (Id),
	Nombre nvarchar(50) NOT NULL, 
	IdRegion int NOT NULL, 
	CONSTRAINT fkCiudad_IdRegion FOREIGN KEY (IdRegion)
		REFERENCES Region(Id),
	Area float NULL, 
	Poblacion int NULL,
	CapitalPais bit DEFAULT 0 NOT NULL,
	CapitalRegion bit DEFAULT 0 NOT NULL,
	AreaMetropolitana bit DEFAULT 0 NOT NULL
)

