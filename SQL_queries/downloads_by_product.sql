/* downloads by product type backfill query*/

WITH 

	/* get all nested components under connected suppnode to also classify them as suppnodes */
	RECURSIVE supp_children_nodes AS (SELECT osf_noderelation.id, osf_noderelation._id, is_node_link, child_id, parent_id, parent_id AS suppnode_id
										FROM osf_preprint
										LEFT JOIN osf_noderelation
										ON osf_preprint.node_id = osf_noderelation.parent_id
										WHERE is_node_link IS FALSE
									UNION
										SELECT cl.id, cl._id, cl.is_node_link, rl.child_id, rl.parent_id, suppnode_id
											FROM osf_noderelation rl
											INNER JOIN supp_children_nodes cl
											ON cl.child_id = rl.parent_id
											WHERE rl.is_node_link IS FALSE),

	/*get info about when each suppnode added to pp, and for nodes added to multiple pps, when was the first time they were added*/
	pp_suppnode_info AS (SELECT MIN(date_supp_added) AS date_supp_added, node_id, MIN(created) AS pp_created
							FROM osf_preprint
							LEFT JOIN (SELECT preprint_id, MAX(created) AS date_supp_added
 											 FROM osf_preprintlog
 											 WHERE action = 'supplement_node_added'
 											 GROUP BY preprint_id) AS preprint_suppnode 
							ON osf_preprint.id = preprint_suppnode.preprint_id
							GROUP BY node_id),

	 /*break apart json field into one line for each day with download info*/
	 daily_format AS (SELECT *, json_object_keys(date::json) AS download_date, json_each_text(date::json) AS daily_downloads
						FROM osf_pagecounter
						WHERE action = 'download' AND version IS NULL),

	 /*for each day, extract total download numbers for that day*/
	 daily_downloads AS (SELECT daily_format.id, file_id, resource_id,TO_DATE(download_date, 'YYYY/MM/DD') AS download_date, 
								(SELECT regexp_matches(daily_downloads::text, '\{""total"": ([0-9]*)'))[1] AS total,
								target_content_type_id, target_object_id
							FROM daily_format
							LEFT JOIN osf_basefilenode
							ON daily_format.file_id = osf_basefilenode.id),

	 /*categorize each file by node/file type and connections*/
 	file_categorization AS (SELECT  file_id, 
 									target_object_id, 
 									target_content_type_id,
 									collection_id, 
 									download_date, 
 									total::INTEGER, 
 									type, 
 									preprints.created AS pp_created,
 									tag_id,
 									pp_suppnode_info.date_supp_added,
 									pp_suppnode_info.node_id,
 									pp_suppnode_info.pp_created,
 									child_id,
 									supp_nodes.date_supp_added AS date_parent_supp_added,
 									supp_nodes.pp_created AS date_parent_pp_created,
 									CASE WHEN institution_id IS NOT NULL THEN 1 ELSE 0 END as inst_affil,
 									CASE WHEN tag_id = 26265 THEN 1 ELSE 0 END as osf4m,
 									CASE WHEN target_content_type_id = 47 AND download_date >= date_trunc('day', preprints.created) THEN 1 ELSE 0 END as preprint,
 									CASE WHEN pp_suppnode_info.node_id IS NOT NULL AND download_date >= date_trunc('day', pp_suppnode_info.date_supp_added) THEN 1 
 										 WHEN pp_suppnode_info.node_id IS NOT NULL AND pp_suppnode_info.date_supp_added IS NULL AND download_date >= date_trunc('day', pp_suppnode_info.pp_created) THEN 1 
 										 WHEN child_id IS NOT NULL AND download_date >= date_trunc('day', supp_nodes.date_supp_added) THEN 1
 										 WHEN child_id IS NOT NULL AND supp_nodes.date_supp_added IS NULL AND download_date >= date_trunc('day', supp_nodes.pp_created) THEN 1
 										 ELSE 0 END as supp_node,
 									CASE WHEN collection_id IS NOT NULL AND download_date >= date_trunc('day', collection_submit_date) THEN 1 ELSE 0 END as collection

								 FROM daily_downloads
								 
								 /*join in node info for node type [node vs. registration vs. quickfiles]*/
								 LEFT JOIN osf_abstractnode
								 ON daily_downloads.target_object_id = osf_abstractnode.id AND daily_downloads.target_content_type_id = 30
								 
								 /*identify and merge in osf4m tags on nodes and don't include original osf4m nodes that were migrated to preprints at start of services*/
								 LEFT JOIN (SELECT abstractnode_id, MAX(tag_id) AS tag_id
								 				FROM osf_abstractnode_tags
								 				WHERE tag_id = 26265 OR tag_id = 26294
								 				GROUP BY abstractnode_id) AS project_tags
								 ON osf_abstractnode.id = project_tags.abstractnode_id

								 /* nodes can be affiliated with multiple institutions, so need to deduplicate before joining in to keep 1 row per node */ 
								 LEFT JOIN (SELECT DISTINCT ON (abstractnode_id) abstractnode_id, institution_id
								 				FROM osf_abstractnode_affiliated_institutions
								 				WHERE institution_id != 12) AS deduped_inst_nodes /*exclude node only affiliated with COS institution*/
								 ON osf_abstractnode.id = deduped_inst_nodes.abstractnode_id

								 LEFT JOIN pp_suppnode_info
								 ON osf_abstractnode.id = pp_suppnode_info.node_id

								 /* same file are primary files on multiple pps */
								 LEFT JOIN (SELECT primary_file_id, MIN(created) AS created
								 				FROM osf_preprint
								 				GROUP BY primary_file_id) AS preprints
								 ON daily_downloads.file_id = preprints.primary_file_id

								 LEFT JOIN (SELECT Distinct(child_id), date_supp_added, pp_created
								 				FROM supp_children_nodes
								 				LEFT JOIN pp_suppnode_info
								 				ON supp_children_nodes.suppnode_id = pp_suppnode_info.node_id) AS supp_nodes
								 ON osf_abstractnode.id = supp_nodes.child_id

								 LEFT JOIN (SELECT collection_id,
												   	COALESCE(project_nodes.id, object_id) AS node_id,
												   	osf_collectionsubmission.created AS collection_submit_date
												FROM osf_collectionsubmission
												LEFT JOIN (SELECT *
															FROM osf_guid
															WHERE content_type_id = 30) as node_guids
												ON osf_collectionsubmission.guid_id = node_guids.id
												LEFT JOIN osf_abstractnode as project_nodes
												ON node_guids.object_id = project_nodes.root_id
												WHERE (collection_id = 711617 OR collection_id = 709754 OR collection_id = 775210 OR collection_id = 735729)) AS collection_nodes
								 ON osf_abstractnode.id = collection_nodes.node_id)

