/* getting currently active add-on folders, which we have to assume have files in them b/c add-on files only show up in the basefilenode table if the API has touched them 
(if I connect a dropbox file then don't open any of the files, they won't show up in the basefilenode table) */

WITH pp_contrib AS (SELECT user_id, COUNT(preprint_id) AS number_pp, MIN(created) AS first_preprint, MAX(created) AS last_preprint
						FROM osf_preprintcontributor
						LEFT JOIN osf_preprint pp
						ON osf_preprintcontributor.preprint_id = pp.id
						WHERE pp.is_published = 'TRUE' AND (pp.machine_state = 'pending' OR pp.machine_state = 'accepted') AND 
					    pp.is_public = 'TRUE' AND primary_file_id IS NOT NULL AND pp.deleted IS NULL
					    GROUP BY user_id),
	  node_contrib AS (SELECT osf_contributor.node_id, user_id, type, nodes.node_created AS node_created, is_public, registered_date, embargo_id, registered_from_id, root_id, date_retracted
	 					FROM osf_contributor
	 					LEFT JOIN (SELECT osf_abstractnode.id AS node_id, osf_abstractnode.created AS node_created, *
	 									FROM osf_abstractnode
	 									LEFT JOIN osf_retraction
										ON osf_abstractnode.retraction_id = osf_retraction.id
										WHERE is_deleted IS FALSE AND (spam_status = 4 OR spam_status IS NULL) AND ((type LIKE '%quickfile%') OR (type LIKE 'osf.node') OR (type LIKE 'osf.registration' AND date_retracted IS NULL AND (is_public IS TRUE OR embargo_id IS NOT NULL)))) nodes
						ON osf_contributor.node_id = nodes.node_id),
	  existing_files AS (SELECT COUNT(*) AS num_files, target_object_id, MIN(created) AS first_osf_file_created, MAX(created) AS last_osf_file_created
						FROM osf_basefilenode
						WHERE type NOT LIKE '%folder%' AND provider LIKE 'osfstorage' AND osf_basefilenode.deleted_on IS NULL AND osf_basefilenode.target_content_type_id = 30
						GROUP BY target_object_id),
	  addon_connections AS (SELECT node_contrib.is_public, node_contrib.embargo_id, node_contrib.type, node_contrib.node_id, node_contrib.root_id, node_contrib.user_id, node_contrib.node_created, node_contrib.registered_date, node_contrib.registered_from_id, bitbucket.repo 											AS bitbucket_repo, bitbucket.created AS bitbucket_created, bitbucket.modified AS bitbucket_modified, 
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
						FROM node_contrib
						LEFT JOIN (SELECT created, modified, owner_id, repo
										FROM addons_bitbucket_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) bitbucket
						ON node_contrib.node_id = bitbucket.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_box_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) box
						ON node_contrib.node_id = box.owner_id
						LEFT JOIN (SELECT dataverse, dataset, created, modified, owner_id
										FROM addons_dataverse_nodesettings
										WHERE deleted IS FALSE AND dataset IS NOT NULL) dataverse
						ON node_contrib.node_id = dataverse.owner_id
						LEFT JOIN (SELECT folder, owner_id, created, modified
										FROM addons_dropbox_nodesettings
										WHERE deleted IS FALSE AND folder IS NOT NULL) dropbox
						ON node_contrib.node_id = dropbox.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_figshare_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) figshare
						ON node_contrib.node_id = figshare.owner_id
						LEFT JOIN (SELECT repo, owner_id, created, modified
										FROM addons_github_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) github
						ON node_contrib.node_id = github.owner_id
						LEFT JOIN (SELECT repo, owner_id, created, modified
										FROM addons_gitlab_nodesettings
										WHERE deleted IS FALSE AND repo IS NOT NULL) gitlab
						ON node_contrib.node_id = gitlab.owner_id
						LEFT JOIN (SELECT folder_path, owner_id, created, modified
										FROM addons_googledrive_nodesettings
										WHERE deleted IS FALSE AND folder_path IS NOT NULL) googledrive
						ON node_contrib.node_id = googledrive.owner_id
						LEFT JOIN (SELECT folder_path, owner_id, created, modified
										FROM addons_onedrive_nodesettings
										WHERE deleted IS FALSE AND folder_path IS NOT NULL) onedrive
						ON node_contrib.node_id = onedrive.owner_id
						LEFT JOIN (SELECT folder_id, owner_id, created, modified
										FROM addons_owncloud_nodesettings
										WHERE deleted IS FALSE AND folder_id IS NOT NULL) owncloud
						ON node_contrib.node_id = owncloud.owner_id
						LEFT JOIN (SELECT folder_name, owner_id, created, modified
										FROM addons_s3_nodesettings
										WHERE deleted IS FALSE AND folder_name IS NOT NULL) s3
						ON node_contrib.node_id = s3.owner_id),
	    files_on_nodes AS (SELECT node_id, user_id, type, node_created, is_public, registered_date, embargo_id, registered_from_id, root_id, COALESCE(num_files, 0) AS num_files, first_osf_file_created, last_osf_file_created,
	    						(SELECT count(*) from (values (bitbucket_repo), (box_folder), (dataverse_dataset), (dropbox_folder), (figshare_folder), (github_repo), (gitlab_repo), (googledrive_folderpath), (onedrive_folderpath), (owncloud_folderid), (s3_foldername)) as 									v(col) WHERE v.col is not null) AS addons_on_node
						FROM addon_connections
						LEFT JOIN existing_files
						ON addon_connections.node_id = existing_files.target_object_id),					
		eligible_node_contribs AS (SELECT user_id, COUNT(DISTINCT root_id) FILTER (WHERE type LIKE 'osf.node' AND is_public IS TRUE AND (num_files >0 OR addons_on_node > 0)) AS eligible_nodes, COUNT(DISTINCT root_id) FILTER (WHERE type LIKE 'osf.registration') AS 						eligible_regs, MIN(node_created) FILTER (WHERE type LIKE 'osf.node' AND is_public IS TRUE AND (num_files >0 OR addons_on_node > 0)) AS first_node, MAX(node_created) FILTER (WHERE type LIKE 'osf.node' AND is_public IS TRUE AND (num_files >0 OR 						addons_on_node > 0)) AS last_node, MIN(registered_date) FILTER (WHERE type LIKE 'osf.registration') AS first_registration, MAX(registered_date) FILTER (WHERE type LIKE 'osf.registration') AS last_registration,
						COUNT(DISTINCT root_id) FILTER (WHERE type LIKE 'osf.node' AND is_public IS FALSE AND (num_files >0 OR addons_on_node > 0)) AS private_file_nodes, COUNT(DISTINCT root_id) FILTER (WHERE type LIKE '%quickfile%' AND num_files > 0) AS has_quickfiles 
						FROM files_on_nodes
						GROUP BY user_id),
		all_contribs AS (SELECT COALESCE(eligible_node_contribs.user_id, pp_contrib.user_id) AS user_id, COALESCE(eligible_nodes, 0) AS number_public_file_nodes, COALESCE(eligible_regs, 0) AS number_regs, first_node, last_node, first_registration, 														last_registration, COALESCE(number_pp, 0) AS number_pp, first_preprint,last_preprint, COALESCE(private_file_nodes, 0) AS number_private_file_nodes, COALESCE(has_quickfiles, 0) AS quickfile_node
						FROM eligible_node_contribs
						FULL OUTER JOIN pp_contrib
						ON eligible_node_contribs.user_id = pp_contrib.user_id)

SELECT * 
	FROM all_contribs
	LEFT JOIN osf_osfuser
	ON all_contribs.user_id = osf_osfuser.id;