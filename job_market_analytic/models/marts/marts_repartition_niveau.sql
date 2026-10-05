WITH nb_by_niveau AS (
    SELECT  categorie_xp, 
            COUNT(job_offert_id) as nb,
            SUM(COUNT(job_offert_id)) OVER () as total
    FROM {{ ref('int_jobs_enriched') }}
    GROUP BY categorie_xp
),


nb_by_niveau_percentage AS (
    SELECT *,
        ROUND(100.0 * nb / total, 2) as percentage
    FROM nb_by_niveau
)

SELECT categorie_xp, percentage
FROM nb_by_niveau_percentage