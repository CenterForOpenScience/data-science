/* identifying empty supp_nodes created b/c of NPD */

WITH supp_nodes AS (SELECT osf_preprint.node_id, 
							MIN(osf_abstractnode.title) AS node_title, 
							is_deleted,
							osf_abstractnode.is_public AS is_public, 
							MIN(deleted_date) AS date_deleted, 
							COUNT(node_files.id) number_files, 
					 		MIN(nodes) AS num_nodes, 
					 		MIN(wiki_edited) AS num_wiki_edits, 
					 		MIN(addon_added) AS num_addons, 
					 		MIN(registration) AS num_regs,
					 		COALESCE(COUNT(node_files.id),0) + COALESCE(MIN(nodes),0) + COALESCE(MIN(wiki_edited),0) + COALESCE(MIN(addon_added),0) + COALESCE(MIN(registration),0) AS total_actions,
					 		MIN(osf_preprint.created) AS preprint_created, 
					 		MIN(osf_abstractnode.created) AS node_created,
					 		MIN(osf_abstractnode.last_logged) AS last_log_date,
					 		MIN(first_node) AS first_node_added, 
					 		MIN(node_files.created) AS first_file_uploaded, 
					 		MIN(first_wiki_edit) AS first_wiki_edit, 
					 		MIN(first_addon_added) AS first_addon_added, 
					 		MIN(first_reg) AS first_reg,
					 		MIN(last_node) AS last_node_added, 
					 		MAX(node_files.created) AS last_file_uploaded, 
					 		MIN(last_wiki_edit) AS last_wiki_edit, 
					 		MIN(last_addon_added) AS last_addon_added, 
					 		MIN(last_reg) AS last_reg						
			FROM osf_preprint
			
			/* add in files on supp node so that these can be counted */
			LEFT JOIN (SELECT * 
							FROM osf_basefilenode 
							WHERE osf_basefilenode.type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30) AS node_files
			ON osf_preprint.node_id = node_files.target_object_id
			
			/* calculate the number of non-file based information additions per supp node and when those happened */
			LEFT JOIN (SELECT node_id, SUM(CASE WHEN osf_nodelog.action LIKE 'node_created' THEN 1 ELSE 0 END) nodes, 
									   SUM(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN 1 ELSE 0 END) wiki_edited,
									   SUM(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN 1 ELSE 0 END) addon_added,
									   SUM(CASE WHEN osf_nodelog.action LIKE 'registration_approved' THEN 1 ELSE 0 END) registration,
									   MIN(CASE WHEN osf_nodelog.action LIKE 'node_created' THEN osf_nodelog.date ELSE NULL END) first_node,
									   MIN(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN osf_nodelog.date ELSE NULL END) first_wiki_edit,
									   MIN(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN osf_nodelog.date ELSE NULL END) first_addon_added,
									   MIN(CASE WHEN osf_nodelog.action LIKE 'registration_approved' THEN osf_nodelog.date ELSE NULL END) first_reg,
									   MAX(CASE WHEN osf_nodelog.action LIKE 'node_created' THEN osf_nodelog.date ELSE NULL END) last_node,
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
			WHERE osf_preprint.node_id IS NOT NULL AND osf_preprint.created < '2018-12-15'
			GROUP BY osf_preprint.node_id, is_deleted, osf_abstractnode.is_public)
	
	/* retain only supp nodes with 0 content addition actions */
SELECT node_id, total_actions, is_deleted, is_public
	FROM supp_nodes
	WHERE total_actions = 0;