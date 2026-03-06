/* count of emails by institution */

/* get a list of all the institutions registered users have email accounts with */
WITH emails AS (SELECT SPLIT_PART(address, '@', 2) AS institution, user_id, address, is_registered, is_active 
	FROM osf_email
	LEFT JOIN osf_osfuser
	ON osf_email.user_id = osf_osfuser.id
	WHERE is_registered IS TRUE AND (spam_status IS NULL OR spam_status != 2))

/* count up the number of users by institution*/	
SELECT COUNT(user_id), institution
	/* remove duplicate user/institution rows for schools like UVA that allow email aliases*/
	FROM (SELECT DISTINCT user_id, institution
			FROM emails) AS deduplicate
	GROUP BY institution;