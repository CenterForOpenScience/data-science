/* downloads by product type backfill query*/

WITH daily_format AS (SELECT *, json_object_keys(date::json) AS download_date, json_each_text(date::json) AS daily_downloads
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
 									CASE WHEN institution_id IS NOT NULL THEN 1 ELSE 0 END as inst_affil
								 FROM daily_downloads
								 LEFT JOIN osf_abstractnode
								 ON daily_downloads.target_object_id = osf_abstractnode.id
								 LEFT JOIN (SELECT *
								 				FROM osf_abstractnode_tags
								 				LEFT JOIN osf_tag
								 				ON osf_abstractnode_tags.tag_id = osf_tag.id
								 				WHERE name = 'osf4m') AS project_tags
								 ON osf_abstractnode.id = project_tags.abstractnode_id,

								 /* nodes can be affiliated with multiple institutions, so need to deduplicate before joining in to keep 1 row per node */ 
								 LEFT JOIN (SELECT DISTINCT ON (abstractnode_id) abstractnode_id, institution_id
								 				FROM osf_abstractnode_affiliated_institutions) AS deduped_inst_nodes
								 ON osf_abstractnode.id = deduped_inst_nodes.abstractnode_id
								 WHERE target_content_type_id = 30)


/* downloads by product type per quater */

SELECT *
	FROM osf_pagecounter
	WHERE modified >= date_trunc('month', current_date - interval '3' month) AND
			action = 'download'

