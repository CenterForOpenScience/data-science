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
										WHERE type = 'osf.node' AND is_deleted IS FALSE AND is_public IS TRUE AND (spam_status IS NULL OR spam_status = 4 OR spam_status = 1) AND title IS NOT LIKE 'Bookmarks') as project_nodes
							ON node_guids.object_id = project_nodes.root_id
							LEFT JOIN (SELECT *
										 FROM osf_basefilenode
										 WHERE type = 'osf.osfstoragefile') as osf_files
							ON project_nodes.id = osf_files.target_object_id
							WHERE (collection_id = 711617 OR collection_id = 709754 OR collection_id = 775210 OR collection_id = 735729)),
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
	   COALESCE(SUM(num_versions),0) AS num_versions,
	   COALESCE(SUM(storage),0) AS storage,
	   COALESCE(SUM(downloads),0) AS downloads,
	   COALESCE(SUM(views),0) AS views
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
WITH registries_files AS (SELECT root_id, 
								 osf_abstractnode.id AS node_id,
								 osf_files.id AS file_id
							FROM osf_abstractnode_registered_schema
							LEFT JOIN osf_abstractnode
							ON osf_abstractnode_registered_schema.abstractnode_id = osf_abstractnode.id
							LEFT JOIN (SELECT *
										 FROM osf_basefilenode
										 WHERE type = 'osf.osfstoragefile') as osf_files
							ON osf_abstractnode.id = osf_files.target_object_id
							WHERE registrationschema_id = 26 AND is_deleted IS FALSE),
	 file_actions AS (SELECT file_id, Min(_id), action, Max(total),
	 						 CASE WHEN action = 'download' THEN Max(total) ELSE 0 END AS downloads,
							 CASE WHEN action = 'view' THEN Max(total) ELSE 0 END AS views
						FROM osf_pagecounter
						WHERE file_id IN (SELECT file_id from registries_files)
						GROUP BY file_id, action)

SELECT COUNT(DISTINCT root_id) AS num_toplevel_reg,
	   COUNT(DISTINCT node_id) AS num_reg_nodes,
	   COUNT(DISTINCT registries_files.file_id) AS num_files,
	   SUM(num_versions) AS num_versions,
	   SUM(storage) AS storage,
	   SUM(downloads) AS downloads,
	   SUM(views) AS views
	FROM registries_files
	LEFT JOIN (SELECT osf_basefilenode.id, Max(target_object_id) as target_object_id, SUM(size) AS storage, COUNT(DISTINCT osf_fileversion.id) AS num_versions
					FROM osf_basefilenode
					LEFT JOIN osf_basefileversionsthrough
					ON osf_basefilenode.id = osf_basefileversionsthrough.basefilenode_id
					LEFT JOIN osf_fileversion
					ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
					WHERE type = 'osf.osfstoragefile' AND osf_basefilenode.id IN (SELECT file_id from registries_files)
					GROUP BY osf_basefilenode.id) AS file_info
	ON registries_files.file_id = file_info.id
	LEFT JOIN (SELECT file_id, SUM(downloads) as downloads, SUM(views) AS views
				 FROM file_actions
				 GROUP BY file_id) as actions_file
	ON registries_files.file_id = actions_file.file_id
	

/* number of different object types and storage by each non-COS OSF4I */
WITH osf4I_files AS (SELECT root_id,
							nodes.type,
							nodes.id AS node_id,
							osf_files.id AS file_id,
							osf_institution.name
						FROM osf_abstractnode_affiliated_institutions
						LEFT JOIN (SELECT *
									FROM osf_abstractnode
									WHERE is_deleted IS FALSE AND (spam_status IS NULL OR spam_status = 4 OR spam_status = 1) AND title IS NOT LIKE 'Bookmarks') AS nodes
						ON osf_abstractnode_affiliated_institutions.abstractnode_id = nodes.id
						LEFT JOIN osf_institution
						ON osf_abstractnode_affiliated_institutions.institution_id = osf_institution.id
						LEFT JOIN (SELECT *
									 FROM osf_basefilenode
									 WHERE type = 'osf.osfstoragefile') as osf_files
						ON nodes.id = osf_files.target_object_id
						WHERE osf_abstractnode_affiliated_institutions.institution_id != 65),
	 file_actions AS (SELECT file_id, Min(_id), action, Max(total),
	 						 CASE WHEN action = 'download' THEN Max(total) ELSE 0 END AS downloads,
							 CASE WHEN action = 'view' THEN Max(total) ELSE 0 END AS views
						FROM osf_pagecounter
						WHERE file_id IN (SELECT file_id from osf4I_files)
						GROUP BY file_id, action)

