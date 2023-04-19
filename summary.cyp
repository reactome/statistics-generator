CALL apoc.export.json.query(
"MATCH (s:Species)<-[:species]-(e:PhysicalEntity)-[:referenceEntity]->(p:ReferenceGeneProduct)
  WHERE s.displayName = 'Homo sapiens'
RETURN 'prot' AS name, count(DISTINCT p) AS value

UNION

MATCH (s:Species)<-[:species]-(e:EntityWithAccessionedSequence)-[:referenceEntity]->(p:ReferenceGeneProduct)
  WHERE s.displayName = 'Homo sapiens'
RETURN 'netProt' AS name, count(DISTINCT p.identifier) AS value

UNION

MATCH (s:Species)<-[:species]-(rxn:ReactionLikeEvent)
  WHERE s.displayName = 'Homo sapiens'
RETURN 'rxn' AS name, count(rxn) AS value

UNION

MATCH (l:LiteratureReference)
RETURN 'litRef' AS name, count(l) AS value

UNION

MATCH (m:ReferenceMolecule)
RETURN 'chemicals' AS name, count(m) AS value

UNION

MATCH (e:EntityWithAccessionedSequence)
RETURN 'EWAS' AS name, count(e) AS value

UNION

MATCH(g:GeneticallyModifiedResidue)-[:referenceSequence]->(p:ReferenceGeneProduct)-[:species]->(s:Species)
  WHERE s.displayName = 'Homo sapiens'
RETURN 'DiseaseProt' AS name, count(DISTINCT p) AS value

UNION

MATCH (g:GeneticallyModifiedResidue)
WITH count(g) AS total
MATCH (g:GeneticallyModifiedResidue)-[:referenceSequence]->(p:ReferenceGeneProduct)-[:species]->(s:Species)
  WHERE s.displayName = 'Homo sapiens'
WITH count(DISTINCT g) AS human, total
RETURN 'DiseaseVar' AS name, total - human AS value

UNION

MATCH (d:ChemicalDrug)-[:referenceEntity]->(t:ReferenceTherapeutic)
RETURN 'chemDrug' AS name, count(DISTINCT t) AS value

UNION

MATCH (d:ProteinDrug)-[:referenceEntity]->(t:ReferenceTherapeutic)
RETURN 'protDrug' AS name, count(DISTINCT t) AS value

UNION

MATCH (s:Species)<-[:species]-(pathway:Pathway)
  WHERE s.displayName = 'Homo sapiens'
RETURN 'pathway' AS name, count(pathway) AS value
",
null,
{jsonFormat: 'ARRAY_JSON', stream: true}
)