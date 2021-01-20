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