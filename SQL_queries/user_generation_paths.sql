/* User Generation Tag Counting */


/* intital query to get info about users with system tags, dates, and SSO */

/* get all non-spam, non-deactived confirmed/not yet confirmed users and their source/claimed tags */
WITH user_tag_info AS (SELECT osf_osfuser.id AS user_id, 
							is_registered, 
							is_invited, 
							date_registered, 
							date_confirmed, 
							date_disabled, 
							osf_tag.name, 
							institution_id,
						CASE WHEN osf_tag.name LIKE 'source%' THEN 'source' WHEN osf_tag.name LIKE 'claimed%' THEN 'claimed' END AS tag_type,
						regexp_replace(osf_tag.name, 'source:|claimed:', '') AS product
						FROM osf_osfuser
						LEFT JOIN osf_osfuser_tags
						ON osf_osfuser.id = osf_osfuser_tags.osfuser_id
						LEFT JOIN osf_tag
						ON osf_osfuser_tags.tag_id = osf_tag.id
						LEFT JOIN osf_osfuser_affiliated_institutions
						ON osf_osfuser.id = osf_osfuser_affiliated_institutions.osfuser_id
						WHERE osf_osfuser.date_disabled IS NULL AND
							(osf_osfuser.spam_status IS NULL OR osf_osfuser.spam_status = 4 OR osf_osfuser.spam_status = 1) AND 
							osf_tag.system IS TRUE AND 
							(osf_tag.name LIKE 'source%' OR osf_tag.name LIKE 'claimed%')),

	/* count up, by month, new direct sign-ups by source provider */
	 new_signups AS (SELECT COUNT(user_id) AS new_signups, 
	 						COUNT(CASE WHEN institution_id IS NOT NULL THEN 1 END) AS sso_newsignups, 
	 						date_trunc('month', date_confirmed) as month, product
						FROM user_tag_info
						WHERE is_registered IS TRUE AND is_invited IS FALSE AND tag_type = 'source' AND
								date_confirmed < '2020-07-01'
						GROUP BY product, date_trunc('month', date_confirmed)),
	 
	 /* count up number of invited users by source provider (overall, not by month, since we don't have time of tag creation and an unconfirmed user could be added to multiple products across a number of months*/
	 new_invites AS (SELECT COUNT(user_id) AS new_invitees, product
 						FROM user_tag_info
 						WHERE is_invited IS TRUE AND tag_type = 'source'
 						GROUP BY product),

	 /* count up, by month, new invited users who have claimed their account by source provider, based on when they claimed */
  	 new_claims AS (SELECT COUNT(user_id) AS new_claims,
	 					   COUNT(CASE WHEN institution_id IS NOT NULL THEN 1 END) AS sso_newclaims, 
	 					   date_trunc('month', date_confirmed) as month, product
	 				FROM user_tag_info
	 				WHERE is_invited IS TRUE AND date_confirmed IS NOT NULL AND
	 						date_confirmed < '2020-07-01' AND tag_type = 'claimed'
	 				GROUP BY product, date_trunc('month', date_confirmed))

/* combine all queries together to get one datafile with all information*/
SELECT new_signups, new_claims, new_invitees, sso_newsignups, sso_newclaims, new_signups.name, new_signups.month
	FROM new_signups
	FULL JOIN new_claims
	ON new_signups.product = new_claims.product AND new_signups.month = new_claims.month
	FULL JOIN new_invites
	ON new_signups.product = new_invites.product;
	

