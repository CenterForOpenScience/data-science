/* User Generation Tag Counting */


/* intital query to get info about users with system tags, dates, and SSO */
SELECT username, is_registered, is_invited, date_registered, date_confirmed, is_active, deleted, spam_status, osf_tag.name, institution_id
	FROM osf_osfuser
	LEFT JOIN osf_osfuser_tags
	ON osf_osfuser.id = osf_osfuser_tags.osfuser_id
	LEFT JOIN osf_tag
	ON osf_osfuser_tags.tag_id = osf_tag.id
	LEFT JOIN osf_osfuser_affiliated_institutions
	ON osf_osfuser.id = osf_osfuser_affiliated_institutions.osfuser_id
	WHERE osf_tag.system IS TRUE;