/* calculate monthly downloads for all product types*/
SELECT date_trunc('month', download_date) AS date,
		SUM(CASE WHEN osf4m = 1 THEN total ELSE 0 END) AS osf4m_downloads,
		SUM(CASE WHEN type = 'osf.quickfilesnode' THEN total ELSE 0 END) AS quickfile_downloads,
		SUM(CASE WHEN type = 'osf.registration' THEN total ELSE 0 END) AS reg_downloads,
		SUM(CASE WHEN preprint = 1 THEN total ELSE 0 END) AS pp_downloads,
		SUM(CASE WHEN supp_node = 1 THEN total ELSE 0 END) AS suppnode_downloads,
		SUM(CASE WHEN inst_affil = 1 THEN total ELSE 0 END) AS inst_downloads,
		SUM(CASE WHEN collection = 1 THEN total ELSE 0 END) AS collection_downloads,
		SUM(CASE WHEN type = 'osf.node' THEN total ELSE 0 END) AS osfnode_download,
		SUM(CASE WHEN type = 'osf.node' AND osf4m = 0 AND supp_node = 0 AND inst_affil = 0 AND collection = 0 THEN total ELSE 0 END) AS osfgen_download
	FROM file_categorization
	GROUP BY date_trunc('month', download_date)


/* downloads by product type per quater */

