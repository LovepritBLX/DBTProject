SELECT 'Hello, World!' AS greeting;



-- {{ config(
--     materialized         = 'incremental',
--     unique_key           = ['DimPlantId','DimPlantScdId','DimDivisionId','DimDivisionScdId','DimMonthId'],
--     on_schema_change     = 'sync_all_columns'
-- ) }}

-- with last_run as (
--     select
--       -- Si la table n'existe pas encore (1er run), on force une ligne fallback
--       {% if is_incremental() %}
--         coalesce( (select max(ModifiedDate) from {{ this }}),
--                   cast('1900-01-01' as datetime2(0)) ) as max_mod
--       {% else %}
--         cast('1900-01-01' as datetime2(0)) as max_mod
--       {% endif %}
-- ),

-- src AS (
--     SELECT
--         i.PlantCode,
--         i.DivisionCode,
--         i.MonthId,
--         i.FirstDayOfMonth,
--         i.LastDayOfMonth,
--         i.ProductionKWh,
--         -- Dates techniques en l’état (normalisées dans le staging idéalement)
--         TRY_CONVERT(datetime2(0), i.InsertedDate, 120) AS InsertedDate,
--         TRY_CONVERT(datetime2(0), i.ModifiedDate, 120) AS ModifiedDate
--     FROM {{ ref('Int_ProductionMeteredByPlant') }} i
    
--     {% if is_incremental() %}
--       where try_convert(datetime2(0), i.ModifiedDate, 120) > (select max_mod from last_run)
--     {% endif %}
-- ),

-- /* ------------------------------
--    JOINTURES DIMENSIONS
--    - Plant/Division : AS IS (CurrentFlag='Y') + AS WAS (bandée sur LastDayOfMonth)
--    - Month          : sur DimMonthId = MonthId
--    ------------------------------ */

-- plant_as_is AS (
--   SELECT DimPlantId,  BusinessKey
--   FROM {{ ref('DimPlant') }}
--   WHERE CurrentFlag = 'Y'
-- ),
-- plant_as_was AS (
--   SELECT DimPlantScdId, BusinessKey, EffDate, EndDate
--   FROM {{ ref('DimPlant') }}
-- ),

-- division_as_is AS (
--   SELECT DimDivisionId, BusinessKey
--   FROM {{ ref('DimDivision') }}
--   WHERE CurrentFlag = 'Y'
-- ),
-- division_as_was AS (
--   SELECT DimDivisionScdId, BusinessKey, EffDate, EndDate
--   FROM {{ ref('DimDivision') }}
-- ),

-- /* ------------------------------
--    ENRICHISSEMENT AVEC LES DIMS
--    ------------------------------ */
-- enriched AS (
--   SELECT
--     -- Clés Dim AS IS
--     COALESCE(pis.DimPlantId,    -1) AS DimPlantId,
--     COALESCE(dis.DimDivisionId, -1) AS DimDivisionId,

--     -- Clés Dim AS WAS (bandées sur la fin de mois)
--     COALESCE(pwas.DimPlantScdId,    -1) AS DimPlantScdId,
--     COALESCE(dwas.DimDivisionScdId, -1) AS DimDivisionScdId,

--     -- Temps
--   s.MonthId as DimMonthId,

--     -- Mesures
--     s.ProductionKWh,

--     -- Audit
--     s.InsertedDate,
--     s.ModifiedDate
--   FROM src s

--   -- DimPlant AS IS
--   LEFT JOIN plant_as_is  pis
--     ON  s.PlantCode = pis.BusinessKey

--   -- DimPlant AS WAS (EffDate <= LastDayOfMonth < EndDate)
--   LEFT JOIN plant_as_was pwas
--     ON  s.PlantCode       = pwas.BusinessKey
--     AND s.LastDayOfMonth >= pwas.EffDate
--     AND s.LastDayOfMonth <  pwas.EndDate

--   -- DimDivision AS IS
--   LEFT JOIN division_as_is dis
--     ON  s.DivisionCode = dis.BusinessKey

--   -- DimDivision AS WAS
--   LEFT JOIN division_as_was dwas
--     ON  s.DivisionCode     = dwas.BusinessKey
--     AND s.LastDayOfMonth  >= dwas.EffDate
--     AND s.LastDayOfMonth  <  dwas.EndDate

-- ),

-- /* ------------------------------
--    AGRÉGATION FINALE AU GRAIN :
--    (DimPlantId, DimPlantScdId, DimDivisionId, DimDivisionScdId, DimMonthId)
--    ------------------------------ */
-- final AS (
--   SELECT
--     DimPlantId,
--     DimPlantScdId,
--     DimDivisionId,
--     DimDivisionScdId,
--     DimMonthId,

--     SUM(ProductionKWh)     AS ProductionKWh,
--     MAX(InsertedDate)      AS InsertedDate,
--     MAX(ModifiedDate)      AS ModifiedDate
--   FROM enriched
--   GROUP BY
--     DimPlantId, DimPlantScdId, DimDivisionId, DimDivisionScdId, DimMonthId
-- )

-- SELECT * FROM final;
