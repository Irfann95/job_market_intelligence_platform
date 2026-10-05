SELECT departement, AVG(salaire_annuel_moyen) as salaire_moyen, count(*) as nb_offres, count(salaire_annuel_moyen) as nb_offres_salaire
FROM {{ ref('int_jobs_enriched') }} 
WHERE departement != 'non renseigné' 
GROUP BY departement;
