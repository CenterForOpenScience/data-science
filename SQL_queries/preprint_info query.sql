/*return subjects (disciplines) on each preprint*/
SELECT osf_preprint.id preprint_id, osf_preprint.created, osf_preprint.modified, osf_preprint.is_published, osf_preprint.date_published, machine_state, original_publication_date, ever_public, spam_status, primary_file_id, creator_id, is_public, deleted, article_doi, subject_id, text, parent_id, bepress_subject_id, osf_abstractprovider._id
	FROM osf_preprint
	LEFT JOIN osf_preprint_subjects
	ON osf_preprint.id = osf_preprint_subjects.preprint_id
	LEFT JOIN osf_subject
	ON osf_preprint_subjects.subject_id = osf_subject.id
	JOIN osf_abstractprovider
	ON osf_preprint.provider_id = osf_abstractprovider.id;

/*prperint tags*/
SELECT osf_preprint.id preprint_id, osf_preprint.created, osf_preprint.modified, osf_preprint.is_published, osf_preprint.date_published, machine_state, original_publication_date, ever_public, spam_status, primary_file_id, creator_id, is_public, deleted, article_doi, osf_tag.name, osf_tag.system,osf_abstractprovider._id
	FROM osf_preprint
	LEFT JOIN osf_preprint_tags
	ON osf_preprint.id = osf_preprint_tags.preprint_id
	LEFT JOIN osf_tag
	ON osf_preprint_tags.tag_id = osf_tag.id
	JOIN osf_abstractprovider
	ON osf_preprint.provider_id = osf_abstractprovider.id;


/* return all public preprints with their GUIDs, DOIs, and supplement GUID; There are some duplicates when same preprint in multiple sources, can tell how many by calling DISTINCT on pp.primary_file_id*/
WITH dois AS (SELECT osf_identifier.object_id, osf_identifier.value
				FROM osf_identifier
				WHERE content_type_id = 47 AND category = 'doi'),
	supplement AS (SELECT DISTINCT(node_id), osf_guid._id supplement_guid
						FROM osf_preprint pp
						JOIN osf_guid
						ON pp.node_id = osf_guid.object_id
						WHERE osf_guid.content_type_id = 30)

SELECT pp.created, pp.modified, date_published, license_id, pp.node_id, provider_id, original_publication_date, article_doi, osf_guid._id AS preprint_guid, supplement_guid, value AS preprint_doi, osf_abstractprovider._id AS provider
	FROM osf_preprint pp
	LEFT JOIN osf_guid
	ON pp.id = osf_guid.object_id
	JOIN osf_abstractprovider
	ON pp.provider_id = osf_abstractprovider.id
	FULL OUTER JOIN dois
	ON pp.id = dois.object_id
	FULL OUTER JOIN supplement
	ON pp.node_id = supplement.node_id
	WHERE pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND osf_guid.content_type_id = 47 AND pp.is_public = 'TRUE' AND primary_file_id IS NOT NULL AND pp.deleted IS NULL;


/* return all public preprints with their GUIDs and DOIs; There are some duplicates when same preprint in multiple sources, can tell how many by calling DISTINCT on pp.primary_file_id*/
WITH dois AS (SELECT osf_identifier.object_id, osf_identifier.value
				FROM osf_identifier
				WHERE content_type_id = 47 AND category = 'doi')
SELECT *
	FROM osf_preprint pp
	LEFT JOIN osf_guid
	ON pp.id = osf_guid.object_id
	JOIN osf_abstractprovider
	ON pp.provider_id = osf_abstractprovider.id
	FULL OUTER JOIN dois
	ON pp.id = dois.object_id
	WHERE pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND osf_guid.content_type_id = 47 AND pp.deleted IS NULL;


/*how many osfpreprints have pub DOIs*/
SELECT COUNT(DISTINCT osf_preprintservice.id), osf_abstractprovider._id, osf_abstractprovider.id
	FROM osf_subject
	INNER JOIN osf_preprintservice_subjects
	ON osf_subject.id = osf_preprintservice_subjects.subject_id
	JOIN osf_preprintservice
	ON osf_preprintservice.id = osf_preprintservice_subjects.preprintservice_id
	JOIN osf_abstractprovider
	ON osf_subject.provider_id = osf_abstractprovider.id
	GROUP BY osf_abstractprovider._id, osf_abstractprovider.id;


