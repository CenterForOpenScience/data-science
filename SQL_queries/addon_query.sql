/* count of the number of top level projects that have each addon connected fully and overall number of projects with at least one storage addon */

WITH addons_per_rootid AS (SELECT root_id, 
		COUNT(osf_abstractnode.id) filter (where bitbucket_repo IS NOT NULL) AS has_bitbucket,
		COUNT(osf_abstractnode.id) filter (where S3_folder IS NOT NULL) AS has_S3,
		COUNT(osf_abstractnode.id) filter (where box_folder IS NOT NULL) AS has_box,
		COUNT(osf_abstractnode.id) filter (where github_repo IS NOT NULL) AS has_github,
		COUNT(osf_abstractnode.id) filter (where gitlab_repo IS NOT NULL) AS has_gitlab,
		COUNT(osf_abstractnode.id) filter (where zotero_list IS NOT NULL) AS has_zotero,
		COUNT(osf_abstractnode.id) filter (where dropbox_folder IS NOT NULL) AS has_dropbox,
		COUNT(osf_abstractnode.id) filter (where figshare_folder IS NOT NULL) AS has_figshare,
		COUNT(osf_abstractnode.id) filter (where mendeley_list IS NOT NULL) AS has_mendeley,
		COUNT(osf_abstractnode.id) filter (where onedrive_folder IS NOT NULL) AS has_onedrive,
		COUNT(osf_abstractnode.id) filter (where owncloud_folder IS NOT NULL) AS has_owncloud,
		COUNT(osf_abstractnode.id) filter (where dataverse_dataset IS NOT NULL) AS has_dataverse,
		COUNT(osf_abstractnode.id) filter (where google_folder IS NOT NULL) AS has_google
	FROM osf_abstractnode
	LEFT JOIN (SELECT owner_id, repo AS bitbucket_repo
					FROM addons_bitbucket_nodesettings
					WHERE is_deleted IS FALSE and repo IS NOT NULL) AS bitbucket
	ON osf_abstractnode.id = bitbucket.owner_id
	LEFT JOIN (SELECT owner_id, folder_id AS S3_folder
					FROM addons_s3_nodesettings
					WHERE is_deleted IS FALSE AND folder_id IS NOT NULL) AS s3
	ON osf_abstractnode.id = s3.owner_id
	LEFT JOIN (SELECT owner_id, folder_name AS box_folder
					FROM addons_box_nodesettings
					WHERE is_deleted IS FALSE AND folder_name IS NOT NULL) AS box
	ON osf_abstractnode.id = box.owner_id
	LEFT JOIN (SELECT owner_id, repo AS github_repo
					FROM addons_github_nodesettings
					WHERE is_deleted IS FALSE AND repo IS NOT NULL) AS github
	ON osf_abstractnode.id = github.owner_id
	LEFT JOIN (SELECT owner_id, repo AS gitlab_repo
					FROM addons_gitlab_nodesettings
					WHERE is_deleted IS FALSE AND repo IS NOT NULL) AS gitlab
	ON osf_abstractnode.id = gitlab.owner_id
	LEFT JOIN (SELECT owner_id, list_id AS zotero_list
					FROM addons_zotero_nodesettings
					WHERE is_deleted IS FALSE AND list_id IS NOT NULL) AS zotero
	ON osf_abstractnode.id = zotero.owner_id
	LEFT JOIN (SELECT owner_id, folder AS dropbox_folder
					FROM addons_dropbox_nodesettings
					WHERE is_deleted IS FALSE AND folder IS NOT NULL) AS dropbox
	ON osf_abstractnode.id = dropbox.owner_id
	LEFT JOIN (SELECT owner_id, folder_id AS figshare_folder
					FROM addons_figshare_nodesettings
					WHERE is_deleted IS FALSE AND folder_id IS NOT NULL) AS figshare
	ON osf_abstractnode.id = figshare.owner_id
	LEFT JOIN (SELECT owner_id, list_id AS mendeley_list
					FROM addons_mendeley_nodesettings
					WHERE is_deleted IS FALSE AND list_id IS NOT NULL) AS mendeley
	ON osf_abstractnode.id = mendeley.owner_id
	LEFT JOIN (SELECT owner_id, folder_id AS onedrive_folder
					FROM addons_onedrive_nodesettings
					WHERE is_deleted IS FALSE AND folder_id IS NOT NULL) AS onedrive
	ON osf_abstractnode.id = onedrive.owner_id
	LEFT JOIN (SELECT owner_id, folder_id AS owncloud_folder
					FROM addons_owncloud_nodesettings
					WHERE is_deleted IS FALSE AND folder_id IS NOT NULL) AS owncloud
	ON osf_abstractnode.id = owncloud.owner_id
	LEFT JOIN (SELECT owner_id, dataset AS dataverse_dataset
					FROM addons_dataverse_nodesettings
					WHERE is_deleted IS FALSE AND dataset IS NOT NULL) AS dataverse
	ON osf_abstractnode.id = dataverse.owner_id
	LEFT JOIN (SELECT owner_id, folder_id AS google_folder
					FROM addons_googledrive_nodesettings
					WHERE is_deleted IS FALSE AND folder_id IS NOT NULL) AS google
	ON osf_abstractnode.id = google.owner_id
	WHERE osf_abstractnode.type = 'osf.node' AND osf_abstractnode.is_deleted IS FALSE AND (spam_status IS NULL OR spam_status = 4)
	GROUP BY root_id)


SELECT 
	COUNT(CASE WHEN has_bitbucket > 0 THEN root_id END) as bitbucket,
	COUNT(CASE WHEN has_S3 > 0 THEN root_id END) as S3,
	COUNT(CASE WHEN has_box > 0 THEN root_id END) as box,
	COUNT(CASE WHEN has_github > 0 THEN root_id END) as github,
	COUNT(CASE WHEN has_gitlab > 0 THEN root_id END) as gitlab,
	COUNT(CASE WHEN has_zotero > 0 THEN root_id END) as zotero,
	COUNT(CASE WHEN has_dropbox > 0 THEN root_id END) as dropbox,
	COUNT(CASE WHEN has_figshare > 0 THEN root_id END) as figshare,
	COUNT(CASE WHEN has_mendeley > 0 THEN root_id END) as mendeley,
	COUNT(CASE WHEN has_onedrive > 0 THEN root_id END) as onedrive,
	COUNT(CASE WHEN has_owncloud > 0 THEN root_id END) as owncloud,
	COUNT(CASE WHEN has_dataverse > 0 THEN root_id END) as dataverse,
	COUNT(CASE WHEN has_google > 0 THEN root_id END) as google,
	COUNT(CASE WHEN has_bitbucket > 0 OR has_S3 > 0 OR has_box > 0 OR has_github > 0 OR has_gitlab > 0 OR
					has_dropbox > 0 OR has_figshare > 0 OR
					has_onedrive > 0 OR has_owncloud > 0 OR has_dataverse > 0 OR has_google > 0 THEN root_id END) AS any_storage_addons
	FROM addons_per_rootid