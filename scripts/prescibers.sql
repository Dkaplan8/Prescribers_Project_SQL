-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
-- SELECT pr.npi, pr.nppes_provider_last_org_name, pn.total_claim_count
-- FROM prescriber AS pr
-- INNER JOIN prescription AS pn
-- USING (npi)
-- ORDER BY pn.total_claim_count DESC;

-- npi 1912011792	"COFFEY"	total claims 4538

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
-- SELECT pr.npi, pr.nppes_provider_first_name, pr.nppes_provider_last_org_name, pr.specialty_description, pn.total_claim_count
-- FROM prescriber AS pr
-- INNER JOIN prescription AS pn
-- USING (npi)
-- ORDER BY pn.total_claim_count DESC;

-- npi 1912011792	"DAVID"	"COFFEY"	"Family Practice"	total claims 4538

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
-- SELECT prescriber.specialty_description AS specialty, 	SUM(prescription.total_claim_count) AS total_claims
-- FROM prescriber
-- LEFT JOIN prescription
-- USING(npi)
-- WHERE prescription.total_claim_count IS NOT NULL
-- GROUP BY specialty
-- ORDER BY total_claims DESC
-- LIMIT 1;
--Family Practice
--     b. Which specialty had the most total number of claims for opioids?

-- SELECT prescriber.specialty_description AS specialty, COUNT(drug.opioid_drug_flag) AS count_opioid
-- FROM prescriber
-- LEFT JOIN prescription
-- USING(npi)
-- LEFT JOIN drug
-- USING(drug_name)
-- WHERE prescription.total_claim_count IS NOT NULL
-- AND drug.opioid_drug_flag = 'Y'
-- GROUP BY specialty
-- ORDER BY count_opioid DESC;

-- "Nurse Practitioner"	9551


--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

-- SELECT specialty_description, SUM(total_claim_count)
-- FROM prescriber
-- FULL JOIN prescription
-- USING(npi)
-- GROUP BY specialty_description
-- EXCEPT
-- (SELECT specialty_description, SUM(total_claim_count)
-- FROM prescriber
-- FULL JOIN prescription
-- USING(npi)
-- 	WHERE total_claim_count >= 0
-- GROUP BY specialty_description)


--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

-- SELECT d.generic_name, SUM(pr.total_drug_cost) AS total_drug_cost
-- FROM prescription as pr
-- JOIN drug as d ON pr.drug_name = d.drug_name
-- GROUP BY d.generic_name
-- ORDER BY total_drug_cost DESC
-- LIMIT 1;

--"INSULIN GLARGINE,HUM.REC.ANLOG"	104264066.35

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
-- SELECT d.generic_name, ROUND(SUM(pr.total_drug_cost) / SUM(pr.total_day_supply), 2) AS cost_per_day
-- FROM prescription as pr
-- INNER JOIN drug as d using(drug_name)
-- GROUP BY d.generic_name
-- ORDER BY cost_per_day DESC
-- LIMIT 1;

-- "C1 ESTERASE INHIBITOR"	3495.2190186915887850
-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

-- SELECT drug_name,
-- CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
-- WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
-- ELSE 'neither' END AS drug_type
-- FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

-- SELECT 'opiods' AS drug_category, CAST(SUM(pr.total_drug_cost)AS money) AS total_drug_cost
-- FROM prescription AS pr
-- INNER JOIN drug AS d ON pr.drug_name = d.drug_name
-- WHERE d.opioid_drug_flag = 'Y'
-- UNION ALL
-- SELECT 'antibiotics' AS drug_category, CAST(SUM(pr.total_drug_cost) AS money) AS total_drug_cost
-- FROM prescription as PR
-- INNER JOIN drug as D on pr.drug_name = d.drug_name
-- WHERE d.antibiotic_drug_flag = 'Y'
-- ORDER BY total_drug_cost DESC
-- LIMIT 1;

--"opiods"	"$105,080,626.37"

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

-- SELECT COUNT(*)
-- FROM cbsa
-- WHERE cbsaname LIKE '%TN';
--33

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
-- SELECT cb.cbsaname, SUM(p.population)
-- FROM cbsa as cb
-- LEFT JOIN population as p
-- USING (fipscounty)
-- WHERE population IS NOT NULL
-- GROUP BY p.population, cb.cbsaname
-- ORDER BY population ASC;
--memphis TN 937847 is largest, nashville-davidson-murfreesboro-fanklin TN 8773

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

-- SELECT population.population, population.fipscounty
-- FROM population
-- WHERE fipscounty NOT IN
-- (SELECT fipscounty
-- FROM cbsa)
-- ORDER BY population.population DESC;

--

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

-- SELECT drug_name, total_claim_count
-- FROM prescription AS pr
-- WHERE total_claim_count >= 3000
-- ORDER BY total_claim_count DESC;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
-- SELECT pr.drug_name, pr.total_claim_count, d.opioid_drug_flag
-- FROM prescription AS pr
-- LEFT JOIN drug AS d
-- USING (drug_name)
-- WHERE pr.total_claim_count >= 3000
-- AND d.opioid_drug_flag = 'Y'
-- ORDER BY total_claim_count DESC;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row

-- SELECT pn.drug_name, pn.total_claim_count, d.opioid_drug_flag, pr.nppes_provider_last_org_name, pr.nppes_provider_first_name
-- FROM prescription AS pn
-- LEFT JOIN drug AS d
-- USING (drug_name)
-- LEFT JOIN prescriber AS pr
-- USING (npi)
-- WHERE pn.total_claim_count >= 3000
-- AND d.opioid_drug_flag = 'Y'	
-- ORDER BY pn.total_claim_count DESC;

--DR. DAVID COFFEY sentenced to 40 months in prison for running a pill mill

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

-- SELECT pn.npi, pn.drug_name, pr.nppes_provider_city
-- FROM prescription AS pn
-- LEFT JOIN drug AS d
-- USING (drug_name)
-- LEFT JOIN prescriber as pr
-- USING (npi)
-- WHERE pr.nppes_provider_city = 'NASHVILLE'
-- AND d.opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

-- SELECT pn.npi, pn.drug_name, COALESCE(pn.total_claim_count)
-- FROM prescription AS pn
-- LEFT JOIN drug AS d
-- USING (drug_name)
-- LEFT JOIN prescriber as pr
-- USING (npi)

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function


-- 1. Write a query which returns the total number of claims for these two groups.

-- SELECT distinct(pr.specialty_description), pn.total_claim_count
-- from prescriber as pr
-- join prescription as pn
-- using (npi)
-- where pr.specialty_description IN ('Pain Management', 'Interventional Pain Management')
-- group by pn.total_claim_count, pr.specialty_description
