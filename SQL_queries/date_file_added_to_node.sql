
/* get WB id for each file uploaded to osf_storage */
WITH view_links AS (SELECT json_extract_path_text(params::json, 'urls', 'view') AS view_link, logs.id AS log_id, node_id, original_node_id, date
						FROM osf_abstractnode
						LEFT JOIN (SELECT *
									FROM osf_nodelog
									WHERE action = 'osf_storage_file_added' OR action = 'file_added'
									LIMIT 10000) AS logs
						ON osf_abstractnode.id = logs.node_id
						WHERE is_deleted IS FALSE AND title NOT LIKE 'Bookmarks' AND type = 'osf.node'),
	wb_ids AS (SELECT log_id, view_link, reverse(split_part(reverse(view_link), '/', 2)) AS wb_id, node_id, date
					FROM view_links
					WHERE node_id = original_node_id)

/* join up with basefilenode table on GUIDs to compare log dates and file created dates */
SELECT node_id, wb_ids.date AS nodelog_date, wb_id, type, name, created, modified, copied_from_id
	FROM osf_basefilenode
	FULL OUTER JOIN wb_ids
	ON osf_basefilenode._id = wb_ids.wb_id AND osf_basefilenode.target_object_id = wb_ids.node_id
	WHERE target_content_type_id = 30;



/* get WB id for moved files */
WITH view_links AS (SELECT json_extract_path_text(params::json, 'destination', 'path') AS wb_path,
						   json_extract_path_text(params::json, 'destination', 'nid') AS destination_guid,
						   json_extract_path_text(params::json, 'destination', 'addon') AS addon_type, 
						   json_extract_path_text(params::json, 'sourcec', 'kind') AS source_type, 
						   json_extract_path_text(params::json, 'destination', 'kind') AS destination_type, 
						   json_extract_path_text(params::json, 'destination', 'children') AS file_or_folder,  
						   id, node_id, original_node_id, date, params 
						FROM osf_nodelog
						WHERE action = 'addon_file_moved')
						
SELECT *, each_etag ->> 'path' AS path
	FROM view_links
	cross join json_array_elements(file_or_folder::json) each_etag
	WHERE addon_type = 'OSF Storage' AND destination_type = 'folder' AND file_or_folder IS NOT NULL;