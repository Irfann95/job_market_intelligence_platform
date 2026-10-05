WITH number_experience_year as ( 
    SELECT 
        *,
        CASE 
            WHEN regexp_substr(experience_libelle, '[0-9]+') != '' THEN CAST(regexp_substr(experience_libelle, '[0-9]+') AS INTEGER)
        END AS number
    FROM {{ ref('stg_jobs') }}
),


departement AS (
    SELECT *,
        CASE
            WHEN regexp_substr(ville, '^[0-9]+', 1,1, 'i') != '' THEN CAST(regexp_substr(ville, '^[0-9]+', 1,1, 'i') AS VARCHAR(4))
            ELSE 'non renseigné'
        END AS departement 
    FROM number_experience_year

),

categorie AS (
    SELECT 
        *,
        CASE 
            WHEN (experience_exige = 'E' AND experience_libelle LIKE '%An(s)%' AND number BETWEEN 0 AND 1) OR (experience_exige = 'D' AND experience_libelle = 'Débutant accepté' AND number IS NULL) OR (experience_exige = 'E' AND experience_libelle LIKE '%Mois%' AND number BETWEEN 0 AND 23 ) THEN 'Junior'
            WHEN (experience_exige = 'E' AND experience_libelle LIKE '%An(s)%' AND number BETWEEN 2 AND 4) OR (experience_exige = 'E' AND experience_libelle LIKE '%Mois%' AND number BETWEEN 24 AND 59 ) THEN 'Confirmé'
            WHEN (experience_exige = 'E' AND experience_libelle LIKE '%An(s)%' AND number >=5) OR (experience_exige = 'E' AND experience_libelle LIKE '%Mois%' AND number >= 60 ) THEN 'Senior'
            ELSE 'Non précisé'
        END AS categorie_xp
    FROM departement
),

error_check AS (
    SELECT *,
        CASE 
            WHEN REGEXP_SUBSTR(salaire, '^Mensuel', 1, 1, 'i') != '' AND (
                (REGEXP_SUBSTR(salaire, 'de [0-9]+', 1, 1) != '' AND CASE WHEN REGEXP_SUBSTR(REGEXP_SUBSTR(salaire, 'de [0-9]+(\\.[0-9]+)? Euros', 1, 1), '[0-9]+') ~ '^[0-9]+$' THEN CAST(REGEXP_SUBSTR(REGEXP_SUBSTR(salaire, 'de [0-9]+(\\.[0-9]+)? Euros', 1, 1), '[0-9]+') AS INTEGER) ELSE 0 END > 20000)
                OR 
                (REGEXP_SUBSTR(salaire, 'à [0-9]+', 1, 1) != '' AND CASE WHEN REGEXP_SUBSTR(REGEXP_SUBSTR(salaire, 'à [0-9]+(\\.[0-9]+)? Euros', 1, 1), '[0-9]+') ~ '^[0-9]+$' THEN CAST(REGEXP_SUBSTR(REGEXP_SUBSTR(salaire, 'à [0-9]+(\\.[0-9]+)? Euros', 1, 1), '[0-9]+') AS INTEGER) ELSE 0 END > 20000)
            )            
            THEN REPLACE(salaire, REGEXP_SUBSTR(salaire, 'Mensuel', 1, 1, 'i'), 'Annuel')
            
            WHEN REGEXP_SUBSTR(salaire, '^Annuel', 1, 1, 'i') != '' AND (
                (REGEXP_SUBSTR(salaire, 'de [0-9]+', 1, 1) != '' AND CASE WHEN REGEXP_SUBSTR(REGEXP_SUBSTR(salaire, 'de [0-9]+(\\.[0-9]+)? Euros', 1, 1), '[0-9]+') ~ '^[0-9]+$' THEN CAST(REGEXP_SUBSTR(REGEXP_SUBSTR(salaire, 'de [0-9]+(\\.[0-9]+)? Euros', 1, 1), '[0-9]+') AS INTEGER) ELSE 99999 END < 10000)
                OR 
                (REGEXP_SUBSTR(salaire, 'à [0-9]+', 1, 1) != '' AND CASE WHEN REGEXP_SUBSTR(REGEXP_SUBSTR(salaire, 'à [0-9]+(\\.[0-9]+)? Euros', 1, 1), '[0-9]+') ~ '^[0-9]+$' THEN CAST(REGEXP_SUBSTR(REGEXP_SUBSTR(salaire, 'à [0-9]+(\\.[0-9]+)? Euros', 1, 1), '[0-9]+') AS INTEGER) ELSE 99999 END < 10000)
            )            
            THEN REPLACE(salaire, REGEXP_SUBSTR(salaire, 'Annuel', 1, 1, 'i'), 'Mensuel')
            
            ELSE salaire
        END AS new_salary
    FROM categorie
),

salaire_analysis AS (
    SELECT *,
        CASE 
            WHEN REGEXP_SUBSTR(new_salary, 'de [0-9]+(\\.[0-9]+)? Euros', 1, 1) = '' THEN NULL 
            ELSE CAST(REGEXP_SUBSTR(REGEXP_SUBSTR(new_salary, 'de [0-9]+(\\.[0-9]+)? Euros'), '[0-9]+(\\.[0-9]+)?') AS DECIMAL(12,2)) 
        END AS premier_salaire,
        
        CASE 
            WHEN REGEXP_SUBSTR(new_salary, 'à [0-9]+(\\.[0-9]+)? Euros', 1, 1) = '' THEN NULL 
            ELSE CAST(REGEXP_SUBSTR(REGEXP_SUBSTR(new_salary, 'à [0-9]+(\\.[0-9]+)? Euros'), '[0-9]+(\\.[0-9]+)?') AS DECIMAL(12,2)) 
        END AS deuxieme_salaire
    FROM error_check
),

avg_salaire AS (
    SELECT *, 
        CASE 
            WHEN premier_salaire IS NOT NULL AND deuxieme_salaire IS NOT NULL 
                THEN (premier_salaire + deuxieme_salaire) / 2.0
            WHEN premier_salaire IS NOT NULL 
                THEN premier_salaire 
            ELSE NULL
        END AS avg_salaire
    FROM salaire_analysis
),

avg_salaire_v2 AS (
    SELECT *, 
            CASE 
                WHEN REGEXP_SUBSTR(new_salary, '^mensuel', 1, 1, 'i') != '' THEN avg_salaire*12
                ELSE avg_salaire
            END AS salaire_annuel_moyen
    FROM avg_salaire
)

SELECT *
FROM avg_salaire_v2