WITH 

	/* get all nested components under connected suppnode to also classify them as suppnodes */
	RECURSIVE supp_children_nodes AS (SELECT osf_noderelation.id, osf_noderelation._id, is_node_link, child_id, parent_id, parent_id AS suppnode_id
										FROM osf_preprint
										LEFT JOIN osf_noderelation
										ON osf_preprint.node_id = osf_noderelation.parent_id
										WHERE is_node_link IS FALSE
									UNION
										SELECT cl.id, cl._id, cl.is_node_link, rl.child_id, rl.parent_id, suppnode_id
											FROM osf_noderelation rl
											INNER JOIN supp_children_nodes cl
											ON cl.child_id = rl.parent_id
											WHERE rl.is_node_link IS FALSE),

	/*get info about when each suppnode added to pp, and for nodes added to multiple pps, when was the first time they were added*/
	pp_suppnode_info AS (SELECT MIN(date_supp_added) AS date_supp_added, node_id, MIN(created) AS pp_created
							FROM osf_preprint
							LEFT JOIN (SELECT preprint_id, MAX(created) AS date_supp_added
 											 FROM osf_preprintlog
 											 WHERE action = 'supplement_node_added'
 											 GROUP BY preprint_id) AS preprint_suppnode 
							ON osf_preprint.id = preprint_suppnode.preprint_id
							GROUP BY node_id),

	/*break apart json field into one line for each day with download info (but only for files who've had their downloads updated within the last 3 months*/
	 daily_format AS (SELECT *, json_object_keys(date::json) AS download_date, json_each_text(date::json) AS daily_downloads
						FROM osf_pagecounter
						WHERE action = 'download' AND version IS NULL AND modified >= date_trunc('month', current_date - interval '3' month)),

	 /*for each day, extract total download numbers for that day*/
	 daily_downloads AS (SELECT daily_format.id, file_id, resource_id,TO_DATE(download_date, 'YYYY/MM/DD') AS download_date, 
								(SELECT regexp_matches(daily_downloads::text, '\{""total"": ([0-9]*)'))[1] AS total,
								target_content_type_id, target_object_id
							FROM daily_format
							LEFT JOIN osf_basefilenode
							ON daily_format.file_id = osf_basefilenode.id),

	  /*categorize each file by node/file type and connections*/
 	file_categorization AS (SELECT  file_id, 
 									target_object_id, 
 									target_content_type_id,
 									collection_id, 
 									download_date, 
 									total::INTEGER, 
 									type, 
 									preprints.created AS pp_created,
 									tag_id,
 									pp_suppnode_info.date_supp_added,
 									pp_suppnode_info.node_id,
 									pp_suppnode_info.pp_created,
 									child_id,
 									supp_nodes.date_supp_added AS date_parent_supp_added,
 									supp_nodes.pp_created AS date_parent_pp_created,
 									CASE WHEN institution_id IS NOT NULL THEN 1 ELSE 0 END as inst_affil,
 									CASE WHEN tag_id = 26265 THEN 1 ELSE 0 END as osf4m,
 									CASE WHEN target_content_type_id = 47 AND download_date >= date_trunc('day', preprints.created) THEN 1 ELSE 0 END as preprint,
 									CASE WHEN pp_suppnode_info.node_id IS NOT NULL AND download_date >= date_trunc('day', pp_suppnode_info.date_supp_added) THEN 1 
 										 WHEN pp_suppnode_info.node_id IS NOT NULL AND pp_suppnode_info.date_supp_added IS NULL AND download_date >= date_trunc('day', pp_suppnode_info.pp_created) THEN 1 
 										 WHEN child_id IS NOT NULL AND download_date >= date_trunc('day', supp_nodes.date_supp_added) THEN 1
 										 WHEN child_id IS NOT NULL AND supp_nodes.date_supp_added IS NULL AND download_date >= date_trunc('day', supp_nodes.pp_created) THEN 1
 										 ELSE 0 END as supp_node,
 									CASE WHEN collection_id IS NOT NULL AND download_date >= date_trunc('day', collection_submit_date) THEN 1 ELSE 0 END as collection

								 FROM daily_downloads
								 
								 /*join in node info for node type [node vs. registration vs. quickfiles]*/
								 LEFT JOIN osf_abstractnode
								 ON daily_downloads.target_object_id = osf_abstractnode.id AND daily_downloads.target_content_type_id = 30
								 
								 /*identify and merge in osf4m tags on nodes and don't include original osf4m nodes that were migrated to preprints at start of services*/
								 LEFT JOIN (SELECT abstractnode_id, MAX(tag_id) AS tag_id
								 				FROM osf_abstractnode_tags
								 				WHERE tag_id = 26265 OR tag_id = 26294
								 				GROUP BY abstractnode_id) AS project_tags
								 ON osf_abstractnode.id = project_tags.abstractnode_id

								 /* nodes can be affiliated with multiple institutions, so need to deduplicate before joining in to keep 1 row per node */ 
								 LEFT JOIN (SELECT DISTINCT ON (abstractnode_id) abstractnode_id, institution_id
								 				FROM osf_abstractnode_affiliated_institutions
								 				WHERE institution_id != 12) AS deduped_inst_nodes /*exclude node only affiliated with COS institution*/
								 ON osf_abstractnode.id = deduped_inst_nodes.abstractnode_id

								 LEFT JOIN pp_suppnode_info
								 ON osf_abstractnode.id = pp_suppnode_info.node_id

								 /* same file are primary files on multiple pps */
								 LEFT JOIN (SELECT primary_file_id, MIN(created) AS created
								 				FROM osf_preprint
								 				GROUP BY primary_file_id) AS preprints
								 ON daily_downloads.file_id = preprints.primary_file_id

								 LEFT JOIN (SELECT Distinct(child_id), date_supp_added, pp_created
								 				FROM supp_children_nodes
								 				LEFT JOIN pp_suppnode_info
								 				ON supp_children_nodes.suppnode_id = pp_suppnode_info.node_id) AS supp_nodes
								 ON osf_abstractnode.id = supp_nodes.child_id

								 LEFT JOIN (SELECT collection_id,
												   	COALESCE(project_nodes.id, object_id) AS node_id,
												   	osf_collectionsubmission.created AS collection_submit_date
												FROM osf_collectionsubmission
												LEFT JOIN (SELECT *
															FROM osf_guid
															WHERE content_type_id = 30) as node_guids
												ON osf_collectionsubmission.guid_id = node_guids.id
												LEFT JOIN osf_abstractnode as project_nodes
												ON node_guids.object_id = project_nodes.root_id
												WHERE (collection_id = 711617 OR collection_id = 709754 OR collection_id = 775210 OR collection_id = 735729)) AS collection_nodes
								 ON osf_abstractnode.id = collection_nodes.node_id

								 /* only get information for downloads that happened last quarter [assuming you're running the script sometime in the 1st month of the new quarter] */
								 WHERE download_date >= date_trunc('month', current_date - interval '3' month) AND download_date < date_trunc('month', current_date))

/* calculate monthly downloads for all product types*/
SELECT date_trunc('month', download_date) AS date,
		SUM(CASE WHEN osf4m = 1 THEN total ELSE 0 END) AS osf4m_downloads,
		SUM(CASE WHEN type = 'osf.quickfilesnode' THEN total ELSE 0 END) AS quickfile_downloads,
		SUM(CASE WHEN type = 'osf.registration' THEN total ELSE 0 END) AS reg_downloads,
		SUM(CASE WHEN preprint = 1 THEN total ELSE 0 END) AS pp_downloads,
		SUM(CASE WHEN supp_node = 1 THEN total ELSE 0 END) AS suppnode_downloads,
		SUM(CASE WHEN inst_affil = 1 THEN total ELSE 0 END) AS inst_downloads,
		SUM(CASE WHEN collection = 1 THEN total ELSE 0 END) AS collection_downloads,
		SUM(CASE WHEN type = 'osf.node' THEN total ELSE 0 END) AS osfnode_download,
		SUM(CASE WHEN type = 'osf.node' AND osf4m = 0 AND supp_node = 0 AND inst_affil = 0 AND collection = 0 THEN total ELSE 0 END) AS osfgen_download
	FROM file_categorization
	GROUP BY date_trunc('month', download_date)