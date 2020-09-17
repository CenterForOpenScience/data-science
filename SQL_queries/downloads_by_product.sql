/* downloads by product type backfill query*/

WITH 

	/* get all nested components under connected suppnode to also classify them as suppnodes */
	RECURSIVE children_nodes AS (SELECT osf_noderelation.id, osf_noderelation._id, is_node_link, child_id, parent_id, parent_id AS suppnode_id, osf_preprint.id AS preprint_id
										FROM osf_preprint
										LEFT JOIN osf_noderelation
										ON osf_preprint.node_id = osf_noderelation.parent_id
										WHERE is_node_link IS FALSE
									UNION
										SELECT cl.id, cl._id, cl.is_node_link, rl.child_id, rl.parent_id, suppnode_id, preprint_id
											FROM osf_noderelation rl
											INNER JOIN children_nodes cl
											ON cl.child_id = rl.parent_id
											WHERE rl.is_node_link IS FALSE),

	/*get info about when each suppnode added to pp, and for nodes added to multiple pps, when was the first time they were added as a suppnode?*/
	pp_suppnode_info AS (SELECT preprint_id, MIN(date_supp_added), node_id
							FROM osf_preprint
							LEFT JOIN (SELECT preprint_id, MAX(created) AS date_supp_added
 											 FROM osf_preprintlog
 											 WHERE action = 'supplement_node_added'
 											 GROUP BY preprint_id) AS preprint_suppnode 
							ON osf_preprint.id = preprint_suppnode.preprint_id
							GROUP BY node_id, preprint_id),

	 /* dedpublicate resulting relations since single suppnode can be connected to mulitple preprints */ /*this only ids suppnodes that have children, doesn't include suppnodes that don't have kids*/
	 suppnode_relations AS (SELECT child_id, suppnode_id, parent_id, children_nodes.preprint_id, date_supp_added, node_id
								FROM children_nodes
								LEFT JOIN osf_preprint
								ON osf_preprint.node_id = suppnode_id
								LEFT JOIN (SELECT preprint_id, MAX(created) AS date_supp_added
 											 FROM osf_preprintlog
 											 WHERE action = 'supplement_node_added'
 											 GROUP BY preprint_id) AS preprint_suppnode
 								ON osf_preprint.id = preprint_suppnode.preprint_id),

	 /*break apart json field into one line for each day with download info*/
	 daily_format AS (SELECT *, json_object_keys(date::json) AS download_date, json_each_text(date::json) AS daily_downloads
						FROM osf_pagecounter
						WHERE action = 'download' AND version IS NULL
						LIMIT 100),

	 /*for each day, extract total download numbers for that day*/
	 daily_downloads AS (SELECT daily_format.id, file_id, resource_id,TO_DATE(download_date, 'YYYY/MM/DD') AS download_date, 
								(SELECT regexp_matches(daily_downloads::text, '\{""total"": ([0-9]*)'))[1] AS total,
								target_content_type_id, target_object_id
							FROM daily_format
							LEFT JOIN osf_basefilenode
							ON daily_format.file_id = osf_basefilenode.id),

	 /*categorize each file by node/file type and connections*/
 	file_categorization AS (SELECT daily_downloads.id, 
 									target_object_id, 
 									target_content_type_id,
 									osf_abstractnode.id, 
 									download_date, 
 									total, 
 									type, 
 									spam_status, 
 									tag_id,
 									CASE WHEN institution_id IS NOT NULL THEN 1 ELSE 0 END as inst_affil,
 									CASE WHEN sr_child.suppnode_id IS NOT NULL OR sr_parent.suppnode_id IS NOT NULL THEN 1 ELSE 0 END as supp_node,
 									CASE WHEN tag_id = 26265 THEN 1 ELSE 0 END as osf4m,
 									CASE WHEN target_content_type_id = 47 THEN 1 ELSE 0 END as preprint

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
								 ON osf_abstractnode.id = deduped_inst_nodes.abstractnode_id)

/* calculate monthly downloads for all product types*/
SELECT *
	FROM file_categorization


/* downloads by product type per quater */

SELECT *
	FROM osf_pagecounter
	WHERE modified >= date_trunc('month', current_date - interval '3' month) AND
			action = 'download'




 /* join in parents and children suppnodes seperately to categorize both */
								 LEFT JOIN suppnode_relations sr_child
								 ON osf_abstractnode.id = sr_child.child_id
								 LEFT JOIN (SELECT DISTINCT ON (parent_id) parent_id, suppnode_id, child_id
				 								FROM suppnode_relations) AS sr_parent
								 ON osf_abstractnode.id = sr_parent.parent_id

 								/* join in preprint information */
 								LEFT JOIN (SELECT osf_preprint.id AS preprint_id, add_date, node_id
 											 FROM osf_preprint
 												LEFT JOIN (SELECT preprint_id, MAX(created) AS add_date
 																FROM osf_preprintlog
				 												WHERE action = 'supplement_node_added'
																GROUP BY preprint_id) AS pp_suppnode_adds
 												ON osf_preprint.id = pp_suppnode_adds.preprint_id) AS pp_info
 								ON daily_downloads.target_object_id = pp_info.preprint_id AND daily_downloads.target_content_type_id = 47