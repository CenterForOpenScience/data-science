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