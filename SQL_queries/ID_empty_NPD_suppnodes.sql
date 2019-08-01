/* identifying empty supp_nodes created b/c of NPD */

WITH RECURSIVE children_nodes AS (SELECT osf_noderelation.id, osf_noderelation._id, is_node_link, child_id, parent_id, parent_id AS suppnode_id
																		FROM osf_preprint
																		LEFT JOIN osf_noderelation
																		ON osf_preprint.node_id = osf_noderelation.parent_id
																		WHERE is_node_link IS FALSE
																	UNION
																		SELECT cl.id, cl._id, cl.is_node_link, rl.child_id, rl.parent_id, suppnode_id
																			FROM osf_noderelation rl
																			INNER JOIN children_nodes cl
																			ON cl.child_id = rl.parent_id),
	 supp_nodes AS (SELECT DISTINCT ON (osf_preprint.node_id) AS suppnode_id /* same node could be suppnode on multiple preprints */ 
							osf_abstractnode.title AS node_title, 
							is_deleted,
							osf_abstractnode.is_public AS is_public, 
							deleted_date, 
							num_files, 
					 		num_wiki_edits, 
					 		num_addons, 
					 		num_regs,
					 		num_components,
					 		COALESCE(num_files,0) + COALESCE(num_wiki_edits,0) + COALESCE(num_addons,0) + COALESCE(num_regs,0) + COALESCE(num_components, 0) AS total_actions,
					 		osf_preprint.created AS preprint_created, 
					 		osf_abstractnode.created AS node_created,
					 		osf_abstractnode.last_logged AS last_log
					
			FROM osf_preprint
			
			/* count non-deleted files in osf storage on each node*/
			LEFT JOIN (SELECT COUNT(id) AS num_files, target_object_id, MIN(created) AS first_file_uploaded, MAX(created) AS last_file_uploaded
							FROM osf_basefilenode 
							WHERE osf_basefilenode.type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30
							GROUP BY target_object_id) AS node_files
			ON osf_preprint.node_id = node_files.target_object_id
			
			/* calculate the number of components on each suppnode, assuming that is someone bothered to create a component they would have put something in it*/
			LEFT JOIN (SELECT COUNT(child_id) AS num_components, suppnode_id
							FROM children_nodes
							GROUP BY suppnode_id) AS components
			ON osf_preprint.node_id = components.suppnode_id

			/* calculate the number of non-file based information additions per supp node and when those happened */
			LEFT JOIN (SELECT node_id, SUM(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN 1 ELSE 0 END) num_wiki_edits,
									   SUM(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN 1 ELSE 0 END) num_addons,
									   SUM(CASE WHEN osf_nodelog.action LIKE 'registration_approved' THEN 1 ELSE 0 END) num_regs
							FROM osf_nodelog
							WHERE action = 'node_created' OR action = 'wiki_updated' OR action = 'addon_added' OR action = 'registration_approved'
							GROUP BY node_id) AS node_actions
			ON osf_preprint.node_id = node_actions.node_id
			
			/* add in abstractnode table to get date the node was created so can distinguish between nodes created by preprint process vs. before preprint process */
			LEFT JOIN osf_abstractnode
			ON osf_preprint.node_id = osf_abstractnode.id
			WHERE osf_preprint.node_id IS NOT NULL AND osf_preprint.created < '2018-12-14 04:45:00' AND osf_abstractnode.created < '2018-12-14 04:45:00')

SELECT *
	FROM supp_nodes;