/* categorizing nodes by products [preprint supp nodes, osf4m, node, registration, 
public with files, public without files, private with files, private without files] - doesn't include links, excludes empty projects created by NPD*/


WITH existing_files AS (SELECT COUNT(*) AS num_files, target_object_id, MIN(created) AS first_osf_file_created, MAX(created) AS last_osf_file_created
						FROM osf_basefilenode
						WHERE type NOT LIKE '%folder%' AND 
							  provider LIKE 'osfstorage' AND 
							  osf_basefilenode.deleted_on IS NULL AND 
							  osf_basefilenode.target_content_type_id = 30
						GROUP BY target_object_id),
	
	/* determine what addons are currently connected to which nodes and when those connections happened */
	addon_connections AS (SELECT osf_abstractnode.id,
								LEAST(bitbucket.created, box.created, dataverse.created, dropbox.created, figshare.created, github.created, gitlab.created, googledrive.created, onedrive.created, owncloud.created, s3.created) AS first_addon_added,
								GREATEST(bitbucket.created, box.created, dataverse.created, dropbox.created, figshare.created, github.created, gitlab.created, googledrive.created, onedrive.created, owncloud.created, s3.created) AS last_addon_added,
								(SELECT count(*) from (values (bitbucket.created), (box.created), (dataverse.created), (dropbox.created), (figshare.created), (github.created), (gitlab.created), (googledrive.created), (onedrive.created), (owncloud.created), (s3.created)) as v(col) WHERE v.col is not null) AS num_addons,
								bitbucket.created AS bitbucket_added,
								box.created AS box_added,
								dataverse.created AS dataverse_added,
								dropbox.created AS dropbox_added,
								figshare.created AS figshare_added,
								github.created AS github_added,
								gitlab.created AS gitlab_added,
								googledrive.created AS googledrive_added,
								onedrive.created AS onedrive_added,
								owncloud.created AS owncloud_added,
								s3.created AS s3_added
							FROM osf_abstractnode
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_bitbucket_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_bitbucket_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  repo IS NOT NULL AND
												  action = 'bitbucket_repo_linked'
											GROUP BY node_id) bitbucket
							ON osf_abstractnode.id = bitbucket.node_id	
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_box_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_box_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  folder_name IS NOT NULL AND
												  action = 'box_folder_selected'
											GROUP BY node_id) box
							ON osf_abstractnode.id = box.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_dataverse_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_dataverse_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  dataset IS NOT NULL AND
												  action = 'dataverse_dataset_linked'
											GROUP BY node_id) dataverse
							ON osf_abstractnode.id = dataverse.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_dropbox_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_dropbox_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  folder IS NOT NULL AND
												  action = 'dropbox_folder_selected'
											GROUP BY node_id) dropbox
							ON osf_abstractnode.id = dropbox.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_figshare_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_figshare_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  folder_name IS NOT NULL AND
												  action = 'figshare_folder_selected'
											GROUP BY node_id) figshare
							ON osf_abstractnode.id = figshare.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_github_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_github_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  repo IS NOT NULL AND 
												  action = 'github_repo_linked'
											GROUP BY node_id) github
							ON osf_abstractnode.id = github.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_gitlab_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_gitlab_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
											      repo IS NOT NULL AND
											      action = 'gitlab_repo_linked'
											GROUP BY node_id) gitlab
							ON osf_abstractnode.id = gitlab.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_googledrive_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_googledrive_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  folder_path IS NOT NULL AND
												  action = 'googledrive_folder_selected'
											GROUP BY node_id) googledrive
							ON osf_abstractnode.id = googledrive.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_onedrive_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_onedrive_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  folder_path IS NOT NULL AND
												  action = 'onedrive_folder_selected'
											GROUP BY node_id) onedrive
							ON osf_abstractnode.id = onedrive.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_owncloud_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_owncloud_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  folder_id IS NOT NULL AND
												  action = 'owncloud_folder_selected'
											GROUP BY node_id) owncloud
							ON osf_abstractnode.id = owncloud.node_id
							LEFT JOIN (SELECT node_id, MAX(date) AS created
											FROM addons_s3_nodesettings
											LEFT JOIN osf_nodelog
											ON addons_s3_nodesettings.owner_id = osf_nodelog.node_id
											WHERE deleted IS FALSE AND 
												  folder_name IS NOT NULL AND
												  action = 's3_bucket_linked'
											GROUP BY node_id) s3
							ON osf_abstractnode.id = s3.node_id
							WHERE type = 'osf.node' AND 
								  is_deleted IS FALSE AND 
								  title NOT LIKE 'Bookmarks' 
								  AND (spam_status IS NULL OR spam_status = 4))

