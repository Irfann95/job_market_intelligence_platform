{{
    config(
        pre_hook=[
            "SET enable_case_sensitive_identifier TO true"
        ]
    )
}}

SELECT 
    raw_offers.id as job_offert_id,
    raw_offers.intitule as intitule_offres, 
    cast(raw_offers.lieutravail."codePostal" as VARCHAR(255)) as code_postal,
    cast(raw_offers.lieutravail."libelle" as VARCHAR(255)) as ville,
    cast(raw_offers.lieutravail."commune" as VARCHAR(255)) as commune,
    cast(raw_offers.entreprise."nom" as VARCHAR(255)) as entreprise_nom,
    raw_offers.experienceexige as experience_exige,
    raw_offers.experiencelibelle as experience_libelle,
    raw_offers.typecontrat as type_contrat,
    cast(raw_offers.salaire."libelle" as VARCHAR(255)) as salaire,
    raw_offers.datecreation as date_creation,
    raw_offers.dateactualisation as date_actualisation,
    raw_offers.romecode as rome_code,
    raw_offers.romelibelle as rome_libelle
FROM {{ source('job_market_analytic', 'raw_offers') }} raw_offers;