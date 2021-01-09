/* number of different object types, storage, and views/downloads by collection */

WITH collection_files AS (SELECT osf_abstractprovider.name, 
							   	project_nodes.root_id AS root_id,
							    project_nodes.id AS node_id,
							    osf_files.id AS file_id
							FROM osf_abstractprovider 
							LEFT JOIN osf_collectionsubmission
							ON osf_abstractprovider.primary_collection_id = osf_collectionsubmission.collection_id
							LEFT JOIN osf_guid
							ON osf_collectionsubmission.guid_id = osf_guid.id /* don't have to specify content_type_id as usually b/c joins right into id which is unique, rather than object_id like other tables */
							LEFT JOIN (SELECT *
										FROM osf_abstractnode
										WHERE type = 'osf.node' AND 
											is_deleted IS FALSE AND 
											is_public IS TRUE AND 
											(spam_status IS NULL OR spam_status != 2) AND 
											title NOT LIKE 'Bookmarks') as project_nodes
							ON osf_guid.object_id = project_nodes.root_id AND content_type_id = 30 /* need this here to only join in to nodes b/c of object_id join variable*/
							LEFT JOIN (SELECT *
										 FROM osf_basefilenode
										 WHERE type = 'osf.osfstoragefile') as osf_files
							ON project_nodes.id = osf_files.target_object_id
							WHERE osf_abstractprovider.type = 'osf.collectionprovider' AND osf_abstractprovider.name != 'Test'),
	file_actions AS (SELECT file_id, Min(_id), action, Max(total),
							CASE WHEN action = 'download' THEN Max(total) ELSE 0 END AS downloads,
							CASE WHEN action = 'view' THEN Max(total) ELSE 0 END AS views
							FROM osf_pagecounter
							WHERE file_id IN (SELECT file_id from collection_files)
							GROUP BY file_id, action)

SELECT collection_files.title,  
	   COUNT(DISTINCT root_id) AS num_toplevel_projects,
	   COUNT(DISTINCT node_id) AS num_nonreg_nodes,
	   COUNT(DISTINCT collection_files.file_id) AS num_nonreg_files,
	   COALESCE(SUM(num_versions),0) AS num_nonreg_file_versions,
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




WITH RECURSIVE collection_tree AS (SELECT osf_abstractprovider.name AS name, 
									   	project_nodes.root_id AS root_id,
									    project_nodes.id AS node_id,
									    child_id,
									    parent_id,
									    parent_id AS collect_point
									FROM osf_abstractprovider 
									LEFT JOIN osf_collectionsubmission
									ON osf_abstractprovider.primary_collection_id = osf_collectionsubmission.collection_id
									LEFT JOIN osf_guid
									ON osf_collectionsubmission.guid_id = osf_guid.id /* don't have to specify content_type_id as usually b/c joins right into id which is unique, rather than object_id like other tables */
									LEFT JOIN (SELECT *
												FROM osf_abstractnode
												WHERE type = 'osf.node' AND 
													is_deleted IS FALSE AND 
													is_public IS TRUE AND 
													(spam_status IS NULL OR spam_status != 2) AND 
													title NOT LIKE 'Bookmarks') as project_nodes
									ON osf_guid.object_id = project_nodes.id AND content_type_id = 30
									LEFT JOIN osf_noderelation
									ON project_nodes.id = osf_noderelation.parent_id
									WHERE osf_abstractprovider.type = 'osf.collectionprovider' AND osf_abstractprovider.name != 'Test'
									UNION
										SELECT cl.name, cl.root_id, cl.node_id, rl.child_id, rl.parent_id, collect_point
										FROM osf_noderelation rl
										INNER JOIN collection_tree cl
										ON cl.child_id = rl.parent_id
										WHERE rl.is_node_link IS FALSE),
				collection_nodes AS (SELECT *, COALESCE(collect_point,node_id) AS collection_root
										FROM collection_tree
										WHERE root_id IS NOT NULL),
				files AS (SELECT *
							FROM osf_basefilenode
							WHERE type = 'osf.osfstoragefile'),
				file_info AS (SELECT files.id AS file_id, target_object_id, cn_roots.name AS root_name, cn_roots.collection_root, cn_child.name AS child_name, cn_child.child_id
								FROM files
								LEFT JOIN collection_nodes AS cn_roots
								ON files.target_object_id = cn_roots.collection_root
								LEFT JOIN collection_nodes AS cn_child
								ON files.target_object_id = cn_child.child_id),
				collection_files AS (SELECT DISTINCT file_id, target_object_id, COALESCE(root_name, child_name) AS collection_name, collection_root, child_id
										FROM file_info
										WHERE root_name IS NOT NULL OR child_name IS NOT NULL),
				file_actions AS (SELECT file_id, Min(_id), action, Max(total),
										CASE WHEN action = 'download' THEN Max(total) ELSE 0 END AS downloads,
										CASE WHEN action = 'view' THEN Max(total) ELSE 0 END AS views
									FROM osf_pagecounter
									WHERE file_id IN (SELECT file_id from collection_files)
									GROUP BY file_id, action)

SELECT date_trunc('month', current_date) AS date,
	   collection_name,  
	   COUNT(DISTINCT collection_root) AS num_nonreg_top_nodes,
	   COUNT(DISTINCT child_id) AS num_nonreg_nodes,
	   COUNT(DISTINCT CASE WHEN collection_root IS NOT NULL THEN collection_files.file_id END) AS num_nonreg_topnode_files,
	   COUNT(DISTINCT collection_files.file_id) AS num_nonreg_files,   
	   COALESCE(SUM(CASE WHEN collection_root IS NOT NULL THEN num_versions END), 0) AS num_nonreg_top_file_version,
	   COALESCE(SUM(num_versions),0) AS num_nonreg_file_versions,
	   COALESCE(SUM(CASE WHEN collection_root IS NOT NULL THEN storage END)/1073741824,0) AS storage_top, 
	   COALESCE(SUM(storage)/1073741824,0) AS storage,
	   COALESCE(SUM(CASE WHEN collection_root IS NOT NULL THEN downloads END),0) AS downloads_top,
	   COALESCE(SUM(downloads),0) AS downloads,
	   COALESCE(SUM(CASE WHEN collection_root IS NOT NULL THEN views END),0) AS views_top,
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
	GROUP BY collection_files.collection_name;











