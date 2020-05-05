
/* return email addresses of users who uploaded still public (non-withdrawn, non-deleted) preprints on Marxiv */

SELECT DISTINCT(username)
	FROM osf_preprint
	LEFT JOIN osf_osfuser
	ON osf_preprint.creator_id = osf_osfuser.id
	WHERE provider_id = 27 AND 
			is_published IS TRUE AND 
			(machine_state = 'accepted' OR machine_state = 'pendind') AND 
			ever_public IS TRUE AND 
			is_public IS TRUE AND 
			osf_preprint.deleted IS NULL AND 
			date_withdrawn IS NULL



## counting, for each OSF4I, how many preprints have contritbutors who have SSO, and how many users with SSO are contributors on preprints
WITH users_instit_pps AS (SELECT osfuser_id, institution_id, preprint_id, osf_institution._id AS OSF4I, osf_institution.name
							FROM osf_osfuser_affiliated_institutions
							LEFT JOIN osf_preprintcontributor
							ON osf_osfuser_affiliated_institutions.osfuser_id = osf_preprintcontributor.user_id
							LEFT JOIN osf_preprint
							ON osf_preprintcontributor.preprint_id = osf_preprint.id
							LEFT JOIN osf_institution
							ON osf_osfuser_affiliated_institutions.institution_id = osf_institution.id
							LEFT JOIN osf_osfuser
							ON osf_osfuser_affiliated_institutions.osfuser_id = osf_osfuser.id
							WHERE is_registered = TRUE AND 
									date_confirmed IS NOT NULL AND 
									date_disabled IS NULL AND 
									is_published IS TRUE AND 
									(machine_state = 'accepted' OR machine_state = 'pending') AND 
									ever_public = TRUE AND 
									date_withdrawn IS NULL AND 
									is_public IS TRUE AND 
									osf_preprint.deleted IS NULL)

SELECT distinct on (users_instit_pps.name) users_instit_pps.name, num_users, num_preprints
	FROM users_instit_pps
	LEFT JOIN (SELECT name, COUNT(DISTINCT osfuser_id) AS num_users 
					FROM users_instit_pps 
					GROUP BY name) AS n_users
	ON users_instit_pps.name = n_users.name
	LEFT JOIN (SELECT name, COUNT(DISTINCT preprint_id) AS num_preprints
					FROM users_instit_pps 
					GROUP BY name) AS n_preprints
	ON users_instit_pps.name = n_preprints.name;

## number of preprints submitted by month for a particular service
SELECT COUNT(id) AS submitted_pp, date_trunc('month', date_published) AS date
	FROM osf_preprint
	WHERE provider_id = 5 AND machine_state != 'initial'
	GROUP BY date_trunc('month', date_published)



