/* Projects that exhibit multiple OSF product usages (OSF file sharing, registrations, preprints) */


/* How many non-deleted, not spam or flaggest as spam, top-level projects, excluding registrations, have at least 1 public component that has a file (e.g. are doing some sort of file sharing behavior)
Doesn't include linked components [DOES NOT INCLUDE LINKED PROJECTS/COMPONENTS] */
WITH existing_files AS (SELECT COUNT(*) AS num_files, target_object_id, MIN(created) AS first_osf_file_created, MAX(created) AS last_osf_file_created
						FROM osf_basefilenode
						WHERE type NOT LIKE '%folder%' AND provider LIKE 'osfstorage' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30
						GROUP BY target_object_id),
	addon_connections AS (SELECT is_public, is_deleted, spam_status, type, osf_abstractnode.id, root_id, osf_abstractnode.created AS node_created, 
											  bitbucket.repo AS bitbucket_repo, bitbucket.created AS bitbucket_created, bitbucket.modified AS bitbucket_modified, 
											  box.folder_name AS box_folder, box.created AS box_created, box.modified AS box_modified,
											  dataverse.dataset AS dataverse_dataset, dataverse.created AS dataverse_created, dataverse.modified AS dataverse_modified,
											  dropbox.folder AS dropbox_folder, dropbox.created AS dropbox_created, dropbox.modified AS dropbox_modified,
											  figshare.folder_name AS figshare_folder, figshare.created AS figshare_created, figshare.modified AS figshare_modified,
											  github.repo AS github_repo, github.created AS github_created, github.modified AS github_modified,
											  gitlab.repo AS gitlab_repo, gitlab.created AS gitlab_created, gitlab.modified AS gitlab_modified,
											  googledrive.folder_path AS googledrive_folderpath, googledrive.created AS googledrive_created, googledrive.modified AS googledrive_modified,
											  onedrive.folder_path AS onedrive_folderpath, onedrive.created AS onedrive_created, onedrive.modified AS onedrive_modified,
											  owncloud.folder_id AS owncloud_folderid, owncloud.created AS owncloud_created, owncloud.modified AS owncloud_modified,
											  s3.folder_name AS s3_foldername, s3.created AS s3_created, s3.modified AS s3_modified
						FROM osf_abstractnode
						LEFT JOIN (SELECT created, modified, owner_id, repo
										FROM addons_bitbucket_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) bitbucket
						ON osf_abstractnode.id = bitbucket.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_box_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) box
						ON osf_abstractnode.id = box.owner_id
						LEFT JOIN (SELECT dataverse, dataset, created, modified, owner_id
										FROM addons_dataverse_nodesettings
										WHERE deleted IS FALSE AND dataset IS NOT NULL) dataverse
						ON osf_abstractnode.id = dataverse.owner_id
						LEFT JOIN (SELECT folder, owner_id, created, modified
										FROM addons_dropbox_nodesettings
										WHERE deleted IS FALSE AND folder IS NOT NULL) dropbox
						ON osf_abstractnode.id = dropbox.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_figshare_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) figshare
						ON osf_abstractnode.id = figshare.owner_id
						LEFT JOIN (SELECT repo, owner_id, created, modified
										FROM addons_github_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) github
						ON osf_abstractnode.id = github.owner_id
						LEFT JOIN (SELECT repo, owner_id, created, modified
										FROM addons_gitlab_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) gitlab
						ON osf_abstractnode.id = gitlab.owner_id
						LEFT JOIN (SELECT folder_path, owner_id, created, modified
										FROM addons_googledrive_nodesettings
										WHERE deleted IS FALSE AND folder_path IS NOT NULL) googledrive
						ON osf_abstractnode.id = googledrive.owner_id
						LEFT JOIN (SELECT folder_path, owner_id, created, modified
										FROM addons_onedrive_nodesettings
										WHERE deleted IS FALSE AND folder_path IS NOT NULL) onedrive
						ON osf_abstractnode.id = onedrive.owner_id
						LEFT JOIN (SELECT folder_id, owner_id, created, modified
										FROM addons_owncloud_nodesettings
										WHERE deleted IS FALSE AND folder_id IS NOT NULL) owncloud
						ON osf_abstractnode.id = owncloud.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_s3_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) s3
						ON osf_abstractnode.id = s3.owner_id),
	    files_on_nodes AS (SELECT id, node_created, is_public, root_id, COALESCE(num_files, 0) AS number_files, first_osf_file_created, last_osf_file_created,
	    						(SELECT count(*) from (values (bitbucket_repo), (box_folder), (dataverse_dataset), (dropbox_folder), (figshare_folder), (github_repo), (gitlab_repo), (googledrive_folderpath), (onedrive_folderpath), (owncloud_folderid), (s3_foldername)) as v(col) WHERE v.col is not null) AS addons_on_node
						FROM addon_connections
						LEFT JOIN existing_files
						ON addon_connections.id = existing_files.target_object_id
						WHERE type LIKE 'osf.node' AND is_deleted IS FALSE AND (spam_status = 4 OR spam_status IS NULL))

