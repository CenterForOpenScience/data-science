/* Projects that exhibit multiple OSF product usages (OSF file sharing, registrations, preprints) */


/* How many non-deleted, not spam or flaggest as spam, top-level projects, excluding registrations, have at least 1 public component that has a file (e.g. are doing some sort of file sharing behavior)
Doesn't include linked components [DOES NOT INCLUDE LINKED PROJECTS/COMPONENTS] */
WITH existing_files AS (SELECT COUNT(*) AS num_files, target_object_id, MIN(created) AS first_file_created, MAX(created) AS last_file_created
													FROM osf_basefilenode
													WHERE type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30
													GROUP BY target_object_id),
	files_on_node AS (SELECT id, root_id, COALESCE(num_files,0) AS number_files, is_public, first_file_created, last_file_created, osf_abstractnode.created AS node_created
													FROM osf_abstractnode
													LEFT JOIN existing_files
													ON osf_abstractnode.id = existing_files.target_object_id
													WHERE type LIKE 'osf.node' AND is_deleted IS FALSE AND (spam_status = 4 OR spam_status IS NULL))

Select COUNT(DISTINCT root_id) AS sharing_projects
	FROM files_on_node
	WHERE number_files > 0 AND is_public IS TRUE;


/* How many non-deleted, not spam or flagged as spam, top-level projects have a currently active registration (not deleted, not withdrawn, not old private) or have a registration on at least one of their components. [DOES NOT INCLUDE LINKED PORJECTS/COMPONENTS] */
WITH registered_projects AS (SELECT DISTINCT ON (osf_abstractnode.root_id) osf_abstractnode.id, type, registered_date, root_id, is_public, is_deleted, date_retracted, embargo_id, osf_embargo.state, registered_from_id
								FROM osf_abstractnode
								LEFT JOIN osf_retraction
								ON osf_abstractnode.retraction_id = osf_retraction.id
								LEFT JOIN osf_embargo
								ON osf_abstractnode.embargo_id = osf_embargo.id
								WHERE type LIKE 'osf.registration' AND is_deleted IS FALSE AND (spam_status = 4 OR spam_status IS NULL) AND date_retracted IS NULL AND (is_public IS TRUE OR embargo_id IS NOT NULL)),
	nodes_with_registrations AS (SELECT osf_abstractnode.root_id, osf_abstractnode.id AS node_id, osf_abstractnode.created AS node_created, registered_projects.registered_date AS registration_date
										FROM osf_abstractnode
										FULL OUTER JOIN registered_projects
										ON osf_abstractnode.id = registered_projects.registered_from_id
										WHERE osf_abstractnode.type LIKE 'osf.node' AND osf_abstractnode.is_deleted IS FALSE AND (osf_abstractnode.spam_status = 4 OR osf_abstractnode.spam_status IS NULL))

SELECT COUNT(DISTINCT root_id)
	FROM nodes_with_registrations
	WHERE registration_date IS NOT NULL;



/* How many non-deleted, not spam or flagged as spam, top-level projects have a currently active registration (not deleted, not withdrawn, not old private) 
or have registrations on one of their components and also have at least 1 copmonent that is public and has a file [DOES NOT INCLUDE LINKED PROJECTS/COMPONENTS] */
WITH existing_files AS (SELECT COUNT(*) AS num_files, target_object_id, MIN(created) AS first_file_created, MAX(created) AS last_file_created
													FROM osf_basefilenode
													WHERE type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30
													GROUP BY target_object_id),
	registered_projects AS (SELECT DISTINCT ON (osf_abstractnode.root_id) osf_abstractnode.id, type, registered_date, root_id, is_public, is_deleted, date_retracted, embargo_id, osf_embargo.state, registered_from_id
													FROM osf_abstractnode
													LEFT JOIN osf_retraction
													ON osf_abstractnode.retraction_id = osf_retraction.id
													LEFT JOIN osf_embargo
													ON osf_abstractnode.embargo_id = osf_embargo.id
													WHERE type LIKE 'osf.registration' AND is_deleted IS FALSE AND (spam_status = 4 OR spam_status IS NULL) AND date_retracted IS NULL AND (is_public IS TRUE OR embargo_id IS NOT NULL)),
	files_and_registrations AS (SELECT osf_abstractnode.id AS node_id, osf_abstractnode.root_id, COALESCE(num_files,0) AS number_files, osf_abstractnode.is_public, first_file_created, last_file_created, osf_abstractnode.created AS node_created, registered_projects.registered_date AS registration_date
													FROM osf_abstractnode
													LEFT JOIN existing_files
													ON osf_abstractnode.id = existing_files.target_object_id
													LEFT JOIN registered_projects
													ON osf_abstractnode.id = registered_projects.registered_from_id
													WHERE osf_abstractnode.type LIKE 'osf.node' AND osf_abstractnode.is_deleted IS FALSE AND (osf_abstractnode.spam_status = 4 OR osf_abstractnode.spam_status IS NULL))

Select *
	FROM files_and_registrations;
	






- need to alter the part below to deal with supp_nodes that might be at the component level and have files shared a level down from the supp_node level itself

/* How many non-deleted, non-spam or flagged spam, top-level porjects have a node that is a supplemental node for a published preprint that have public files in it */
/* return all public preprints with their GUIDs, DOIs, and supplement GUID as well as the number of non-deleted files on the supplemental node and the date the first file was added*/
WITH supp_nodes AS (SELECT DISTINCT(node_id) supp_node_id, osf_abstractnode.root_id
						FROM osf_preprint pp
						LEFT JOIN osf_abstractnode
						ON pp.node_id = osf_abstractnode.root_id
						WHERE pp.node_id IS NOT NULL AND osf_abstractnode.is_deleted IS FALSE AND (osf_abstractnode.spam_status = 4 OR osf_abstractnode.spam_status IS NULL) AND osf_abstractnode.is_public IS TRUE AND 
								pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND pp.is_public = 'TRUE' AND primary_file_id IS NOT NULL AND pp.deleted IS NULL),
	 files_on_supp_nodes AS (SELECT supp_node_id, COUNT(node_files.id) number_files, MIN(created) first_file_added, MAX(created) last_file_added
	 						FROM supp_nodes
	 						LEFT JOIN (SELECT * FROM osf_basefilenode WHERE osf_basefilenode.type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30) AS node_files
	 						ON supp_nodes.supp_node_id = node_files.target_object_id
	 						GROUP BY supp_node_id)
	 supp_node_info AS (SELECT *
	 						FROM )

SELECT pp.id, pp.created, pp.modified, date_published, license_id, pp.node_id, provider_id, original_publication_date, article_doi, osf_guid._id AS preprint_guid, supplement_guid, value AS preprint_doi, osf_abstractprovider._id AS provider,
			number_files, first_file_added
	FROM osf_preprint pp
	JOIN osf_abstractprovider
	ON pp.provider_id = osf_abstractprovider.id
	FULL OUTER JOIN supp_node_files
	ON pp.node_id = supp_node_files.supp_node_id
	WHERE pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND osf_guid.content_type_id = 47 AND pp.is_public = 'TRUE' AND primary_file_id IS NOT NULL AND pp.deleted IS NULL;








/* How many non-deleted, not spam or flagged as spam, top-level projects, excluding registrations, have at least 1 public component with a file and have at least 1 component that has a currently active registraion */

