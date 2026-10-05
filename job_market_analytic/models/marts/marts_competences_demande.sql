WITH clean_code_competence AS (
    SELECT *, COALESCE(code_competence, LOWER(TRIM(libelle_competence))) as cle_competence
    FROM {{ ref('stg_job_competences') }}
)

SELECT cle_competence, MIN(libelle_competence) as libelle_competence, count(DISTINCT job_offert_id) as nb_offres
FROM clean_code_competence
GROUP BY cle_competence