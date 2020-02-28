/* User Generation Tag Counting */


/* intital query to get info about users with system tags, dates, and SSO */
WITH user_tag_info AS (SELECT osf_osfuser.id AS user_id, username, is_registered, is_invited, date_registered, date_confirmed, date_disabled, is_active, deleted, spam_status, osf_tag.name, institution_id
						FROM osf_osfuser
						LEFT JOIN osf_osfuser_tags
						ON osf_osfuser.id = osf_osfuser_tags.osfuser_id
						LEFT JOIN osf_tag
						ON osf_osfuser_tags.tag_id = osf_tag.id
						LEFT JOIN osf_osfuser_affiliated_institutions
						ON osf_osfuser.id = osf_osfuser_affiliated_institutions.osfuser_id
						WHERE osf_tag.system IS TRUE AND (osf_tag.name NOT LIKE '%spam' AND osf_tag.name != 'high_upload_limit' AND osf_tag.name != 'ham_confirmed' AND osf_tag.name NOT LIKE '%metrics' AND osf_tag.name != 'prereg_admin'))

SELECT COUNT(user_id) AS new_signups, name
	FROM user_tag_info
	WHERE is_registered IS TRUE AND is_invited IS FALSE
	GROUP BY name;
	