Select COUNT(DISTINCT root_id) AS sharing_projects
	FROM files_on_nodes
	WHERE (number_files > 0 OR addons_on_node > 0) AND is_public IS TRUE;





/* How many non-deleted, not spam or flagged as spam, top-level projects have a currently active registration (not deleted, not withdrawn, not old private) or have a registration on at least one of their components. [DOES NOT INCLUDE LINKED PORJECTS/COMPONENTS] */
WITH registered_projects AS (SELECT DISTINCT ON (osf_abstractnode.root_id) osf_abstractnode.id, type, registered_date, root_id, is_public, is_deleted, date_retracted, embargo_id, osf_embargo.state, registered_from_id
								FROM osf_abstractnode
								LEFT JOIN osf_retraction
								ON osf_abstractnode.retraction_id = osf_retraction.id
								LEFT JOIN osf_embargo
								ON osf_abstractnode.embargo_id = osf_embargo.id
								WHERE type LIKE 'osf.registration' AND is_deleted IS FALSE AND (spam_status = 4 OR spam_status IS NULL) AND date_retracted IS NULL AND (is_public IS TRUE OR embargo_id IS NOT NULL)),
	nodes_with_registrations AS (SELECT osf_abstractnode.root_id, osf_abstractnode.id AS node_id, osf_abstractnode.created AS node_created, registered_projects.registered_date AS registration_date
										FROM osf_abstractnode
										FULL OUTER JOIN registered_projects
										ON osf_abstractnode.id = registered_projects.registered_from_id
										WHERE osf_abstractnode.type LIKE 'osf.node' AND osf_abstractnode.is_deleted IS FALSE AND (osf_abstractnode.spam_status = 4 OR osf_abstractnode.spam_status IS NULL))

SELECT COUNT(DISTINCT root_id)
	FROM nodes_with_registrations
	WHERE registration_date IS NOT NULL;



