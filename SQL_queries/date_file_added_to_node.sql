
/* get WB id for each file uploaded to osf_storage */
WITH view_links AS (SELECT json_extract_path_text(params::json, 'urls', 'view') AS view_link, id
	FROM osf_nodelog
	WHERE action = 'osf_storage_file_added'
	LIMIT 100)
	
SELECT id, view_link, reverse(split_part(reverse(view_link), '/', 2)) AS wb_id
	FROM view_links;