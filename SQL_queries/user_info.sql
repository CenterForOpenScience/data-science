/* Getting the GUID for a user [just looked at mine to double check join]*/
SELECT osf_osfuser.*, osf_guid.*
	FROM osf_osfuser
	JOIN osf_guid
	ON osf_osfuser.id = osf_guid.object_id
	WHERE osf_osfuser.username = 'csoderbe@gmail.com' AND osf_guid.content_type_id = 18;

/* getting the number of users with virginia.edu email addresses associated with their accounts*/
WITH uva1 AS (SELECT * FROM osf_email WHERE osf_email.address LIKE '%virginia.edu%')

SELECT DISTINCT ON (osf_osfuser.id) *
	FROM osf_osfuser
	FULL OUTER JOIN uva1
	ON osf_osfuser.id = uva1.user_id
	WHERE (osf_osfuser.username LIKE '%virginia.edu%' OR uva1.address LIKE '%virginia.edu%') AND is_registered IS TRUE;


	/*how many social/personality posters*/
SELECT osf_osfuser.username
	FROM osf_tag
	JOIN osf_abstractnode_tags
	ON osf_abstractnode_tags.tag_id = osf_tag.id
	JOIN osf_abstractnode
	ON osf_abstractnode_tags.abstractnode_id = osf_abstractnode.id
	JOIN osf_contributor
	ON osf_abstractnode.id = osf_contributor.node_id
	JOIN osf_osfuser
	ON osf_contributor.user_id = osf_osfuser.id
	WHERE (osf_tag.name LIKE '%SPSP%' OR osf_tag.name LIKE '%spsp%') AND osf_abstractnode.type = 'osf.node' AND osf_osfuser.is_active = 'TRUE';

/*how many social/personality preprints*/
SELECT COUNT(DISTINCT osf_osfuser.username)
	FROM osf_subject
	INNER JOIN osf_preprintservice_subjects
	ON osf_subject.id = osf_preprintservice_subjects.subject_id
	JOIN osf_preprintservice
	ON osf_preprintservice.id = osf_preprintservice_subjects.preprintservice_id
	JOIN osf_abstractnode
	ON osf_preprintservice.node_id = osf_abstractnode.id
	JOIN osf_contributor
	ON osf_abstractnode.id = osf_contributor.node_id
	JOIN osf_osfuser
	ON osf_contributor.user_id = osf_osfuser.id
	WHERE osf_preprintservice.provider_id IS NOT NULL AND (osf_subject.text = 'Social Psychology' OR osf_subject.text = 'Personality and Social Contexts' OR osf_subject.text = 'Social and Personality Psychology') AND osf_osfuser.is_active = 'TRUE';

/* users per year */
SELECT DATE_PART('year', date_registered) AS year_registered, COUNT(*) AS per_year
	FROM osf_osfuser
	WHERE deleted IS NULL AND is_active = 'TRUE'
	GROUP BY 1;


/* Getting the 100 most recent nodelogs for Courtney Soderberg with the node they went with */
SELECT node.*, guid.*, osf.*
	FROM osf_nodelog node
	JOIN osf_guid guid
	ON guid.id = node_id
	JOIN osf_osfuser osf
	ON node.user_id = osf.id
	WHERE osf.username = 'csoderbe@gmail.com'
	ORDER BY node.date DESC
	LIMIT(100);

/*getting my files (files I uploaded)*/
SELECT *
	FROM osf_fileversion
	JOIN osf_osfuser
	ON osf_osfuser.id = osf_fileversion.creator_id
	JOIN osf_guid
	ON osf_osfuser.id = osf_guid.object_id
	JOIN osf_basefilenode_versions
	ON osf_fileversion.id = osf_basefilenode_versions.fileversion_id
	JOIN osf_basefilenode
	ON osf_basefilenode.id = osf_basefilenode_versions.basefilenode_id
	WHERE osf_osfuser.username = 'csoderbe@gmail.com' AND osf_guid.content_type_id = 18 AND osf_fileversion._id = '59a6daaeb83f69025d2179ed'
	LIMIT(100);

/* user activity points and last login dates */
SELECT osf_osfuser.id, fullname, username, osf_guid._id AS guid, total AS activity_points, date_registered, date_confirmed, date_last_login
	FROM osf_osfuser
	LEFT JOIN osf_guid
	ON osf_osfuser.id = osf_guid.object_id
	LEFT JOIN osf_useractivitycounter
	ON osf_guid._id = osf_useractivitycounter._id
	WHERE content_type_id = 18 AND is_active IS TRUE


/* How many SSO users, by institution, don't have any valid OSF password? */
SELECT COUNT(osfuser_id) AS users, osf_institution._id
	FROM osf_osfuser_affiliated_institutions
	LEFT JOIN osf_osfuser
	ON osf_osfuser_affiliated_institutions.osfuser_id = osf_osfuser.id
	LEFT JOIN osf_institution
	ON osf_osfuser_affiliated_institutions.institution_id = osf_institution.id
	WHERE is_active = TRUE AND password LIKE '!%'
	GROUP BY osf_institution._id;