/*who is posting a preprint*/
SELECT osf_preprint.id preprint_id, osf_preprint.created preprint_created, osf_preprint.modified preprint_modified, is_published, date_published, license_id, node_id, provider_id, machine_state, original_publication_date, ever_public, primary_file_id, creator_id, is_public, osf_preprint.deleted preprint_deleted, article_doi, title, last_login, username, fullname, is_registered, is_invited, date_registered, date_confirmed, date_disabled, timezone, locale, requested_deactivation, is_active, osf_osfuser.deleted user_deleted
	FROM osf_preprint
	LEFT JOIN osf_osfuser
	ON osf_preprint.creator_id = osf_osfuser.id;


/*how many preprints has each user posted?*/
SELECT osf_osfuser.id, fullname, username, count, creator_id 
	FROM (SELECT COUNT(osf_preprint.id), osf_preprint.creator_id
			FROM osf_preprint
			GROUP BY osf_preprint.creator_id) user_counts 
	LEFT JOIN osf_osfuser
	ON user_counts.creator_id = osf_osfuser.id;


/*Who are collaborators on each preprint? Could later get what preprints someone is a collaborator on but not uploader of through filtering out cases where creater_id and user_id are the same thing*/
SELECT preprint_id, user_id, username, fullname, is_registered, is_invited, date_registered, date_disabled, timezone, locale, requested_deactivation, is_active, merged_by_id, is_published, osf_preprint.created, date_published, license_id, node_id, provider_id, machine_state, ever_public, creator_id, is_public, osf_preprint.deleted
	FROM osf_preprintcontributor
	LEFT JOIN osf_osfuser
	ON osf_preprintcontributor.user_id = osf_osfuser.id
	JOIN osf_preprint
	ON osf_preprintcontributor.preprint_id = osf_preprint.id;


/* return all public preprints with their GUIDs, DOIs, and supplement GUID as well as the number of non-deleted files on the supplemental node and the date the first file was added*/
WITH dois AS (SELECT osf_identifier.object_id, osf_identifier.value
				FROM osf_identifier
				WHERE content_type_id = 47 AND category = 'doi'),
	supp_nodes AS (SELECT DISTINCT(node_id) supp_node_id, osf_guid._id supplement_guid, COALESCE(osf_abstractnode.id, node_id) all_node_id, osf_abstractnode.root_id
						FROM osf_preprint pp
						JOIN osf_guid
						ON pp.node_id = osf_guid.object_id
						LEFT JOIN osf_abstractnode
						ON pp.node_id = osf_abstractnode.root_id
						WHERE osf_guid.content_type_id = 30 AND pp.node_id IS NOT NULL),
	 supp_node_files AS (SELECT supp_node_id, supplement_guid, COUNT(node_files.id) number_files, MIN(created) first_file_added
	 						FROM supp_nodes
	 						LEFT JOIN (SELECT * FROM osf_basefilenode WHERE osf_basefilenode.type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30) AS node_files
	 						ON supp_nodes.all_node_id = node_files.target_object_id
	 						GROUP BY supp_node_id, supplement_guid)

SELECT pp.id, pp.created, pp.modified, date_published, license_id, pp.node_id, provider_id, original_publication_date, article_doi, osf_guid._id AS preprint_guid, supplement_guid, value AS preprint_doi, osf_abstractprovider._id AS provider,
			number_files, first_file_added
	FROM osf_preprint pp
	LEFT JOIN osf_guid
	ON pp.id = osf_guid.object_id
	JOIN osf_abstractprovider
	ON pp.provider_id = osf_abstractprovider.id
	FULL OUTER JOIN dois
	ON pp.id = dois.object_id
	FULL OUTER JOIN supp_node_files
	ON pp.node_id = supp_node_files.supp_node_id
	WHERE pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND osf_guid.content_type_id = 47 AND pp.is_public = 'TRUE' AND primary_file_id IS NOT NULL AND pp.deleted IS NULL;