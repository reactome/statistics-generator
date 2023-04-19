MATCH (s:Species)
MATCH (s)<-[:species]-(e:EntityWithAccessionedSequence)-[:referenceEntity]->(p:ReferenceGeneProduct)
WITH count (DISTINCT p) AS rawProt, count(DISTINCT p.identifier) AS prot, s
WITH rawProt - prot AS iso, rawProt, prot, s
MATCH (s)<-[:species]-(rxn:ReactionLikeEvent)
WITH count(rxn) AS rxn, prot, iso, rawProt, s
MATCH (s)<-[:species]-(pathway:Pathway)
WITH count(pathway) AS pathway, rxn, iso, prot, rawProt, s
MATCH (s)<-[:species]-(complex:Complex)
WITH count(complex) AS complex, pathway, rxn, iso, prot, rawProt, s
RETURN s.displayName AS Species, prot AS PROTEINS, complex AS COMPLEXES, rxn AS REACTIONS, pathway AS PATHWAYS, rawProt
  ORDER BY REACTIONS DESC