/* How many non-deleted, not spam or flagged as spam, top-level projects have a currently active registration (not deleted, not withdrawn, not old private) 
or have registrations on one of their components and also have at least 1 copmonent that is public and has a file [DOES NOT INCLUDE LINKED PROJECTS/COMPONENTS] */
WITH existing_files AS (SELECT COUNT(*) AS num_files, target_object_id, MIN(created) AS first_osf_file_created, MAX(created) AS last_osf_file_created
						FROM osf_basefilenode
						WHERE type NOT LIKE '%folder%' AND provider LIKE 'osfstorage' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30
						GROUP BY target_object_id),
	addon_connections AS (SELECT is_public, is_deleted, spam_status, type, osf_abstractnode.id, root_id, osf_abstractnode.created AS node_created, 
											  bitbucket.repo AS bitbucket_repo, bitbucket.created AS bitbucket_created, bitbucket.modified AS bitbucket_modified, 
											  box.folder_name AS box_folder, box.created AS box_created, box.modified AS box_modified,
											  dataverse.dataset AS dataverse_dataset, dataverse.created AS dataverse_created, dataverse.modified AS dataverse_modified,
											  dropbox.folder AS dropbox_folder, dropbox.created AS dropbox_created, dropbox.modified AS dropbox_modified,
											  figshare.folder_name AS figshare_folder, figshare.created AS figshare_created, figshare.modified AS figshare_modified,
											  github.repo AS github_repo, github.created AS github_created, github.modified AS github_modified,
											  gitlab.repo AS gitlab_repo, gitlab.created AS gitlab_created, gitlab.modified AS gitlab_modified,
											  googledrive.folder_path AS googledrive_folderpath, googledrive.created AS googledrive_created, googledrive.modified AS googledrive_modified,
											  onedrive.folder_path AS onedrive_folderpath, onedrive.created AS onedrive_created, onedrive.modified AS onedrive_modified,
											  owncloud.folder_id AS owncloud_folderid, owncloud.created AS owncloud_created, owncloud.modified AS owncloud_modified,
											  s3.folder_name AS s3_foldername, s3.created AS s3_created, s3.modified AS s3_modified
						FROM osf_abstractnode
						LEFT JOIN (SELECT created, modified, owner_id, repo
										FROM addons_bitbucket_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) bitbucket
						ON osf_abstractnode.id = bitbucket.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_box_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) box
						ON osf_abstractnode.id = box.owner_id
						LEFT JOIN (SELECT dataverse, dataset, created, modified, owner_id
										FROM addons_dataverse_nodesettings
										WHERE deleted IS FALSE AND dataset IS NOT NULL) dataverse
						ON osf_abstractnode.id = dataverse.owner_id
						LEFT JOIN (SELECT folder, owner_id, created, modified
										FROM addons_dropbox_nodesettings
										WHERE deleted IS FALSE AND folder IS NOT NULL) dropbox
						ON osf_abstractnode.id = dropbox.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_figshare_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) figshare
						ON osf_abstractnode.id = figshare.owner_id
						LEFT JOIN (SELECT repo, owner_id, created, modified
										FROM addons_github_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) github
						ON osf_abstractnode.id = github.owner_id
						LEFT JOIN (SELECT repo, owner_id, created, modified
										FROM addons_gitlab_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) gitlab
						ON osf_abstractnode.id = gitlab.owner_id
						LEFT JOIN (SELECT folder_path, owner_id, created, modified
										FROM addons_googledrive_nodesettings
										WHERE deleted IS FALSE AND folder_path IS NOT NULL) googledrive
						ON osf_abstractnode.id = googledrive.owner_id
						LEFT JOIN (SELECT folder_path, owner_id, created, modified
										FROM addons_onedrive_nodesettings
										WHERE deleted IS FALSE AND folder_path IS NOT NULL) onedrive
						ON osf_abstractnode.id = onedrive.owner_id
						LEFT JOIN (SELECT folder_id, owner_id, created, modified
										FROM addons_owncloud_nodesettings
										WHERE deleted IS FALSE AND folder_id IS NOT NULL) owncloud
						ON osf_abstractnode.id = owncloud.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_s3_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) s3
						ON osf_abstractnode.id = s3.owner_id),
	registered_projects AS (SELECT DISTINCT ON (osf_abstractnode.root_id) osf_abstractnode.id, type, registered_date, root_id, is_public, is_deleted, date_retracted, embargo_id, osf_embargo.state, registered_from_id
													FROM osf_abstractnode
													LEFT JOIN osf_retraction
													ON osf_abstractnode.retraction_id = osf_retraction.id
													LEFT JOIN osf_embargo
													ON osf_abstractnode.embargo_id = osf_embargo.id
													WHERE type LIKE 'osf.registration' AND is_deleted IS FALSE AND (spam_status = 4 OR spam_status IS NULL) AND date_retracted IS NULL AND (is_public IS TRUE OR embargo_id IS NOT NULL)),
	 files_and_registrations AS (SELECT addon_connections.id AS node_id, addon_connections.root_id, COALESCE(num_files, 0) AS number_files, addon_connections.is_public, node_created, registered_projects.registered_date AS registration_date, first_osf_file_created, last_osf_file_created,
	    						(SELECT count(*) from (values (bitbucket_repo), (box_folder), (dataverse_dataset), (dropbox_folder), (figshare_folder), (github_repo), (gitlab_repo), (googledrive_folderpath), (onedrive_folderpath), (owncloud_folderid), (s3_foldername)) as v(col) WHERE v.col is not null) AS addons_on_node
						FROM addon_connections
						LEFT JOIN existing_files
						ON addon_connections.id = existing_files.target_object_id
						LEFT JOIN registered_projects
						ON addon_connections.id = registered_projects.registered_from_id
						WHERE addon_connections.type LIKE 'osf.node' AND addon_connections.is_deleted IS FALSE AND (addon_connections.spam_status = 4 OR addon_connections.spam_status IS NULL))

