
/* get WB id for each file uploaded to osf_storage */
WITH eligible_nodes AS (SELECT id, root_id, is_fork, is_public, created
							FROM osf_abstractnode
							WHERE is_deleted IS FALSE AND title NOT LIKE 'Bookmarks' AND type = 'osf.node' AND
							id NOT IN (203576, 16756, 697313, 697312, 757287, 803779, 803816, 803815, 758391, 803783, 693151, 
								723541, 693068, 53157) AND 
							creator_id NOT IN(38706, 44674, 45859, 29901, 60863, 41245, 8559, 17491, 5322, 40861, 69259, 69181, 69833, 
								70258, 70262, 10310, 49223, 53835, 55925, 47949, 1599, 2187, 32702, 57637, 99653, 17756, 49847, 117933,
								129785, 9991, 28225, 32238, 76344, 36859, 208328, 207423, 17713, 24528, 46874, 12094, 53851, 56723, 63403,
								90649, 19264, 63662, 144039, 10126, 11381, 19209, 22327, 62326, 55635, 64182, 55113, 18159, 47635, 60542,
								9892, 27492, 33786, 60662, 1422, 53340, 10014, 48829, 78579, 99653, 2187, 1599, 57637, 32702, 43125, 13100, 46045)),
	view_links AS (SELECT json_extract_path_text(params::json, 'urls', 'view') AS view_link, logs.id AS log_id, node_id, original_node_id, date
						FROM eligible_nodes
						LEFT JOIN (SELECT *
									FROM osf_nodelog
									WHERE action = 'osf_storage_file_added' OR action = 'file_added'
									LIMIT 10000) AS logs
						ON eligible_nodes.id = logs.node_id),
	wb_ids AS (SELECT log_id, view_link, reverse(split_part(reverse(view_link), '/', 2)) AS wb_id, node_id, date
					FROM view_links
					WHERE node_id = original_node_id),
	moved_view_links AS (SELECT json_extract_path_text(params::json, 'destination', 'path') AS wb_path,
						   json_extract_path_text(params::json, 'destination', 'nid') AS destination_guid,
						   json_extract_path_text(params::json, 'source', 'nid') AS source_guid,
						   json_extract_path_text(params::json, 'destination', 'addon') AS addon_type, 
						   json_extract_path_text(params::json, 'destination', 'children') AS file_or_folder,  
						   moved_logs.id AS moved_log_id, node_id AS moved_node_id, original_node_id AS moved_original_node_id, date AS moved_log_date, params, action 
						FROM eligible_nodes
						LEFT JOIN (SELECT *
									FROM osf_nodelog
									WHERE (action = 'addon_file_moved' OR  action = 'addon_file_copied') AND node_id != 203576 AND node_id != 16756
									LIMIT 5000) AS moved_logs
						ON eligible_nodes.id = moved_logs.node_id),
	moved_wb_folder_ids AS (SELECT *, BTRIM(each_etag ->> 'path', '/') AS path
						FROM moved_view_links
						cross join json_array_elements(file_or_folder::json) each_etag
						WHERE addon_type = 'OSF Storage' AND file_or_folder IS NOT NULL AND destination_guid != source_guid),
	moved_wb_nonfolder_ids AS (SELECT *, BTRIM(wb_path, '/') AS path
						FROM moved_view_links
						WHERE addon_type = 'OSF Storage' AND file_or_folder IS NULL AND destination_guid != source_guid)	

/* join up with basefilenode table on GUIDs to compare log dates and file created dates */
SELECT node_id, wb_ids.date AS nodelog_date, wb_id, osf_basefilenode.type, name, osf_basefilenode.created, osf_basefilenode.modified, copied_from_id, 
		moved_wb_folder_ids.path AS folder_moved_path, moved_wb_nonfolder_ids.path AS nonfolder_moved_path, 
		moved_wb_folder_ids.moved_log_id, moved_wb_folder_ids.moved_node_id, moved_wb_folder_ids.moved_original_node_id, moved_wb_folder_ids.moved_log_date,
		moved_wb_nonfolder_ids.moved_log_id, moved_wb_nonfolder_ids.moved_node_id, moved_wb_nonfolder_ids.moved_original_node_id, moved_wb_nonfolder_ids.moved_log_date,
		moved_wb_folder_ids.destination_guid, moved_wb_folder_ids.source_guid, moved_wb_nonfolder_ids.destination_guid, moved_wb_nonfolder_ids.source_guid
	FROM eligible_nodes
	LEFT JOIN osf_basefilenode
	ON eligible_nodes.id = osf_basefilenode.target_object_id
	LEFT JOIN wb_ids
	ON osf_basefilenode._id = wb_ids.wb_id AND osf_basefilenode.target_object_id = wb_ids.node_id
	LEFT JOIN moved_wb_folder_ids
	ON osf_basefilenode._id = moved_wb_folder_ids.path AND osf_basefilenode.target_object_id = moved_wb_folder_ids.moved_node_id
	LEFT JOIN moved_wb_nonfolder_ids
	ON osf_basefilenode._id = moved_wb_nonfolder_ids.path AND osf_basefilenode.target_object_id = moved_wb_nonfolder_ids.moved_node_id
	WHERE target_content_type_id = 30 AND osf_basefilenode.type = 'osf.osfstoragefile';



/* get WB id for copied files */
WITH copied_links AS (SELECT json_extract_path_text(params::json, 'destination', 'path') AS wb_path,
						   json_extract_path_text(params::json, 'destination', 'nid') AS destination_guid,
						   json_extract_path_text(params::json, 'destination', 'addon') AS addon_type, 
						   json_extract_path_text(params::json, 'destination', 'children') AS file_or_folder,  
						   id, node_id, original_node_id, date, params 
						FROM osf_nodelog
						WHERE action = 'addon_file_copied' AND node_id != 203576 AND node_id != 16756),
	non_folder_paths AS (SELECT *, BTRIM(wb_path, '/') AS path
						FROM copied_links
						WHERE addon_type = 'OSF Storage' AND file_or_folder IS NULL),
	fold_paths AS (SELECT *, BTRIM(each_etag ->> 'path', '/') AS path
						FROM copied_links
						cross join json_array_elements(file_or_folder::json) each_etag
						WHERE addon_type = 'OSF Storage' AND file_or_folder IS NOT NULL)



