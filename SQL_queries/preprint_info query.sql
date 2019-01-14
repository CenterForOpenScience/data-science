/* return all public preprints with their GUIDs, DOIs, and supplement GUID; There are some duplicates when same preprint in multiple sources, can tell how many by calling DISTINCT on pp.primary_file_id*/
WITH dois AS (SELECT osf_identifier.object_id, osf_identifier.value
				FROM osf_identifier
				WHERE content_type_id = 47 AND category = 'doi')

WITH supplement AS (SELECT DISTINCT(node_id), osf_guid._id supplement_guid
						FROM osf_preprint pp
						JOIN osf_guid
						ON pp.node_id = osf_guid.object_id
						WHERE osf_guid.content_type_id = 30)

SELECT *
	FROM osf_preprint pp
	LEFT JOIN osf_guid
	ON pp.id = osf_guid.object_id
	JOIN osf_abstractprovider
	ON pp.provider_id = osf_abstractprovider.id
	FULL OUTER JOIN dois
	ON pp.id = dois.object_id
	WHERE pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND osf_guid.content_type_id = 47 AND pp.deleted IS NULL;