SELECT name,
		COUNT(DISTINCT (CASE WHEN type = 'osf.node' THEN root_id END)) AS num_topleve_projects,
		COUNT(DISTINCT (CASE WHEN type = 'osf.registration' THEN root_id END)) AS num_topleve_reg,
		COUNT(DISTINCT (CASE WHEN type = 'osf.node' THEN node_id END)) AS num_nonreg_nodes,
		COUNT(DISTINCT (CASE WHEN type = 'osf.registration' THEN node_id END)) AS num_reg_nodes,
		COUNT(DISTINCT (CASE WHEN type = 'osf.node' THEN osf4I_files.file_id END)) AS num_nonreg_files,
		COUNT(DISTINCT (CASE WHEN type = 'osf.registration' THEN osf4I_files.file_id END)) AS num_reg_files,
		COALESCE(SUM(CASE WHEN type = 'osf.node' THEN num_versions END),0) AS num_nonreg_file_version,
		COALESCE(SUM(CASE WHEN type = 'osf.registration' THEN num_versions END),0) AS num_reg_file_versions,
		COALESCE(SUM(storage),0) AS storage,
		COALESCE(SUM(downloads),0) AS downloads,
	    COALESCE(SUM(views),0) AS views
	FROM osf4I_files
	LEFT JOIN (SELECT osf_basefilenode.id, Max(target_object_id) as target_object_id, SUM(size) AS storage, COUNT(DISTINCT osf_fileversion.id) AS num_versions
					FROM osf_basefilenode
					LEFT JOIN osf_basefileversionsthrough
					ON osf_basefilenode.id = osf_basefileversionsthrough.basefilenode_id
					LEFT JOIN osf_fileversion
					ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
					WHERE type = 'osf.osfstoragefile' AND osf_basefilenode.id IN (SELECT file_id from osf4I_files)
					GROUP BY osf_basefilenode.id) AS file_info
	ON osf4I_files.file_id = file_info.id
	LEFT JOIN (SELECT file_id, SUM(downloads) as downloads, SUM(views) AS views
				 FROM file_actions
				 GROUP BY file_id) as actions_file
	ON osf4I_files.file_id = actions_file.file_id
	GROUP BY name




/* number of OSF4I nodes that are above the potential storage capts */
WITH institutional_storage AS (SELECT nodes.id, 
									 institution_id,
									 is_deleted,
									 is_fork,
									 is_public,
									 nodes.type,
									 SUM(size) AS storage
							  	FROM (SELECT DISTINCT(abstractnode_id), institution_id
							  			FROM osf_abstractnode_affiliated_institutions
							  			WHERE institution_id != 12) AS institution /* exclude COS osf4I nodes */
								LEFT JOIN (SELECT *
											FROM osf_abstractnode
											WHERE is_deleted IS FALSE) AS nodes
								ON institution.abstractnode_id = nodes.id
								LEFT JOIN (SELECT *
											 FROM osf_basefilenode
											 WHERE type = 'osf.osfstoragefile') as osf_files
								ON nodes.id = osf_files.target_object_id
								LEFT JOIN osf_basefileversionsthrough
								ON osf_files.id = osf_basefileversionsthrough.basefilenode_id
								LEFT JOIN osf_fileversion
								ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
								WHERE nodes.type = 'osf.node' AND is_deleted IS FALSE
								GROUP BY nodes.id, institution_id, is_deleted, is_fork, is_public, nodes.type)
SELECT
	sum(CASE WHEN storage > 5*1024^3 AND is_public IS FALSE THEN 1 ELSE 0 END) AS private_overlimit,
	sum(CASE WHEN storage >= 4*1014^3 AND storage <= 5*1024^3 AND is_public IS FALSE THEN 1 ELSE 0 END) AS private_nearlimit,
	sum(CASE WHEN storage > 50*1024^3 AND is_public IS TRUE THEN 1 ELSE 0 END) AS public_overlimit,
	sum(CASE WHEN storage >= 45*1024^3 AND storage <= 50*1024^3 AND is_public IS TRUE THEN 1 ELSE 0 END) AS public_nearlimit 
	FROM institutional_storage
	WHERE storage IS NOT NULL;

/* number of forked nodes that are over potential storage caps */
WITH fork_storage AS (SELECT nodes.id, 
									 is_deleted,
									 is_fork,
									 is_public,
									 nodes.type,
									 SUM(size) AS storage
								FROM (SELECT *
											FROM osf_abstractnode
											WHERE is_deleted IS FALSE AND type = 'osf.node' AND is_fork IS TRUE) AS nodes
								LEFT JOIN (SELECT *
											 FROM osf_basefilenode
											 WHERE type = 'osf.osfstoragefile') as osf_files
								ON nodes.id = osf_files.target_object_id
								LEFT JOIN osf_basefileversionsthrough
								ON osf_files.id = osf_basefileversionsthrough.basefilenode_id
								LEFT JOIN osf_fileversion
								ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
								GROUP BY nodes.id, is_deleted, is_fork, is_public, nodes.type)
SELECT
	sum(CASE WHEN storage > 5*1024^3 AND is_public IS FALSE THEN 1 ELSE 0 END) AS private_overlimit,
	sum(CASE WHEN storage >= 4*1014^3 AND storage <= 5*1024^3 AND is_public IS FALSE THEN 1 ELSE 0 END) AS private_nearlimit,
	sum(CASE WHEN storage > 50*1024^3 AND is_public IS TRUE THEN 1 ELSE 0 END) AS public_overlimit,
	sum(CASE WHEN storage >= 45*1024^3 AND storage <= 50*1024^3 AND is_public IS TRUE THEN 1 ELSE 0 END) AS public_nearlimit 
	FROM fork_storage
	WHERE storage IS NOT NULL;


SELECT COUNT(id), is_public
	FROM osf_abstractnode
	WHERE is_deleted IS FALSE AND type = 'osf.node' AND (spam_status = 1 OR spam_status = 4 OR spam_status IS NULL) AND title NOT LIKE 'Bookmarks'
	GROUP BY is_public 

