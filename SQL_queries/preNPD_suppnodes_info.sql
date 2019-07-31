/* identifying empty supp_nodes created b/c of NPD */

WITH RECURSIVE children_links AS (SELECT id, _id, is_node_link, child_id, parent_id, parent_id AS linked_top_node
																		FROM osf_noderelation
																		WHERE is_node_link IS TRUE
																	UNION
																		SELECT cl.id, cl._id, cl.is_node_link, rl.child_id, rl.parent_id, linked_top_node
																			FROM osf_noderelation rl
																			INNER JOIN children_links cl
																			ON cl.child_id = rl.parent_id),






WITH supp_nodes AS (SELECT osf_preprint.node_id, 
							osf_abstractnode.title AS node_title, 
							is_deleted,
							osf_abstractnode.is_public AS is_public, 
							deleted_date, 
							num_files, 
					 		num_wiki_edits, 
					 		num_addons, 
					 		num_regs,
					 		COALESCE(num_files,0) + COALESCE(num_wiki_edits,0) + COALESCE(num_addons,0) + COALESCE(num_regs,0) AS total_actions,
					 		osf_preprint.created AS preprint_created, 
					 		osf_abstractnode.created AS node_created,
					 		osf_abstractnode.last_logged AS last_log_date,
					 		first_file_uploaded, 
					 		first_wiki_edit, 
					 		first_addon_added, 
					 		first_reg,
					 		last_file_uploaded, 
					 		last_wiki_edit, 
					 		last_addon_added, 
					 		last_reg						
			FROM osf_preprint
			
			/* count non-deleted files in osf storage on each node*/
			LEFT JOIN (SELECT COUNT(id) AS num_files, target_object_id, MIN(created) AS first_file_uploaded, MAX(created) AS last_file_uploaded
							FROM osf_basefilenode 
							WHERE osf_basefilenode.type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30
							GROUP BY target_object_id) AS node_files
			ON osf_preprint.node_id = node_files.target_object_id
			
			/* calculate the number of non-file based information additions per supp node and when those happened */
			LEFT JOIN (SELECT node_id, SUM(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN 1 ELSE 0 END) num_wiki_edits,
									   SUM(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN 1 ELSE 0 END) num_addons,
									   SUM(CASE WHEN osf_nodelog.action LIKE 'registration_approved' THEN 1 ELSE 0 END) num_regs,
									   MIN(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN osf_nodelog.date ELSE NULL END) first_wiki_edit,
									   MIN(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN osf_nodelog.date ELSE NULL END) first_addon_added,
									   MIN(CASE WHEN osf_nodelog.action LIKE 'registration_approved' THEN osf_nodelog.date ELSE NULL END) first_reg,
									   MAX(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN osf_nodelog.date ELSE NULL END) last_wiki_edit,
									   MAX(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN osf_nodelog.date ELSE NULL END) last_addon_added,
									   MAX(CASE WHEN osf_nodelog.action LIKE 'registration_approved' THEN osf_nodelog.date ELSE NULL END) last_reg
							FROM osf_nodelog
							WHERE action = 'node_created' OR action = 'wiki_updated' OR action = 'addon_added' OR action = 'registration_approved'
							GROUP BY node_id) AS node_actions
			ON osf_preprint.node_id = node_actions.node_id
			
			/* add in abstractnode table to get date the node was created so can distinguish between nodes created by preprint process vs. before preprint process */
			LEFT JOIN osf_abstractnode
			ON osf_preprint.node_id = osf_abstractnode.id
			WHERE osf_preprint.node_id IS NOT NULL AND osf_preprint.created < '2018-12-15')
	
	/* retain only supp nodes with 0 content addition actions */
SELECT node_id, total_actions, is_deleted, is_public
	FROM supp_nodes
	WHERE total_actions = 0;