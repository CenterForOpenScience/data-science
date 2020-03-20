/* downloads by product type backfill query*/

SELECT *
	FROM osf_pagecounter
	LEFT JOIN osf_basefilenode
	osf_pagecounter.file_id = osf_basefilenode.id
	WHERE action = 'download'


/* downloads by product type per quater */

SELECT *
	FROM osf_pagecounter
	WHERE modified >= date_trunc('month', current_date - interval '3' month) AND
			action = 'download'

