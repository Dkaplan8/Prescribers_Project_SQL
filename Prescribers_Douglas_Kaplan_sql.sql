-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 1;

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
USING(npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
	OR long_acting_opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;

--     c. Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT DISTINCT specialty_description
FROM prescriber
WHERE specialty_description NOT IN (
	SELECT specialty_description
	FROM prescriber
	INNER JOIN prescription
	USING(npi)
);

--     d. For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT
	specialty_description,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) as opioid_claims,
	SUM(total_claim_count) AS total_claims,
	SUM(
		CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count
		ELSE 0
	END
	) * 100.0 /  SUM(total_claim_count) AS opioid_percentage
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
GROUP BY specialty_description
ORDER BY opioid_percentage DESC;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS total_cost
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC;

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT 
	generic_name, 
	SUM(total_drug_cost) / SUM(total_day_supply) AS total_cost_per_day
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost_per_day DESC;

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT 
	drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type,
	SUM(total_drug_cost)::MONEY AS total_cost
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY drug_type;


-- 5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(*)
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN';

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(population) AS total_population
FROM cbsa 
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_population DESC;

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, population
FROM fips_county
INNER JOIN population
USING(fipscounty)
WHERE fipscounty NOT IN (
	SELECT fipscounty
	FROM cbsa
)
ORDER BY population DESC;

-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY opioid_drug_flag, drug_name;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	drug_name, 
	total_claim_count, 
	opioid_drug_flag
FROM prescription
INNER JOIN drug
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000
ORDER BY opioid_drug_flag, drug_name;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. 

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT npi, drug_name, total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND opioid_drug_flag = 'Y';
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT npi, drug_name, COALESCE(total_claim_count, 0)
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND opioid_drug_flag = 'Y';

-- 8. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(*)
FROM 
(
	(SELECT npi
	 FROM prescriber)
	 EXCEPT
	 (SELECT npi
	 FROM prescription)
) AS sub;

-- 9. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) as total_claims
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

--	b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY sum(total_claim_count) DESC
LIMIT 5

-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

(SELECT generic_name
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY sum(total_claim_count) DESC
LIMIT 5
)
INTERSECT
(
SELECT generic_name
FROM drug
INNER JOIN prescription
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY sum(total_claim_count) DESC
LIMIT 5);
	
-- 10. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee. a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT npi, sum(total_claim_count) as total_claims, nppes_provider_city
FROM prescriber 
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5 

-- b. Now, report the same for Memphis.

SELECT npi, sum(total_claim_count) as total_claims, nppes_provider_city
FROM prescriber 
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5
	
-- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

(SELECT npi, sum(total_claim_count) as total_claims, nppes_provider_city
	FROM prescriber 
	INNER JOIN prescription
	USING (npi)
	WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5)
UNION
	(SELECT npi, sum(total_claim_count) as total_claims, nppes_provider_city
	FROM prescriber 
	INNER JOIN prescription
	USING (npi)
	WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5)
UNION
	(SELECT npi, sum(total_claim_count) as total_claims, nppes_provider_city
	FROM prescriber 
	INNER JOIN prescription
	USING (npi)
	WHERE nppes_provider_city = 'KNOXVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5)
UNION
	(SELECT npi, sum(total_claim_count) as total_claims, nppes_provider_city
	FROM prescriber 
	INNER JOIN prescription
	USING (npi)
	WHERE nppes_provider_city = 'Chattanooga'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5)

-- 10. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT county, overdose_deaths
FROM overdose_deaths
INNER JOIN fips_county
USING (fipscounty)
WHERE year = 2017 AND overdose_deaths > (SELECT AVG (overdose_deaths) FROM overdose_deaths WHERE year = 2017);

-- 11. Write a query that finds the total population of Tennessee.

SELECT sum(population) 
FROM population;

-- b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT county, population, ROUND(100*population / (SELECT sum(population) FROM population),2) AS population_pct
FROM population
INNER JOIN fips_county
USING (fipscounty);

-- PART 2
-- Your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.


WITH opioid_labels AS 
	(SELECT * FROM
		(SELECT drug_name, generic_name,
			CASE 
				WHEN generic_name LIKE '%HYDROCODONE%' THEN 'HYDROCODONE'
				WHEN generic_name LIKE '%OXYCODONE%' THEN 'OXYCODONE'
				WHEN generic_name LIKE '%OXYMORPHONE%' THEN 'OXYMORPHONE'
				WHEN generic_name LIKE '%MORPHINE%' THEN 'MORPHINE'
				WHEN generic_name LIKE '%CODEINE%' THEN 'CODEINE'
				WHEN generic_name LIKE '%FENTANYL%' THEN 'FENTANYL'
			END AS label
		FROM drug) AS labels
		where label IS NOT NULL
		ORDER BY drug_name)
SELECT nppes_provider_city AS city, label, SUM(total_claim_count)
FROM prescription
INNER JOIN opioid_labels
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
GROUP BY label, city
ORDER BY city, label 
