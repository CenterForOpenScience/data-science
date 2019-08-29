

/* count up the logs made by each user (on deleted and non-deleted projects), excluding empty NPD projects and bookmarks */

/* get all nodes (excluding registrations) with their logs (excluding actions that come along when a project is forked) */
SELECT is_deleted, user_id, 
			SUM(CASE WHEN osf_nodelog.action LIKE 'contributer_added' THEN 1 ELSE 0 END) added_contributor,
			SUM(CASE WHEN osf_nodelog.action LIKE '%file_added' THEN 1 ELSE 0 END) added_file,
			SUM(CASE WHEN osf_nodelog.action LIKE '%file_updated' THEN 1 ELSE 0 END) updated_file,
			SUM(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN 1 ELSE 0 END) wiki_edited,
			SUM(CASE WHEN osf_nodelog.action LIKE 'made_public' THEN 1 ELSE 0 END) made_public,
			SUM(CASE WHEN osf_nodelog.action LIKE 'made_private' THEN 1 ELSE 0 END) made_private,
			SUM(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN 1 ELSE 0 END) addon_added,
			MIN(CASE WHEN osf_nodelog.action LIKE 'contributer_added' THEN osf_nodelog.date ELSE NULL END) first_add_contrib,
			MIN(CASE WHEN osf_nodelog.action LIKE '%file_added' THEN osf_nodelog.date ELSE NULL END) first_upload_file,
			MIN(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN osf_nodelog.date ELSE NULL END) first_wiki_edit,
			MIN(CASE WHEN osf_nodelog.action LIKE 'made_public' THEN osf_nodelog.date ELSE NULL END) first_made_public,
			MIN(CASE WHEN osf_nodelog.action LIKE 'made_private' THEN osf_nodelog.date ELSE NULL END) first_made_private,
			MIN(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN osf_nodelog.date ELSE NULL END) first_addon_added,
			MAX(CASE WHEN osf_nodelog.action LIKE 'contributer_added' THEN osf_nodelog.date ELSE NULL END) last_add_contrib,
			MAX(CASE WHEN osf_nodelog.action LIKE '%file_added' THEN osf_nodelog.date ELSE NULL END) last_upload_file,
			MAX(CASE WHEN osf_nodelog.action LIKE 'wiki_updated' THEN osf_nodelog.date ELSE NULL END) last_wiki_edit,
			MAX(CASE WHEN osf_nodelog.action LIKE 'made_public' THEN osf_nodelog.date ELSE NULL END) last_made_public,
			MAX(CASE WHEN osf_nodelog.action LIKE 'made_private' THEN osf_nodelog.date ELSE NULL END) last_made_private,
			MAX(CASE WHEN osf_nodelog.action LIKE 'addon_added' THEN osf_nodelog.date ELSE NULL END) last_addon_added
 	FROM osf_abstractnode
	LEFT JOIN osf_nodelog
	ON osf_abstractnode.id = osf_nodelog.node_id
	LEFT JOIN (SELECT osf_abstractnode.node_id, osf_tag.name
					FROM osf_tag
					LEFT JOIN osf_abstractnode_tags
					ON osf_abstractnode_tags.tag_id = osf_tag.id
					WHERE osf_tag.id = 26265) AS osf4m_nodes
	ON osf_abstractnode.id = osf4m_nodes.node_id
	LEFT JOIN osf_preprint
	ON osf_abstractnode.id = osf_preprint.suppnode_id
	WHERE title NOT LIKE 'Bookmarks' AND type = 'osf.node' AND node_id = original_node_id AND (spam_status = 4 OR spam_status IS NULL OR spam_status = 1) AND
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
							WHERE total_actions = 0)
	GROUP BY user_id, is_deleted;




