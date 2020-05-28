/* number of different object types and storage by collection */
SELECT osf_collection.title, 
	   COUNT(DISTINCT project_nodes.root_id) AS num_projects,
	   COUNT(DISTINCT project_nodes.id) AS num_nodes,
	   COUNT(DISTINCT osf_files.id) AS num_files,
	   COUNT(DISTINCT osf_fileversion.id) AS num_versions,
	   SUM(size) AS storage
	FROM osf_collectionsubmission
	LEFT JOIN osf_collection
	ON osf_collectionsubmission.collection_id = osf_collection.id
	LEFT JOIN (SELECT *
				FROM osf_guid
				WHERE content_type_id = 30) as node_guids
	ON osf_collectionsubmission.guid_id = node_guids.id
	LEFT JOIN (SELECT *
				FROM osf_abstractnode
				WHERE type = 'osf.node' AND is_deleted IS FALSE AND is_public IS TRUE) as project_nodes
	ON node_guids.object_id = project_nodes.root_id
	LEFT JOIN (SELECT *
				 FROM osf_basefilenode
				 WHERE type = 'osf.osfstoragefile') as osf_files
	ON project_nodes.id = osf_files.target_object_id
	LEFT JOIN osf_basefileversionsthrough
	ON osf_files.id = osf_basefileversionsthrough.basefilenode_id
	LEFT JOIN osf_fileversion
	ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
	WHERE (collection_id = 711617 OR collection_id = 709754)
	GROUP BY osf_collection.title;


/* number of different object types and storage by branded registry (EGAP to start) */
SELECT COUNT(DISTINCT root_id) AS num_toplevel_reg,
	   COUNT(DISTINCT osf_abstractnode.id) AS num_reg_nodes,
	   COUNT(DISTINCT osf_files.id) AS num_files,
	   COUNT(DISTINCT osf_fileversion.id) AS num_versions,
	   SUM(size) AS storage
	FROM osf_abstractnode_registered_schema
	LEFT JOIN osf_abstractnode
	ON osf_abstractnode_registered_schema.abstractnode_id = osf_abstractnode.id
	LEFT JOIN (SELECT *
				 FROM osf_basefilenode
				 WHERE type = 'osf.osfstoragefile') as osf_files
	ON osf_abstractnode.id = osf_files.target_object_id
	LEFT JOIN osf_basefileversionsthrough
	ON osf_files.id = osf_basefileversionsthrough.basefilenode_id
	LEFT JOIN osf_fileversion
	ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
	WHERE registrationschema_id = 26 AND is_deleted IS FALSE

/* number of different object types and storage by 3 example OSF4I */
SELECT osf_institution.name,
		COUNT(DISTINCT (CASE WHEN nodes.type = 'osf.node' THEN root_id END)) AS num_topleve_projects,
		COUNT(DISTINCT (CASE WHEN nodes.type = 'osf.registration' THEN root_id END)) AS num_topleve_reg,
		COUNT(DISTINCT (CASE WHEN nodes.type = 'osf.node' THEN nodes.id END)) AS num_nonreg_nodes,
		COUNT(DISTINCT (CASE WHEN nodes.type = 'osf.registration' THEN nodes.id END)) AS num_reg_nodes,
		COUNT(DISTINCT (CASE WHEN nodes.type = 'osf.node' THEN osf_files.id END)) AS num_nonreg_files,
		COUNT(DISTINCT (CASE WHEN nodes.type = 'osf.registration' THEN osf_files.id END)) AS num_reg_files,
		COUNT(DISTINCT (CASE WHEN nodes.type = 'osf.node' THEN osf_fileversion.id END)) AS num_nonreg_file_version,
		COUNT(DISTINCT (CASE WHEN nodes.type = 'osf.registration' THEN osf_fileversion.id END)) AS num_reg_file_versions,
		SUM(size) AS storage
	FROM osf_abstractnode_affiliated_institutions
	LEFT JOIN (SELECT *
				FROM osf_abstractnode
				WHERE is_deleted IS FALSE) AS nodes
	ON osf_abstractnode_affiliated_institutions.abstractnode_id = nodes.id
	LEFT JOIN osf_institution
	ON osf_abstractnode_affiliated_institutions.institution_id = osf_institution.id
	LEFT JOIN (SELECT *
				 FROM osf_basefilenode
				 WHERE type = 'osf.osfstoragefile') as osf_files
	ON nodes.id = osf_files.target_object_id
	LEFT JOIN osf_basefileversionsthrough
	ON osf_files.id = osf_basefileversionsthrough.basefilenode_id
	LEFT JOIN osf_fileversion
	ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
	WHERE osf_abstractnode_affiliated_institutions.institution_id = 17 OR 
			osf_abstractnode_affiliated_institutions.institution_id = 58 OR 
			osf_abstractnode_affiliated_institutions.institution_id = 52
	GROUP BY osf_institution.name