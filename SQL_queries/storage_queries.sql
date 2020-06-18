/* number of different object types, storage, and views/downloads by collection */
WITH collection_files AS (SELECT osf_collection.title, 
							   	project_nodes.root_id AS root_id,
							    project_nodes.id AS node_id,
							    osf_files.id AS file_id
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
							WHERE (collection_id = 711617 OR collection_id = 709754)),
	file_actions AS (SELECT file_id, Min(_id), action, Max(total),
							CASE WHEN action = 'download' THEN Max(total) ELSE 0 END AS downloads,
							CASE WHEN action = 'view' THEN Max(total) ELSE 0 END AS views
							FROM osf_pagecounter
							WHERE file_id IN (SELECT file_id from collection_files)
							GROUP BY file_id, action)

SELECT collection_files.title,  
	   COUNT(DISTINCT root_id) AS num_projects,
	   COUNT(DISTINCT node_id) AS num_nodes,
	   COUNT(DISTINCT collection_files.file_id) AS num_files,
	   SUM(num_versions) AS num_versions,
	   SUM(storage) AS storage,
	   SUM(downloads) AS downloads,
	   SUM(views) AS views
	FROM collection_files
	LEFT JOIN (SELECT osf_basefilenode.id, Max(target_object_id) as target_object_id, SUM(size) AS storage, COUNT(DISTINCT osf_fileversion.id) AS num_versions
					FROM osf_basefilenode
					LEFT JOIN osf_basefileversionsthrough
					ON osf_basefilenode.id = osf_basefileversionsthrough.basefilenode_id
					LEFT JOIN osf_fileversion
					ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
					WHERE type = 'osf.osfstoragefile' AND osf_basefilenode.id IN (SELECT file_id from collection_files)
					GROUP BY osf_basefilenode.id) AS file_info
	ON collection_files.file_id = file_info.id
	LEFT JOIN (SELECT file_id, SUM(downloads) as downloads, SUM(views) AS views
				 FROM file_actions
				 GROUP BY file_id) as actions_file
	ON collection_files.file_id = actions_file.file_id
	GROUP BY collection_files.title;


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