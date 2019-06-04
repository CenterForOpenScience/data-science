/* nodes and their wiki content */
SELECT osf_abstractnode.id, root_id, osf_abstractnode.title, description, osf_abstractnode.is_deleted, is_public,
		osf_abstractnode.created AS node_created, osf_abstractnode.modified AS node_modified, type, content AS wiki_content,
		addons_wiki_wikipage.page_name AS wiki_name
	FROM osf_abstractnode
	LEFT JOIN addons_wiki_wikipage
	ON osf_abstractnode.id = addons_wiki_wikipage.node_id
	LEFT JOIN addons_wiki_wikiversion
	ON addons_wiki_wikipage.id = addons_wiki_wikiversion.wiki_page_id
	WHERE (spam_status = 4 OR spam_status IS NULL) and (type LIKE 'osf.node' OR type LIKE 'osf.registration');


/* collect project files and file tags */
SELECT osf_abstractnode.id AS node_id, root_id, osf_abstractnode.is_deleted, is_public,
		osf_abstractnode.created AS node_created, osf_abstractnode.modified AS node_modified, 
		osf_abstractnode.type, osf_basefilenode.id AS file_id, osf_basefilenode.name AS file_name, 
		osf_basefilenode.created AS file_created, osf_basefilenode.type AS file_type,
		deleted_on, osf_tag.name AS tag_name, osf_tag.created AS tag_created
	FROM osf_abstractnode
	LEFT JOIN osf_basefilenode
	ON osf_abstractnode.id = osf_basefilenode.target_object_id
	LEFT JOIN osf_basefilenode_tags
	ON osf_basefilenode.id = osf_basefilenode_tags.basefilenode_id
	LEFT JOIN osf_tag
	ON osf_basefilenode_tags.tag_id = osf_tag.id
	WHERE target_content_type_id = 30 and (spam_status = 4 OR spam_status IS NULL) and (osf_abstractnode.type LIKE 'osf.node' OR osf_abstractnode.type LIKE 'osf.registration');

/* collecting project tags */
SELECT osf_abstractnode.id, root_id, type, osf_abstractnode.is_public, osf_abstractnode.is_deleted, osf_tag.name AS tag_name
	FROM osf_abstractnode
	LEFT JOIN osf_abstractnode_tags
	ON osf_abstractnode.id = osf_abstractnode_tags.abstractnode_id
	LEFT JOIN osf_tag
	ON osf_abstractnode_tags.tag_id = osf_tag.id
	WHERE (spam_status = 4 OR spam_status IS NULL) and (type LIKE 'osf.node' OR type LIKE 'osf.registration');

/* nodes and contributor information, excluding spam and bookmarks */
SELECT osf_abstractnode.id, root_id, type, fullname, username, is_invited, osf_osfuser.date_confirmed AS user_confirmed, jobs, schools, social, osf_osfuser.id AS user_id
	FROM osf_abstractnode
	LEFT JOIN osf_contributor
	ON osf_abstractnode.id = osf_contributor.node_id
	LEFT JOIN osf_osfuser
	ON osf_contributor.user_id = osf_osfuser.id
	WHERE is_active IS TRUE AND title NOT LIKE 'Bookmarks' and (spam_status = 4 OR spam_status IS NULL);
