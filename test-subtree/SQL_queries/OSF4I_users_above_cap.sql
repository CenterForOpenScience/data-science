/* number of OSF4I nodes and affiliated users that are above the potential storage capts by institution*/
WITH institutional_storage AS (SELECT nodes.id, 
									 osf_institution._id,
									 is_public,
									 osf_guid._id AS guid,
									 SUM(size) AS storage
							  	FROM (SELECT DISTINCT(abstractnode_id), institution_id
							  			FROM osf_abstractnode_affiliated_institutions
							  			WHERE institution_id != 12) AS institution /* exclude COS osf4I nodes */
								LEFT JOIN (SELECT *
											FROM osf_abstractnode
											WHERE is_deleted IS FALSE) AS nodes
								ON institution.abstractnode_id = nodes.id
								LEFT JOIN osf_institution
								ON institution.institution_id = osf_institution.id
								LEFT JOIN osf_guid
								ON nodes.id = osf_guid.object_id AND content_type_id = 30
								LEFT JOIN (SELECT *
											 FROM osf_basefilenode
											 WHERE type = 'osf.osfstoragefile') as osf_files
								ON nodes.id = osf_files.target_object_id
								LEFT JOIN osf_basefileversionsthrough
								ON osf_files.id = osf_basefileversionsthrough.basefilenode_id
								LEFT JOIN osf_fileversion
								ON osf_basefileversionsthrough.fileversion_id = osf_fileversion.id
								WHERE nodes.type = 'osf.node' AND nodes.is_deleted IS FALSE
								GROUP BY nodes.id, osf_institution._id, is_public, osf_guid._id),
				cap_filter AS (SELECT
								CASE WHEN storage > 5*1024^3 AND is_public IS FALSE THEN 1 ELSE 0 END AS private_overlimit,
								CASE WHEN storage > 50*1024^3 AND is_public IS TRUE THEN 1 ELSE 0 END AS public_overlimit,
								id AS node_id,
								_id AS institution,
								storage,
								is_public,
								guid
								FROM institutional_storage
								WHERE storage IS NOT NULL),
				hit_cap AS (SELECT private_overlimit, public_overlimit, institution, storage, is_public, guid as node_guid, user_id, user_instit._id AS user_instit
							 FROM cap_filter
							 LEFT JOIN (SELECT *
											FROM osf_contributor
											LEFT JOIN osf_osfuser_affiliated_institutions
											ON osf_contributor.user_id = osf_osfuser_affiliated_institutions.osfuser_id
											LEFT JOIN osf_institution
											ON osf_osfuser_affiliated_institutions.institution_id = osf_institution.id
											WHERE osf_osfuser_affiliated_institutions.osfuser_id IS NOT NULL AND osf_osfuser_affiliated_institutions.institution_id != 12) AS user_instit
							 ON cap_filter.node_id = user_instit.node_id
							 WHERE public_overlimit = 1 OR private_overlimit = 1)

SELECT hit_cap.institution, node_info.public_overlimit, node_info.private_overlimit, MIN(num_nodes) AS num_nodes, MIN(num_affil_users) AS num_affil_users
	FROM hit_cap
	LEFT JOIN (SELECT COUNT(DISTINCT node_guid) AS num_nodes, 
							public_overlimit, 
							private_overlimit, 
							institution
				FROM hit_cap
				GROUP BY public_overlimit, private_overlimit, institution) node_info
	ON hit_cap.institution = node_info.institution
	LEFT JOIN (SELECT COUNT(DISTINCT user_id) AS num_affil_users,
								public_overlimit,
								private_overlimit,
								user_instit
					FROM hit_cap
					WHERE institution = user_instit
					GROUP BY public_overlimit, private_overlimit, user_instit) user_info
	ON hit_cap.institution = user_info.user_instit
	WHERE node_info.public_overlimit = user_info.public_overlimit AND node_info.private_overlimit = user_info.private_overlimit
	GROUP BY hit_cap.institution, node_info.public_overlimit, node_info.private_overlimit;
