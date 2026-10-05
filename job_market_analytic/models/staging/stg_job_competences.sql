SELECT ft.id as job_offert_id,
       cast(unnested_competences.competence."code" as varchar(6)) as code_competence,
       cast(unnested_competences.competence."libelle" as varchar(500)) as libelle_competence,
       cast(unnested_competences.competence."exigence" as varchar(1)) as exigence_competence

FROM {{ source('job_market_analytic', 'raw_offers') }} as ft, UNNEST(ft.competences) AS unnested_competences(competence)