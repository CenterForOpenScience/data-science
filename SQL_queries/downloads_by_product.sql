/* downloads by product type backfill query*/

WITH 

	/* get all nested components under connected suppnode to also classify them as suppnodes */
	RECURSIVE children_nodes AS (SELECT osf_noderelation.id, osf_noderelation._id, is_node_link, child_id, parent_id, parent_id AS suppnode_id
										FROM osf_preprint
										LEFT JOIN osf_noderelation
										ON osf_preprint.node_id = osf_noderelation.parent_id
										WHERE is_node_link IS FALSE
									UNION
										SELECT cl.id, cl._id, cl.is_node_link, rl.child_id, rl.parent_id, suppnode_id
											FROM osf_noderelation rl
											INNER JOIN children_nodes cl
											ON cl.child_id = rl.parent_id
											WHERE rl.is_node_link IS FALSE),

	 /* dedpublicate resulting relations since single suppnode can be connected to mulitple preprints */
	 suppnode_relations AS (SELECT DISTINCT ON (child_id) child_id, suppnode_id, parent_id, id
								FROM children_nodes),
	 daily_format AS (SELECT *, json_object_keys(date::json) AS download_date, json_each_text(date::json) AS daily_downloads
						FROM osf_pagecounter
						WHERE action = 'download'
						LIMIT 100),
	 daily_downloads AS (SELECT daily_format.id, file_id, resource_id,TO_DATE(download_date, 'YYYY/MM/DD') AS download_date, 
								(SELECT regexp_matches(daily_downloads::text, '\{""total"": ([0-9]*)'))[1] AS total,
								target_content_type_id, target_object_id
							FROM daily_format
							LEFT JOIN osf_basefilenode
							ON daily_format.file_id = osf_basefilenode.id),
 	monthly_pp_downloads AS (SELECT COUNT(total) AS downloads, date_trunc('month', download_date) AS trunc_date
							FROM daily_downloads
							WHERE target_content_type_id = 47
							GROUP BY date_trunc('month', download_date)),
 	monthly_file_downloads AS (SELECT daily_downloads.id, target_object_id, osf_abstractnode.id, download_date, total, type, spam_status, name,
 									CASE WHEN institution_id IS NOT NULL THEN 1 ELSE 0 END as inst_affil,
 									CASE WHEN sr_child.suppnode_id IS NOT NULL OR sr_parent.suppnode_id IS NOT NULL THEN 1 ELSE 0 END as supp_node
								 FROM daily_downloads
								 LEFT JOIN osf_abstractnode
								 ON daily_downloads.target_object_id = osf_abstractnode.id
								 LEFT JOIN (SELECT *
								 				FROM osf_abstractnode_tags
								 				LEFT JOIN osf_tag
								 				ON osf_abstractnode_tags.tag_id = osf_tag.id
								 				WHERE name = 'osf4m') AS project_tags
								 ON osf_abstractnode.id = project_tags.abstractnode_id

								 /* nodes can be affiliated with multiple institutions, so need to deduplicate before joining in to keep 1 row per node */ 
								 LEFT JOIN (SELECT DISTINCT ON (abstractnode_id) abstractnode_id, institution_id
								 				FROM osf_abstractnode_affiliated_institutions) AS deduped_inst_nodes
								 ON osf_abstractnode.id = deduped_inst_nodes.abstractnode_id

								 /* join in parents and children suppnodes seperately to categorize both */
								 LEFT JOIN suppnode_relations sr_child
								 ON osf_abstractnode.id = sr_child.child_id
								 LEFT JOIN (SELECT DISTINCT ON (parent_id) parent_id, suppnode_id, child_id
				 								FROM suppnode_relations) AS sr_parent
								 ON osf_abstractnode.id = sr_parent.parent_id

								 WHERE target_content_type_id = 30)


/* downloads by product type per quater */

SELECT *
	FROM osf_pagecounter
	WHERE modified >= date_trunc('month', current_date - interval '3' month) AND
			action = 'download'