/* build full node timeline and categorication table */
SELECT osf_abstractnode.id AS node_id, 
	   type, 
	   created, 
	   deleted_date, 
	   is_fork, 
	   is_deleted, 
	   is_public, 
	   registered_date, 
	   creator_id, 
	   embargo_id, 
	   registered_from_id, 
	   retraction_id, 
	   root_id, 
	   tag_id, 
	   preprint_id, 
	   preprint_created, 
	   supp_node,
	   suppnode_date_added,
	   num_files,
	   first_osf_file_created,
	   last_osf_file_created,
	   num_addons,
	   first_addon_added,
	   last_addon_added,
	   LEAST(first_osf_file_created, first_addon_added) AS first_file,
	   GREATEST(last_osf_file_created, last_addon_added) AS last_file,
	   bitbucket_added,
	   box_added,
	   dataverse_added,
	   dropbox_added,
	   figshare_added,
	   github_added,
	   gitlab_added,
	   googledrive_added,
	   onedrive_added,
	   owncloud_added,
	   s3_added,
	   CASE WHEN is_public IS TRUE THEN date_made_public ELSE NULL END AS date_made_public,
	   num_regs,
	   first_reg,
	   last_reg,
	   num_wiki_edits,
	   num_links_added,
	   num_links_removed,
	   CASE WHEN num_regs IS NOT NULL AND type = 'osf.node' THEN 1 ELSE 0 END AS registered,
	   CASE WHEN tag_id IS NOT NULL THEN 1 ELSE 0 END AS osf4m,
	   CASE WHEN preprint_id IS NOT NULL THEN 1 ELSE 0 END AS preprint_suppnode,
	   CASE WHEN LEAST(first_osf_file_created, first_addon_added) IS NOT NULL THEN 1 ELSE 0 END AS has_files,
	   CASE WHEN is_public IS TRUE AND retraction_id IS NULL AND LEAST(first_osf_file_created, first_addon_added) IS NOT NULL THEN 1 ELSE 0 END AS public_sharing,
	   CASE WHEN is_public IS FALSE AND retraction_id IS NULL AND LEAST(first_osf_file_created, first_addon_added) IS NOT NULL THEN 1 ELSE 0 END AS private_storage,
		CASE WHEN is_public IS TRUE AND retraction_id IS NULL AND 
	   			LEAST(first_osf_file_created, first_addon_added) IS NOT NULL THEN 
	   			GREATEST(date_made_public, LEAST(first_osf_file_created, first_addon_added)) ELSE NULL END AS date_public_sharing
	FROM osf_abstractnode
	
	/* identify osf4m nodes */
	LEFT JOIN (SELECT *
					FROM osf_abstractnode_tags
					WHERE tag_id = 26265) AS osf4m_tags
	ON osf_abstractnode.id = osf4m_tags.abstractnode_id
	
	/* identify preprint supp nodes */
	LEFT JOIN (SELECT id AS preprint_id, osf_preprint.created AS preprint_created, node_id AS supp_node, suppnode_date_added
					FROM osf_preprint
					LEFT JOIN (SELECT preprint_id, MAX(created) AS suppnode_date_added
									FROM osf_preprintlog
									WHERE action = 'supplement_node_added'
									GROUP BY preprint_id) as suppnode_log
					ON osf_preprint.id = suppnode_log.preprint_id
					WHERE node_id IS NOT NULL) AS supp_nodes
	ON osf_abstractnode.id = supp_nodes.supp_node
	
	/* join in file and addon information */
	LEFT JOIN existing_files
	ON osf_abstractnode.id = existing_files.target_object_id
	LEFT JOIN addon_connections
	ON osf_abstractnode.id = addon_connections.id

	/* join in when each node was last made public and the number of wiki and link logs per node*/
	LEFT JOIN (SELECT node_id, MAX(CASE WHEN osf_nodelog.action LIKE 'made_public' THEN osf_nodelog.date ELSE NULL END) date_made_public, 
					SUM(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN 1 ELSE 0 END) num_wiki_edits,
					SUM(CASE WHEN osf_nodelog.action LIKE 'pointer_created' THEN 1 ELSE 0 END) num_links_added,
					SUM(CASE WHEN osf_nodelog.action LIKE 'pointer_removed' THEN 1 ELSE 0 END) num_links_removed,
					SUM(CASE WHEN osf_nodelog.action = 'addon_file_copied' OR osf_nodelog.action = 'addon_file_moved' THEN 1 ELSE 0 END) num_copy_moves,
				FROM osf_nodelog
				WHERE action = 'made_public' OR action = 'pointer_created' OR action = 'pointer_removed' OR action = 'wiki_updated' OR action = 'addon_file_copied' OR action = 'addon_file_moved'
				GROUP BY node_id) as public_dates
	ON osf_abstractnode.id = public_dates.node_id

	/* add in registrations per node and timing of first and last registration */
	LEFT JOIN (SELECT COUNT(regs.id) AS num_regs, osf_abstractnode.id AS node_id, MIN(regs.registered_date) AS first_reg, MAX(regs.registered_date) AS last_reg
					FROM osf_abstractnode
					LEFT JOIN osf_abstractnode AS regs
					ON osf_abstractnode.id = regs.registered_from_id
					WHERE osf_abstractnode.type = 'osf.node' AND 
						  osf_abstractnode.title NOT LIKE 'Bookmarks' AND 
						  regs.is_deleted IS FALSE AND 
						  regs.retraction_id IS NULL AND 
						  regs.type = 'osf.registration'
					GROUP BY osf_abstractnode.id) as regs_data
	ON osf_abstractnode.id = regs_data.node_id

	WHERE (type LIKE 'osf.node' OR type LIKE 'osf.registration') AND 
			title NOT LIKE 'Bookmarks' AND
			(spam_status IS NULL OR spam_status = 4) AND 
			is_deleted IS FALSE AND 
			retraction_id IS NULL AND
			osf_abstractnode.id NOT IN (/* identifying empty supp_nodes created b/c of NPD */
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
							 supp_nodes AS (SELECT DISTINCT ON (osf_preprint.node_id) 
							 						osf_preprint.node_id AS suppnode_id, /* same node could be suppnode on multiple preprints */ 
													osf_abstractnode.title AS node_title, 
													is_deleted,
													osf_abstractnode.is_public AS is_public, 
													deleted_date, 
													num_files, 
											 		num_wiki_edits, 
											 		num_addons, 
											 		num_regs,
											 		num_components,
											 		num_links,
											 		COALESCE(num_files,0) + COALESCE(num_wiki_edits,0) + COALESCE(num_addons,0) + COALESCE(num_regs,0) + COALESCE(num_components, 0) + COALESCE(num_links, 0) AS total_actions,
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
															   SUM(CASE WHEN osf_nodelog.action LIKE 'registration_approved' THEN 1 ELSE 0 END) num_regs,
															   SUM(CASE WHEN osf_nodelog.action LIKE 'pointer_created' THEN 1 ELSE 0 END) - SUM(CASE WHEN osf_nodelog.action LIKE 'pointer_removed' THEN 1 ELSE 0 END) num_links
													FROM osf_nodelog
													WHERE action = 'node_created' OR action = 'wiki_updated' OR action = 'addon_added' OR action = 'registration_approved' OR action = 'pointer_created' OR action = 'pointer_removed'
													GROUP BY node_id) AS node_actions
									ON osf_preprint.node_id = node_actions.node_id
									
									/* add in abstractnode table to get date the node was created so can distinguish between nodes created by preprint process vs. before preprint process */
									LEFT JOIN osf_abstractnode
									ON osf_preprint.node_id = osf_abstractnode.id
									WHERE osf_preprint.node_id IS NOT NULL AND osf_preprint.created < '2018-12-14 04:45:00' AND osf_abstractnode.created < '2018-12-14 04:45:00')

						SELECT suppnode_id
							FROM supp_nodes
							WHERE total_actions = 0);




