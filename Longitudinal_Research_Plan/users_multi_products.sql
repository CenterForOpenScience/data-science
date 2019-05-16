WITH pp_contrib AS (SELECT user_id, COUNT(preprint_id) AS number_pp, MIN(created) AS first_preprint, MAX(created) AS last_preprint
						FROM osf_preprintcontributor
						LEFT JOIN osf_preprint pp
						ON osf_preprintcontributor.preprint_id = pp.id
						WHERE pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND 
					    pp.is_public = 'TRUE' AND primary_file_id IS NOT NULL AND pp.deleted IS NULL
					    GROUP BY user_id),
	  node_contrib AS (SELECT node_id, user_id, type, osf_abstractnode.created AS node_created, is_public, registered_date, embargo_id, registered_from_id, root_id, date_retracted
	 					FROM osf_contributor
	 					LEFT JOIN osf_abstractnode
						ON osf_contributor.node_id = osf_abstractnode.id
						LEFT JOIN osf_retraction
						ON osf_abstractnode.retraction_id = osf_retraction.id
						WHERE is_deleted IS FALSE AND (spam_status = 4 OR spam_status IS NULL) AND ((type LIKE 'osf.node' AND is_public IS TRUE) OR (type LIKE 'osf.registration' AND date_retracted IS NULL AND (is_public IS TRUE OR 										embargo_id IS NOT NULL)))),
	  existing_files AS (SELECT COUNT(*) AS num_files, target_object_id, MIN(created) AS first_file_created, MAX(created) AS last_file_created
													FROM osf_basefilenode
													WHERE type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30
													GROUP BY target_object_id),
		files_on_nodes AS (SELECT node_id, user_id, type, node_created, is_public, registered_date, embargo_id, registered_from_id, root_id, COALESCE(num_files, 0) AS num_files, first_file_created, last_file_created
													FROM node_contrib
													LEFT JOIN existing_files
													ON node_contrib.node_id = existing_files.target_object_id
													WHERE type LIKE 'osf.registration' OR (type LIKE 'osf.node' AND num_files > 0)),		
						
		eligible_node_contribs AS (SELECT user_id, COUNT(DISTINCT root_id) FILTER (WHERE type LIKE 'osf.node') AS eligible_nodes, COUNT(DISTINCT root_id) FILTER (WHERE type LIKE 'osf.registration') AS eligible_regs, 
																			MIN(node_created) FILTER (WHERE type LIKE 'osf.node') AS first_node, MAX(node_created) FILTER (WHERE type LIKE 'osf.node') AS last_node,
																			MIN(registered_date) FILTER (WHERE type LIKE 'osf.registration') AS first_registration, MAX(registered_date) FILTER (WHERE type LIKE 'osf.registration') AS last_registration		 															FROM files_on_nodes
																	GROUP BY user_id),
	all_contribs AS (SELECT COALESCE(eligible_node_contribs.user_id, pp_contrib.user_id) AS user_id, COALESCE(eligible_nodes, 0) AS number_nodes, COALESCE(eligible_regs, 0) AS number_regs, first_node, last_node, first_registration, 														last_registration, COALESCE(number_pp, 0) AS number_pp, first_preprint,last_preprint
												FROM eligible_node_contribs
												FULL OUTER JOIN pp_contrib
												ON eligible_node_contribs.user_id = pp_contrib.user_id)

SELECT * 
	FROM all_contribs
	LEFT JOIN osf_osfuser
	ON all_contribs.user_id = osf_osfuser.id;