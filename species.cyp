MATCH (species:Species)<-[:species]-(ewas:EntityWithAccessionedSequence)-[:referenceEntity]->(rgp:ReferenceGeneProduct)
WITH
   species,
   COUNT(DISTINCT rgp) AS raw_protein_count,
   COUNT(DISTINCT rgp.identifier) AS protein_count
WITH
    species,
    raw_protein_count,
    protein_count,
    raw_protein_count - protein_count AS isoform_count
MATCH (species:Species)<-[:species]-(rle:ReactionLikeEvent)
WITH
    species,
    raw_protein_count,
    protein_count,
    isoform_count,
    COUNT(rle) AS reaction_count
MATCH (species:Species)<-[:species]-(pathway:Pathway)
WITH
    species,
    raw_protein_count,
    protein_count,
    isoform_count,
    reaction_count,
    COUNT(pathway) AS pathway_count
MATCH (species:Species)<-[:species]-(complex:Complex)
WITH 
    species,
    raw_protein_count,
    protein_count,
    isoform_count,
    reaction_count,
    pathway_count,
    COUNT(complex) AS complex_count
RETURN 
    species.displayName AS species,
    protein_count AS protein,
    isoform_count AS isoform,
    complex_count AS complex,
    reaction_count AS reaction,
    pathway_count AS pathway
ORDER BY reaction DESC
