/* get a count, by node, of the frequency of each type of log and the first and last date of each type */
SELECT root_id, osf_abstractnode.id, min(osf_nodelog.date) AS first_date, max(osf_nodelog.date) AS last_date, COUNT(osf_nodelog.id) AS num_actions, action
	FROM osf_abstractnode
	LEFT JOIN osf_nodelog
	ON osf_abstractnode.id = osf_nodelog.node_id
	WHERE type = 'osf.node' AND title NOT LIKE 'Bookmarks' AND is_deleted IS FALSE AND
							/* excluding log heavy API testings and QA projects */
							osf_abstractnode.id NOT IN (203576, 16756, 697313, 697312, 757287, 803779, 803816, 803815, 758391, 803783, 693151, 
								723541, 693068, 53157) AND 
							osf_abstractnode.creator_id NOT IN(38706, 44674, 45859, 29901, 60863, 41245, 8559, 17491, 5322, 40861, 69259, 69181, 69833, 
								70258, 70262, 10310, 49223, 53835, 55925, 47949, 1599, 2187, 32702, 57637, 99653, 17756, 49847, 117933,
								129785, 9991, 28225, 32238, 76344, 36859, 208328, 207423, 17713, 24528, 46874, 12094, 53851, 56723, 63403,
								90649, 19264, 63662, 144039, 10126, 11381, 19209, 22327, 62326, 55635, 64182, 55113, 18159, 47635, 60542,
								9892, 27492, 33786, 60662, 1422, 53340, 10014, 48829, 78579, 99653, 2187, 1599, 57637, 32702, 43125, 13100, 46045)
	GROUP BY osf_abstractnode.id, action, root_id


/* first five types of logs on a project */
WITH lastyr_projects AS (SELECT osf_abstractnode.id AS project_id, 
							MIN(osf_nodelog.created) AS first_timestamp, 
							action, 
							osf_abstractnode.created AS project_created 
								FROM osf_abstractnode
								LEFT JOIN osf_nodelog
								ON osf_abstractnode.id = osf_nodelog.node_id
								WHERE type = 'osf.node' AND 
									title NOT LIKE 'Bookmarks' AND 
									title NOT LIKE 'SCORE%' AND
									osf_abstractnode.id = root_id AND 
									(spam_status = 1 OR spam_status IS NULL OR spam_status = 4) AND
									osf_abstractnode.created >= '2019-06-30' AND osf_abstractnode.created < '2020-07-01' AND
									is_fork IS FALSE AND
									is_deleted IS FALSE AND
									action != 'project_created'
								GROUP BY osf_abstractnode.id, action, osf_abstractnode.created)


SELECT *
		FROM (
			SELECT lastyr_projects.*,
				rank() OVER (
					PARTITION BY project_id
					ORDER BY first_timestamp)
				FROM lastyr_projects) AS top_five
		WHERE rank < 6

/* first five logs on a project */
WITH lastyr_projects AS (SELECT osf_abstractnode.id AS project_id,osf_nodelog.created AS first_timestamp, action, 		osf_abstractnode.created AS project_created
								FROM osf_abstractnode
								LEFT JOIN osf_nodelog
								ON osf_abstractnode.id = osf_nodelog.node_id
								WHERE type = 'osf.node' AND 
									title NOT LIKE 'Bookmarks' AND 
									title NOT LIKE 'SCORE%' AND
									osf_abstractnode.id = root_id AND 
									(spam_status = 1 OR spam_status IS NULL OR spam_status = 4) AND
									osf_abstractnode.created >= '2019-06-30' AND osf_abstractnode.created < '2020-07-01' AND
									is_fork IS FALSE AND
									is_deleted IS FALSE AND
									action != 'project_created')


SELECT *
		FROM (
			SELECT lastyr_projects.*,
				rank() OVER (
					PARTITION BY project_id
					ORDER BY first_timestamp)
				FROM lastyr_projects) AS top_five
		WHERE rank < 6


/* first five types of logs on components */
WITH lastyr_components AS (SELECT osf_abstractnode.id AS component_id, 
							MIN(osf_nodelog.created) AS first_timestamp, 
							action, 
							osf_abstractnode.created AS project_created 
								FROM osf_abstractnode
								LEFT JOIN osf_nodelog
								ON osf_abstractnode.id = osf_nodelog.node_id
								WHERE type = 'osf.node' AND 
									title NOT LIKE 'Bookmarks' AND 
									title NOT LIKE 'SCORE%' AND
									osf_abstractnode.id != root_id AND 
									(spam_status = 1 OR spam_status IS NULL OR spam_status = 4) AND
									osf_abstractnode.created >= '2019-06-30' AND osf_abstractnode.created < '2020-07-01' AND
									is_fork IS FALSE AND
									is_deleted IS FALSE AND
									action != 'project_created'
								GROUP BY osf_abstractnode.id, action, osf_abstractnode.created)


SELECT *
		FROM (
			SELECT lastyr_components.*,
				rank() OVER (
					PARTITION BY component_id
					ORDER BY first_timestamp)
				FROM lastyr_components) AS top_five
		WHERE rank < 6

/* first five logs on components */
WITH lastyr_components AS (SELECT osf_abstractnode.id AS component_id,osf_nodelog.created AS first_timestamp, action, 		osf_abstractnode.created AS project_created
								FROM osf_abstractnode
								LEFT JOIN osf_nodelog
								ON osf_abstractnode.id = osf_nodelog.node_id
								WHERE type = 'osf.node' AND 
									title NOT LIKE 'Bookmarks' AND 
									title NOT LIKE 'SCORE%' AND
									osf_abstractnode.id != root_id AND 
									(spam_status = 1 OR spam_status IS NULL OR spam_status = 4) AND
									osf_abstractnode.created >= '2019-06-30' AND osf_abstractnode.created < '2020-07-01' AND
									is_fork IS FALSE AND
									is_deleted IS FALSE AND
									action != 'project_created')


SELECT *
		FROM (
			SELECT lastyr_components.*,
				rank() OVER (
					PARTITION BY component_id
					ORDER BY first_timestamp)
				FROM lastyr_components) AS top_five
		WHERE rank < 6


