/* number of different object types and storage by each OSF4I */
WITH osf4I_files AS (SELECT root_id,
							nodes.type,
							nodes.id AS node_id,
							osf_files.id AS file_id,
							osf_institution.name
						FROM osf_abstractnode_affiliated_institutions
						LEFT JOIN (SELECT *
									FROM osf_abstractnode
									WHERE is_deleted IS FALSE AND (spam_status IS NULL OR spam_status = 4 OR spam_status = 1) AND title NOT LIKE 'Bookmarks') AS nodes
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
		COUNT(DISTINCT (CASE WHEN type = 'osf.node' THEN root_id END)) AS num_toplevel_projects,
		COUNT(DISTINCT (CASE WHEN type = 'osf.registration' THEN root_id END)) AS num_toplevel_reg,
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