/* get the number of top level projects, top level registrations, and published preprints a user is a contributor on, excluding deleted projects, spam, and empty pre-NPD preojcts */


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
								  AND (spam_status IS NULL OR spam_status = 4)),
	node_categories AS (SELECT osf_abstractnode.id AS node_id, /* build full node timeline and categorication table */
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
						   registered_user_id,
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
										SUM(CASE WHEN osf_nodelog.action LIKE 'pointer_removed' THEN 1 ELSE 0 END) num_links_removed
									FROM osf_nodelog
									WHERE action = 'made_public' OR action = 'pointer_created' OR action = 'pointer_removed' OR action = 'wiki_updated'
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
												WHERE total_actions = 0)),
	/* count the number of osf4m, projects, and subnodes each user created */
	user_nodes AS (SELECT creator_id,
								  SUM(CASE WHEN node_id = root_id AND /*only counting rootids b/c osf4m emails automatically created a new project*/
								  		osf4m = 1 THEN 1 ELSE 0 END) AS num_osf4m,  
								  SUM(CASE WHEN node_id = root_id AND 
								  		osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR /*want to exclude project created as part of preprint workflow*/
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) THEN 1 ELSE 0 END) AS num_toplevel_projects,
								  SUM(CASE WHEN osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR /*want to exclude nodes created as part of preprint workflow*/
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) THEN 1 ELSE 0 END) AS num_nodes,
								  SUM(CASE WHEN osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR /*want to exclude nodes created as part of preprint workflow*/
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) AND 
								  		public_sharing = 1 THEN 1 ELSE 0 END) AS num_publicfiles_nodes,
								  SUM(CASE WHEN osf4m = 0 AND 
								  		(preprint_suppnode = 0  OR /*want to exclude nodes created as part of preprint workflow*/
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) AND 
								  		private_storage = 1 THEN 1 ELSE 0 END) AS num_privatefiles_nodes,
								  SUM(CASE WHEN osf4m = 0 AND
								  		preprint_suppnode =1 AND /*only want to count nodes made during the preprint process*/
								  		((preprint_created > '2018-12-14' AND created > preprint_created) OR 
								  		(preprint_created <= '2018-12-14' AND date_trun('day', created) = date_trun('day', preprint_created))) THEN 1 ELSE 0 END) AS num_suppnode,
								MIN(CASE WHEN node_id = root_id AND 
								  		osf4m = 1 THEN created ELSE NULL END) AS first_osf4m,
								MAX(CASE WHEN node_id = root_id AND 
								  		osf4m = 1 THEN created ELSE NULL END) AS last_osf4m,
								MIN(CASE WHEN node_id = root_id AND 
								  		osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR 
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) THEN created ELSE NULL END) AS first_toplevel_project,
								MAX(CASE WHEN node_id = root_id AND 
								  		osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR 
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) THEN created ELSE NULL END) AS last_toplevel_project,
								MIN(CASE WHEN osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) THEN created ELSE NULL END) AS first_node,
								MAX(CASE WHEN osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) THEN created ELSE NULL END) AS last_node,		
								MIN(CASE WHEN osf4m = 0 AND
								  		preprint_suppnode =1 AND
								  		((preprint_created > '2018-12-14' AND created > preprint_created) OR 
								  			(preprint_created <= '2018-12-14' AND date_trunc('day', created) = date_trunc('day', preprint_created))) THEN created ELSE NULL END) AS first_suppnode,
								MAX(CASE WHEN osf4m = 0 AND
								  		preprint_suppnode =1 AND
								  		((preprint_created > '2018-12-14' AND created > preprint_created) OR 
								  			(preprint_created <= '2018-12-14' AND date_trunc('day', created) = date_trunc('day', preprint_created))) AS last_suppnode	
								FROM node_categories
								WHERE type = 'osf.node'
								GROUP BY creator_id),
	/*count number of registrations made by each user*/
	user_regs AS (SELECT registered_user_id,
						 SUM(CASE WHEN node_id = root_id THEN 1 ELSE 0 END) AS num_toplevel_regs,
						 COUNT(DISTINCT node_id) AS num_reg_nodes,
						 MIN(CASE WHEN node_id = root_id THEN registered_date ELSE NULL END) AS first_toplevel_reg,
						 MAX(CASE WHEN node_id = root_id THEN registered_date ELSE NULL END) AS last_toplevel_reg
					FROM node_categories
					WHERE type = 'osf.registration'
					GROUP BY registered_user_id),
	/*get a list of only published preprints*/
	published_preprints AS (SELECT *
								FROM osf_preprint
								WHERE (osf_preprint.spam_status IS NULL or osf_preprint.spam_status = 4 OR osf_preprint.spam_status = 1) AND 
										is_published IS TRUE AND 
										is_public IS TRUE AND 
										(machine_state = 'accepted' OR machine_state = 'initial' OR machine_state = 'pending') AND 
										date_withdrawn IS NULL AND 
										osf_preprint.deleted IS NULL),
	/* how many published preprints created by each user */
	num_preprints_created AS (SELECT creator_id AS user, COUNT(published_preprints.id) AS num_preprints, MIN(created) AS date_first_preprint, MAX(created) AS date_last_preprint
									FROM published_preprints
									GROUP BY creator_id),
	/* how many published preprint is each user a contributor on*/
	num_preprints_contrib AS (SELECT user_id, 
									SUM(CASE WHEN visible IS FALSE THEN 1 ELSE 0 END) AS num_pp_invisible_contrib,
									SUM(CASE WHEN visible IS TRUE THEN 1 ELSE 0 END) AS num_pp_visible_contrib
								FROM published_preprints
								LEFT JOIN osf_preprintcontributor
								ON published_preprints.id = osf_preprintcontributor.preprint_id
								GROUP BY osf_preprintcontributor.user_id),
	user_preprint_nums AS (SELECT id, num_preprints, date_first_preprint, date_last_preprint, num_pp_visible_contrib, num_pp_invisible_contrib
								FROM osf_osfuser
								LEFT JOIN num_preprints_created
								ON osf_osfuser.id = num_preprints_created.user
								LEFT JOIN num_preprints_contrib
								ON osf_osfuser.id = user_id
								WHERE (spam_status IS NULL or spam_status = 4 OR spam_status = 1)),
	/* how many of each node type is a user a contributor on */
	user_node_contribs AS (SELECT user_id,
								   SUM(CASE WHEN osf4m = 1 THEN 1 ELSE 0 END) AS num_osf4m_contrib,
								   SUM(CASE WHEN type = 'osf.registration' THEN 1 ELSE 0 END) AS num_regnodes_contrib,
								   SUM(CASE WHEN osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) THEN 1 ELSE 0 END) AS num_nodes_contrib,
								   SUM(CASE WHEN osf4m = 0 AND 
								  		(preprint_suppnode = 0 OR
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) AND 
								  		public_sharing = 1 THEN 1 ELSE 0 END) AS num_publicfiles_nodes_contrib,
								   SUM(CASE WHEN osf4m = 0 AND 
								  		(preprint_suppnode = 0  OR
								  			(preprint_suppnode = 1 AND preprint_created > '2018-12-14' AND created < preprint_created) OR
								  			(preprint_suppnode = 1 AND preprint_created <= '2018-12-14' AND created != preprint_created)) AND 
								  		private_storage = 1 THEN 1 ELSE 0 END) AS num_privatefiles_nodes_contrib,
								   SUM(CASE WHEN osf4m = 0 AND
								  		preprint_suppnode =1 AND
								  		((preprint_created > '2018-12-14' AND created > preprint_created) OR (preprint_created <= '2018-12-14' AND created::date = preprint_created::date)) THEN 1 ELSE 0 END) AS num_suppnode_contrib
								FROM node_categories
								LEFT JOIN osf_contributor
								ON node_categories.node_id = osf_contributor.node_id
								GROUP BY user_id)
									
