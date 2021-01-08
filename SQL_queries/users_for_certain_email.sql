/* getting the users with virginia.edu email addresses associated with their accounts*/

SELECT DISTINCT ON (osf_osfuser.id) * /* call distinct on id to handle schools like UVA that allow people that have multiple email alases*/
	FROM osf_osfuser
	LEFT JOIN (SELECT *
				FROM osf_email WHERE osf_email.address LIKE '%virginia.edu') as uvaers
	ON osf_osfuser.id = uvaers.user_id
	WHERE uvaers.address LIKE '%virginia.edu%' AND 
			is_registered IS TRUE; /* will exclude spam & disabled accounts, but will include merged accounts/secondary emails*/)