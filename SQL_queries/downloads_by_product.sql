/* downloads by product type backfill query*/

WITH daily_format AS (SELECT *, json_object_keys(date::json) AS download_date, json_each_text(date::json) AS daily_downloads
						FROM osf_pagecounter
						WHERE action = "download"
						LIMIT 100)

SELECT osf_pagecounter.id, date, osf_pagecounter.modified, file_id, resource_id, version, 
		target_content_type_id, target_object_id
	FROM osf_pagecounter
	LEFT JOIN osf_basefilenode
	ON osf_pagecounter.file_id = osf_basefilenode.id
	WHERE action = 'download'
	LIMIT 100


/* downloads by product type per quater */

SELECT *
	FROM osf_pagecounter
	WHERE modified >= date_trunc('month', current_date - interval '3' month) AND
			action = 'download'