/* count creations and contributor types by project types */
SELECT osf_osfuser.id,
		username,
		fullname,
		is_registered,
		is_invited,
		date_registered,
		jobs,
		schools,
		social,
		date_last_login,
		date_confirmed,
		date_disabled,
		requested_deactivation,
		is_active,
		merged_by_id,
		_id AS guid,
		name AS user_tag,
		COALESCE(num_osf4m, 0) AS num_osf4m,
		COALESCE(num_toplevel_projects,0) AS num_toplevel_projects,
		COALESCE(num_nodes,0) AS num_nodes,
		COALESCE(num_publicfiles_nodes,0) AS num_publicfiles_nodes,
		COALESCE(num_privatefiles_nodes,0) AS num_privatefiles_nodes,
		COALESCE(num_suppnode,0) AS num_suppnode,
		COALESCE(num_toplevel_regs,0) AS num_toplevel_regs,
		COALESCE(num_reg_nodes,0) AS num_reg_nodes,
		COALESCE(num_preprints,0) AS num_preprints,
		COALESCE(num_pp_visible_contrib,0) AS num_pp_visible_contrib,
		COALESCE(num_pp_invisible_contrib,0) AS num_pp_invisible_contrib,
		first_osf4m,
		last_osf4m,
		first_toplevel_project,
		last_toplevel_project,
		first_node,
		last_node,
		first_suppnode,
		last_suppnode,
		first_toplevel_reg,
		last_toplevel_reg,
		date_first_preprint,
		date_last_preprint,
		COALESCE(num_osf4m_contrib,0) AS num_osf4m_contrib,
		COALESCE(num_regnodes_contrib,0) AS num_regnodes_contrib,
		COALESCE(num_nodes_contrib,0) AS num_nodes_contrib,
		COALESCE(num_publicfiles_nodes_contrib,0) AS num_publicfiles_nodes_contrib,
		COALESCE(num_privatefiles_nodes_contrib,0) AS num_privatefiles_nodes_contrib,
		COALESCE(num_suppnode_contrib,0) AS num_suppnode_contrib
	FROM osf_osfuser
	LEFT JOIN (SELECT * 
			FROM osf_guid
			WHERE osf_guid.content_type_id = 18) AS guids
	ON osf_osfuser.id = guids.object_id
	LEFT JOIN (SELECT osfuser_id, name
				 FROM osf_osfuser_tags
				 JOIN osf_tag
				 ON osf_osfuser_tags.tag_id = osf_tag.id
				 WHERE system IS TRUE AND name NOT LIKE '%spam%') AS system_tags
	ON osf_osfuser.id = system_tags.osfuser_id
	LEFT JOIN user_nodes
	ON osf_osfuser.id = user_nodes.creator_id
	LEFT JOIN user_regs
	ON osf_osfuser.id = user_regs.registered_user_id
	LEFT JOIN user_preprint_nums
	ON osf_osfuser.id = user_preprint_nums.id
	LEFT JOIN user_node_contribs
	ON osf_osfuser.id = user_node_contribs.user_id
	WHERE (spam_status IS NULL OR spam_status = 1 OR spam_status = 4);









