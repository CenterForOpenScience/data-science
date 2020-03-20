/* downloads by product type backfill query*/

SELECT osf_pagecounter.id, date, osf_pagecounter.modified, file_id, resource_id, version, 
		target_content_type_id, target_object_id
	FROM osf_pagecounter
	LEFT JOIN osf_basefilenode
	ON osf_pagecounter.file_id = osf_basefilenode.id
	WHERE action = 'download'


/* downloads by product type per quater */

SELECT *
	FROM osf_pagecounter
	WHERE modified >= date_trunc('month', current_date - interval '3' month) AND
			action = 'download'