Select root_id, MIN(first_osf_file_created) AS first_osffile_created, MAX(last_osf_file_created) AS last_osffile_created, MIN(registration_date) AS first_registration, MAX(registration_date) AS last_registration
	FROM files_and_registrations
	WHERE (number_files > 0 OR addons_on_node > 0) AND is_public IS TRUE
	GROUP BY (root_id);
	






- need to alter the part below to deal with supp_nodes that might be at the component level and have files shared a level down from the supp_node level itself

/* How many non-deleted, non-spam or flagged spam, top-level porjects have a node that is a supplemental node for a published preprint that have public files in it */
/* return all public preprints with their GUIDs, DOIs, and supplement GUID as well as the number of non-deleted files on the supplemental node and the date the first file was added*/
WITH supp_nodes AS (SELECT DISTINCT(node_id) supp_node_id, osf_abstractnode.root_id
						FROM osf_preprint pp
						LEFT JOIN osf_abstractnode
						ON pp.node_id = osf_abstractnode.root_id
						WHERE pp.node_id IS NOT NULL AND osf_abstractnode.is_deleted IS FALSE AND (osf_abstractnode.spam_status = 4 OR osf_abstractnode.spam_status IS NULL) AND osf_abstractnode.is_public IS TRUE AND 
								pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND pp.is_public = 'TRUE' AND primary_file_id IS NOT NULL AND pp.deleted IS NULL),
	 files_on_supp_nodes AS (SELECT supp_node_id, COUNT(node_files.id) number_files, MIN(created) first_file_added, MAX(created) last_file_added
	 						FROM supp_nodes
	 						LEFT JOIN (SELECT * FROM osf_basefilenode WHERE osf_basefilenode.type NOT LIKE '%folder%' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30) AS node_files
	 						ON supp_nodes.supp_node_id = node_files.target_object_id
	 						GROUP BY supp_node_id)
	 supp_node_info AS (SELECT *
	 						FROM )

SELECT pp.id, pp.created, pp.modified, date_published, license_id, pp.node_id, provider_id, original_publication_date, article_doi, osf_guid._id AS preprint_guid, supplement_guid, value AS preprint_doi, osf_abstractprovider._id AS provider,
			number_files, first_file_added
	FROM osf_preprint pp
	JOIN osf_abstractprovider
	ON pp.provider_id = osf_abstractprovider.id
	FULL OUTER JOIN supp_node_files
	ON pp.node_id = supp_node_files.supp_node_id
	WHERE pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND osf_guid.content_type_id = 47 AND pp.is_public = 'TRUE' AND primary_file_id IS NOT NULL AND pp.deleted IS NULL;








/* How many non-deleted, not spam or flagged as spam, top-level projects, excluding registrations, have at least 1 public component with a file and have at least 1 component that has a currently active registraion */

