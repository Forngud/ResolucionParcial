-- Una región no puede tener sino una ciudad capital

CREATE TRIGGER tActualizarCapitalRegion
ON Ciudad
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si no hay ninguna fila marcada como CapitalRegion en la inserción/actualización, no hay nada que validar
    IF EXISTS (SELECT 1 FROM Inserted WHERE CapitalRegion = 1)
    BEGIN
        -- Verificar si la inserción/actualización causaría más de una capital por región
        IF EXISTS (
            SELECT 1
            FROM Inserted I
            JOIN Ciudad C ON I.IdRegion = C.IdRegion
            WHERE I.CapitalRegion = 1
              AND C.CapitalRegion = 1
              AND C.Id <> I.Id
            GROUP BY I.IdRegion
            HAVING COUNT(*) > 1
        )
        BEGIN
            RAISERROR('No se acepta más de una capital por región', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Si se está estableciendo una ciudad como capital, asegurarse de que las demás del mismo region queden en 0
        UPDATE C
        SET CapitalRegion = 0
        FROM Ciudad C
        JOIN Inserted I ON C.IdRegion = I.IdRegion
        WHERE C.Id <> I.Id
          AND I.CapitalRegion = 1;
    END
END
GO


-- Un país no puede tener sino una ciudad capital que no necesariamente tiene que ser capital de región.

CREATE TRIGGER tActualizarCapitalPais
ON Ciudad
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Evitar ejecución recursiva
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    -- Solo actuar si en la inserción/actualización se marcó CapitalPais = 1
    IF EXISTS (SELECT 1 FROM Inserted WHERE CapitalPais = 1)
    BEGIN
        -- Identificar la(s) ciudad(es) que quedan como última capital por país
        ;WITH UltimaCapital AS (
            SELECT C.Id, R.IdPais
            FROM Inserted I
            JOIN Ciudad C ON C.Id = I.Id
            JOIN Region R ON C.IdRegion = R.Id
            WHERE I.CapitalPais = 1
        )
        -- Actualizar: dejar solo la ciudad marcada como capital del país en 1, las demás en 0
        UPDATE C
        SET C.CapitalPais = CASE WHEN C.Id = U.Id THEN 1 ELSE 0 END
        FROM Ciudad C
        JOIN Region R ON C.IdRegion = R.Id
        JOIN UltimaCapital U ON U.IdPais = R.IdPais;
    END
END;
GO

-- Un país no puede figurar en más de un Grupo dentro del mismo Campeonato

CREATE TRIGGER tActualizarGrupoPais
ON GrupoPais
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar si algún país de la inserción/actualización
    -- ya está en otro grupo del mismo campeonato
    IF EXISTS (
        SELECT 1
        FROM Inserted I
        JOIN Grupo GNuevo ON GNuevo.Id = I.IdGrupo
        JOIN GrupoPais GP ON GP.IdPais = I.IdPais
        JOIN Grupo GExistente ON GExistente.Id = GP.IdGrupo
        WHERE GNuevo.IdCampeonato = GExistente.IdCampeonato
          AND GNuevo.Id <> GExistente.Id
    )
    BEGIN
        RAISERROR('Un país no puede pertenecer a más de un grupo en el mismo campeonato.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO


--  Basado en la anterior base de datos, validar que, en un mismo campeonato y fase, 
-- un encuentro entre dos países no puede repetirse. (Ejemplo: si ya existe Brasil vs 
-- Alemania en fase de grupos, no se puede volver a insertar ese mismo partido en 
-- esa fase del mismo campeonato)

CREATE TRIGGER dbo.tValidarEncuentroUnico
ON dbo.Encuentro
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT 
                I.IdCampeonato,
                I.IdFase,
                CASE WHEN I.IdPais1 < I.IdPais2 THEN I.IdPais1 ELSE I.IdPais2 END AS PaisMin,
                CASE WHEN I.IdPais1 < I.IdPais2 THEN I.IdPais2 ELSE I.IdPais1 END AS PaisMax,
                COUNT(*) AS cnt
            FROM inserted I
            GROUP BY 
                I.IdCampeonato, I.IdFase,
                CASE WHEN I.IdPais1 < I.IdPais2 THEN I.IdPais1 ELSE I.IdPais2 END,
                CASE WHEN I.IdPais1 < I.IdPais2 THEN I.IdPais2 ELSE I.IdPais1 END
            HAVING COUNT(*) > 1
        ) t
    )
    BEGIN
        RAISERROR('Inserción inválida: duplicado dentro del lote (mismo encuentro en el mismo campeonato/fase).',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted I
        JOIN Encuentro E
          ON E.IdCampeonato = I.IdCampeonato
         AND E.IdFase       = I.IdFase
         AND (
               (E.IdPais1 = I.IdPais1 AND E.IdPais2 = I.IdPais2)
            OR (E.IdPais1 = I.IdPais2 AND E.IdPais2 = I.IdPais1)
         )
        WHERE ISNULL(E.Id, -1) <> ISNULL(I.Id, -1)
    )
    BEGIN
        RAISERROR('Ya existe ese encuentro en la misma fase y campeonato.',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

